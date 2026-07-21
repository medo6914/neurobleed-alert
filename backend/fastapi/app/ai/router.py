from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.core.dependencies import get_current_user, require_permission
from app.core.rbac import Permission
from app.models.user import User
from app.ai.schemas import (
    RiskAssessmentRequest,
    RiskAssessmentResponse,
    BatchRiskRequest,
    BatchRiskResponse,
    KnowledgeSearchRequest,
    KnowledgeSearchResponse,
    RiskExplanationRequest,
    RiskExplanationResponse,
)
from app.ai.service import ai_service

router = APIRouter(prefix="/ai", tags=["ai"])


@router.post(
    "/risk/assess",
    response_model=RiskAssessmentResponse,
    summary="Real-time risk assessment from sensor data",
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
    summary="Get patient risk assessment history",
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
    summary="Search medical knowledge base",
)
async def search_knowledge(
    data: KnowledgeSearchRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await ai_service.search_knowledge(data, db)


@router.get(
    "/health",
    summary="AI service health check",
)
async def ai_health():
    return {
        "status": "ok",
        "service": "ai-gateway",
        "model_version": "NB-RISK-1.0.0",
        "rules_loaded": hasattr(ai_service.rules_engine, "rules") and len(ai_service.rules_engine.rules) > 0,
        "risk_engine_ready": True,
    }
