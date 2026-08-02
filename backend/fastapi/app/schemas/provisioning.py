from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.enums import ProvisioningKeyStatus, DeviceType


class ProvisioningKeyCreate(BaseModel):
    device_type: DeviceType
    label: str | None = None
    hospital_id: UUID | None = None
    expires_at: datetime | None = None
    max_uses: int = 1
    metadata: str | None = None


class ProvisioningKeyResponse(BaseModel):
    id: UUID
    key: str
    device_type: DeviceType
    label: str | None
    hospital_id: UUID | None
    status: ProvisioningKeyStatus
    expires_at: datetime | None
    used_at: datetime | None
    used_by_device_id: UUID | None
    max_uses: int
    use_count: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ProvisioningKeyListResponse(BaseModel):
    items: list[ProvisioningKeyResponse]
    total: int
    page: int
    per_page: int
    total_pages: int
    has_next: bool
    has_prev: bool


class ProvisioningClaimRequest(BaseModel):
    provisioning_key: str = Field(..., min_length=8, max_length=64)
    serial_number: str = Field(..., min_length=1, max_length=100)
    device_name: str | None = None
    device_type: DeviceType | None = None
    mac_address: str | None = None
    firmware_version: str = "0.1.0"
    hardware_version: str | None = None


class ProvisioningClaimResponse(BaseModel):
    success: bool
    device_id: UUID | None = None
    serial_number: str | None = None
    message: str
    device: dict | None = None
