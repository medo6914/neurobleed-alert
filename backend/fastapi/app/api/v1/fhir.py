import logging
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc

from app.database import get_db
from app.core.dependencies import get_current_user, require_permission
from app.core.rbac import Permission
from app.core.fhir_mapping import fhir_mapper
from app.models.patient import Patient
from app.models.sensor_reading import SensorReading
from app.models.ai_report import AIReport
from app.models.user import User

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/fhir", tags=["fhir"])


@router.get("/Patient/{patient_id}", summary="Get FHIR R4 Patient resource")
async def get_fhir_patient(
    patient_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.PATIENT_VIEW)),
):
    result = await db.execute(select(Patient).where(Patient.id == patient_id))
    patient = result.scalar_one_or_none()
    if not patient:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Patient not found")

    return fhir_mapper.patient_to_fhir(patient)


@router.get("/Patient/{patient_id}/Observation", summary="Get FHIR R4 vital sign observations")
async def get_fhir_observations(
    patient_id: uuid.UUID,
    limit: int = Query(50, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.PATIENT_VIEW)),
):
    result = await db.execute(
        select(Patient).where(Patient.id == patient_id)
    )
    patient = result.scalar_one_or_none()
    if not patient:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Patient not found")

    readings_result = await db.execute(
        select(SensorReading)
        .where(SensorReading.patient_id == patient_id)
        .order_by(desc(SensorReading.created_at))
        .limit(limit)
    )
    readings = readings_result.scalars().all()

    all_observations = []
    for reading in readings:
        all_observations.extend(fhir_mapper.observation_to_fhir(reading, str(patient_id)))

    return {"resourceType": "Bundle", "type": "searchset", "entry": [{"resource": obs} for obs in all_observations], "total": len(all_observations)}


@router.get("/Patient/{patient_id}/Condition", summary="Get FHIR R4 conditions from AI reports")
async def get_fhir_conditions(
    patient_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.PATIENT_VIEW)),
):
    result = await db.execute(
        select(Patient).where(Patient.id == patient_id)
    )
    patient = result.scalar_one_or_none()
    if not patient:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Patient not found")

    ai_result = await db.execute(
        select(AIReport)
        .where(AIReport.patient_id == patient_id, AIReport.risk_score.isnot(None))
        .order_by(desc(AIReport.created_at))
        .limit(20)
    )
    reports = ai_result.scalars().all()

    conditions = []
    for report in reports:
        condition = fhir_mapper.condition_to_fhir(report, str(patient_id))
        if condition:
            conditions.append(condition)

    return {"resourceType": "Bundle", "type": "searchset", "entry": [{"resource": c} for c in conditions], "total": len(conditions)}


@router.get("/Patient/{patient_id}/$everything", summary="FHIR R4 patient compartment export")
async def get_fhir_everything(
    patient_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.PATIENT_VIEW)),
):
    result = await db.execute(select(Patient).where(Patient.id == patient_id))
    patient = result.scalar_one_or_none()
    if not patient:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Patient not found")

    patient_resource = fhir_mapper.patient_to_fhir(patient)
    entries = [{"resource": patient_resource}]

    readings_result = await db.execute(
        select(SensorReading)
        .where(SensorReading.patient_id == patient_id)
        .order_by(desc(SensorReading.created_at))
        .limit(50)
    )
    for reading in readings_result.scalars().all():
        for obs in fhir_mapper.observation_to_fhir(reading, str(patient_id)):
            entries.append({"resource": obs})

    ai_result = await db.execute(
        select(AIReport)
        .where(AIReport.patient_id == patient_id, AIReport.risk_score.isnot(None))
        .order_by(desc(AIReport.created_at))
        .limit(20)
    )
    for report in ai_result.scalars().all():
        condition = fhir_mapper.condition_to_fhir(report, str(patient_id))
        if condition:
            entries.append({"resource": condition})

    return {
        "resourceType": "Bundle",
        "type": "searchset",
        "entry": entries,
        "total": len(entries),
    }
