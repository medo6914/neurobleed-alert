import json
import logging
from typing import List, Optional
from uuid import UUID

from app.core.redis import get_redis

logger = logging.getLogger(__name__)

_SESSION_NS = "neurobleed:session"
_USER_SESSIONS_NS = "neurobleed:user_sessions"
_DEFAULT_TTL = 3600


async def store_session(user_id: UUID, token_jti: str, ttl: int = _DEFAULT_TTL) -> bool:
    redis = await get_redis()
    if redis is None:
        return False
    try:
        session_key = f"{_SESSION_NS}:{token_jti}"
        await redis.setex(session_key, ttl, str(user_id))
        user_sessions_key = f"{_USER_SESSIONS_NS}:{user_id}"
        await redis.sadd(user_sessions_key, token_jti)
        await redis.expire(user_sessions_key, ttl)
        return True
    except Exception as e:
        logger.warning(f"Session store error: {e}")
        return False


async def validate_session(token_jti: str) -> Optional[str]:
    redis = await get_redis()
    if redis is None:
        return None
    try:
        session_key = f"{_SESSION_NS}:{token_jti}"
        user_id = await redis.get(session_key)
        return user_id
    except Exception as e:
        logger.warning(f"Session validate error: {e}")
        return None


async def invalidate_session(token_jti: str) -> bool:
    redis = await get_redis()
    if redis is None:
        return False
    try:
        session_key = f"{_SESSION_NS}:{token_jti}"
        user_id = await redis.get(session_key)
        await redis.delete(session_key)
        if user_id:
            user_sessions_key = f"{_USER_SESSIONS_NS}:{user_id}"
            await redis.srem(user_sessions_key, token_jti)
        return True
    except Exception as e:
        logger.warning(f"Session invalidate error: {e}")
        return False


async def invalidate_user_sessions(user_id: UUID) -> int:
    redis = await get_redis()
    if redis is None:
        return 0
    try:
        user_sessions_key = f"{_USER_SESSIONS_NS}:{user_id}"
        token_jtis = await redis.smembers(user_sessions_key)
        if not token_jtis:
            return 0
        session_keys = [f"{_SESSION_NS}:{jti}" for jti in token_jtis]
        session_keys.append(user_sessions_key)
        deleted = await redis.delete(*session_keys)
        return deleted
    except Exception as e:
        logger.warning(f"User sessions invalidate error: {e}")
        return 0


async def get_active_sessions(user_id: UUID) -> List[str]:
    redis = await get_redis()
    if redis is None:
        return []
    try:
        user_sessions_key = f"{_USER_SESSIONS_NS}:{user_id}"
        token_jtis = await redis.smembers(user_sessions_key)
        return list(token_jtis) if token_jtis else []
    except Exception as e:
        logger.warning(f"Get active sessions error: {e}")
        return []
