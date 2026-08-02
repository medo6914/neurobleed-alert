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


class ShapExplanation(BaseModel):
    shap_values: dict[str, float] = {}
    expected_value: float = 0.0
    base_risk: float = 0.0


class RiskAssessmentResponse(BaseModel):
    model_config = {"protected_namespaces": ()}
    risk_score: float = Field(ge=0.0, le=1.0)
    risk_level: str
    confidence: float = Field(ge=0.0, le=1.0)
    contributing_factors: list[str] = []
    trend: str | None = None
    rules_triggered: list[str] = []
    model_version: str = "NB-RISK-XGB-2.0.0"
    inference_time_ms: float = 0.0
    explanation: ShapExplanation | None = None
    shap_values: list[float] = []
    feature_names: list[str] = []


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
    semantic_results: list[dict] = []


class RiskExplanationRequest(BaseModel):
    patient_id: UUID
    risk_score: float
    risk_level: str
    features: dict


class RiskExplanationResponse(BaseModel):
    shap_values: dict = {}
    top_features: list[dict] = []
    narrative: str = ""


class ModelStatusResponse(BaseModel):
    model_config = {"protected_namespaces": ()}
    status: str
    progress: float = 0.0
    message: str = ""
    model_exists: bool = False
    model_path: str = ""
    started_at: str | None = None
    completed_at: str | None = None


class TrainModelRequest(BaseModel):
    n_samples: int = Field(default=10000, ge=100, le=100000)


class ExportModelRequest(BaseModel):
    format: str = Field(default="onnx", pattern="^(onnx|tflite)$")


class ExportModelResponse(BaseModel):
    model_config = {"protected_namespaces": ()}
    success: bool = False
    model_path: str | None = None
    format: str = ""
    message: str = ""


class DashboardStatsResponse(BaseModel):
    model_config = {"protected_namespaces": ()}
    total_assessments: int = 0
    total_alerts: int = 0
    model_version: str = ""
    model_trained: bool = False
    rag_document_count: int = 0
    rag_index_loaded: bool = False
    active_patients: int = 0
    active_devices: int = 0
    avg_risk_score: float = 0.0
    risk_distribution: dict = {}
    alerts_by_severity: dict = {}
    recent_activity: list[dict] = []


class IngestKnowledgeRequest(BaseModel):
    source: str = Field(default="manual", pattern="^(manual|pubmed)$")
    query: str | None = None
    max_results: int = Field(default=10, ge=1, le=50)
    title: str | None = None
    content: str | None = None
    category: str = "general"
    tags: list[str] = []


class IngestKnowledgeResponse(BaseModel):
    success: bool = False
    count: int = 0
    message: str = ""
