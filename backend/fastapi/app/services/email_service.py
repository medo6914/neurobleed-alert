import logging
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

import httpx

from app.config import settings

logger = logging.getLogger(__name__)


class EmailService:
    """Email delivery: SMTP (default) or Resend / SendGrid HTTP APIs."""

    async def send(
        self,
        to: str | list[str],
        subject: str,
        html_body: str,
        text_body: str | None = None,
        from_email: str | None = None,
    ) -> bool:
        recipients = to if isinstance(to, list) else [to]
        sender = from_email or settings.SMTP_FROM_EMAIL
        provider = settings.EMAIL_PROVIDER.lower()

        if provider == "resend" and settings.RESEND_API_KEY:
            return await self._send_resend(recipients, subject, html_body, sender)
        if provider == "sendgrid" and settings.SENDGRID_API_KEY:
            return await self._send_sendgrid(
                recipients, subject, html_body, sender, text_body
            )
        return await self._send_smtp(recipients, subject, html_body, sender)

    async def _send_smtp(
        self, recipients: list[str], subject: str, html_body: str, sender: str
    ) -> bool:
        if not settings.SMTP_HOST or not settings.SMTP_USER:
            logger.warning("SMTP not configured, skipping email to %s", recipients)
            return False
        try:
            msg = MIMEMultipart("alternative")
            msg["Subject"] = subject
            msg["From"] = sender
            msg["To"] = ", ".join(recipients)
            msg.attach(MIMEText(html_body, "html"))
            with smtplib.SMTP(
                settings.SMTP_HOST, settings.SMTP_PORT, timeout=20
            ) as server:
                server.starttls()
                server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
                server.sendmail(sender, recipients, msg.as_string())
            logger.info("SMTP email sent to %s", recipients)
            return True
        except Exception as e:
            logger.warning("SMTP send failed: %s", e)
            return False

    async def _send_resend(
        self, recipients: list[str], subject: str, html_body: str, sender: str
    ) -> bool:
        try:
            async with httpx.AsyncClient(timeout=20) as client:
                resp = await client.post(
                    "https://api.resend.com/emails",
                    headers={"Authorization": f"Bearer {settings.RESEND_API_KEY}"},
                    json={
                        "from": sender,
                        "to": recipients,
                        "subject": subject,
                        "html": html_body,
                    },
                )
                resp.raise_for_status()
            logger.info("Resend email sent to %s", recipients)
            return True
        except Exception as e:
            logger.warning("Resend send failed: %s", e)
            return False

    async def _send_sendgrid(
        self,
        recipients: list[str],
        subject: str,
        html_body: str,
        sender: str,
        text_body: str | None,
    ) -> bool:
        try:
            from_email = settings.SENDGRID_FROM_EMAIL or sender
            async with httpx.AsyncClient(timeout=20) as client:
                resp = await client.post(
                    "https://api.sendgrid.com/v3/mail/send",
                    headers={"Authorization": f"Bearer {settings.SENDGRID_API_KEY}"},
                    json={
                        "personalizations": [
                            {"to": [{"email": r} for r in recipients]}
                        ],
                        "from": {"email": from_email},
                        "subject": subject,
                        "content": [{"type": "text/plain", "value": text_body or ""}],
                    },
                )
                resp.raise_for_status()
            logger.info("SendGrid email sent to %s", recipients)
            return True
        except Exception as e:
            logger.warning("SendGrid send failed: %s", e)
            return False


email_service = EmailService()
