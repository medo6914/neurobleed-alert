from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class AlertCreate(BaseModel):
    patient_id: UUID
    device_id: UUID | None = None
    sensor_reading_id: UUID | None = None
    alert_type: str = "general"
    severity: str = "medium"
    risk_score: float | None = None
    message: str = Field(..., min_length=1)
    extra_data: dict | None = None


class AlertUpdate(BaseModel):
    alert_type: str | None = None
    severity: str | None = None
    risk_score: float | None = None
    message: str | None = None
    is_acknowledged: bool | None = None
    is_resolved: bool | None = None
    resolved_by: UUID | None = None
    resolution_notes: str | None = None
    extra_data: dict | None = None


class AlertResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    patient_id: UUID
    device_id: UUID | None
    sensor_reading_id: UUID | None
    alert_type: str
    severity: str
    risk_score: float | None
    message: str
    is_acknowledged: bool
    acknowledged_by: UUID | None
    acknowledged_at: datetime | None
    is_resolved: bool
    resolved_by: UUID | None
    resolved_at: datetime | None
    resolution_notes: str | None
    extra_data: dict | None
    created_at: datetime
    updated_at: datetime


class AlertListResponse(BaseModel):
    items: list[AlertResponse]
    total: int
    page: int
    per_page: int
    total_pages: int
    has_next: bool
    has_prev: bool


class AlertAcknowledge(BaseModel):
    is_acknowledged: bool = True


class AlertEscalateRequest(BaseModel):
    reason: str = Field(..., min_length=1, max_length=500)
