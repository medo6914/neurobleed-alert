import json
import logging
from typing import Any, Dict, Optional
from uuid import UUID

from app.core.redis import get_redis

logger = logging.getLogger(__name__)

_TASK_NS = "neurobleed:tasks"


async def enqueue_task(queue: str, task_data: Dict[str, Any]) -> bool:
    redis = await get_redis()
    if redis is None:
        logger.warning(f"Cannot enqueue task, Redis unavailable (queue={queue})")
        return False
    try:
        key = f"{_TASK_NS}:{queue}"
        serialized = json.dumps(task_data, default=str)
        await redis.lpush(key, serialized)
        return True
    except Exception as e:
        logger.warning(f"Enqueue task error: {e}")
        return False


async def dequeue_task(queue: str, timeout: int = 5) -> Optional[Dict[str, Any]]:
    redis = await get_redis()
    if redis is None:
        return None
    try:
        key = f"{_TASK_NS}:{queue}"
        result = await redis.brpop(key, timeout=timeout)
        if result is None:
            return None
        _, serialized = result
        return json.loads(serialized)
    except Exception as e:
        logger.warning(f"Dequeue task error: {e}")
        return None


async def enqueue_email(to: str, subject: str, body: str) -> bool:
    return await enqueue_task("email", {
        "to": to,
        "subject": subject,
        "body": body,
    })


async def enqueue_alert_processing(alert_id: UUID) -> bool:
    return await enqueue_task("alert_processing", {
        "alert_id": str(alert_id),
    })
