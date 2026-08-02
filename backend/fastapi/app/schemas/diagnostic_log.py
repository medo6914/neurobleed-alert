from datetime import datetime
from uuid import UUID

from pydantic import BaseModel

from app.models.enums import DeviceStatus


class DiagnosticLogCreate(BaseModel):
    status: DeviceStatus
    battery_level: float | None = None
    signal_strength: float | None = None
    temperature: float | None = None
    charging_status: bool | None = None
    lte_signal: float | None = None
    sim_status: str | None = None
    ble_status: str | None = None
    wifi_status: str | None = None
    memory_usage: float | None = None
    storage_usage: float | None = None
    firmware_version: str | None = None
    uptime_seconds: int | None = None
    error_code: str | None = None
    error_message: str | None = None
    raw_data: dict | None = None
    recorded_at: datetime | None = None


class DiagnosticLogResponse(BaseModel):
    id: UUID
    device_id: UUID
    status: DeviceStatus
    battery_level: float | None
    signal_strength: float | None
    temperature: float | None
    charging_status: bool | None
    lte_signal: float | None
    sim_status: str | None
    ble_status: str | None
    wifi_status: str | None
    memory_usage: float | None
    storage_usage: float | None
    firmware_version: str | None
    uptime_seconds: int | None
    error_code: str | None
    error_message: str | None
    raw_data: dict | None
    recorded_at: datetime
    created_at: datetime

    class Config:
        from_attributes = True


class DiagnosticLogListResponse(BaseModel):
    items: list[DiagnosticLogResponse]
    total: int
    page: int
    per_page: int
    total_pages: int
    has_next: bool
    has_prev: bool
