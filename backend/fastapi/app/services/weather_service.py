import logging
from typing import Any

import httpx

from app.config import settings

logger = logging.getLogger(__name__)


class WeatherService:
    """OpenWeatherMap integration (free tier). Returns None gracefully when unconfigured."""

    def __init__(self) -> None:
        self.api_key = settings.OPENWEATHER_API_KEY
        self.units = settings.OPENWEATHER_UNITS
        self._client: httpx.AsyncClient | None = None

    def configured(self) -> bool:
        return bool(self.api_key)

    @property
    def client(self) -> httpx.AsyncClient:
        if self._client is None:
            self._client = httpx.AsyncClient(timeout=httpx.Timeout(15.0))
        return self._client

    async def aclose(self) -> None:
        if self._client is not None:
            await self._client.aclose()
            self._client = None

    async def current(self, lat: float, lng: float) -> dict[str, Any] | None:
        if not self.configured():
            return None
        try:
            resp = await self.client.get(
                "https://api.openweathermap.org/data/2.5/weather",
                params={
                    "lat": lat,
                    "lon": lng,
                    "appid": self.api_key,
                    "units": self.units,
                },
            )
            resp.raise_for_status()
            data = resp.json()
            return {
                "temp_c": data["main"]["temp"],
                "feels_like_c": data["main"]["feels_like"],
                "humidity": data["main"]["humidity"],
                "pressure_hpa": data["main"]["pressure"],
                "description": data["weather"][0]["description"],
                "wind_speed": data["wind"]["speed"],
                "sunrise": data["sys"]["sunrise"],
                "sunset": data["sys"]["sunset"],
                "city": data["name"],
            }
        except Exception as e:
            logger.warning("OpenWeatherMap current failed: %s", e)
            return None

    async def forecast(
        self, lat: float, lng: float, days: int = 3
    ) -> dict[str, Any] | None:
        if not self.configured():
            return None
        try:
            resp = await self.client.get(
                "https://api.openweathermap.org/data/2.5/forecast/daily",
                params={
                    "lat": lat,
                    "lon": lng,
                    "cnt": days,
                    "appid": self.api_key,
                    "units": self.units,
                },
            )
            resp.raise_for_status()
            data = resp.json()
            return [
                {
                    "date": day["dt"],
                    "temp_min_c": day["temp"]["min"],
                    "temp_max_c": day["temp"]["max"],
                    "description": day["weather"][0]["description"],
                }
                for day in data.get("list", [])
            ]
        except Exception as e:
            logger.warning("OpenWeatherMap forecast failed: %s", e)
            return None


weather_service = WeatherService()
