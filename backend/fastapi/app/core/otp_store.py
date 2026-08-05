import json
import logging
import secrets
from datetime import datetime, timezone
from typing import Optional

from app.core.redis import get_redis

logger = logging.getLogger(__name__)

_OTP_NS = "neurobleed:otp"
_OTP_RATE_NS = "neurobleed:otp_rate"
_MAX_OTP_PER_HOUR = 5
_OTP_TTL = 300


async def store_otp(email_or_phone: str, otp: str, ttl: int = _OTP_TTL) -> bool:
    redis = await get_redis()
    if redis is None:
        return False
    try:
        key = f"{_OTP_NS}:{email_or_phone}"
        data = json.dumps(
            {
                "otp": otp,
                "verified": False,
                "attempts": 0,
                "created_at": datetime.now(timezone.utc).isoformat(),
            }
        )
        await redis.setex(key, ttl, data)
        return True
    except Exception as e:
        logger.warning(f"OTP store error: {e}")
        return False


async def verify_otp(email_or_phone: str, otp: str) -> bool:
    redis = await get_redis()
    if redis is None:
        return False
    try:
        key = f"{_OTP_NS}:{email_or_phone}"
        data = await redis.get(key)
        if data is None:
            return False

        record = json.loads(data)
        if record.get("verified"):
            return False

        record["attempts"] += 1
        if record["attempts"] > 3:
            await redis.delete(key)
            return False

        if record["otp"] != otp:
            ttl = await redis.ttl(key)
            await redis.setex(key, max(ttl, 1), json.dumps(record))
            return False

        record["verified"] = True
        ttl = await redis.ttl(key)
        await redis.setex(key, max(ttl, 1), json.dumps(record))
        return True
    except Exception as e:
        logger.warning(f"OTP verify error: {e}")
        return False


async def delete_otp(email_or_phone: str) -> bool:
    redis = await get_redis()
    if redis is None:
        return False
    try:
        key = f"{_OTP_NS}:{email_or_phone}"
        await redis.delete(key)
        return True
    except Exception as e:
        logger.warning(f"OTP delete error: {e}")
        return False


async def check_otp_rate_limit(email_or_phone: str) -> bool:
    redis = await get_redis()
    if redis is None:
        return True
    try:
        hour_bucket = datetime.now(timezone.utc).strftime("%Y%m%d%H")
        key = f"{_OTP_RATE_NS}:{email_or_phone}:{hour_bucket}"
        count = await redis.incr(key)
        if count == 1:
            await redis.expire(key, 3600)
        return count <= _MAX_OTP_PER_HOUR
    except Exception as e:
        logger.warning(f"OTP rate limit check error: {e}")
        return True
