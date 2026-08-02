from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class ClinicalReportCreate(BaseModel):
    patient_id: UUID
    alert_id: UUID | None = None
    title: str = Field(..., min_length=1, max_length=255)
    report_type: str = "clinical_summary"
    format: str = "pdf"
    include_shap: bool = False
    include_trends: bool = True
    language: str = "en"
    parameters: dict | None = None


class ClinicalReportUpdate(BaseModel):
    title: str | None = Field(None, min_length=1, max_length=255)
    format: str | None = None
    status: str | None = None
    parameters: dict | None = None
    include_shap: bool | None = None
    include_trends: bool | None = None


class ClinicalReportResponse(BaseModel):
    id: UUID
    patient_id: UUID
    alert_id: UUID | None
    title: str
    report_type: str
    format: str
    status: str
    file_path: str | None
    file_size: int | None
    generated_by: UUID | None
    generated_at: datetime | None
    error_message: str | None
    risk_score: float | None
    include_shap: bool
    include_trends: bool
    language: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ClinicalReportListResponse(BaseModel):
    items: list[ClinicalReportResponse]
    total: int
    page: int
    per_page: int
    total_pages: int
    has_next: bool
    has_prev: bool
