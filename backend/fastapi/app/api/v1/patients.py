import logging
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, desc, asc, or_
from app.database import get_db
from app.core.dependencies import get_current_user, require_permission
from app.core.rbac import Permission
from app.models.patient import Patient
from app.models.alert import Alert
from app.models.ai_report import AIReport
from app.models.user import User
from app.schemas.patient import (
    PatientCreate, PatientUpdate, PatientResponse, PatientListResponse,
    PatientHistoryResponse, PatientHistoryItem,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/patients", tags=["patients"])


@router.post("/", response_model=PatientResponse, status_code=status.HTTP_201_CREATED)
async def create_patient(
    data: PatientCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.PATIENT_CREATE)),
):
    patient = Patient(**data.model_dump())
    db.add(patient)
    await db.commit()
    await db.refresh(patient)
    logger.info("Patient created", extra={"patient_id": str(patient.id), "user_id": str(current_user.id)})
    return patient


@router.get("/", response_model=PatientListResponse)
async def list_patients(
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=200),
    sort_by: str | None = Query(None, description="Field to sort by"),
    sort_order: str = Query("desc", regex="^(asc|desc)$"),
    search: str | None = Query(None, min_length=2, description="Search by name or MRN"),
    gender: str | None = Query(None),
    blood_type: str | None = Query(None, alias="blood_type"),
    hospital_id: str | None = Query(None),
    department_id: str | None = Query(None),
    is_active: bool | None = Query(None),
    is_ihd_suspected: bool | None = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.PATIENT_LIST)),
):
    query = select(Patient)

    if search:
        search_filter = or_(
            Patient.full_name.ilike(f"%{search}%"),
            Patient.mrn.ilike(f"%{search}%"),
        )
        query = query.where(search_filter)
    if gender:
        query = query.where(Patient.gender == gender)
    if blood_type:
        query = query.where(Patient.blood_type == blood_type)
    if hospital_id:
        query = query.where(Patient.hospital_id == hospital_id)
    if department_id:
        query = query.where(Patient.department_id == department_id)
    if is_active is not None:
        query = query.where(Patient.is_active == is_active)
    if is_ihd_suspected is not None:
        query = query.where(Patient.is_ihd_suspected == is_ihd_suspected)

    total = await db.scalar(select(func.count()).select_from(query.subquery()))

    sort_column = getattr(Patient, sort_by, None) if sort_by else Patient.created_at
    if sort_column is not None:
        order_fn = desc if sort_order == "desc" else asc
        query = query.order_by(order_fn(sort_column))

    query = query.offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(query)
    patients = result.scalars().all()

    total_pages = max(1, (total + per_page - 1) // per_page)
    return PatientListResponse(
        items=[PatientResponse.model_validate(p) for p in patients],
        total=total, page=page, per_page=per_page,
        total_pages=total_pages,
        has_next=page < total_pages, has_prev=page > 1,
    )


@router.get("/{patient_id}", response_model=PatientResponse)
async def get_patient(
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
    return patient


@router.put("/{patient_id}", response_model=PatientResponse)
async def update_patient(
    patient_id: uuid.UUID,
    data: PatientUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.PATIENT_UPDATE)),
):
    result = await db.execute(select(Patient).where(Patient.id == patient_id))
    patient = result.scalar_one_or_none()
    if not patient:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Patient not found")

    update_data = data.model_dump(exclude_unset=True)
    if update_data:
        for key, value in update_data.items():
            setattr(patient, key, value)

    await db.commit()
    await db.refresh(patient)
    logger.info("Patient updated", extra={"patient_id": str(patient.id), "user_id": str(current_user.id)})
    return patient


@router.delete("/{patient_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_patient(
    patient_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.PATIENT_DELETE)),
):
    result = await db.execute(select(Patient).where(Patient.id == patient_id))
    patient = result.scalar_one_or_none()
    if not patient:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Patient not found")

    patient.is_active = False
    patient.deleted_at = datetime.now(timezone.utc)
    await db.commit()
    logger.info("Patient soft-deleted", extra={"patient_id": str(patient_id), "user_id": str(current_user.id)})


@router.get("/{patient_id}/history", response_model=PatientHistoryResponse)
async def get_patient_history(
    patient_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.PATIENT_VIEW)),
):
    result = await db.execute(select(Patient).where(Patient.id == patient_id))
    patient = result.scalar_one_or_none()
    if not patient:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Patient not found")

    events: list[PatientHistoryItem] = []

    # Admission/discharge events
    if patient.admission_date:
        events.append(PatientHistoryItem(
            event_type="admission",
            event_date=patient.admission_date,
            description=f"Patient admitted to {'bed ' + patient.bed_number if patient.bed_number else 'hospital'}",
        ))
    if patient.discharge_date:
        events.append(PatientHistoryItem(
            event_type="discharge",
            event_date=patient.discharge_date,
            description="Patient discharged",
        ))

    # Alert events
    alert_result = await db.execute(
        select(Alert).where(Alert.patient_id == patient_id).order_by(desc(Alert.created_at))
    )
    for alert in alert_result.scalars().all():
        events.append(PatientHistoryItem(
            event_type=f"alert_{alert.alert_type.value if hasattr(alert.alert_type, 'value') else alert.alert_type}",
            event_date=alert.created_at,
            description=alert.message,
            details={"severity": str(alert.severity), "risk_score": alert.risk_score},
        ))

    # AI report events
    report_result = await db.execute(
        select(AIReport).where(AIReport.patient_id == patient_id).order_by(desc(AIReport.created_at))
    )
    for report in report_result.scalars().all():
        events.append(PatientHistoryItem(
            event_type="ai_report",
            event_date=report.created_at,
            description=f"AI risk assessment performed (score: {report.risk_score})",
            details={"risk_score": report.risk_score},
        ))

    events.sort(key=lambda e: e.event_date, reverse=True)

    return PatientHistoryResponse(
        patient_id=patient.id,
        patient_name=patient.full_name,
        events=events,
    )
