import logging
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func, desc, or_
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.core.dependencies import get_current_user, require_permission
from app.core.rbac import Permission
from app.models.user import User
from app.models.device import Device
from app.models.audit_log import AuditLog
from app.models.enums import DeviceStatus

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/devices/{device_id}/history", tags=["device-history"])


@router.get("/events")
async def get_device_events(
    device_id: UUID,
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=1000),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.DEVICE_VIEW)),
):
    result = await db.execute(
        select(Device).where(Device.id == device_id, Device.is_active == True)
    )
    device = result.scalar_one_or_none()
    if not device:
        raise HTTPException(404, "Device not found")

    resource_pattern = f"/v1/devices/{device_id}"
    count_query = (
        select(func.count())
        .select_from(AuditLog)
        .where(
            AuditLog.resource.like(f"%{resource_pattern}%"),
        )
    )
    total = (await db.execute(count_query)).scalar() or 0

    events_query = (
        select(AuditLog)
        .where(AuditLog.resource.like(f"%{resource_pattern}%"))
        .order_by(desc(AuditLog.created_at))
        .offset((page - 1) * per_page)
        .limit(per_page)
    )
    events = (await db.execute(events_query)).scalars().all()

    return {
        "device_id": str(device_id),
        "events": [
            {
                "id": str(e.id),
                "action": e.action,
                "resource": e.resource,
                "resource_id": e.resource_id,
                "details": e.details,
                "user_id": str(e.user_id) if e.user_id else None,
                "ip_address": e.ip_address,
                "correlation_id": e.correlation_id,
                "timestamp": e.created_at.isoformat() if e.created_at else None,
            }
            for e in events
        ],
        "total": total,
        "page": page,
        "per_page": per_page,
    }


@router.get("/status-changes")
async def get_device_status_changes(
    device_id: UUID,
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=1000),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.DEVICE_VIEW)),
):
    result = await db.execute(
        select(Device).where(Device.id == device_id, Device.is_active == True)
    )
    device = result.scalar_one_or_none()
    if not device:
        raise HTTPException(404, "Device not found")

    resource_pattern = f"/v1/devices/{device_id}"
    status_filter = or_(
        AuditLog.resource == f"/v1/devices/{device_id}/status",
        AuditLog.resource == f"/v1/devices/{device_id}/heartbeat",
        AuditLog.action == "PATCH",
    )
    count_query = (
        select(func.count())
        .select_from(AuditLog)
        .where(
            AuditLog.resource.like(f"%{resource_pattern}%"),
            status_filter,
        )
    )
    total = (await db.execute(count_query)).scalar() or 0

    changes_query = (
        select(AuditLog)
        .where(
            AuditLog.resource.like(f"%{resource_pattern}%"),
            status_filter,
        )
        .order_by(desc(AuditLog.created_at))
        .offset((page - 1) * per_page)
        .limit(per_page)
    )
    changes = (await db.execute(changes_query)).scalars().all()

    return {
        "device_id": str(device_id),
        "current_status": device.status.value,
        "changes": [
            {
                "id": str(c.id),
                "action": c.action,
                "details": c.details,
                "user_id": str(c.user_id) if c.user_id else None,
                "timestamp": c.created_at.isoformat() if c.created_at else None,
            }
            for c in changes
        ],
        "total": total,
        "page": page,
        "per_page": per_page,
    }
