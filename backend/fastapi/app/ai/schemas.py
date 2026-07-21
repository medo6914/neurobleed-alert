from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class RiskAssessmentRequest(BaseModel):
    patient_id: UUID
    heart_rate: float | None = None
    spo2: float | None = None
    rso2: float | None = None
    ir_value: float | None = None
    red_value: float | None = None
    systolic_bp: float | None = None
    diastolic_bp: float | None = None
    gcs: float | None = None
    signal_quality: float = 0.0
    motion_artifact: float = 0.0
    readings_window: list[dict] | None = None


class RiskAssessmentResponse(BaseModel):
    model_config = {"protected_namespaces": ()}
    risk_score: float = Field(ge=0.0, le=1.0)
    risk_level: str
    confidence: float = Field(ge=0.0, le=1.0)
    contributing_factors: list[str] = []
    trend: str | None = None
    rules_triggered: list[str] = []
    model_version: str = "NB-RISK-1.0.0"
    inference_time_ms: float = 0.0


class BatchRiskRequest(BaseModel):
    patient_id: UUID
    readings: list[RiskAssessmentRequest]


class BatchRiskResponse(BaseModel):
    assessments: list[RiskAssessmentResponse]
    aggregate_score: float = 0.0
    aggregate_level: str = "unknown"
    trend: str = "stable"


class MedicalRuleResult(BaseModel):
    rule_name: str
    triggered: bool
    priority: int
    action: str | None = None
    severity: str = "info"


class KnowledgeSearchRequest(BaseModel):
    query: str
    category: str | None = None
    limit: int = Field(default=10, le=50)


class KnowledgeSearchResponse(BaseModel):
    results: list[dict] = []
    total: int = 0
    query_time_ms: float = 0.0


class RiskExplanationRequest(BaseModel):
    patient_id: UUID
    risk_score: float
    risk_level: str
    features: dict


class RiskExplanationResponse(BaseModel):
    shap_values: dict = {}
    top_features: list[dict] = []
    narrative: str = ""
