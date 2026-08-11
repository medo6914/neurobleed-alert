import logging
from uuid import UUID

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.core.dependencies import get_current_user, require_permission
from app.core.rbac import Permission
from app.models.user import User
from app.schemas.analytics import (
    AnalyticsOverview,
    PatientAnalytics,
    DeviceAnalytics,
    AlertAnalytics,
    HospitalOverview,
    SystemHealth,
    ActivityFeedItem,
)
from app.services.analytics_service import AnalyticsService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/analytics", tags=["analytics"])


async def get_analytics_service(db: AsyncSession = Depends(get_db)) -> AnalyticsService:
    return AnalyticsService(db)


@router.get("/overview", response_model=AnalyticsOverview)
async def get_analytics_overview(
    hospital_id: UUID | None = None,
    service: AnalyticsService = Depends(get_analytics_service),
    current_user: User = Depends(require_permission(Permission.ADMIN_ACCESS, Permission.PATIENT_VIEW)),
):
    return await service.get_overview(hospital_id=hospital_id)


@router.get("/patients", response_model=PatientAnalytics)
async def get_patient_analytics(
    hospital_id: UUID | None = None,
    service: AnalyticsService = Depends(get_analytics_service),
    current_user: User = Depends(require_permission(Permission.PATIENT_VIEW)),
):
    return await service.get_patient_analytics(hospital_id=hospital_id)


@router.get("/devices", response_model=DeviceAnalytics)
async def get_device_analytics(
    hospital_id: UUID | None = None,
    service: AnalyticsService = Depends(get_analytics_service),
    current_user: User = Depends(require_permission(Permission.DEVICE_LIST)),
):
    return await service.get_device_analytics(hospital_id=hospital_id)


@router.get("/alerts", response_model=AlertAnalytics)
async def get_alert_analytics(
    hospital_id: UUID | None = None,
    service: AnalyticsService = Depends(get_analytics_service),
    current_user: User = Depends(require_permission(Permission.ALERT_LIST)),
):
    return await service.get_alert_analytics(hospital_id=hospital_id)


@router.get("/hospitals", response_model=HospitalOverview)
async def get_hospital_overview(
    service: AnalyticsService = Depends(get_analytics_service),
    current_user: User = Depends(require_permission(Permission.ADMIN_ACCESS, Permission.PATIENT_VIEW)),
):
    return await service.get_hospital_overview()


@router.get("/system-health", response_model=SystemHealth)
async def get_system_health(
    service: AnalyticsService = Depends(get_analytics_service),
    current_user: User = Depends(require_permission(Permission.ADMIN_ACCESS)),
):
    return await service.get_system_health()


@router.get("/activity-feed", response_model=list[ActivityFeedItem])
async def get_activity_feed(
    limit: int = Query(50, le=200),
    service: AnalyticsService = Depends(get_analytics_service),
    current_user: User = Depends(require_permission(Permission.ADMIN_ACCESS, Permission.PATIENT_VIEW)),
):
    return await service.get_activity_feed(limit=limit)
