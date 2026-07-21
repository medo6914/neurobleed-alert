from datetime import datetime, date
from typing import Literal
from uuid import UUID

from pydantic import BaseModel

from app.models.enums import DeviceType, DeviceStatus


class DeviceCreate(BaseModel):
    serial_number: str
    device_name: str | None = None
    device_type: DeviceType = DeviceType.NB_01
    mac_address: str | None = None
    firmware_version: str = "0.1.0"
    hardware_version: str | None = None
    hospital_id: UUID | None = None
    department: str | None = None


class DeviceUpdate(BaseModel):
    device_name: str | None = None
    firmware_version: str | None = None
    hospital_id: UUID | None = None
    department: str | None = None
    status: DeviceStatus | None = None


class DeviceStatusUpdate(BaseModel):
    status: DeviceStatus
    battery_level: float | None = None
    signal_strength: float | None = None
    temperature: float | None = None
    charging_status: bool | None = None
    lte_signal: float | None = None
    sim_status: str | None = None
    ble_status: str | None = None


class DeviceAssignRequest(BaseModel):
    patient_id: UUID | None = None
    hospital_id: UUID | None = None
    department: str | None = None


class DeviceDiagnosticResponse(BaseModel):
    device_id: UUID
    status: DeviceStatus
    battery_level: float
    signal_strength: float
    firmware_version: str
    hardware_version: str | None
    temperature: float | None
    charging_status: bool | None
    lte_signal: float | None
    sim_status: str | None
    ble_status: str | None
    last_seen: datetime | None
    uptime: int | None
    memory_usage: float | None = None
    storage_usage: float | None = None

    class Config:
        from_attributes = True


class DeviceResponse(BaseModel):
    id: UUID
    device_name: str | None
    device_type: DeviceType
    serial_number: str
    mac_address: str | None
    firmware_version: str
    hardware_version: str | None
    sim_iccid: str | None
    sim_status: str | None
    lte_signal: float | None
    wifi_status: str | None
    battery_level: float
    charging_status: bool | None
    temperature: float | None
    signal_strength: float
    ble_status: str | None
    status: DeviceStatus
    last_seen: datetime | None
    last_heartbeat: datetime | None
    manufacturing_date: date | None
    warranty_expiry: date | None
    hospital_id: UUID | None
    patient_id: UUID | None
    department: str | None
    certificate_thumbprint: str | None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class DeviceListResponse(BaseModel):
    items: list[DeviceResponse]
    total: int
    page: int
    per_page: int
    total_pages: int
    has_next: bool
    has_prev: bool


class DeviceHeartbeatRequest(BaseModel):
    battery_level: float | None = None
    signal_strength: float | None = None
    temperature: float | None = None
    charging_status: bool | None = None
    lte_signal: float | None = None
    sim_status: str | None = None
    ble_status: str | None = None


class DeviceCertRequest(BaseModel):
    certificate: str
    public_key: str


class BulkDeviceOperation(BaseModel):
    device_ids: list[UUID]
    operation: Literal["activate", "deactivate", "maintenance", "update_firmware"]
    firmware_version: str | None = None
