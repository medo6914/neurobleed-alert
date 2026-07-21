from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class AlertResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    patient_id: UUID
    alert_type: str
    severity: str
    risk_score: float | None
    message: str
    is_acknowledged: bool
    acknowledged_at: datetime | None
    created_at: datetime


class AlertAcknowledge(BaseModel):
    is_acknowledged: bool = True
