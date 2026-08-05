import logging
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc, asc, func
from typing import Literal

from app.database import get_db
from app.core.dependencies import get_current_user, require_permission
from app.core.rbac import Permission
from app.models.alert import Alert
from app.models.user import User
from app.models.enums import Severity
from app.schemas.alert import (
    AlertResponse,
    AlertCreate,
    AlertUpdate,
    AlertAcknowledge,
    AlertEscalateRequest,
    AlertListResponse,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/alerts", tags=["alerts"])


@router.post("/", response_model=AlertResponse, status_code=status.HTTP_201_CREATED)
async def create_alert(
    data: AlertCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.ALERT_CREATE)),
):
    alert = Alert(**data.model_dump())
    db.add(alert)
    await db.commit()
    await db.refresh(alert)
    logger.info(
        "Alert created",
        extra={
            "alert_id": str(alert.id),
            "patient_id": str(alert.patient_id),
            "severity": str(alert.severity),
            "user_id": str(current_user.id),
        },
    )
    return alert


@router.get("/", response_model=AlertListResponse)
async def get_alerts(
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=200),
    sort_by: str | None = Query(None),
    sort_order: Literal["asc", "desc"] = Query("desc"),
    patient_id: str | None = Query(None),
    severity: str | None = Query(None),
    alert_type: str | None = Query(None),
    is_acknowledged: bool | None = Query(None, alias="acknowledged"),
    is_resolved: bool | None = Query(None, alias="resolved"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.ALERT_LIST)),
):
    query = select(Alert)

    if patient_id:
        query = query.where(Alert.patient_id == patient_id)
    if severity:
        query = query.where(Alert.severity == severity)
    if alert_type:
        query = query.where(Alert.alert_type == alert_type)
    if is_acknowledged is not None:
        query = query.where(Alert.is_acknowledged == is_acknowledged)
    if is_resolved is not None:
        query = query.where(Alert.is_resolved == is_resolved)

    total = await db.scalar(select(func.count()).select_from(query.subquery()))

    sort_column = getattr(Alert, sort_by, None) if sort_by else Alert.created_at
    if sort_column is not None:
        order_fn = desc if sort_order == "desc" else asc
        query = query.order_by(order_fn(sort_column))

    query = query.offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(query)
    alerts = result.scalars().all()

    total_pages = max(1, (total + per_page - 1) // per_page)
    return AlertListResponse(
        items=[AlertResponse.model_validate(a) for a in alerts],
        total=total,
        page=page,
        per_page=per_page,
        total_pages=total_pages,
        has_next=page < total_pages,
        has_prev=page > 1,
    )


@router.get("/{alert_id}", response_model=AlertResponse)
async def get_alert(
    alert_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.ALERT_VIEW)),
):
    result = await db.execute(select(Alert).where(Alert.id == alert_id))
    alert = result.scalar_one_or_none()
    if not alert:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found"
        )
    return alert


@router.put("/{alert_id}", response_model=AlertResponse)
async def update_alert(
    alert_id: uuid.UUID,
    data: AlertUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.ALERT_UPDATE)),
):
    result = await db.execute(select(Alert).where(Alert.id == alert_id))
    alert = result.scalar_one_or_none()
    if not alert:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found"
        )

    update_data = data.model_dump(exclude_unset=True)
    if update_data:
        for key, value in update_data.items():
            setattr(alert, key, value)

    await db.commit()
    await db.refresh(alert)
    return alert


@router.patch("/{alert_id}/acknowledge", response_model=AlertResponse)
async def acknowledge_alert(
    alert_id: uuid.UUID,
    data: AlertAcknowledge,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.ALERT_ACKNOWLEDGE)),
):
    result = await db.execute(select(Alert).where(Alert.id == alert_id))
    alert = result.scalar_one_or_none()
    if not alert:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found"
        )

    alert.is_acknowledged = data.is_acknowledged
    alert.acknowledged_by = current_user.id
    alert.acknowledged_at = datetime.now(timezone.utc)

    await db.commit()
    await db.refresh(alert)
    logger.info(
        "Alert acknowledged",
        extra={"alert_id": str(alert_id), "user_id": str(current_user.id)},
    )
    return alert


@router.post("/{alert_id}/escalate", response_model=AlertResponse)
async def escalate_alert(
    alert_id: uuid.UUID,
    data: AlertEscalateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.ALERT_UPDATE)),
):
    result = await db.execute(select(Alert).where(Alert.id == alert_id))
    alert = result.scalar_one_or_none()
    if not alert:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found"
        )

    alert.severity = Severity.CRITICAL
    alert.extra_data = {
        **(alert.extra_data or {}),
        "escalated_at": datetime.now(timezone.utc).isoformat(),
        "escalated_by": str(current_user.id),
        "escalation_reason": data.reason,
        "previous_severity": str(alert.severity),
    }

    await db.commit()
    await db.refresh(alert)
    logger.info(
        "Alert escalated",
        extra={
            "alert_id": str(alert_id),
            "user_id": str(current_user.id),
            "reason": data.reason,
        },
    )
    return alert
