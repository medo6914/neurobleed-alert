import asyncio
import json
import logging
from typing import Callable, Coroutine, Any

from app.core.redis import get_redis

logger = logging.getLogger(__name__)

EventHandler = Callable[[str, dict], Coroutine[Any, Any, None]]


class EventBus:
    def __init__(self):
        self._handlers: dict[str, list[EventHandler]] = {}

    def subscribe(self, event_type: str, handler: EventHandler):
        if event_type not in self._handlers:
            self._handlers[event_type] = []
        self._handlers[event_type].append(handler)

    def unsubscribe(self, event_type: str, handler: EventHandler):
        if event_type in self._handlers:
            self._handlers[event_type] = [h for h in self._handlers[event_type] if h is not handler]

    async def publish(self, event_type: str, data: dict):
        handlers = self._handlers.get(event_type, [])
        if handlers:
            results = await asyncio.gather(
                *[handler(event_type, data) for handler in handlers],
                return_exceptions=True,
            )
            for i, result in enumerate(results):
                if isinstance(result, Exception):
                    logger.error(f"Event handler[{i}] error for {event_type}: {result}")

        redis = await get_redis()
        if redis is not None:
            try:
                await redis.publish(
                    f"event:{event_type}",
                    json.dumps(data, default=str),
                )
            except Exception as e:
                logger.debug(f"Redis pub failed for {event_type}: {e}")


event_bus = EventBus()
