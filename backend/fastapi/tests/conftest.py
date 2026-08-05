import uuid
from datetime import date, datetime, timedelta, timezone

import pytest
from sqlalchemy import event
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession

from app.database import Base
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
from app.models.enums import (
    HospitalType,
    UserRole,
    Gender,
    BloodType,
    RiskLevel,
    Severity,
    AlertType,
    DeviceType,
    DeviceStatus,
    ReportType,
    OrganizationType,
    KnowledgeUpdateAction,
)


@pytest.fixture
async def db_session():
    engine = create_async_engine("sqlite+aiosqlite://", echo=False)

    @event.listens_for(engine.sync_engine, "connect")
    def set_sqlite_pragma(dbapi_connection, connection_record):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    async with AsyncSession(engine, expire_on_commit=False) as session:
        yield session
    await engine.dispose()


@pytest.fixture
async def hospital_repo(db_session: AsyncSession):
    return HospitalRepository(db_session)


@pytest.fixture
async def user_repo(db_session: AsyncSession):
    return UserRepository(db_session)


@pytest.fixture
async def patient_repo(db_session: AsyncSession):
    return PatientRepository(db_session)


@pytest.fixture
async def device_repo(db_session: AsyncSession):
    return DeviceRepository(db_session)


@pytest.fixture
async def sensor_reading_repo(db_session: AsyncSession):
    return SensorReadingRepository(db_session)


@pytest.fixture
async def alert_repo(db_session: AsyncSession):
    return AlertRepository(db_session)


@pytest.fixture
async def ai_report_repo(db_session: AsyncSession):
    return AIReportRepository(db_session)


@pytest.fixture
async def knowledge_base_repo(db_session: AsyncSession):
    return KnowledgeBaseRepository(db_session)


@pytest.fixture
async def knowledge_update_log_repo(db_session: AsyncSession):
    return KnowledgeUpdateLogRepository(db_session)


@pytest.fixture
async def audit_log_repo(db_session: AsyncSession):
    return AuditLogRepository(db_session)


@pytest.fixture
async def role_repo(db_session: AsyncSession):
    return RoleRepository(db_session)


@pytest.fixture
async def permission_repo(db_session: AsyncSession):
    return PermissionRepository(db_session)


@pytest.fixture
async def session_repo(db_session: AsyncSession):
    return SessionRepository(db_session)


@pytest.fixture
async def refresh_token_repo(db_session: AsyncSession):
    return RefreshTokenRepository(db_session)


@pytest.fixture
async def department_repo(db_session: AsyncSession):
    return DepartmentRepository(db_session)


@pytest.fixture
async def organization_repo(db_session: AsyncSession):
    return OrganizationRepository(db_session)


@pytest.fixture
async def seeded_hospital(hospital_repo: HospitalRepository):
    return await hospital_repo.create(
        {
            "name": "Test Hospital",
            "email": f"hospital.{uuid.uuid4()}@example.com",
            "license_number": f"LIC-{uuid.uuid4().hex[:8].upper()}",
            "phone": "+1-555-0100",
            "hospital_type": HospitalType.GENERAL,
            "is_active": True,
        }
    )


@pytest.fixture
async def seeded_user(user_repo: UserRepository, seeded_hospital):
    return await user_repo.create(
        {
            "email": f"user.{uuid.uuid4()}@example.com",
            "hashed_password": "$2b$12$hashed_password_here",
            "full_name": "Test User",
            "role": UserRole.DOCTOR,
            "hospital_id": seeded_hospital.id,
            "is_active": True,
        }
    )


@pytest.fixture
async def seeded_patient(patient_repo: PatientRepository, seeded_hospital):
    return await patient_repo.create(
        {
            "mrn": f"MRN-{uuid.uuid4().hex[:8].upper()}",
            "full_name": "John Doe",
            "date_of_birth": date(1990, 1, 15),
            "gender": Gender.MALE,
            "blood_type": BloodType.O_POSITIVE,
            "hospital_id": seeded_hospital.id,
            "is_active": True,
        }
    )


@pytest.fixture
async def seeded_device(device_repo: DeviceRepository, seeded_hospital, seeded_patient):
    return await device_repo.create(
        {
            "device_name": "NB-01 Monitor",
            "device_type": DeviceType.NB_01,
            "serial_number": f"SN-{uuid.uuid4().hex[:8].upper()}",
            "firmware_version": "1.0.0",
            "hospital_id": seeded_hospital.id,
            "patient_id": seeded_patient.id,
            "status": DeviceStatus.ONLINE,
            "battery_level": 85.0,
            "signal_strength": -65.0,
            "is_active": True,
        }
    )


@pytest.fixture
async def seeded_sensor_reading(
    sensor_reading_repo: SensorReadingRepository, seeded_patient, seeded_device
):
    return await sensor_reading_repo.create(
        {
            "patient_id": seeded_patient.id,
            "device_id": seeded_device.id,
            "timestamp": datetime.now(timezone.utc),
            "spo2": 98.0,
            "heart_rate": 72.0,
            "rso2": 68.0,
            "risk_score": 0.1,
            "risk_level": RiskLevel.LOW,
            "signal_quality": 0.95,
            "motion_artifact": 0.02,
        }
    )


@pytest.fixture
async def seeded_alert(
    alert_repo: AlertRepository, seeded_patient, seeded_device, seeded_sensor_reading
):
    return await alert_repo.create(
        {
            "patient_id": seeded_patient.id,
            "device_id": seeded_device.id,
            "sensor_reading_id": seeded_sensor_reading.id,
            "alert_type": AlertType.ICP_ELEVATED,
            "severity": Severity.HIGH,
            "risk_score": 0.85,
            "message": "Elevated ICP detected",
            "is_acknowledged": False,
            "is_resolved": False,
        }
    )


@pytest.fixture
async def seeded_ai_report(
    ai_report_repo: AIReportRepository, seeded_patient, seeded_alert
):
    return await ai_report_repo.create(
        {
            "patient_id": seeded_patient.id,
            "alert_id": seeded_alert.id,
            "report_type": ReportType.RISK_ASSESSMENT,
            "risk_score": 0.75,
            "confidence": 0.92,
            "bleeding_type": "subdural",
            "summary": "Patient shows signs of subdural hemorrhage",
            "model_version": "1.0.0",
            "is_reviewed": False,
        }
    )


@pytest.fixture
async def seeded_knowledge_base(knowledge_base_repo: KnowledgeBaseRepository):
    return await knowledge_base_repo.create(
        {
            "title": "ICP Monitoring Guidelines",
            "content": "Standard guidelines for ICP monitoring in neurocritical care...",
            "category": "protocols",
            "source": "Neurocritical Care Society",
            "tags": ["icp", "monitoring", "guidelines"],
            "is_published": True,
        }
    )


@pytest.fixture
async def seeded_role(role_repo: RoleRepository):
    return await role_repo.create(
        {
            "name": "admin",
            "description": "System administrator",
            "is_system": True,
        }
    )


@pytest.fixture
async def seeded_permission(permission_repo: PermissionRepository):
    return await permission_repo.create(
        {
            "codename": "patients.read",
            "name": "Read Patient Records",
            "description": "Allows reading patient medical records",
            "resource": "patients",
        }
    )
