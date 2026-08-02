import uuid
from datetime import datetime

from sqlalchemy import String, DateTime, Float, ForeignKey, Boolean, Text, JSON, func
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base
from app.models.mixins import TimestampMixin
from app.models.enums import DeviceStatus


class DeviceDiagnosticLog(TimestampMixin, Base):
    __tablename__ = "device_diagnostic_logs"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    device_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("devices.id", ondelete="CASCADE"), nullable=False, index=True
    )
    status: Mapped[DeviceStatus] = mapped_column(SAEnum(DeviceStatus), nullable=False)
    battery_level: Mapped[float | None] = mapped_column(Float, nullable=True)
    signal_strength: Mapped[float | None] = mapped_column(Float, nullable=True)
    temperature: Mapped[float | None] = mapped_column(Float, nullable=True)
    charging_status: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    lte_signal: Mapped[float | None] = mapped_column(Float, nullable=True)
    sim_status: Mapped[str | None] = mapped_column(String(50), nullable=True)
    ble_status: Mapped[str | None] = mapped_column(String(20), nullable=True)
    wifi_status: Mapped[str | None] = mapped_column(String(20), nullable=True)
    memory_usage: Mapped[float | None] = mapped_column(Float, nullable=True)
    storage_usage: Mapped[float | None] = mapped_column(Float, nullable=True)
    firmware_version: Mapped[str | None] = mapped_column(String(50), nullable=True)
    uptime_seconds: Mapped[int | None] = mapped_column(nullable=True)
    error_code: Mapped[str | None] = mapped_column(String(50), nullable=True)
    error_message: Mapped[str | None] = mapped_column(Text, nullable=True)
    raw_data: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, index=True
    )

    def __repr__(self) -> str:
        return f"<DeviceDiagnosticLog(id={self.id}, device={self.device_id})>"
