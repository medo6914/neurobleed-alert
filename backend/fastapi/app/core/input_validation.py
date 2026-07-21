import re
import uuid
from html import unescape

MAX_JSON_SIZE = 1024 * 100
MAX_PAGE_SIZE = 200

_HTML_TAG_RE = re.compile(r"<[^>]*>")
_EMAIL_RE = re.compile(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
_PHONE_RE = re.compile(r"^\+?[1-9]\d{6,14}$")


def sanitize_string(value: str | None, max_length: int = 255) -> str:
    if value is None:
        return ""
    cleaned = _HTML_TAG_RE.sub("", value).strip()
    if len(cleaned) > max_length:
        cleaned = cleaned[:max_length]
    return cleaned


def sanitize_email(email: str | None) -> str:
    if email is None:
        return ""
    cleaned = sanitize_string(email, max_length=254)
    if not _EMAIL_RE.match(cleaned):
        return ""
    return cleaned.lower()


def sanitize_phone(phone: str | None) -> str:
    if phone is None:
        return ""
    cleaned = re.sub(r"[\s\-\(\)\.]+", "", phone.strip())
    if not _PHONE_RE.match(cleaned):
        return ""
    return cleaned


def sanitize_html(text: str | None) -> str:
    if text is None:
        return ""
    stripped = _HTML_TAG_RE.sub("", text)
    return unescape(stripped).strip()


def validate_blood_pressure(systolic: int, diastolic: int) -> bool:
    return 30 <= systolic <= 300 and 20 <= diastolic <= 200 and systolic > diastolic


def validate_heart_rate(rate: float) -> bool:
    return 20.0 <= rate <= 300.0


def validate_spo2(level: float) -> bool:
    return 0.0 <= level <= 100.0


def validate_temperature(temp: float) -> bool:
    return 32.0 <= temp <= 43.0


def validate_uuid(value: str | None) -> bool:
    if value is None:
        return False
    try:
        uuid.UUID(value)
        return True
    except (ValueError, AttributeError):
        return False


def validate_sort_field(field: str, allowed_fields: list[str]) -> bool:
    return field in allowed_fields
