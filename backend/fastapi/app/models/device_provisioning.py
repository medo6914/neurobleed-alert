import uuid
from datetime import datetime

from sqlalchemy import String, DateTime, Float, ForeignKey, Boolean, Text, func
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base
from app.models.mixins import TimestampMixin, SoftDeleteMixin
from app.models.enums import ProvisioningKeyStatus, DeviceType


class DeviceProvisioningKey(TimestampMixin, SoftDeleteMixin, Base):
    __tablename__ = "device_provisioning_keys"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    key: Mapped[str] = mapped_column(String(64), unique=True, nullable=False, index=True)
    device_type: Mapped[DeviceType] = mapped_column(SAEnum(DeviceType), nullable=False)
    label: Mapped[str | None] = mapped_column(String(255), nullable=True)
    hospital_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("hospitals.id", ondelete="SET NULL"), nullable=True
    )
    status: Mapped[ProvisioningKeyStatus] = mapped_column(
        SAEnum(ProvisioningKeyStatus), nullable=False, default=ProvisioningKeyStatus.ACTIVE
    )
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    used_by_device_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("devices.id", ondelete="SET NULL"), nullable=True
    )
    max_uses: Mapped[int] = mapped_column(default=1)
    use_count: Mapped[int] = mapped_column(default=0)
    created_by_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    provisioning_metadata: Mapped[str | None] = mapped_column(Text, nullable=True)

    def __repr__(self) -> str:
        return f"<DeviceProvisioningKey(id={self.id}, key='{self.key[:8]}...', status='{self.status}')>"
