import uuid
from datetime import datetime

from sqlalchemy import String, DateTime, Boolean, Integer, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, declared_attr


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )


class SoftDeleteMixin:
    is_deleted: Mapped[bool] = mapped_column(Boolean, default=False, server_default="0")
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    deleted_by_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), nullable=True)


class VersionMixin:
    version: Mapped[int] = mapped_column(Integer, default=1, server_default="1")

    @declared_attr
    def __mapper_args__(cls):
        return {
            "version_id_col": cls.version,
            "version_id_generator": lambda v: (v or 0) + 1,
        }


class AuditMixin:
    created_by_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )
    updated_by_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )


class FHIRMixin:
    fhir_resource_type: Mapped[str | None] = mapped_column(String(50), nullable=True)
    fhir_id: Mapped[str | None] = mapped_column(String(100), nullable=True)


class MedicalCodeMixin:
    icd10_code: Mapped[str | None] = mapped_column(String(20), nullable=True)
    snomed_ct_code: Mapped[str | None] = mapped_column(String(20), nullable=True)
    loinc_code: Mapped[str | None] = mapped_column(String(20), nullable=True)
