import uuid
from datetime import datetime, timezone

from sqlalchemy import func, or_, select
from sqlalchemy.orm import selectinload

from app.models.alert import Alert
from app.models.ai_report import AIReport
from app.models.audit_log import AuditLog
from app.models.department import Department
from app.models.device import Device
from app.models.hospital import Hospital
from app.models.knowledge_base import KnowledgeBase
from app.models.knowledge_update_log import KnowledgeUpdateLog
from app.models.organization import Organization
from app.models.patient import Patient
from app.models.permission import Permission
from app.models.refresh_token import RefreshToken
from app.models.role import Role
from app.models.sensor_reading import SensorReading
from app.models.session import Session
from app.models.user import User

from app.repositories.base import BaseRepository


class HospitalRepository(BaseRepository[Hospital]):
    def __init__(self, db):
        super().__init__(Hospital, db)

    async def get_with_relations(self, id: uuid.UUID) -> Hospital | None:
        stmt = (
            select(Hospital)
            .where(Hospital.id == id)
            .options(selectinload(Hospital.users), selectinload(Hospital.departments))
        )
        stmt = self._apply_soft_delete_filter(stmt)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()


class UserRepository(BaseRepository[User]):
    def __init__(self, db):
        super().__init__(User, db)

    async def get_by_email(self, email: str) -> User | None:
        stmt = select(User).where(User.email == email)
        stmt = self._apply_soft_delete_filter(stmt)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_firebase_uid(self, firebase_uid: str) -> User | None:
        stmt = select(User).where(User.firebase_uid == firebase_uid)
        stmt = self._apply_soft_delete_filter(stmt)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_user_with_roles(self, id: uuid.UUID) -> User | None:
        stmt = (
            select(User)
            .where(User.id == id)
            .options(selectinload(User.roles))
        )
        stmt = self._apply_soft_delete_filter(stmt)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()


class PatientRepository(BaseRepository[Patient]):
    def __init__(self, db):
        super().__init__(Patient, db)

    async def get_by_mrn(self, mrn: str) -> Patient | None:
        stmt = select(Patient).where(Patient.mrn == mrn)
        stmt = self._apply_soft_delete_filter(stmt)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def search_by_name(self, name: str, limit: int = 20) -> list[Patient]:
        stmt = select(Patient).where(
            Patient.full_name.ilike(f"%{name}%")
        )
        stmt = self._apply_soft_delete_filter(stmt)
        stmt = stmt.limit(limit)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_patients_by_hospital(
        self, hospital_id: uuid.UUID, skip: int = 0, limit: int = 100
    ) -> list[Patient]:
        stmt = select(Patient).where(Patient.hospital_id == hospital_id)
        stmt = self._apply_soft_delete_filter(stmt)
        stmt = stmt.offset(skip).limit(limit)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())


class DeviceRepository(BaseRepository[Device]):
    def __init__(self, db):
        super().__init__(Device, db)

    async def get_by_serial(self, serial_number: str) -> Device | None:
        stmt = select(Device).where(Device.serial_number == serial_number)
        stmt = self._apply_soft_delete_filter(stmt)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_devices_by_hospital(
        self, hospital_id: uuid.UUID, skip: int = 0, limit: int = 100
    ) -> list[Device]:
        stmt = select(Device).where(Device.hospital_id == hospital_id)
        stmt = self._apply_soft_delete_filter(stmt)
        stmt = stmt.offset(skip).limit(limit)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())


class SensorReadingRepository(BaseRepository[SensorReading]):
    def __init__(self, db):
        super().__init__(SensorReading, db)

    async def get_readings_by_patient_range(
        self,
        patient_id: uuid.UUID,
        from_date: datetime | None = None,
        to_date: datetime | None = None,
        skip: int = 0,
        limit: int = 100,
    ) -> list[SensorReading]:
        stmt = select(SensorReading).where(SensorReading.patient_id == patient_id)
        if from_date:
            stmt = stmt.where(SensorReading.timestamp >= from_date)
        if to_date:
            stmt = stmt.where(SensorReading.timestamp <= to_date)
        stmt = stmt.order_by(SensorReading.timestamp.desc()).offset(skip).limit(limit)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())


class AlertRepository(BaseRepository[Alert]):
    def __init__(self, db):
        super().__init__(Alert, db)

    async def get_unacknowledged(
        self, skip: int = 0, limit: int = 100
    ) -> list[Alert]:
        stmt = select(Alert).where(Alert.is_acknowledged == False)  # noqa: E712
        stmt = self._apply_soft_delete_filter(stmt)
        stmt = stmt.order_by(Alert.created_at.desc()).offset(skip).limit(limit)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_unresolved(
        self, skip: int = 0, limit: int = 100
    ) -> list[Alert]:
        stmt = select(Alert).where(Alert.is_resolved == False)  # noqa: E712
        stmt = self._apply_soft_delete_filter(stmt)
        stmt = stmt.order_by(Alert.created_at.desc()).offset(skip).limit(limit)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())


