import uuid
from datetime import datetime, date

from sqlalchemy import String, DateTime, Date, ForeignKey, Text, Boolean, Float, JSON, func
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.models.mixins import (
    TimestampMixin, SoftDeleteMixin, VersionMixin, AuditMixin, FHIRMixin, MedicalCodeMixin,
)
from app.models.enums import Gender, BloodType


class Patient(TimestampMixin, SoftDeleteMixin, VersionMixin, AuditMixin, FHIRMixin, MedicalCodeMixin, Base):
    __tablename__ = "patients"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    mrn: Mapped[str | None] = mapped_column(String(50), unique=True, nullable=True, index=True)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    date_of_birth: Mapped[date] = mapped_column(Date, nullable=False)
    gender: Mapped[Gender] = mapped_column(SAEnum(Gender), nullable=False)
    national_id: Mapped[str | None] = mapped_column(String(50), unique=True, nullable=True)
    phone: Mapped[str | None] = mapped_column(String(50), nullable=True)
    email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    emergency_contact_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    emergency_contact_phone: Mapped[str | None] = mapped_column(String(50), nullable=True)
    emergency_contact_relation: Mapped[str | None] = mapped_column(String(50), nullable=True)
    blood_type: Mapped[BloodType | None] = mapped_column(SAEnum(BloodType), nullable=True)
    allergies: Mapped[str | None] = mapped_column(Text, nullable=True)
    medical_conditions: Mapped[str | None] = mapped_column(Text, nullable=True)
    medications: Mapped[str | None] = mapped_column(Text, nullable=True)
    height_cm: Mapped[float | None] = mapped_column(Float, nullable=True)
    weight_kg: Mapped[float | None] = mapped_column(Float, nullable=True)
    is_ihd_suspected: Mapped[bool] = mapped_column(Boolean, default=False, server_default="0")
    admission_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    discharge_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    department_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("departments.id", ondelete="SET NULL"), nullable=True
    )
    bed_number: Mapped[str | None] = mapped_column(String(20), nullable=True)
    hospital_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("hospitals.id", ondelete="CASCADE"), nullable=True, index=True
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default="1")

    hospital = relationship("Hospital", back_populates="patients")
    device = relationship("Device", back_populates="patient", uselist=False)
    alerts = relationship("Alert", back_populates="patient")
    sensor_readings = relationship("SensorReading", back_populates="patient")
    ai_reports = relationship("AIReport", back_populates="patient")
    clinical_reports = relationship("ClinicalReport", back_populates="patient")
    department = relationship("Department")

    def __repr__(self) -> str:
        return f"<Patient(id={self.id}, name='{self.full_name}', mrn='{self.mrn}')>"
