import functools
import json
import logging
from typing import Any, Callable, Optional

from app.core.redis import get_redis

logger = logging.getLogger(__name__)

_NS = "neurobleed:cache"


async def get_cache(key: str) -> Any:
    redis = await get_redis()
    if redis is None:
        return None
    try:
        data = await redis.get(f"{_NS}:{key}")
        if data is None:
            return None
        return json.loads(data)
    except Exception as e:
        logger.warning(f"Cache get error: {e}")
        return None


async def set_cache(key: str, value: Any, ttl: int = 300) -> bool:
    redis = await get_redis()
    if redis is None:
        return False
    try:
        serialized = json.dumps(value, default=str)
        await redis.setex(f"{_NS}:{key}", ttl, serialized)
        return True
    except Exception as e:
        logger.warning(f"Cache set error: {e}")
        return False


async def delete_cache(key: str) -> bool:
    redis = await get_redis()
    if redis is None:
        return False
    try:
        await redis.delete(f"{_NS}:{key}")
        return True
    except Exception as e:
        logger.warning(f"Cache delete error: {e}")
        return False


async def delete_pattern(pattern: str) -> int:
    redis = await get_redis()
    if redis is None:
        return 0
    try:
        cursor = 0
        deleted = 0
        while True:
            cursor, keys = await redis.scan(cursor, match=f"{_NS}:{pattern}", count=100)
            if keys:
                deleted += await redis.delete(*keys)
            if cursor == 0:
                break
        return deleted
    except Exception as e:
        logger.warning(f"Cache delete_pattern error: {e}")
        return 0


async def get_or_set(key: str, factory: Callable, ttl: int = 300) -> Any:
    cached = await get_cache(key)
    if cached is not None:
        return cached
    value = await factory()
    await set_cache(key, value, ttl)
    return value


def cached(ttl: int = 300, prefix: str = ""):
    def decorator(func):
        @functools.wraps(func)
        async def wrapper(*args, **kwargs):
            cache_key = f"{prefix}:{func.__name__}" if prefix else func.__name__
            result = await get_cache(cache_key)
            if result is not None:
                return result
            result = await func(*args, **kwargs)
            await set_cache(cache_key, result, ttl)
            return result
        return wrapper
    return decorator
