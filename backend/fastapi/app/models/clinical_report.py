import uuid
from datetime import datetime

from sqlalchemy import String, DateTime, Float, ForeignKey, Text, Boolean, JSON, func, Index
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.models.mixins import TimestampMixin, SoftDeleteMixin, VersionMixin, AuditMixin, FHIRMixin, MedicalCodeMixin
from app.models.enums import ReportFormat, ReportStatus


class ClinicalReport(TimestampMixin, SoftDeleteMixin, VersionMixin, AuditMixin, FHIRMixin, MedicalCodeMixin, Base):
    __tablename__ = "clinical_reports"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    patient_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("patients.id", ondelete="CASCADE"), nullable=False, index=True
    )
    alert_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("alerts.id", ondelete="SET NULL"), nullable=True
    )
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    report_type: Mapped[str] = mapped_column(String(100), nullable=False, default="clinical_summary")
    format: Mapped[ReportFormat] = mapped_column(SAEnum(ReportFormat), nullable=False, default=ReportFormat.PDF)
    status: Mapped[ReportStatus] = mapped_column(SAEnum(ReportStatus), nullable=False, default=ReportStatus.PENDING)
    file_path: Mapped[str | None] = mapped_column(String(500), nullable=True)
    file_size: Mapped[int | None] = mapped_column(Float, nullable=True)
    content_html: Mapped[str | None] = mapped_column(Text, nullable=True)
    parameters: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    generated_by: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    generated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    error_message: Mapped[str | None] = mapped_column(Text, nullable=True)
    risk_score: Mapped[float | None] = mapped_column(Float, nullable=True)
    include_shap: Mapped[bool] = mapped_column(Boolean, default=False, server_default="0")
    include_trends: Mapped[bool] = mapped_column(Boolean, default=True, server_default="1")
    language: Mapped[str] = mapped_column(String(10), default="en", server_default="en")

    patient = relationship("Patient", back_populates="clinical_reports")
    alert = relationship("Alert")


Index("ix_clinical_reports_patient_status", ClinicalReport.patient_id, ClinicalReport.status)
Index("ix_clinical_reports_created", ClinicalReport.created_at.desc())
