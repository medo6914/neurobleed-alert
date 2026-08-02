import logging
from typing import Any

from fastapi import APIRouter, Depends, Query

from app.core.dependencies import get_current_user
from app.models.user import User
from app.services.maps_service import maps_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/maps", tags=["maps"])


@router.get("/geocode")
async def geocode(
    q: str = Query(..., min_length=2, max_length=200),
    limit: int = Query(5, ge=1, le=20),
    current_user: User = Depends(get_current_user),
) -> list[dict[str, Any]]:
    return await maps_service.geocode(q, limit=limit)


@router.get("/reverse")
async def reverse(
    lat: float = Query(..., ge=-90, le=90),
    lng: float = Query(..., ge=-180, le=180),
    current_user: User = Depends(get_current_user),
) -> dict[str, Any] | None:
    return await maps_service.reverse_geocode(lat, lng)


@router.get("/hospitals/nearby")
async def nearby_hospitals(
    lat: float = Query(..., ge=-90, le=90),
    lng: float = Query(..., ge=-180, le=180),
    radius_m: int = Query(10000, ge=100, le=50000),
    limit: int = Query(10, ge=1, le=30),
    current_user: User = Depends(get_current_user),
) -> list[dict[str, Any]]:
    return await maps_service.nearby_hospitals(lat, lng, radius_m=radius_m, limit=limit)


@router.get("/route")
async def route(
    from_lat: float = Query(...),
    from_lng: float = Query(...),
    to_lat: float = Query(...),
    to_lng: float = Query(...),
    current_user: User = Depends(get_current_user),
) -> dict[str, Any] | None:
    return await maps_service.route(from_lat, from_lng, to_lat, to_lng)
