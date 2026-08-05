from twilio.rest import Client as TwilioClient
from app.config import settings

_twilio_client = None


def get_twilio_client() -> TwilioClient | None:
    global _twilio_client
    if (
        _twilio_client is None
        and settings.TWILIO_ACCOUNT_SID
        and settings.TWILIO_AUTH_TOKEN
    ):
        _twilio_client = TwilioClient(
            settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN
        )
    return _twilio_client


async def send_otp_sms(phone_number: str, otp: str) -> bool:
    client = get_twilio_client()
    if not client:
        return False
    try:
        message = client.messages.create(
            body=f"NeuroBleed Alert: رمز التحقق الخاص بك هو {otp}. صالح لمدة 5 دقائق.",
            from_=settings.TWILIO_PHONE_NUMBER,
            to=phone_number,
        )
        return True
    except Exception:
        return False


async def send_emergency_alert(
    phone_number: str, patient_name: str, risk_level: str
) -> bool:
    client = get_twilio_client()
    if not client:
        return False
    try:
        message = client.messages.create(
            body=f"🚨 تنبيه طارئ من NeuroBleed Alert!\nالمريض: {patient_name}\nمستوى الخطر: {risk_level}\nيرجى التوجه فورًا.",
            from_=settings.TWILIO_PHONE_NUMBER,
            to=phone_number,
        )
        return True
    except Exception:
        return False
