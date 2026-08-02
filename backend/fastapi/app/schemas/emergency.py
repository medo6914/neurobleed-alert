from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class EmergencyContactCreate(BaseModel):
    patient_id: UUID
    full_name: str = Field(..., min_length=1, max_length=255)
    relationship: str = Field(..., max_length=100)
    phone: str = Field(..., max_length=50)
    phone_secondary: str | None = Field(None, max_length=50)
    email: str | None = Field(None, max_length=255)
    is_primary: bool = False
    priority: int = 1
    notes: str | None = None


class EmergencyContactUpdate(BaseModel):
    full_name: str | None = Field(None, min_length=1, max_length=255)
    relationship: str | None = Field(None, max_length=100)
    phone: str | None = Field(None, max_length=50)
    phone_secondary: str | None = Field(None, max_length=50)
    email: str | None = Field(None, max_length=255)
    is_primary: bool | None = None
    priority: int | None = None
    notes: str | None = None


class EmergencyContactResponse(BaseModel):
    id: UUID
    patient_id: UUID
    full_name: str
    relationship: str
    phone: str
    phone_secondary: str | None
    email: str | None
    is_primary: bool
    priority: int
    notes: str | None
    created_at: datetime

    class Config:
        from_attributes = True


class SOSRequest(BaseModel):
    patient_id: UUID
    alert_id: UUID | None = None
    sos_type: str = "manual"
    location_lat: float | None = None
    location_lng: float | None = None
    notes: str | None = None


class SOSResponse(BaseModel):
    id: UUID
    patient_id: UUID
    status: str
    sos_type: str
    contacted_count: int
    message: str


class EmergencyEventResponse(BaseModel):
    id: UUID
    patient_id: UUID
    alert_id: UUID | None
    triggered_by: UUID | None
    status: str
    sos_type: str
    location_lat: float | None
    location_lng: float | None
    notes: str | None
    resolved_at: datetime | None
    resolved_by: UUID | None
    escalation_count: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
