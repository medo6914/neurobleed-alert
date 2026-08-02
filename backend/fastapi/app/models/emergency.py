import uuid
from datetime import datetime

from sqlalchemy import String, DateTime, Float, ForeignKey, Text, Boolean, JSON, func
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.models.mixins import TimestampMixin, SoftDeleteMixin
from app.models.enums import EmergencyEventStatus


class EmergencyContact(TimestampMixin, SoftDeleteMixin, Base):
    __tablename__ = "emergency_contacts"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    patient_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("patients.id", ondelete="CASCADE"), nullable=False, index=True
    )
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    contact_relationship: Mapped[str] = mapped_column(String(100), nullable=False)
    phone: Mapped[str] = mapped_column(String(50), nullable=False)
    phone_secondary: Mapped[str | None] = mapped_column(String(50), nullable=True)
    email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    is_primary: Mapped[bool] = mapped_column(Boolean, default=False, server_default="0")
    priority: Mapped[int] = mapped_column(default=1)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    patient = relationship("Patient")


class EmergencyEvent(TimestampMixin, SoftDeleteMixin, Base):
    __tablename__ = "emergency_events"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    patient_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("patients.id", ondelete="CASCADE"), nullable=False, index=True
    )
    alert_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("alerts.id", ondelete="SET NULL"), nullable=True
    )
    triggered_by: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    status: Mapped[EmergencyEventStatus] = mapped_column(
        SAEnum(EmergencyEventStatus), nullable=False, default=EmergencyEventStatus.TRIGGERED
    )
    sos_type: Mapped[str] = mapped_column(String(50), default="manual")
    location_lat: Mapped[float | None] = mapped_column(Float, nullable=True)
    location_lng: Mapped[float | None] = mapped_column(Float, nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    resolved_by: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    escalation_count: Mapped[int] = mapped_column(default=0)
    notification_log: Mapped[dict | None] = mapped_column(JSON, nullable=True)
