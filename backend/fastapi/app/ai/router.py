from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.ai.llm_gateway import llm_gateway
from app.ai.schemas import (
    BatchRiskRequest,
    BatchRiskResponse,
    DashboardStatsResponse,
    ExportModelRequest,
    ExportModelResponse,
    IngestKnowledgeRequest,
    IngestKnowledgeResponse,
    KnowledgeSearchRequest,
    KnowledgeSearchResponse,
    ModelStatusResponse,
    RiskAssessmentRequest,
    RiskAssessmentResponse,
    TrainModelRequest,
)
from app.ai.service import ai_service
from app.config import settings
from app.core.dependencies import get_current_user, require_permission
from app.core.rbac import Permission
from app.database import get_db
from app.models.user import User

router = APIRouter(prefix="/ai", tags=["ai"])


class ChatRequest(BaseModel):
    message: str
    system_prompt: str | None = None
    provider: str | None = None


@router.get("/health", summary="AI service health check")
async def ai_health():
    return {
        "status": "ok",
        "service": "ai-gateway",
        "model_version": ai_service.risk_engine.MODEL_VERSION,
        "rules_loaded": hasattr(ai_service.rules_engine, "rules")
        and len(ai_service.rules_engine.rules) > 0,
        "risk_engine_ready": True,
        "model_trained": ai_service.risk_engine.is_trained(),
        "rag_loaded": ai_service.rag_engine.get_stats()["loaded"],
    }


@router.post(
    "/risk/assess",
    response_model=RiskAssessmentResponse,
    summary="Real-time risk assessment from sensor data with SHAP explanation",
)
async def assess_risk(
    data: RiskAssessmentRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.REPORT_CREATE)),
):
    return await ai_service.assess_risk(data, db, str(current_user.id))


@router.post(
    "/risk/batch",
    response_model=BatchRiskResponse,
    summary="Batch risk assessment on historical data",
)
async def batch_risk(
    data: BatchRiskRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.REPORT_CREATE)),
):
    return await ai_service.batch_assess(data, db, str(current_user.id))


@router.get(
    "/risk/history/{patient_id}",
    response_model=list[dict],
    summary="Get patient risk assessment history with SHAP explanations",
)
async def get_risk_history(
    patient_id: UUID,
    limit: int = Query(default=50, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.REPORT_VIEW)),
):
    return await ai_service.get_patient_history(str(patient_id), db, limit)


@router.post(
    "/knowledge/search",
    response_model=KnowledgeSearchResponse,
    summary="Search medical knowledge base with semantic RAG search",
)
async def search_knowledge(
    data: KnowledgeSearchRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await ai_service.search_knowledge(data, db)


@router.post(
    "/knowledge/ingest",
    response_model=IngestKnowledgeResponse,
    summary="Ingest knowledge from manual entry or PubMed",
)
async def ingest_knowledge(
    data: IngestKnowledgeRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.REPORT_CREATE)),
):
    return await ai_service.ingest_knowledge(data, db)


@router.post(
    "/model/train",
    response_model=ModelStatusResponse,
    summary="Train XGBoost model with synthetic clinical data",
)
async def train_model(
    data: TrainModelRequest,
    current_user: User = Depends(require_permission(Permission.REPORT_CREATE)),
):
    X, y = ai_service.model_manager.generate_synthetic_training_data(data.n_samples)
    result = ai_service.model_manager.train_model(X, y)
    return ModelStatusResponse(**result)


@router.get(
    "/model/status",
    response_model=ModelStatusResponse,
    summary="Get model training status and info",
)
async def model_status(
    current_user: User = Depends(get_current_user),
):
    return await ai_service.get_model_status()


@router.post(
    "/model/export",
    response_model=ExportModelResponse,
    summary="Export model to ONNX or TFLite format",
)
async def export_model(
    data: ExportModelRequest,
    current_user: User = Depends(require_permission(Permission.REPORT_CREATE)),
):
    if data.format == "onnx":
        path = ai_service.model_manager.export_onnx()
    elif data.format == "tflite":
        path = ai_service.model_manager.export_tflite()
    else:
        raise HTTPException(
            status_code=400, detail=f"Unsupported format: {data.format}"
        )

    if not path:
        raise HTTPException(status_code=400, detail="Model not trained yet")

    return ExportModelResponse(
        success=True,
        model_path=path,
        format=data.format,
        message=f"Model exported to {data.format} at {path}",
    )


@router.get(
    "/dashboard/stats",
    response_model=DashboardStatsResponse,
    summary="Get AI monitoring dashboard statistics",
)
async def dashboard_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.REPORT_VIEW)),
):
    return await ai_service.get_dashboard_stats(db)


@router.get("/providers", summary="List configured LLM providers")
async def llm_providers(
    current_user: User = Depends(get_current_user),
):
    return {
        "providers": llm_gateway.providers_available(),
        "ollama": settings.OLLAMA_BASE_URL if settings.OLLAMA_BASE_URL else None,
        "model": settings.OLLAMA_MODEL,
    }


@router.post(
    "/chat",
    summary="Chat with the medical LLM assistant (Ollama/OpenAI/Gemini/HuggingFace)",
)
async def chat(
    data: ChatRequest,
    current_user: User = Depends(get_current_user),
):
    system_prompt = data.system_prompt or (
        "You are a clinical decision support assistant for NeuroBleed Alert, a neurocritical care platform "
        "for intracranial hemorrhage patients. Give concise, evidence-based guidance. Always note that you "
        "are not a substitute for professional medical judgment."
    )
    return await llm_gateway.chat(system_prompt, data.message, provider=data.provider)
