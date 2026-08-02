import logging
from typing import Any

import httpx

from app.config import settings
from app.core.firebase import send_push
from app.services.email_service import email_service

logger = logging.getLogger(__name__)


class NotificationDispatcher:
    """Multi-channel alert dispatch: Twilio SMS/WhatsApp, Vonage SMS, email (SMTP/Resend/SendGrid), FCM push.
    Each channel activates only when its credentials exist; otherwise it's skipped gracefully."""

    def __init__(self) -> None:
        self._client: httpx.AsyncClient | None = None

    @property
    def client(self) -> httpx.AsyncClient:
        if self._client is None:
            self._client = httpx.AsyncClient(timeout=httpx.Timeout(20.0))
        return self._client

    async def aclose(self) -> None:
        if self._client is not None:
            await self._client.aclose()
            self._client = None

    def channels(self) -> dict[str, bool]:
        return {
            "twilio_sms": bool(settings.TWILIO_ACCOUNT_SID and settings.TWILIO_AUTH_TOKEN),
            "twilio_whatsapp": bool(settings.TWILIO_WHATSAPP_NUMBER),
            "vonage_sms": bool(settings.VONAGE_API_KEY and settings.VONAGE_API_SECRET),
            "email": bool(settings.SMTP_HOST or settings.RESEND_API_KEY or settings.SENDGRID_API_KEY),
            "fcm": bool(settings.FIREBASE_CREDENTIALS_PATH),
        }

    async def send_sms(self, phone: str, body: str) -> list[str]:
        """Try all configured SMS channels; return list of channels that delivered."""
        delivered = []
        if settings.TWILIO_ACCOUNT_SID and settings.TWILIO_AUTH_TOKEN:
            try:
                from twilio.rest import Client

                client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
                client.messages.create(body=body, from_=settings.TWILIO_PHONE_NUMBER, to=phone)
                delivered.append("twilio_sms")
            except Exception as e:
                logger.warning("Twilio SMS failed: %s", e)

        if settings.VONAGE_API_KEY and settings.VONAGE_API_SECRET:
            try:
                resp = await self.client.post(
                    "https://rest.nexmo.com/sms/json",
                    data={
                        "api_key": settings.VONAGE_API_KEY,
                        "api_secret": settings.VONAGE_API_SECRET,
                        "from": settings.VONAGE_PHONE_NUMBER,
                        "to": phone,
                        "text": body,
                    },
                )
                resp.raise_for_status()
                if resp.json().get("messages", [{}])[0].get("status") == "0":
                    delivered.append("vonage_sms")
            except Exception as e:
                logger.warning("Vonage SMS failed: %s", e)

        return delivered

    async def send_whatsapp(self, phone: str, body: str) -> list[str]:
        delivered = []
        if settings.TWILIO_WHATSAPP_NUMBER and settings.TWILIO_ACCOUNT_SID:
            try:
                from twilio.rest import Client

                client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
                client.messages.create(
                    body=body,
                    from_=f"whatsapp:{settings.TWILIO_WHATSAPP_NUMBER}",
                    to=f"whatsapp:{phone}",
                )
                delivered.append("twilio_whatsapp")
            except Exception as e:
                logger.warning("Twilio WhatsApp failed: %s", e)
        return delivered

    async def send_email(self, to: str, subject: str, body: str) -> bool:
        return await email_service.send(to, subject, body, body)

    async def dispatch_emergency(
        self,
        phone: str | None,
        email: str | None,
        fcm_token: str | None,
        patient_name: str,
        risk_level: str,
        message: str,
        data: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Fire all configured channels for an emergency; returns per-channel results."""
        results: dict[str, Any] = {}
        if phone:
            sms = await self.send_sms(phone, message)
            wa = await self.send_whatsapp(phone, message)
            results["sms"] = sms
            results["whatsapp"] = wa
        if email:
            results["email"] = await self.send_email(
                email, f"Emergency Alert - {patient_name} ({risk_level})", message
            )
        if fcm_token:
            results["push"] = await send_push(
                fcm_token, "Emergency Alert", message, data=data
            )
        results["channels_configured"] = self.channels()
        return results


notification_dispatcher = NotificationDispatcher()
