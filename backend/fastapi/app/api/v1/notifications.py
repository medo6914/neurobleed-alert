import logging
import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.core.firebase import send_push
from app.database import get_db
from app.models.device import Device
from app.models.enums import UserRole
from app.models.user import User

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/notifications", tags=["notifications"])


class FCMTokenRequest(BaseModel):
    fcm_token: str
    device_id: str | None = None
    platform: str = "android"


class PushRequest(BaseModel):
    token: str | None = None
    topic: str | None = None
    title: str
    body: str
    data: dict | None = None


@router.post("/register-token", status_code=status.HTTP_200_OK)
async def register_fcm_token(
    data: FCMTokenRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not data.fcm_token:
        raise HTTPException(status_code=400, detail="fcm_token is required")
    if data.device_id:
        await db.execute(
            update(Device)
            .where(
                Device.id == uuid.UUID(data.device_id),
                Device.patient_id == str(current_user.id),
            )
            .values(fcm_token=data.fcm_token)
        )
        await db.commit()
    return {"status": "registered", "user_id": str(current_user.id)}


@router.post("/test", status_code=status.HTTP_200_OK)
async def test_push(
    data: PushRequest,
    current_user: User = Depends(get_current_user),
):
    if current_user.role not in (UserRole.ADMIN, UserRole.SUPER_ADMIN):
        raise HTTPException(status_code=403, detail="Only admins can send test pushes")
    ok = await send_push(data.token, data.title, data.body, data.data, data.topic)
    return {"status": "sent" if ok else "skipped", "configured": ok}
