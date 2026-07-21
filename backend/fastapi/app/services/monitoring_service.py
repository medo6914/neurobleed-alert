import logging
from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.core.event_bus import event_bus
from app.models.sensor_reading import SensorReading
from app.models.alert import Alert
from app.models.enums import RiskLevel, Severity, AlertType
from app.ai.risk_engine import RiskEngine
from app.ai.medical_rules_engine import MedicalRulesEngine
from app.ai.schemas import RiskAssessmentRequest
from app.api.v1.device_ws import manager

logger = logging.getLogger(__name__)

_rules_engine = MedicalRulesEngine()
_risk_engine = RiskEngine(rules_engine=_rules_engine)


def _risk_to_severity(risk_level: str) -> Severity:
    mapping = {
        RiskLevel.CRITICAL: Severity.CRITICAL,
        RiskLevel.HIGH: Severity.HIGH,
        RiskLevel.MEDIUM: Severity.MEDIUM,
        RiskLevel.LOW: Severity.LOW,
    }
    return mapping.get(risk_level, Severity.MEDIUM) if isinstance(risk_level, str) else Severity.MEDIUM


def _risk_to_alert_type(risk_score: float, heart_rate: float | None, spo2: float | None) -> AlertType:
    if heart_rate is not None:
        if heart_rate < 60:
            return AlertType.BRADYCARDIA
        if heart_rate > 100:
            return AlertType.TACHYCARDIA
    if spo2 is not None and spo2 < 90:
        return AlertType.DESATURATION
    if risk_score >= 0.8:
        return AlertType.ICP_ELEVATED
    return AlertType.GENERAL


def _build_alert_message(risk_level: str, risk_score: float, factors: list[str]) -> str:
    base = f"Risk level: {risk_level.upper()} (score: {risk_score:.2f})"
    if factors:
        base += f" — Factors: {'; '.join(factors[:3])}"
    return base


async def handle_reading_created(event_type: str, data: dict):
    reading_id = data.get("reading_id")
    patient_id = data.get("patient_id")

    async for db in get_db():
        try:
            result = await db.execute(
                select(SensorReading).where(SensorReading.id == reading_id)
            )
            reading = result.scalar_one_or_none()
            if reading is None:
                logger.warning(f"Reading {reading_id} not found for event processing")
                return

            risk_req = RiskAssessmentRequest(
                patient_id=patient_id,
                heart_rate=reading.heart_rate,
                spo2=reading.spo2,
                rso2=reading.rso2,
                ir_value=reading.ir_value,
                red_value=reading.red_value,
                signal_quality=reading.signal_quality,
                motion_artifact=reading.motion_artifact,
            )
            risk_result = _risk_engine.assess(risk_req)

            reading.risk_score = risk_result.risk_score
            reading.risk_level = risk_result.risk_level

            if risk_result.risk_score >= 0.4:
                alert_type = _risk_to_alert_type(
                    risk_result.risk_score, reading.heart_rate, reading.spo2
                )
                severity = _risk_to_severity(risk_result.risk_level)
                message = _build_alert_message(
                    risk_result.risk_level,
                    risk_result.risk_score,
                    risk_result.contributing_factors,
                )

                alert = Alert(
                    patient_id=patient_id,
                    device_id=data.get("device_id"),
                    sensor_reading_id=reading_id,
                    alert_type=alert_type,
                    severity=severity,
                    risk_score=risk_result.risk_score,
                    message=message,
                    extra_data={
                        "contributing_factors": risk_result.contributing_factors,
                        "rules_triggered": risk_result.rules_triggered,
                        "trend": risk_result.trend,
                        "confidence": risk_result.confidence,
                    },
                )
                db.add(alert)
                await db.commit()
                await db.refresh(alert)

                await event_bus.publish("alert.created", {
                    "alert_id": str(alert.id),
                    "patient_id": str(patient_id),
                    "device_id": str(data.get("device_id", "")),
                    "alert_type": alert_type.value,
                    "severity": severity.value,
                    "risk_score": risk_result.risk_score,
                    "message": message,
                    "contributing_factors": risk_result.contributing_factors,
                    "created_at": alert.created_at.isoformat() if alert.created_at else datetime.now(timezone.utc).isoformat(),
                })

            await db.commit()

            await manager.broadcast_reading({
                "type": "vitals_update",
                "patient_id": str(patient_id),
                "device_id": str(data.get("device_id", "")),
                "reading_id": str(reading_id),
                "heart_rate": reading.heart_rate,
                "spo2": reading.spo2,
                "rso2": reading.rso2,
                "ir_value": reading.ir_value,
                "red_value": reading.red_value,
                "signal_quality": reading.signal_quality,
                "motion_artifact": reading.motion_artifact,
                "risk_score": risk_result.risk_score,
                "risk_level": risk_result.risk_level,
                "trend": risk_result.trend,
                "timestamp": reading.timestamp.isoformat() if reading.timestamp else datetime.now(timezone.utc).isoformat(),
            })

        except Exception as e:
            logger.error(f"Error processing reading {reading_id}: {e}", exc_info=True)


async def handle_alert_created(event_type: str, data: dict):
    await manager.broadcast_alert({
        "type": "alert_created",
        "alert_id": data.get("alert_id"),
        "patient_id": data.get("patient_id"),
        "device_id": data.get("device_id"),
        "alert_type": data.get("alert_type"),
        "severity": data.get("severity"),
        "risk_score": data.get("risk_score"),
        "message": data.get("message"),
        "contributing_factors": data.get("contributing_factors", []),
        "created_at": data.get("created_at"),
    })


def register_handlers():
    event_bus.subscribe("reading.created", handle_reading_created)
    event_bus.subscribe("alert.created", handle_alert_created)
    logger.info("Monitoring event handlers registered")