class AIReportRepository(BaseRepository[AIReport]):
    def __init__(self, db):
        super().__init__(AIReport, db)

    async def get_reports_by_patient(
        self, patient_id: uuid.UUID, skip: int = 0, limit: int = 100
    ) -> list[AIReport]:
        stmt = select(AIReport).where(AIReport.patient_id == patient_id)
        stmt = self._apply_soft_delete_filter(stmt)
        stmt = stmt.order_by(AIReport.created_at.desc()).offset(skip).limit(limit)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())


class KnowledgeBaseRepository(BaseRepository[KnowledgeBase]):
    def __init__(self, db):
        super().__init__(KnowledgeBase, db)

    async def search(self, query: str, limit: int = 20) -> list[KnowledgeBase]:
        stmt = select(KnowledgeBase).where(
            or_(
                KnowledgeBase.title.ilike(f"%{query}%"),
                KnowledgeBase.content.ilike(f"%{query}%"),
            )
        )
        stmt = self._apply_soft_delete_filter(stmt)
        stmt = stmt.where(KnowledgeBase.is_published == True)  # noqa: E712
        stmt = stmt.limit(limit)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_by_category(
        self, category: str, skip: int = 0, limit: int = 100
    ) -> list[KnowledgeBase]:
        stmt = select(KnowledgeBase).where(KnowledgeBase.category == category)
        stmt = self._apply_soft_delete_filter(stmt)
        stmt = stmt.where(KnowledgeBase.is_published == True)  # noqa: E712
        stmt = stmt.offset(skip).limit(limit)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())


class KnowledgeUpdateLogRepository(BaseRepository[KnowledgeUpdateLog]):
    def __init__(self, db):
        super().__init__(KnowledgeUpdateLog, db)


class AuditLogRepository(BaseRepository[AuditLog]):
    def __init__(self, db):
        super().__init__(AuditLog, db)

    async def get_by_user(self, user_id: uuid.UUID, skip: int = 0, limit: int = 100) -> list[AuditLog]:
        stmt = select(AuditLog).where(AuditLog.user_id == user_id)
        stmt = stmt.order_by(AuditLog.created_at.desc()).offset(skip).limit(limit)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_by_resource(self, resource: str, resource_id: str | None = None, skip: int = 0, limit: int = 100) -> list[AuditLog]:
        stmt = select(AuditLog).where(AuditLog.resource == resource)
        if resource_id:
            stmt = stmt.where(AuditLog.resource_id == resource_id)
        stmt = stmt.order_by(AuditLog.created_at.desc()).offset(skip).limit(limit)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())


class RoleRepository(BaseRepository[Role]):
    def __init__(self, db):
        super().__init__(Role, db)

    async def get_by_name(self, name: str) -> Role | None:
        stmt = select(Role).where(Role.name == name)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_with_permissions(self, id: uuid.UUID) -> Role | None:
        stmt = (
            select(Role)
            .where(Role.id == id)
            .options(selectinload(Role.permissions))
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()


class PermissionRepository(BaseRepository[Permission]):
    def __init__(self, db):
        super().__init__(Permission, db)

    async def get_by_codename(self, codename: str) -> Permission | None:
        stmt = select(Permission).where(Permission.codename == codename)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()


class SessionRepository(BaseRepository[Session]):
    def __init__(self, db):
        super().__init__(Session, db)

    async def get_active_user_sessions(self, user_id: uuid.UUID) -> list[Session]:
        stmt = select(Session).where(
            Session.user_id == user_id,
            Session.is_active == True,  # noqa: E712
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def invalidate_session(self, id: uuid.UUID) -> bool:
        session = await self.get(id)
        if not session:
            return False
        session.is_active = False
        await self.db.commit()
        return True


class RefreshTokenRepository(BaseRepository[RefreshToken]):
    def __init__(self, db):
        super().__init__(RefreshToken, db)

    async def get_by_token_hash(self, token_hash: str) -> RefreshToken | None:
        stmt = select(RefreshToken).where(RefreshToken.token_hash == token_hash)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def revoke_token(self, id: uuid.UUID) -> bool:
        token = await self.get(id)
        if not token:
            return False
        token.is_revoked = True
        token.revoked_at = datetime.now(timezone.utc)
        await self.db.commit()
        return True


class DepartmentRepository(BaseRepository[Department]):
    def __init__(self, db):
        super().__init__(Department, db)


class OrganizationRepository(BaseRepository[Organization]):
    def __init__(self, db):
        super().__init__(Organization, db)
