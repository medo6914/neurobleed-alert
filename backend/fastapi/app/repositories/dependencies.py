from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.repositories.repositories import (
    AIReportRepository,
    AlertRepository,
    AuditLogRepository,
    DepartmentRepository,
    DeviceRepository,
    HospitalRepository,
    KnowledgeBaseRepository,
    KnowledgeUpdateLogRepository,
    OrganizationRepository,
    PatientRepository,
    PermissionRepository,
    RefreshTokenRepository,
    RoleRepository,
    SessionRepository,
    SensorReadingRepository,
    UserRepository,
)


async def get_hospital_repository(
    db: AsyncSession = Depends(get_db),
) -> HospitalRepository:
    return HospitalRepository(db)


async def get_user_repository(db: AsyncSession = Depends(get_db)) -> UserRepository:
    return UserRepository(db)


async def get_patient_repository(
    db: AsyncSession = Depends(get_db),
) -> PatientRepository:
    return PatientRepository(db)


async def get_device_repository(db: AsyncSession = Depends(get_db)) -> DeviceRepository:
    return DeviceRepository(db)


async def get_sensor_reading_repository(
    db: AsyncSession = Depends(get_db),
) -> SensorReadingRepository:
    return SensorReadingRepository(db)


async def get_alert_repository(db: AsyncSession = Depends(get_db)) -> AlertRepository:
    return AlertRepository(db)


async def get_ai_report_repository(
    db: AsyncSession = Depends(get_db),
) -> AIReportRepository:
    return AIReportRepository(db)


async def get_knowledge_base_repository(
    db: AsyncSession = Depends(get_db),
) -> KnowledgeBaseRepository:
    return KnowledgeBaseRepository(db)


async def get_knowledge_update_log_repository(
    db: AsyncSession = Depends(get_db),
) -> KnowledgeUpdateLogRepository:
    return KnowledgeUpdateLogRepository(db)


async def get_audit_log_repository(
    db: AsyncSession = Depends(get_db),
) -> AuditLogRepository:
    return AuditLogRepository(db)


async def get_role_repository(db: AsyncSession = Depends(get_db)) -> RoleRepository:
    return RoleRepository(db)


async def get_permission_repository(
    db: AsyncSession = Depends(get_db),
) -> PermissionRepository:
    return PermissionRepository(db)


async def get_session_repository(
    db: AsyncSession = Depends(get_db),
) -> SessionRepository:
    return SessionRepository(db)


async def get_refresh_token_repository(
    db: AsyncSession = Depends(get_db),
) -> RefreshTokenRepository:
    return RefreshTokenRepository(db)


async def get_department_repository(
    db: AsyncSession = Depends(get_db),
) -> DepartmentRepository:
    return DepartmentRepository(db)


async def get_organization_repository(
    db: AsyncSession = Depends(get_db),
) -> OrganizationRepository:
    return OrganizationRepository(db)
