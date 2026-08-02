from datetime import datetime, date
from uuid import UUID

from pydantic import BaseModel, Field


class PatientCreate(BaseModel):
    full_name: str = Field(..., min_length=1, max_length=255)
    date_of_birth: date
    gender: str
    national_id: str | None = Field(None, max_length=50)
    phone: str | None = Field(None, max_length=50)
    email: str | None = Field(None, max_length=255)
    emergency_contact_name: str | None = Field(None, max_length=255)
    emergency_contact_phone: str | None = Field(None, max_length=50)
    emergency_contact_relation: str | None = Field(None, max_length=50)
    medical_conditions: str | None = None
    medications: str | None = None
    blood_type: str | None = None
    allergies: str | None = None
    height_cm: float | None = None
    weight_kg: float | None = None
    bed_number: str | None = Field(None, max_length=20)
    hospital_id: UUID | None = None
    department_id: UUID | None = None
    is_ihd_suspected: bool = False
    mrn: str | None = Field(None, max_length=50)


class PatientUpdate(BaseModel):
    full_name: str | None = Field(None, min_length=1, max_length=255)
    date_of_birth: date | None = None
    gender: str | None = None
    national_id: str | None = Field(None, max_length=50)
    phone: str | None = Field(None, max_length=50)
    email: str | None = Field(None, max_length=255)
    emergency_contact_name: str | None = Field(None, max_length=255)
    emergency_contact_phone: str | None = Field(None, max_length=50)
    emergency_contact_relation: str | None = Field(None, max_length=50)
    medical_conditions: str | None = None
    medications: str | None = None
    blood_type: str | None = None
    allergies: str | None = None
    height_cm: float | None = None
    weight_kg: float | None = None
    bed_number: str | None = Field(None, max_length=20)
    hospital_id: UUID | None = None
    department_id: UUID | None = None
    is_ihd_suspected: bool | None = None
    is_active: bool | None = None


class PatientResponse(BaseModel):
    id: UUID
    mrn: str | None
    full_name: str
    date_of_birth: date
    gender: str
    national_id: str | None
    phone: str | None
    email: str | None
    emergency_contact_name: str | None
    emergency_contact_phone: str | None
    emergency_contact_relation: str | None
    medical_conditions: str | None
    medications: str | None
    blood_type: str | None
    allergies: str | None
    height_cm: float | None
    weight_kg: float | None
    bed_number: str | None
    hospital_id: UUID | None
    department_id: UUID | None
    is_ihd_suspected: bool
    is_active: bool
    admission_date: datetime | None
    discharge_date: datetime | None
    created_at: datetime
    updated_at: datetime
    risk_score: float | None = None
    risk_level: str | None = None

    class Config:
        from_attributes = True


class PatientListResponse(BaseModel):
    items: list[PatientResponse]
    total: int
    page: int
    per_page: int
    total_pages: int
    has_next: bool
    has_prev: bool


class PatientHistoryItem(BaseModel):
    event_type: str
    event_date: datetime
    description: str
    details: dict | None = None


class PatientHistoryResponse(BaseModel):
    patient_id: UUID
    patient_name: str
    events: list[PatientHistoryItem]
