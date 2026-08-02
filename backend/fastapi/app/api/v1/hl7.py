import logging
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.core.dependencies import get_current_user, require_permission
from app.core.rbac import Permission
from app.core.hl7_parser import hl7_v2_parser, HL7Parser
from app.models.patient import Patient
from app.models.sensor_reading import SensorReading
from app.models.user import User
from app.schemas.hl7 import HL7MessageRequest, HL7ParseResponse

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/hl7", tags=["hl7"])


@router.post("/parse", response_model=HL7ParseResponse)
async def parse_hl7_message(
    data: HL7MessageRequest,
    current_user: User = Depends(require_permission(Permission.PATIENT_CREATE)),
):
    try:
        msg = HL7Parser.parse(data.message)
        parsed = msg.to_dict()
        msg_type = HL7Parser.message_type(msg)

        return HL7ParseResponse(
            success=True,
            message_type=msg_type,
            data=parsed,
        )
    except Exception as e:
        logger.error("HL7 parse error", exc_info=e)
        return HL7ParseResponse(
            success=False,
            message_type="UNKNOWN",
            data={},
            error=str(e),
        )


@router.post("/adt", summary="Process HL7 ADT (Admit/Discharge/Transfer) message")
async def process_adt_message(
    data: HL7MessageRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.PATIENT_CREATE)),
):
    try:
        parsed = hl7_v2_parser.parse_patient_admit(data.message)
        mrn = parsed.get("mrn")

        if mrn:
            existing = await db.execute(
                select(Patient).where(Patient.mrn == mrn)
            )
            patient = existing.scalar_one_or_none()
            if not patient:
                patient = Patient(
                    full_name=f"{parsed.get('first_name', '')} {parsed.get('last_name', '')}".strip(),
                    date_of_birth=parsed.get("date_of_birth", "2000-01-01"),
                    gender=parsed.get("gender", "other"),
                    phone=parsed.get("phone"),
                    mrn=mrn,
                )
                db.add(patient)
                await db.commit()
                await db.refresh(patient)

            event = parsed.get("event", "unknown")
            if event == "admission":
                patient.admission_date = datetime.now(timezone.utc)
                patient.is_active = True
            elif event == "discharge":
                patient.discharge_date = datetime.now(timezone.utc)
                patient.is_active = False
            await db.commit()

            return {
                "success": True,
                "event": event,
                "patient_id": str(patient.id),
                "mrn": mrn,
                "message": f"ADT {event} processed for patient {mrn}",
            }

        return {"success": False, "message": "No MRN found in HL7 message"}

    except Exception as e:
        logger.error("HL7 ADT processing error", exc_info=e)
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.post("/oru", summary="Process HL7 ORU (Observation Result) message")
async def process_oru_message(
    data: HL7MessageRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.PATIENT_CREATE)),
):
    try:
        parsed = hl7_v2_parser.parse_oru_message(data.message)
        mrn = parsed.get("mrn")
        observations = parsed.get("observations", [])

        if not mrn:
            return {"success": False, "message": "No MRN found in HL7 message"}

        existing = await db.execute(select(Patient).where(Patient.mrn == mrn))
        patient = existing.scalar_one_or_none()
        if not patient:
            return {"success": False, "message": f"Patient with MRN {mrn} not found"}

        created_readings = 0
        for obs in observations:
            reading = SensorReading(patient_id=patient.id)

            code = (obs.get("code") or "").lower()
            value_str = obs.get("value") or "0"

            try:
                value = float(value_str) if value_str else 0.0
            except (ValueError, TypeError):
                value = 0.0

            if "heart" in code or "rate" in code or "8867-4" in code:
                reading.heart_rate = value
            elif "spo2" in code or "oxygen" in code or "2708-6" in code:
                reading.oxygen_saturation = value
            elif "systolic" in code or "8480-6" in code:
                reading.systolic_bp = value
            elif "diastolic" in code or "8462-4" in code:
                reading.diastolic_bp = value
            elif "temp" in code or "temperature" in code or "8310-5" in code:
                reading.temperature = value
            else:
                continue

            db.add(reading)
            created_readings += 1

        if created_readings > 0:
            await db.commit()

        return {
            "success": True,
            "patient_id": str(patient.id),
            "mrn": mrn,
            "observations_received": len(observations),
            "observations_created": created_readings,
            "message": f"Processed {created_readings} observations for patient {mrn}",
        }

    except Exception as e:
        logger.error("HL7 ORU processing error", exc_info=e)
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.post("/to-fhir", summary="Convert HL7 message to FHIR R4")
async def hl7_to_fhir(
    data: HL7MessageRequest,
    current_user: User = Depends(require_permission(Permission.PATIENT_VIEW)),
):
    try:
        fhir_resource = hl7_v2_parser.to_fhir(data.message)
        if fhir_resource:
            return fhir_resource
        return {"success": False, "message": "Could not convert HL7 message to FHIR"}
    except Exception as e:
        logger.error("HL7 to FHIR conversion error", exc_info=e)
        return {"success": False, "error": str(e)}
