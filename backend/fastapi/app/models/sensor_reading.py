import uuid
from datetime import datetime

from sqlalchemy import String, DateTime, Float, ForeignKey, Boolean, JSON, func, Index
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.models.mixins import FHIRMixin, MedicalCodeMixin
from app.models.enums import RiskLevel


class SensorReading(FHIRMixin, MedicalCodeMixin, Base):
    __tablename__ = "sensor_readings"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    patient_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("patients.id", ondelete="CASCADE"), nullable=False, index=True
    )
    device_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("devices.id", ondelete="SET NULL"), nullable=True
    )
    timestamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), index=True, nullable=False
    )

    ir_value: Mapped[float | None] = mapped_column(Float, nullable=True)
    red_value: Mapped[float | None] = mapped_column(Float, nullable=True)
    spo2: Mapped[float | None] = mapped_column(Float, nullable=True)
    heart_rate: Mapped[float | None] = mapped_column(Float, nullable=True)
    rso2: Mapped[float | None] = mapped_column(Float, nullable=True)

    signal_quality: Mapped[float] = mapped_column(Float, default=0.0)
    motion_artifact: Mapped[float] = mapped_column(Float, default=0.0)

    risk_score: Mapped[float] = mapped_column(Float, default=0.0)
    risk_level: Mapped[RiskLevel] = mapped_column(
        SAEnum(RiskLevel), nullable=False, default=RiskLevel.UNKNOWN
    )

    processed_by_tinyml: Mapped[bool] = mapped_column(
        Boolean, default=False, server_default="0"
    )
    processed_by_cloud: Mapped[bool] = mapped_column(
        Boolean, default=False, server_default="0"
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    patient = relationship("Patient", back_populates="sensor_readings")


Index(
    "ix_sensor_readings_patient_timestamp",
    SensorReading.patient_id,
    SensorReading.timestamp.desc(),
)
Index(
    "ix_sensor_readings_device_timestamp",
    SensorReading.device_id,
    SensorReading.timestamp.desc(),
)
Index(
    "ix_sensor_readings_risk_level_timestamp",
    SensorReading.risk_level,
    SensorReading.timestamp.desc(),
)
