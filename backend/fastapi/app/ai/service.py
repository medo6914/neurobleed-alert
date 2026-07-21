from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc

from app.ai.schemas import (
    RiskAssessmentRequest,
    RiskAssessmentResponse,
    BatchRiskRequest,
    BatchRiskResponse,
    KnowledgeSearchRequest,
    KnowledgeSearchResponse,
)
from app.ai.risk_engine import RiskEngine
from app.ai.medical_rules_engine import MedicalRulesEngine
from app.models.ai_report import AIReport
from app.models.sensor_reading import SensorReading
from app.models.enums import ReportType, RiskLevel


class AIService:
    def __init__(self):
        self.rules_engine = MedicalRulesEngine()
        self.risk_engine = RiskEngine(rules_engine=self.rules_engine)

    async def assess_risk(
        self,
        data: RiskAssessmentRequest,
        db: AsyncSession,
        user_id: str | None = None,
    ) -> RiskAssessmentResponse:
        result = self.risk_engine.assess(data)

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
            raw_output=result.model_dump(),
            model_version=result.model_version,
            input_data=data.model_dump(),
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
            trend = "worsening" if scores[-1] - scores[0] > 0.1 else "improving" if scores[-1] - scores[0] < -0.1 else "stable"
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
        return [r.to_dict() if hasattr(r, "to_dict") else {
            "id": str(r.id),
            "report_type": r.report_type.value if r.report_type else None,
            "risk_score": r.risk_score,
            "confidence": r.confidence,
            "created_at": r.created_at.isoformat() if r.created_at else None,
            "summary": r.summary,
        } for r in reports]

    async def search_knowledge(
        self,
        data: KnowledgeSearchRequest,
        db: AsyncSession,
    ) -> KnowledgeSearchResponse:
        from app.models.knowledge_base import KnowledgeBase

        import time
        start = time.perf_counter()

        query = select(KnowledgeBase).where(KnowledgeBase.is_active == True)
        if data.category:
            query = query.where(KnowledgeBase.category == data.category)
        query = query.limit(data.limit)

        result = await db.execute(query)
        rows = result.scalars().all()

        if data.query:
            query_lower = data.query.lower()
            rows = [r for r in rows if (
                query_lower in (r.title or "").lower()
                or query_lower in (r.content or "").lower()
                or (query_lower in " ".join(r.tags) if r.tags else False)
            )][:data.limit]

        elapsed = (time.perf_counter() - start) * 1000

        return KnowledgeSearchResponse(
            results=[{
                "id": str(r.id),
                "title": r.title,
                "content": r.content[:500] if r.content else "",
                "source": r.source,
                "category": r.category,
                "tags": r.tags or [],
            } for r in rows],
            total=len(rows),
            query_time_ms=round(elapsed, 2),
        )


ai_service = AIService()
