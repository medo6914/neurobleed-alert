from datetime import datetime, date
from uuid import UUID

from pydantic import BaseModel


class PatientCreate(BaseModel):
    full_name: str
    date_of_birth: date
    gender: str
    national_id: str | None = None
    phone: str | None = None
    emergency_contact_name: str | None = None
    emergency_contact_phone: str | None = None
    medical_conditions: str | None = None
    medications: str | None = None
    blood_type: str | None = None
    allergies: str | None = None
    hospital_id: UUID | None = None


class PatientResponse(BaseModel):
    id: UUID
    full_name: str
    date_of_birth: date
    gender: str
    phone: str | None
    emergency_contact_name: str | None
    emergency_contact_phone: str | None
    medical_conditions: str | None
    medications: str | None
    blood_type: str | None
    allergies: str | None
    is_active: bool
    created_at: datetime
    risk_score: float | None = None
    risk_level: str | None = None

    class Config:
        from_attributes = True
