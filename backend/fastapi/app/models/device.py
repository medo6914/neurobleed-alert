import uuid
from datetime import datetime, date

from sqlalchemy import String, DateTime, Date, Float, ForeignKey, Boolean, Text, func
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.models.mixins import TimestampMixin, SoftDeleteMixin, VersionMixin, AuditMixin, FHIRMixin
from app.models.enums import DeviceType, DeviceStatus


class Device(TimestampMixin, SoftDeleteMixin, VersionMixin, AuditMixin, FHIRMixin, Base):
    __tablename__ = "devices"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    device_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    device_type: Mapped[DeviceType] = mapped_column(SAEnum(DeviceType), nullable=False, default=DeviceType.NB_01)
    serial_number: Mapped[str] = mapped_column(String(100), unique=True, nullable=False, index=True)
    mac_address: Mapped[str | None] = mapped_column(String(50), unique=True, nullable=True)
    firmware_version: Mapped[str] = mapped_column(String(50), nullable=False, default="0.1.0")
    hardware_version: Mapped[str | None] = mapped_column(String(50), nullable=True)
    sim_iccid: Mapped[str | None] = mapped_column(String(50), nullable=True)
    sim_status: Mapped[str | None] = mapped_column(String(50), nullable=True)
    lte_signal: Mapped[float | None] = mapped_column(Float, nullable=True)
    wifi_status: Mapped[str | None] = mapped_column(String(20), nullable=True)
    battery_level: Mapped[float] = mapped_column(Float, default=100.0)
    charging_status: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    temperature: Mapped[float | None] = mapped_column(Float, nullable=True)
    signal_strength: Mapped[float] = mapped_column(Float, default=0.0)
    ble_status: Mapped[str | None] = mapped_column(String(20), nullable=True)
    last_seen: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    last_heartbeat: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    manufacturing_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    warranty_expiry: Mapped[date | None] = mapped_column(Date, nullable=True)
    hospital_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("hospitals.id", ondelete="SET NULL"), nullable=True
    )
    patient_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("patients.id", ondelete="SET NULL"), nullable=True, unique=True
    )
    department: Mapped[str | None] = mapped_column(String(100), nullable=True)
    status: Mapped[DeviceStatus] = mapped_column(SAEnum(DeviceStatus), nullable=False, default=DeviceStatus.OFFLINE)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default="1")
    certificate_thumbprint: Mapped[str | None] = mapped_column(String(255), nullable=True)
    public_key: Mapped[str | None] = mapped_column(Text, nullable=True)
    fcm_token: Mapped[str | None] = mapped_column(Text, nullable=True)

    patient = relationship("Patient", back_populates="device")
    hospital = relationship("Hospital", back_populates="devices")

    def __repr__(self) -> str:
        return f"<Device(id={self.id}, serial='{self.serial_number}')>"
