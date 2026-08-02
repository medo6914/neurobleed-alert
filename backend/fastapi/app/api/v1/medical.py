import logging
from typing import Any

from fastapi import APIRouter, Depends, Query

from app.core.dependencies import get_current_user
from app.models.user import User
from app.services.medical_service import medical_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/medical", tags=["medical"])


@router.get("/drugs/lookup")
async def drug_lookup(
    name: str = Query(..., min_length=1, max_length=100),
    current_user: User = Depends(get_current_user),
) -> list[dict[str, Any]]:
    return await medical_service.drug_lookup(name)


@router.get("/drugs/interactions")
async def drug_interactions(
    drugs: str = Query(..., description="Comma-separated drug names"),
    current_user: User = Depends(get_current_user),
) -> list[dict[str, Any]]:
    names = [d.strip() for d in drugs.split(",") if d.strip()]
    return await medical_service.drug_interactions(names)


@router.get("/drugs/labels")
async def drug_labels(
    search: str = Query(..., min_length=2, max_length=100),
    limit: int = Query(10, ge=1, le=50),
    current_user: User = Depends(get_current_user),
) -> list[dict[str, Any]]:
    return await medical_service.drug_labels(search, limit=limit)


@router.get("/drugs/adverse-events")
async def adverse_events(
    drug: str = Query(..., min_length=2, max_length=100),
    limit: int = Query(5, ge=1, le=20),
    current_user: User = Depends(get_current_user),
) -> list[dict[str, Any]]:
    return await medical_service.adverse_events(drug, limit=limit)
