import logging
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc

from app.database import get_db
from app.core.dependencies import get_current_user, require_permission
from app.core.rbac import Permission
from app.models.emergency import EmergencyContact, EmergencyEvent
from app.models.user import User
from app.schemas.emergency import (
    EmergencyContactCreate,
    EmergencyContactUpdate,
    EmergencyContactResponse,
    SOSRequest,
    SOSResponse,
    EmergencyEventResponse,
)
from app.services.emergency_service import emergency_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/emergency", tags=["emergency"])


@router.post("/sos", response_model=SOSResponse, status_code=status.HTTP_201_CREATED)
async def trigger_sos(
    data: SOSRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.ALERT_CREATE)),
):
    result = await emergency_service.trigger_sos(
        patient_id=str(data.patient_id),
        sos_type=data.sos_type,
        alert_id=str(data.alert_id) if data.alert_id else None,
        location_lat=data.location_lat,
        location_lng=data.location_lng,
        notes=data.notes,
        triggered_by=str(current_user.id),
        db=db,
    )
    return SOSResponse(
        id=result["event_id"],
        patient_id=data.patient_id,
        status=result["status"],
        sos_type=data.sos_type,
        contacted_count=result["contacted_count"],
        message=f"SOS triggered, {result['contacted_count']} contacts notified",
    )


@router.get("/events", response_model=list[EmergencyEventResponse])
async def list_emergency_events(
    patient_id: str | None = Query(None),
    status_filter: str | None = Query(None, alias="status"),
    limit: int = Query(50, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.ALERT_LIST)),
):
    query = select(EmergencyEvent)
    if patient_id:
        query = query.where(EmergencyEvent.patient_id == patient_id)
    if status_filter:
        query = query.where(EmergencyEvent.status == status_filter)
    query = query.order_by(desc(EmergencyEvent.created_at)).limit(limit)
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/events/{event_id}", response_model=EmergencyEventResponse)
async def get_emergency_event(
    event_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.ALERT_VIEW)),
):
    result = await db.execute(
        select(EmergencyEvent).where(EmergencyEvent.id == event_id)
    )
    event = result.scalar_one_or_none()
    if not event:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Emergency event not found"
        )
    return event


@router.post("/events/{event_id}/resolve", response_model=EmergencyEventResponse)
async def resolve_emergency_event(
    event_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.ALERT_UPDATE)),
):
    try:
        event = await emergency_service.resolve_sos(
            event_id=str(event_id),
            resolved_by=str(current_user.id),
            db=db,
        )
        return event
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))


@router.post(
    "/contacts",
    response_model=EmergencyContactResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_emergency_contact(
    data: EmergencyContactCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.PATIENT_UPDATE)),
):
    if data.is_primary:
        existing = await db.execute(
            select(EmergencyContact).where(
                EmergencyContact.patient_id == data.patient_id,
                EmergencyContact.is_primary == True,
                EmergencyContact.is_deleted == False,
            )
        )
        for c in existing.scalars().all():
            c.is_primary = False

    contact = EmergencyContact(**data.model_dump())
    db.add(contact)
    await db.commit()
    await db.refresh(contact)
    return contact


@router.get("/contacts", response_model=list[EmergencyContactResponse])
async def list_emergency_contacts(
    patient_id: str | None = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.PATIENT_VIEW)),
):
    query = select(EmergencyContact).where(EmergencyContact.is_deleted == False)
    if patient_id:
        query = query.where(EmergencyContact.patient_id == patient_id)
    query = query.order_by(EmergencyContact.priority)
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/contacts/{contact_id}", response_model=EmergencyContactResponse)
async def get_emergency_contact(
    contact_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.PATIENT_VIEW)),
):
    result = await db.execute(
        select(EmergencyContact).where(
            EmergencyContact.id == contact_id, EmergencyContact.is_deleted == False
        )
    )
    contact = result.scalar_one_or_none()
    if not contact:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Emergency contact not found"
        )
    return contact


@router.put("/contacts/{contact_id}", response_model=EmergencyContactResponse)
async def update_emergency_contact(
    contact_id: uuid.UUID,
    data: EmergencyContactUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.PATIENT_UPDATE)),
):
    result = await db.execute(
        select(EmergencyContact).where(
            EmergencyContact.id == contact_id, EmergencyContact.is_deleted == False
        )
    )
    contact = result.scalar_one_or_none()
    if not contact:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Emergency contact not found"
        )

    update_data = data.model_dump(exclude_unset=True)
    if "is_primary" in update_data and update_data["is_primary"]:
        existing = await db.execute(
            select(EmergencyContact).where(
                EmergencyContact.patient_id == contact.patient_id,
                EmergencyContact.is_primary == True,
                EmergencyContact.id != contact_id,
                EmergencyContact.is_deleted == False,
            )
        )
        for c in existing.scalars().all():
            c.is_primary = False

    for key, value in update_data.items():
        setattr(contact, key, value)

    await db.commit()
    await db.refresh(contact)
    return contact


@router.delete("/contacts/{contact_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_emergency_contact(
    contact_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permission(Permission.PATIENT_DELETE)),
):
    result = await db.execute(
        select(EmergencyContact).where(
            EmergencyContact.id == contact_id, EmergencyContact.is_deleted == False
        )
    )
    contact = result.scalar_one_or_none()
    if not contact:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Emergency contact not found"
        )
    contact.is_deleted = True
    await db.commit()
