import logging
from typing import Any

import httpx

from app.config import settings

logger = logging.getLogger(__name__)

USER_AGENT = "NeuroBleedAlert/1.0 (hospital emergency navigation)"


class MapsService:
    """Free, keyless OpenStreetMap stack: Nominatim geocoding, Overpass POI search, OSRM routing."""

    def __init__(self) -> None:
        self.nominatim = settings.NOMINATIM_BASE_URL
        self.osrm = settings.OSRM_BASE_URL
        self.overpass = settings.OVERPASS_BASE_URL
        self.region = settings.MAP_SEARCH_REGION
        self._client: httpx.AsyncClient | None = None

    @property
    def client(self) -> httpx.AsyncClient:
        if self._client is None:
            self._client = httpx.AsyncClient(
                timeout=httpx.Timeout(20.0),
                headers={"User-Agent": USER_AGENT},
            )
        return self._client

    async def aclose(self) -> None:
        if self._client is not None:
            await self._client.aclose()
            self._client = None

    async def geocode(self, query: str, limit: int = 5) -> list[dict[str, Any]]:
        """Search places by free-text query (Nominatim)."""
        try:
            resp = await self.client.get(
                f"{self.nominatim}/search",
                params={
                    "q": query,
                    "format": "jsonv2",
                    "limit": limit,
                    "addressdetails": 1,
                    "accept-language": "en",
                },
            )
            resp.raise_for_status()
            return [self._normalize_place(item) for item in resp.json()]
        except Exception as e:
            logger.warning("Nominatim geocode failed for %r: %s", query, e)
            return []

    async def reverse_geocode(self, lat: float, lng: float) -> dict[str, Any] | None:
        try:
            resp = await self.client.get(
                f"{self.nominatim}/reverse",
                params={
                    "lat": lat,
                    "lon": lng,
                    "format": "jsonv2",
                    "zoom": 16,
                    "addressdetails": 1,
                },
            )
            resp.raise_for_status()
            data = resp.json()
            return {
                "display_name": data.get("display_name"),
                "address": data.get("address", {}),
                "lat": float(data.get("lat", lat)),
                "lng": float(data.get("lon", lng)),
            }
        except Exception as e:
            logger.warning("Nominatim reverse failed: %s", e)
            return None

    async def nearby_hospitals(
        self,
        lat: float,
        lng: float,
        radius_m: int = 10000,
        limit: int = 10,
    ) -> list[dict[str, Any]]:
        """Hospitals, clinics and emergency rooms near a point (Overpass API)."""
        query = f"""
        [out:json][timeout:25];
        (
          nwr["amenity"~"hospital|clinic|doctors"](around:{radius_m},{lat},{lng});
          nwr["emergency"="emergency_ward_entrance"](around:{radius_m},{lat},{lng});
        );
        out center tags {limit};
        """
        try:
            resp = await self.client.post(
                self.overpass,
                data={"data": query},
                headers={"Content-Type": "application/x-www-form-urlencoded"},
            )
            resp.raise_for_status()
            results = []
            for el in resp.json().get("elements", []):
                el_lat = el.get("lat") or el.get("center", {}).get("lat")
                el_lng = el.get("lon") or el.get("center", {}).get("lon")
                if el_lat is None or el_lng is None:
                    continue
                tags = el.get("tags", {})
                name = tags.get("name") or tags.get("emergency") or "Medical facility"
                results.append(
                    {
                        "osm_id": el.get("id"),
                        "name": name,
                        "lat": el_lat,
                        "lng": el_lng,
                        "type": el.get("type"),
                        "tags": {
                            k: tags.get(k)
                            for k in ("amenity", "emergency", "healthcare", "operator", "phone", "opening_hours")
                            if tags.get(k)
                        },
                    }
                )
                if len(results) >= limit:
                    break
            return results
        except Exception as e:
            logger.warning("Overpass hospital search failed: %s", e)
            return []

    async def route(self, from_lat: float, from_lng: float, to_lat: float, to_lng: float) -> dict[str, Any] | None:
        """Driving route with polyline + distance + duration (OSRM)."""
        try:
            resp = await self.client.get(
                f"{self.osrm}/route/v1/driving/{from_lng},{from_lat};{to_lng},{to_lat}",
                params={"overview": "full", "geometries": "geojson", "steps": "false"},
            )
            resp.raise_for_status()
            data = resp.json()
            if data.get("code") != "Ok" or not data.get("routes"):
                return None
            route = data["routes"][0]
            return {
                "distance_m": route["distance"],
                "duration_s": route["duration"],
                "geometry": route["geometry"],
            }
        except Exception as e:
            logger.warning("OSRM routing failed: %s", e)
            return None

    async def distance_matrix(self, origins: list[tuple[float, float]], destinations: list[tuple[float, float]]) -> dict[str, Any] | None:
        """Driving distance/duration matrix (OSRM table)."""
        coords = ";".join(f"{lng},{lat}" for lat, lng in origins + destinations)
        n_src, n_dst = len(origins), len(destinations)
        try:
            resp = await self.client.get(
                f"{self.osrm}/table/v1/driving/{coords}",
                params={"sources": ";".join(map(str, range(n_src))), "destinations": ";".join(map(str, range(n_src, n_src + n_dst)))},
            )
            resp.raise_for_status()
            data = resp.json()
            if data.get("code") != "Ok":
                return None
            return {"distances": data.get("distances"), "durations": data.get("durations")}
        except Exception as e:
            logger.warning("OSRM table failed: %s", e)
            return None

    @staticmethod
    def _normalize_place(item: dict[str, Any]) -> dict[str, Any]:
        return {
            "place_id": item.get("place_id"),
            "osm_type": item.get("osm_type"),
            "osm_id": item.get("osm_id"),
            "display_name": item.get("display_name"),
            "lat": float(item.get("lat", 0)),
            "lng": float(item.get("lon", 0)),
            "type": item.get("type"),
            "category": item.get("category"),
            "address": item.get("address", {}),
        }


maps_service = MapsService()
