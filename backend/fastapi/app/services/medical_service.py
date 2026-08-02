import logging
from typing import Any

import httpx

logger = logging.getLogger(__name__)

USER_AGENT = "NeuroBleedAlert/1.0 (medical API gateway)"


class MedicalService:
    """Free, keyless medical APIs: RxNav (drug lookup) and OpenFDA (drug label/event search)."""

    def __init__(self) -> None:
        self.rxnav = "https://rxnav.nlm.nih.gov/REST"
        self.openfda = "https://api.fda.gov"
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

    async def drug_lookup(self, name: str) -> list[dict[str, Any]]:
        """Find RxNorm drug concepts by brand/generic name."""
        try:
            resp = await self.client.get(
                f"{self.rxnav}/drugs",
                params={"name": name, "format": "json"},
            )
            resp.raise_for_status()
            return self._parse_rxnav_drugs(resp.text)
        except Exception as e:
            logger.warning("RxNav drug lookup failed for %r: %s", name, e)
            return []

    @staticmethod
    def _parse_rxnav_drugs(xml_text: str) -> list[dict[str, Any]]:
        import xml.etree.ElementTree as ET

        results = []
        try:
            root = ET.fromstring(xml_text)
            for group in root.iter("conceptGroup"):
                for props in group.iter("conceptProperties"):
                    item = {}
                    for child in props:
                        item[child.tag] = (child.text or "").strip()
                    if item.get("rxcui"):
                        results.append(
                            {
                                "rxcui": item["rxcui"],
                                "name": item.get("name"),
                                "synonym": item.get("synonym"),
                                "tty": item.get("tty"),
                            }
                        )
        except Exception as e:
            logger.warning("RxNav XML parse failed: %s", e)
        return results

    async def drug_interactions(self, names: list[str], limit: int = 5) -> list[dict[str, Any]]:
        """Drug-drug interaction data from FDA labels (OpenFDA 'drug_interactions' section).
        Note: the NLM RxNav DDI endpoint was discontinued in 2024; OpenFDA is its free replacement."""
        if not names:
            return []
        interactions: list[dict[str, Any]] = []
        try:
            for name in names[:3]:
                resp = await self.client.get(
                    f"{self.openfda}/drug/label.json",
                    params={"search": f"openfda.generic_name:{name}", "limit": 2},
                )
                resp.raise_for_status()
                for result in resp.json().get("results", []):
                    for section in result.get("drug_interactions", []):
                        interactions.append(
                            {
                                "drug": result.get("openfda", {}).get("generic_name", [name])[0],
                                "section": section[:800],
                            }
                        )
        except Exception as e:
            logger.warning("OpenFDA interaction lookup failed: %s", e)
        seen = set()
        deduped = []
        for item in interactions:
            key = item["section"][:120]
            if key not in seen:
                seen.add(key)
                deduped.append(item)
            if len(deduped) >= limit:
                break
        return deduped

    async def drug_labels(self, search: str, limit: int = 10) -> list[dict[str, Any]]:
        """Search FDA drug labels (OpenFDA, keyless)."""
        try:
            resp = await self.client.get(
                f"{self.openfda}/drug/label.json",
                params={"search": f"openfda.brand_name:{search}", "limit": limit},
            )
            resp.raise_for_status()
            results = []
            for result in resp.json().get("results", []):
                brand = result.get("openfda", {}).get("brand_name", [""])[0]
                generic = result.get("openfda", {}).get("generic_name", [""])[0]
                indications = result.get("indications_and_usage", [""])
                results.append(
                    {
                        "brand_name": brand,
                        "generic_name": generic,
                        "indications": indications[0][:500] if indications else None,
                    }
                )
            return results
        except Exception as e:
            logger.warning("OpenFDA label search failed: %s", e)
            return []

    async def adverse_events(self, drug: str, limit: int = 5) -> list[dict[str, Any]]:
        """Recent adverse event reports for a drug (OpenFDA, keyless)."""
        try:
            resp = await self.client.get(
                f"{self.openfda}/drug/event.json",
                params={
                    "search": f"patient.drug.medicinalproduct:{drug}",
                    "limit": limit,
                    "sort": "receivedate:desc",
                },
            )
            resp.raise_for_status()
            results = []
            for result in resp.json().get("results", []):
                reactions = [r.get("reactionmeddrapt") for r in result.get("patient", {}).get("reaction", [])][:10]
                drugs = [
                    d.get("medicinalproduct")
                    for d in result.get("patient", {}).get("drug", [])
                ][:10]
                results.append(
                    {
                        "report_id": result.get("safetyreportid"),
                        "receivedate": result.get("receivedate"),
                        "reactions": reactions,
                        "drugs": drugs,
                        "serious": result.get("serious", 0) == 1,
                    }
                )
            return results
        except Exception as e:
            logger.warning("OpenFDA adverse events failed: %s", e)
            return []


medical_service = MedicalService()
