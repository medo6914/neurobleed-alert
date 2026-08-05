import time
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc, func as sa_func

from app.ai.schemas import (
    RiskAssessmentRequest,
    RiskAssessmentResponse,
    BatchRiskRequest,
    BatchRiskResponse,
    KnowledgeSearchRequest,
    KnowledgeSearchResponse,
    DashboardStatsResponse,
    IngestKnowledgeRequest,
    IngestKnowledgeResponse,
    ModelStatusResponse,
)
from app.ai.risk_engine import RiskEngine
from app.ai.medical_rules_engine import MedicalRulesEngine
from app.ai.rag_engine import RAGEngine
from app.ai.pubmed_client import PubMedClient
from app.ai.model_manager import ModelManager
from app.models.ai_report import AIReport
from app.models.alert import Alert
from app.models.ai_report import AIReport
from app.models.knowledge_base import KnowledgeBase
from app.models.patient import Patient
from app.models.device import Device
from app.models.enums import ReportType, RiskLevel


class AIService:
    def __init__(self):
        self.rules_engine = MedicalRulesEngine()
        self.risk_engine = RiskEngine(rules_engine=self.rules_engine)
        self.rag_engine = RAGEngine()
        self.pubmed_client = PubMedClient()
        self.model_manager = ModelManager()
        self._rag_initialized = False

    async def initialize(self):
        self.rag_engine.load_index()
        self.model_manager.load_model()
        self._rag_initialized = True

    async def assess_risk(
        self,
        data: RiskAssessmentRequest,
        db: AsyncSession,
        user_id: str | None = None,
    ) -> RiskAssessmentResponse:
        result = self.risk_engine.assess(data)

        explanation_data = None
        shap_values = []
        feature_names = []
        if result.explanation:
            explanation_data = result.explanation.model_dump()
            shap_values = list(result.explanation.shap_values.values())
            feature_names = result.feature_names

        import json

        report = AIReport(
            patient_id=data.patient_id,
            report_type=ReportType.RISK_ASSESSMENT,
            risk_score=result.risk_score,
            confidence=result.confidence,
            features={
                "heart_rate": data.heart_rate,
                "spo2": data.spo2,
                "rso2": data.rso2,
                "signal_quality": data.signal_quality,
                "motion_artifact": data.motion_artifact,
                "contributing_factors": result.contributing_factors,
                "trend": result.trend,
            },
            raw_output=json.loads(result.model_dump_json()),
            model_version=result.model_version,
            input_data=json.loads(data.model_dump_json()),
            explanation=explanation_data,
            shap_values=shap_values,
        )
        db.add(report)
        await db.commit()

        return result

    async def batch_assess(
        self,
        data: BatchRiskRequest,
        db: AsyncSession,
        user_id: str | None = None,
    ) -> BatchRiskResponse:
        assessments = []
        for reading in data.readings:
            reading.patient_id = data.patient_id
            result = await self.assess_risk(reading, db, user_id)
            assessments.append(result)

        scores = [a.risk_score for a in assessments]
        aggregate_score = sum(scores) / len(scores) if scores else 0.0

        if aggregate_score >= 0.8:
            aggregate_level = "critical"
        elif aggregate_score >= 0.6:
            aggregate_level = "high"
        elif aggregate_score >= 0.3:
            aggregate_level = "medium"
        else:
            aggregate_level = "low"

        if len(scores) >= 2:
            trend = (
                "worsening"
                if scores[-1] - scores[0] > 0.1
                else "improving"
                if scores[-1] - scores[0] < -0.1
                else "stable"
            )
        else:
            trend = "stable"

        return BatchRiskResponse(
            assessments=assessments,
            aggregate_score=round(aggregate_score, 4),
            aggregate_level=aggregate_level,
            trend=trend,
        )

    async def get_patient_history(
        self,
        patient_id: str,
        db: AsyncSession,
        limit: int = 50,
    ) -> list[dict]:
        result = await db.execute(
            select(AIReport)
            .where(AIReport.patient_id == patient_id)
            .order_by(desc(AIReport.created_at))
            .limit(limit)
        )
        reports = result.scalars().all()
        return [
            r.to_dict()
            if hasattr(r, "to_dict")
            else {
                "id": str(r.id),
                "report_type": r.report_type.value if r.report_type else None,
                "risk_score": r.risk_score,
                "confidence": r.confidence,
                "created_at": r.created_at.isoformat() if r.created_at else None,
                "summary": r.summary,
                "explanation": r.explanation,
                "shap_values": r.shap_values,
            }
            for r in reports
        ]

    async def search_knowledge(
        self,
        data: KnowledgeSearchRequest,
        db: AsyncSession,
    ) -> KnowledgeSearchResponse:
        import time

        start = time.perf_counter()

        query = select(KnowledgeBase).where(KnowledgeBase.is_published == True)
        if data.category:
            query = query.where(KnowledgeBase.category == data.category)
        query = query.limit(data.limit)

        result = await db.execute(query)
        rows = result.scalars().all()

        if data.query:
            query_lower = data.query.lower()
            rows = [
                r
                for r in rows
                if (
                    query_lower in (r.title or "").lower()
                    or query_lower in (r.content or "").lower()
                    or (query_lower in " ".join(r.tags) if r.tags else False)
                )
            ][: data.limit]

        semantic_results = []
        if data.query and self.rag_engine._loaded:
            try:
                rag_results = self.rag_engine.similarity_search(
                    data.query, k=data.limit
                )
                semantic_results = [
                    {
                        "id": r.get("id", ""),
                        "title": r.get("title", ""),
                        "content": (r.get("content", "") or "")[:500],
                        "source": r.get("source", ""),
                        "category": r.get("category", ""),
                        "tags": r.get("tags", []),
                        "score": r.get("score", 0.0),
                        "distance": r.get("distance", 0.0),
                    }
                    for r in rag_results
                ]
            except Exception:
                pass

        elapsed = (time.perf_counter() - start) * 1000

        return KnowledgeSearchResponse(
            results=[
                {
                    "id": str(r.id),
                    "title": r.title,
                    "content": r.content[:500] if r.content else "",
                    "source": r.source,
                    "category": r.category,
                    "tags": r.tags or [],
                }
                for r in rows
            ],
            total=len(rows),
            query_time_ms=round(elapsed, 2),
            semantic_results=semantic_results,
        )

    async def ingest_knowledge(
        self,
        data: IngestKnowledgeRequest,
        db: AsyncSession,
    ) -> IngestKnowledgeResponse:
        count = 0

        if data.source == "manual" and data.title and data.content:
            entry = KnowledgeBase(
                title=data.title,
                content=data.content,
                source="manual",
                category=data.category,
                tags=data.tags,
                is_published=True,
            )
            db.add(entry)
            count += 1

        elif data.source == "pubmed" and data.query:
            articles = self.pubmed_client.search_and_format(
                data.query, data.max_results
            )
            for article in articles:
                existing = await db.execute(
                    select(KnowledgeBase)
                    .where(
                        KnowledgeBase.source == f"PubMed/{article.get('source', '')}"
                    )
                    .where(KnowledgeBase.title == article["title"])
                )
                if existing.scalar_one_or_none():
                    continue
                entry = KnowledgeBase(
                    title=article["title"],
                    content=article["content"],
                    source=article.get("source", "PubMed"),
                    category="pubmed",
                    tags=article.get("tags", ["pubmed"]),
                    is_published=True,
                )
                db.add(entry)
                count += 1

        if count > 0:
            await db.commit()
            await self._rebuild_rag_index(db)

        return IngestKnowledgeResponse(
            success=True,
            count=count,
            message=f"Ingested {count} knowledge entries from {data.source}",
        )

    async def _rebuild_rag_index(self, db: AsyncSession):
        result = await db.execute(
            select(KnowledgeBase).where(KnowledgeBase.is_published == True)
        )
        entries = result.scalars().all()
        docs = [
            {
                "id": str(e.id),
                "title": e.title or "",
                "content": e.content or "",
                "source": e.source or "",
                "category": e.category or "",
                "tags": e.tags or [],
            }
            for e in entries
        ]
        self.rag_engine.build_index(docs)

        for e in entries:
            e.faiss_indexed = True
        await db.commit()

    async def get_dashboard_stats(self, db: AsyncSession) -> DashboardStatsResponse:
        total_reports = await db.scalar(select(sa_func.count(AIReport.id)))
        total_alerts_result = await db.scalar(select(sa_func.count(Alert.id)))

        active_patients_result = await db.scalar(
            select(sa_func.count(Patient.id)).where(
                Patient.is_active == True, Patient.is_deleted == False
            )
        )
        active_devices_result = await db.scalar(
            select(sa_func.count(Device.id)).where(Device.status == "online")
        )

        risk_scores_result = await db.execute(
            select(AIReport.risk_score).where(AIReport.risk_score.isnot(None))
        )
        risk_scores = [float(r[0]) for r in risk_scores_result if r[0] is not None]

        avg_risk = sum(risk_scores) / len(risk_scores) if risk_scores else 0.0

        risk_dist = {
            "low": sum(1 for s in risk_scores if s < 0.3),
            "medium": sum(1 for s in risk_scores if 0.3 <= s < 0.6),
            "high": sum(1 for s in risk_scores if 0.6 <= s < 0.8),
            "critical": sum(1 for s in risk_scores if s >= 0.8),
        }

        alerts_severity_result = await db.execute(
            select(Alert.severity, sa_func.count(Alert.id)).group_by(Alert.severity)
        )
        alerts_by_severity = {}
        for row in alerts_severity_result:
            sev = row[0].value if hasattr(row[0], "value") else str(row[0])
            alerts_by_severity[sev] = row[1]

        recent = await db.execute(
            select(AIReport).order_by(desc(AIReport.created_at)).limit(10)
        )
        recent_activity = [
            {
                "id": str(r.id),
                "patient_id": str(r.patient_id),
                "risk_score": r.risk_score,
                "risk_level": "high"
                if (r.risk_score or 0) >= 0.6
                else "medium"
                if (r.risk_score or 0) >= 0.3
                else "low",
                "created_at": r.created_at.isoformat() if r.created_at else None,
            }
            for r in recent.scalars().all()
        ]

        return DashboardStatsResponse(
            total_assessments=total_reports or 0,
            total_alerts=total_alerts_result or 0,
            model_version=self.risk_engine.MODEL_VERSION,
            model_trained=self.risk_engine.is_trained(),
            rag_document_count=self.rag_engine.get_stats()["document_count"],
            rag_index_loaded=self.rag_engine.get_stats()["loaded"],
            active_patients=active_patients_result or 0,
            active_devices=active_devices_result or 0,
            avg_risk_score=round(avg_risk, 4),
            risk_distribution=risk_dist,
            alerts_by_severity=alerts_by_severity,
            recent_activity=recent_activity,
        )

    async def get_model_status(self) -> ModelStatusResponse:
        status = self.model_manager.get_status()
        return ModelStatusResponse(
            status=status["status"],
            progress=status["progress"],
            message=status["message"],
            model_exists=status["model_exists"],
            model_path=status["model_path"],
            started_at=status.get("started_at"),
            completed_at=status.get("completed_at"),
        )


ai_service = AIService()
