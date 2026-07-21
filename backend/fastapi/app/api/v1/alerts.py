from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from datetime import datetime, timezone

from app.database import get_db
from app.core.dependencies import get_current_user, require_permission
from app.core.rbac import Permission
from app.models.alert import Alert
from app.models.user import User
from app.schemas.alert import AlertResponse, AlertAcknowledge

router = APIRouter(prefix="/alerts", tags=["alerts"])


@router.get("/", response_model=list[AlertResponse])
async def get_alerts(
    patient_id: str | None = Query(None),
    is_acknowledged: bool | None = Query(None, alias="acknowledged"),
    limit: int = Query(50, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.ALERT_LIST)),
):
    query = select(Alert)

    if patient_id:
        query = query.where(Alert.patient_id == patient_id)
    if is_acknowledged is not None:
        query = query.where(Alert.is_acknowledged == is_acknowledged)

    query = query.order_by(desc(Alert.created_at)).limit(limit)
    result = await db.execute(query)
    return result.scalars().all()


@router.patch("/{alert_id}/acknowledge", response_model=AlertResponse)
async def acknowledge_alert(
    alert_id: str,
    data: AlertAcknowledge,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.ALERT_ACKNOWLEDGE)),
):
    result = await db.execute(select(Alert).where(Alert.id == alert_id))
    alert = result.scalar_one_or_none()
    if not alert:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found")

    alert.is_acknowledged = data.is_acknowledged
    alert.acknowledged_by = current_user.id
    alert.acknowledged_at = datetime.now(timezone.utc)

    await db.commit()
    await db.refresh(alert)
    return alert
