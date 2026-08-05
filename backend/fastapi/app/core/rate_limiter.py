import logging
import time
from collections import defaultdict
from typing import Optional

from fastapi import FastAPI, Request, HTTPException, status
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response

from app.config import settings
from app.core.redis import get_redis

logger = logging.getLogger(__name__)

_RATELIMIT_NS = "neurobleed:ratelimit"


class InMemoryRateLimitStore:
    def __init__(self):
        self._requests: dict[str, list[float]] = defaultdict(list)

    def check(self, key: str, max_requests: int, window_seconds: int) -> bool:
        now = time.time()
        window_start = now - window_seconds
        self._requests[key] = [t for t in self._requests[key] if t > window_start]
        if len(self._requests[key]) >= max_requests:
            return False
        self._requests[key].append(now)
        return True

    def cleanup(self):
        now = time.time()
        for key in list(self._requests.keys()):
            self._requests[key] = [t for t in self._requests[key] if t > now - 300]
            if not self._requests[key]:
                del self._requests[key]


_fallback_store = InMemoryRateLimitStore()

PRODUCTION_LIMITS = {
    "/v1/auth/register": (5, 3600),
    "/v1/auth/login": (10, 300),
    "/v1/auth/forgot-password": (3, 3600),
    "/v1/auth/send-otp": (5, 600),
    "/v1/auth/send-phone-verification": (5, 600),
    "/v1/patients": (300, 60),
    "/v1/devices": (300, 60),
    "/v1/readings": (600, 60),
    "/v1/alerts": (200, 60),
    "/v1/ai/risk/assess": (100, 60),
    "/v1/ai/knowledge/search": (60, 60),
}


async def _check_redis_rate(key: str, max_requests: int, window_seconds: int) -> bool:
    redis = await get_redis()
    if redis is None:
        return _fallback_store.check(key, max_requests, window_seconds)
    try:
        redis_key = f"{_RATELIMIT_NS}:{key}"
        now = time.time()
        window_start = now - window_seconds

        pipe = redis.pipeline()
        pipe.zremrangebyscore(redis_key, "-inf", window_start)
        pipe.zadd(redis_key, {str(now): now})
        pipe.zcard(redis_key)
        pipe.expire(redis_key, window_seconds)
        results = await pipe.execute()

        count = results[2]
        return count <= max_requests
    except Exception as e:
        logger.warning(f"Redis rate check failed, falling back to in-memory: {e}")
        return _fallback_store.check(key, max_requests, window_seconds)


class RateLimitMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if settings.ENVIRONMENT in ("test", "development"):
            return await call_next(request)

        path = request.url.path

        forwarded = request.headers.get("X-Forwarded-For")
        if forwarded:
            client_ip = forwarded.split(",")[0].strip()
        else:
            client_ip = request.client.host if request.client else "unknown"

        matched_path = None
        for limit_path, (max_req, window) in PRODUCTION_LIMITS.items():
            if (
                path == limit_path
                or path.startswith(limit_path + "/")
                or path.startswith(limit_path + "?")
            ):
                matched_path = limit_path
                break
            path_parts = path.rstrip("/").split("/")
            limit_parts = limit_path.rstrip("/").split("/")
            if len(path_parts) >= 2 and len(limit_parts) >= 2:
                if path_parts[0:2] == limit_parts[0:2]:
                    matched_path = limit_path
                    break

        if matched_path:
            max_req, window = PRODUCTION_LIMITS[matched_path]
            key = f"{client_ip}:{matched_path}"
            if not await _check_redis_rate(key, max_req, window):
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail="Too many requests. Please try again later.",
                )
        response = await call_next(request)
        return response


def add_rate_limiting(app: FastAPI):
    app.add_middleware(RateLimitMiddleware)
