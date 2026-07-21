import logging
from typing import Optional

import redis.asyncio as aioredis
from redis import RedisError

from app.config import settings

logger = logging.getLogger(__name__)

redis_client: Optional[aioredis.Redis] = None


async def get_redis() -> Optional[aioredis.Redis]:
    return redis_client


async def init_redis():
    global redis_client
    try:
        redis_client = aioredis.from_url(
            settings.REDIS_URL,
            max_connections=50,
            decode_responses=True,
            socket_connect_timeout=2,
            socket_timeout=2,
            retry_on_timeout=True,
        )
        await redis_client.ping()
        logger.info("Redis connection established")
    except RedisError as e:
        logger.warning(f"Redis connection failed: {e}. Running without Redis.")
        redis_client = None


async def close_redis():
    global redis_client
    if redis_client is not None:
        try:
            await redis_client.aclose()
        except RedisError as e:
            logger.warning(f"Error closing Redis: {e}")
        finally:
            redis_client = None
            logger.info("Redis connection closed")
