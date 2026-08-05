import uuid
from datetime import datetime

from sqlalchemy import (
    String,
    DateTime,
    Float,
    ForeignKey,
    Text,
    Boolean,
    JSON,
    func,
    Index,
)
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.models.mixins import (
    TimestampMixin,
    SoftDeleteMixin,
    VersionMixin,
    AuditMixin,
    FHIRMixin,
    MedicalCodeMixin,
)
from app.models.enums import ReportType, ICPRisk, HerniationRisk


class AIReport(
    TimestampMixin,
    SoftDeleteMixin,
    VersionMixin,
    AuditMixin,
    FHIRMixin,
    MedicalCodeMixin,
    Base,
):
    __tablename__ = "ai_reports"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    patient_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("patients.id", ondelete="CASCADE"), nullable=False, index=True
    )
    alert_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("alerts.id", ondelete="SET NULL"), nullable=True
    )
    report_type: Mapped[ReportType] = mapped_column(
        SAEnum(ReportType), nullable=False, default=ReportType.RISK_ASSESSMENT
    )
    risk_score: Mapped[float | None] = mapped_column(Float, nullable=True)
    confidence: Mapped[float] = mapped_column(Float, default=0.0)
    bleeding_type: Mapped[str | None] = mapped_column(String(100), nullable=True)
    icp_risk: Mapped[ICPRisk | None] = mapped_column(SAEnum(ICPRisk), nullable=True)
    herniation_risk: Mapped[HerniationRisk | None] = mapped_column(
        SAEnum(HerniationRisk), nullable=True
    )
    summary: Mapped[str | None] = mapped_column(Text, nullable=True)
    detailed_analysis: Mapped[str | None] = mapped_column(Text, nullable=True)
    recommendations: Mapped[str | None] = mapped_column(Text, nullable=True)
    features: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    model_version: Mapped[str | None] = mapped_column(String(50), nullable=True)
    input_data: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    raw_output: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    explanation: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    shap_values: Mapped[list | None] = mapped_column(JSON, nullable=True)
    reviewed_by: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    reviewed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    is_reviewed: Mapped[bool] = mapped_column(
        Boolean, default=False, server_default="0"
    )

    patient = relationship("Patient", back_populates="ai_reports")


Index(
    "ix_ai_reports_patient_type",
    AIReport.patient_id,
    AIReport.report_type,
    AIReport.created_at.desc(),
)
Index("ix_ai_reports_risk_score", AIReport.risk_score.desc())
