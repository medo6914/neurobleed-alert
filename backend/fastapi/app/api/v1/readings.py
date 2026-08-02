from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from datetime import datetime, timedelta, timezone

from app.database import get_db
from app.core.dependencies import get_current_user, require_permission
from app.core.event_bus import event_bus
from app.core.rbac import Permission
from app.models.sensor_reading import SensorReading
from app.models.user import User
from app.schemas.sensor_reading import SensorReadingCreate, SensorReadingResponse

router = APIRouter(prefix="/readings", tags=["readings"])


@router.post("/", response_model=SensorReadingResponse, status_code=status.HTTP_201_CREATED)
async def create_reading(
    data: SensorReadingCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.PATIENT_CREATE)),
):
    reading = SensorReading(**data.model_dump())
    db.add(reading)
    await db.commit()
    await db.refresh(reading)

    await event_bus.publish("reading.created", {
        "reading_id": reading.id,
        "patient_id": reading.patient_id,
        "device_id": reading.device_id,
        "timestamp": reading.timestamp.isoformat() if reading.timestamp else None,
    })

    from app.api.v1.device_ws import manager

    await manager.broadcast_reading({
        "type": "vitals_update",
        "patient_id": str(reading.patient_id),
        "device_id": str(reading.device_id) if reading.device_id else None,
        "heart_rate": reading.heart_rate,
        "spo2": reading.spo2,
        "rso2": reading.rso2,
        "signal_quality": reading.signal_quality,
        "motion_artifact": reading.motion_artifact,
        "risk_score": reading.risk_score,
        "risk_level": reading.risk_level.value if hasattr(reading.risk_level, "value") else str(reading.risk_level),
        "timestamp": reading.timestamp.isoformat() if reading.timestamp else None,
    })

    return reading


@router.get("/", response_model=list[SensorReadingResponse])
async def get_readings(
    patient_id: str | None = Query(None),
    limit: int = Query(100, le=1000),
    hours: int = Query(24, le=168),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.MONITORING_VIEW)),
):
    since = datetime.now(timezone.utc) - timedelta(hours=hours)
    query = select(SensorReading).where(SensorReading.timestamp >= since)

    if patient_id:
        query = query.where(SensorReading.patient_id == patient_id)

    query = query.order_by(desc(SensorReading.timestamp)).limit(limit)
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/latest", response_model=SensorReadingResponse | None)
async def get_latest_reading(
    patient_id: str = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.MONITORING_VIEW)),
):
    result = await db.execute(
        select(SensorReading)
        .where(SensorReading.patient_id == patient_id)
        .order_by(desc(SensorReading.timestamp))
        .limit(1)
    )
    return result.scalar_one_or_none()
