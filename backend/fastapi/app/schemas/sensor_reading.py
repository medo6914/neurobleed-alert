from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class SensorReadingCreate(BaseModel):
    patient_id: UUID
    device_id: UUID | None = None
    timestamp: datetime | None = None
    ir_value: float | None = None
    red_value: float | None = None
    spo2: float | None = None
    heart_rate: float | None = None
    rso2: float | None = None
    signal_quality: float = 0.0
    motion_artifact: float = 0.0
    risk_score: float = 0.0
    risk_level: str = "unknown"


class SensorReadingResponse(BaseModel):
    id: UUID
    patient_id: UUID
    timestamp: datetime
    ir_value: float | None
    red_value: float | None
    spo2: float | None
    heart_rate: float | None
    rso2: float | None
    signal_quality: float
    motion_artifact: float
    risk_score: float
    risk_level: str
    created_at: datetime

    class Config:
        from_attributes = True
