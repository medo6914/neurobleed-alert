import logging
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.emergency import EmergencyContact, EmergencyEvent
from app.models.enums import EmergencyEventStatus
from app.models.patient import Patient
from app.services.notification_service import notification_dispatcher

logger = logging.getLogger(__name__)


class EmergencyService:

    async def trigger_sos(
        self,
        patient_id: str,
        sos_type: str = "manual",
        alert_id: str | None = None,
        location_lat: float | None = None,
        location_lng: float | None = None,
        notes: str | None = None,
        triggered_by: str | None = None,
        db: AsyncSession | None = None,
    ) -> dict:
        if db is None:
            raise ValueError("Database session required")

        event = EmergencyEvent(
            patient_id=patient_id,
            alert_id=alert_id,
            triggered_by=triggered_by,
            status=EmergencyEventStatus.TRIGGERED,
            sos_type=sos_type,
            location_lat=location_lat,
            location_lng=location_lng,
            notes=notes,
        )
        db.add(event)
        await db.commit()
        await db.refresh(event)

        contacts_result = await db.execute(
            select(EmergencyContact)
            .where(EmergencyContact.patient_id == patient_id, EmergencyContact.is_deleted == False)
            .order_by(EmergencyContact.priority)
        )
        contacts = contacts_result.scalars().all()

        patient_result = await db.execute(select(Patient).where(Patient.id == patient_id))
        patient = patient_result.scalar_one_or_none()

        notification_log = []
        for contact in contacts:
            sent = await self._notify_contact(contact, patient, event, db)
            notification_log.append({"contact_id": str(contact.id), "contact_name": contact.full_name, "sent": sent})

        event.status = EmergencyEventStatus.CONTACTING
        event.notification_log = notification_log
        await db.commit()

        return {
            "event_id": str(event.id),
            "status": event.status.value,
            "contacted_count": len(notification_log),
            "contacts": [{"name": c.full_name, "phone": c.phone} for c in contacts],
        }

    async def resolve_sos(
        self,
        event_id: str,
        resolved_by: str,
        db: AsyncSession,
    ) -> EmergencyEvent:
        result = await db.execute(select(EmergencyEvent).where(EmergencyEvent.id == event_id))
        event = result.scalar_one_or_none()
        if not event:
            raise ValueError(f"Emergency event {event_id} not found")

        event.status = EmergencyEventStatus.RESOLVED
        event.resolved_at = datetime.now(timezone.utc)
        event.resolved_by = resolved_by
        await db.commit()
        await db.refresh(event)
        return event

    async def _notify_contact(
        self,
        contact: EmergencyContact,
        patient,
        event: EmergencyEvent,
        db: AsyncSession,
    ) -> bool:
        try:
            patient_name = patient.full_name if patient else "a patient"
            message = (
                f"EMERGENCY ALERT from NeuroBleed Alert\n"
                f"Patient: {patient_name}\n"
                f"Event: {event.sos_type}\n"
                f"Status: {event.status.value}\n"
                + (f"Location: https://www.openstreetmap.org/?mlat={event.location_lat}&mlon={event.location_lng}#map=15/{event.location_lat}/{event.location_lng}\n" if event.location_lat and event.location_lng else "")
                + "Please respond immediately."
            )
            results = await notification_dispatcher.dispatch_emergency(
                phone=contact.phone,
                email=contact.email,
                fcm_token=None,
                patient_name=patient_name,
                risk_level=event.sos_type,
                message=message,
            )
            delivered = bool(
                results.get("sms")
                or results.get("whatsapp")
                or results.get("email")
                or results.get("push")
            )
            if not delivered:
                logger.info(
                    "No notification channels configured. Would send to %s: %s",
                    contact.phone, message,
                )
            return delivered
        except Exception as e:
            logger.error("Failed to notify contact %s: %s", contact.id, e)
            return False


emergency_service = EmergencyService()
