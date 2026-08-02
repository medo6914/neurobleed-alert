import logging
from typing import Any

from fastapi import APIRouter, Depends, Query

from app.core.dependencies import get_current_user
from app.models.user import User
from app.services.weather_service import weather_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/weather", tags=["weather"])


@router.get("/current")
async def current_weather(
    lat: float = Query(..., ge=-90, le=90),
    lng: float = Query(..., ge=-180, le=180),
    current_user: User = Depends(get_current_user),
) -> dict[str, Any] | None:
    data = await weather_service.current(lat, lng)
    if data is None:
        return {"status": "unconfigured", "message": "OPENWEATHER_API_KEY not set"}
    return data


@router.get("/forecast")
async def weather_forecast(
    lat: float = Query(..., ge=-90, le=90),
    lng: float = Query(..., ge=-180, le=180),
    days: int = Query(3, ge=1, le=7),
    current_user: User = Depends(get_current_user),
) -> dict[str, Any] | None:
    data = await weather_service.forecast(lat, lng, days=days)
    if data is None:
        return {"status": "unconfigured", "message": "OPENWEATHER_API_KEY not set"}
    return data
