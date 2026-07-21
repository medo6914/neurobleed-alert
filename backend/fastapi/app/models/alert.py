import uuid
from datetime import datetime

from sqlalchemy import String, DateTime, Float, ForeignKey, Text, Boolean, JSON, func, Index
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.models.mixins import TimestampMixin, SoftDeleteMixin, VersionMixin, FHIRMixin, MedicalCodeMixin
from app.models.enums import Severity, AlertType


class Alert(TimestampMixin, SoftDeleteMixin, VersionMixin, FHIRMixin, MedicalCodeMixin, Base):
    __tablename__ = "alerts"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    patient_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("patients.id", ondelete="CASCADE"), nullable=False, index=True
    )
    device_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("devices.id", ondelete="SET NULL"), nullable=True
    )
    sensor_reading_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("sensor_readings.id", ondelete="SET NULL"), nullable=True
    )
    alert_type: Mapped[AlertType] = mapped_column(SAEnum(AlertType), nullable=False, default=AlertType.GENERAL)
    severity: Mapped[Severity] = mapped_column(SAEnum(Severity), nullable=False, default=Severity.MEDIUM)
    risk_score: Mapped[float | None] = mapped_column(Float, nullable=True)
    message: Mapped[str] = mapped_column(Text, nullable=False)
    is_acknowledged: Mapped[bool] = mapped_column(Boolean, default=False, server_default="0")
    acknowledged_by: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    acknowledged_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    is_resolved: Mapped[bool] = mapped_column(Boolean, default=False, server_default="0")
    resolved_by: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    resolution_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    extra_data: Mapped[dict | None] = mapped_column(JSON, nullable=True)

    patient = relationship("Patient", back_populates="alerts")


Index("ix_alerts_patient_severity", Alert.patient_id, Alert.severity, Alert.created_at.desc())
Index("ix_alerts_unacknowledged", Alert.is_acknowledged, Alert.created_at.desc())
Index("ix_alerts_unresolved", Alert.is_resolved, Alert.created_at.desc())
