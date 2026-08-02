import uuid

from sqlalchemy import String, Boolean, func
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.models.mixins import TimestampMixin, SoftDeleteMixin, VersionMixin, AuditMixin, FHIRMixin
from app.models.enums import HospitalType


class Hospital(TimestampMixin, SoftDeleteMixin, VersionMixin, AuditMixin, FHIRMixin, Base):
    __tablename__ = "hospitals"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    address: Mapped[str | None] = mapped_column(String(500), nullable=True)
    phone: Mapped[str | None] = mapped_column(String(50), nullable=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    license_number: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    hospital_type: Mapped[HospitalType | None] = mapped_column(SAEnum(HospitalType), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default="1")

    users = relationship("User", back_populates="hospital", foreign_keys="User.hospital_id")
    patients = relationship("Patient", back_populates="hospital")
    devices = relationship("Device", back_populates="hospital")
    departments = relationship("Department", back_populates="hospital")
    subscription = relationship("Subscription", back_populates="hospital", uselist=False)

    def __repr__(self) -> str:
        return f"<Hospital(id={self.id}, name='{self.name}')>"
