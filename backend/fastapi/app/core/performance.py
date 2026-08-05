import asyncio
import logging
import re
import time
from collections import defaultdict
from contextvars import ContextVar
from functools import wraps
from typing import Any, Callable

from sqlalchemy import Select

logger = logging.getLogger(__name__)

_query_timing_enabled: ContextVar[bool] = ContextVar(
    "_query_timing_enabled", default=False
)
_n1_detection_enabled: ContextVar[bool] = ContextVar(
    "_n1_detection_enabled", default=False
)


def enable_query_timing():
    _query_timing_enabled.set(True)


def disable_query_timing():
    _query_timing_enabled.set(False)


def enable_n1_detection():
    _n1_detection_enabled.set(True)


def disable_n1_detection():
    _n1_detection_enabled.set(False)


def track_query_time(threshold_ms: float = 100):
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def async_wrapper(*args, **kwargs):
            if not _query_timing_enabled.get():
                return await func(*args, **kwargs)
            start = time.perf_counter()
            try:
                return await func(*args, **kwargs)
            finally:
                elapsed = (time.perf_counter() - start) * 1000
                if elapsed > threshold_ms:
                    logger.warning(
                        "Slow query detected: %s took %.2fms (threshold: %.2fms)",
                        func.__qualname__,
                        elapsed,
                        threshold_ms,
                    )

        @wraps(func)
        def sync_wrapper(*args, **kwargs):
            if not _query_timing_enabled.get():
                return func(*args, **kwargs)
            start = time.perf_counter()
            try:
                return func(*args, **kwargs)
            finally:
                elapsed = (time.perf_counter() - start) * 1000
                if elapsed > threshold_ms:
                    logger.warning(
                        "Slow query detected: %s took %.2fms (threshold: %.2fms)",
                        func.__qualname__,
                        elapsed,
                        threshold_ms,
                    )

        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        return sync_wrapper

    return decorator


class NPlusOneDetector:
    _request_queries: ContextVar[dict] = ContextVar("_request_queries", default=None)

    def __init__(self, threshold: int = 5):
        self.threshold = threshold

    def record_query(self, sql: str):
        queries = self._request_queries.get()
        if queries is None:
            return
        normalized = self._normalize(sql)
        queries[normalized] = queries.get(normalized, 0) + 1

    def _normalize(self, sql: str) -> str:
        normalized = re.sub(r"'[^']*'", "'?'", sql)
        normalized = re.sub(r"\b\d+\b", "?", normalized)
        return normalized

    def check(self) -> list[dict]:
        queries = self._request_queries.get()
        if not queries:
            return []
        suspects = []
        for sql, count in queries.items():
            if count >= self.threshold:
                suspects.append({"sql": sql, "count": count})
        return suspects

    async def __aenter__(self):
        self._token = self._request_queries.set(defaultdict(int))
        return self

    async def __aexit__(self, *args):
        suspects = self.check()
        if suspects:
            logger.warning(
                "N+1 query detected: %d query patterns executed %d+ times",
                len(suspects),
                self.threshold,
            )
            for s in suspects:
                logger.warning("  Pattern (x%d): %s", s["count"], s["sql"])
        self._request_queries.reset(self._token)


def apply_query_optimizations(stmt: Select) -> Select:
    return stmt
