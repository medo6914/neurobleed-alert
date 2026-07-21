import json
import logging
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, status
from sqlalchemy import select

from app.database import get_db
from app.core.security import decode_access_token
from app.models.user import User

router = APIRouter()
logger = logging.getLogger(__name__)


class MonitorConnectionManager:
    def __init__(self):
        self._user_connections: dict[str, list[WebSocket]] = {}
        self._patient_subscribers: dict[str, set[str]] = {}
        self._ws_user_map: dict[int, str] = {}

    async def connect(self, user_id: str, websocket: WebSocket):
        await websocket.accept()
        if user_id not in self._user_connections:
            self._user_connections[user_id] = []
        self._user_connections[user_id].append(websocket)
        self._ws_user_map[id(websocket)] = user_id

    def disconnect(self, user_id: str, websocket: WebSocket):
        ws_id = id(websocket)
        if user_id in self._user_connections:
            self._user_connections[user_id].remove(websocket)
            if not self._user_connections[user_id]:
                del self._user_connections[user_id]

        for patient_id in list(self._patient_subscribers.keys()):
            self._patient_subscribers[patient_id].discard(user_id)
            if not self._patient_subscribers[patient_id]:
                del self._patient_subscribers[patient_id]

        self._ws_user_map.pop(ws_id, None)

    def subscribe(self, user_id: str, patient_id: str):
        if patient_id not in self._patient_subscribers:
            self._patient_subscribers[patient_id] = set()
        self._patient_subscribers[patient_id].add(user_id)

    def unsubscribe(self, user_id: str, patient_id: str):
        if patient_id in self._patient_subscribers:
            self._patient_subscribers[patient_id].discard(user_id)
            if not self._patient_subscribers[patient_id]:
                del self._patient_subscribers[patient_id]

    async def _send_to_user(self, user_id: str, message: dict):
        if user_id not in self._user_connections:
            return
        for ws in self._user_connections[user_id][:]:
            try:
                await ws.send_json(message)
            except Exception:
                self._user_connections[user_id].remove(ws)

    async def broadcast_reading(self, message: dict):
        patient_id = message.get("patient_id", "")
        subscribers = self._patient_subscribers.get(patient_id, set())
        for user_id in subscribers:
            await self._send_to_user(user_id, message)

    async def broadcast_alert(self, message: dict):
        patient_id = message.get("patient_id", "")
        subscribers = self._patient_subscribers.get(patient_id, set())
        for user_id in subscribers:
            await self._send_to_user(user_id, message)

    async def broadcast_to_all(self, message: dict):
        for user_id in list(self._user_connections.keys()):
            await self._send_to_user(user_id, message)


manager = MonitorConnectionManager()


async def _verify_ws_token(token: str) -> User | None:
    payload = decode_access_token(token)
    if payload is None:
        return None
    user_id_str = payload.get("sub")
    if user_id_str is None:
        return None
    try:
        user_id = uuid.UUID(user_id_str)
    except ValueError:
        return None
    async for db in get_db():
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if user is None or not user.is_active:
            return None
        return user
    return None


@router.websocket("/ws/devices/{device_id}/telemetry")
async def device_telemetry(websocket: WebSocket, device_id: str):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_text()
            msg = json.loads(data)
            await manager.broadcast_reading({
                "type": "device_telemetry",
                "device_id": device_id,
                "data": msg,
                "timestamp": datetime.now(timezone.utc).isoformat(),
            })
    except WebSocketDisconnect:
        pass
    except Exception as e:
        logger.error("Telemetry WS error", extra={"device_id": device_id, "error": str(e)})


@router.websocket("/ws/devices/monitor")
async def device_monitor(websocket: WebSocket):
    token = websocket.query_params.get("token")
    if not token:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Missing token")
        return

    user = await _verify_ws_token(token)
    if user is None:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Invalid token")
        return

    user_id = str(user.id)
    await manager.connect(user_id, websocket)

    try:
        await manager._send_to_user(user_id, {
            "type": "connected",
            "user_id": user_id,
            "role": user.role.value if hasattr(user.role, "value") else str(user.role),
        })

        while True:
            data = await websocket.receive_text()
            msg = json.loads(data)
            action = msg.get("action")

            if action == "subscribe":
                patient_id = msg.get("patient_id")
                if patient_id:
                    manager.subscribe(user_id, patient_id)
                    await manager._send_to_user(user_id, {
                        "type": "subscribed",
                        "patient_id": patient_id,
                    })

            elif action == "unsubscribe":
                patient_id = msg.get("patient_id")
                if patient_id:
                    manager.unsubscribe(user_id, patient_id)
                    await manager._send_to_user(user_id, {
                        "type": "unsubscribed",
                        "patient_id": patient_id,
                    })

            elif action == "ping":
                await manager._send_to_user(user_id, {"type": "pong"})

    except WebSocketDisconnect:
        manager.disconnect(user_id, websocket)
    except Exception as e:
        logger.error("Monitor WS error", extra={"user_id": user_id, "error": str(e)})
        manager.disconnect(user_id, websocket)
