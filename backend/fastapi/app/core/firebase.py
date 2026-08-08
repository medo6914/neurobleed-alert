import logging

import json
import tempfile
import os

import firebase_admin
from firebase_admin import credentials, auth as firebase_auth, messaging

from app.config import settings

logger = logging.getLogger(__name__)

_firebase_app = None


def init_firebase():
    global _firebase_app
    if _firebase_app is not None:
        return

    cred_obj = None

    if settings.FIREBASE_CREDENTIALS_JSON:
        try:
            info = json.loads(settings.FIREBASE_CREDENTIALS_JSON)
            cred_obj = credentials.Certificate(info)
            logger.info("Firebase credentials loaded from env var")
        except Exception as e:
            logger.warning("Failed to parse FIREBASE_CREDENTIALS_JSON: %s", e)

    if cred_obj is None and settings.FIREBASE_CREDENTIALS_PATH:
        try:
            cred_obj = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
            logger.info(
                "Firebase credentials loaded from file: %s",
                settings.FIREBASE_CREDENTIALS_PATH,
            )
        except FileNotFoundError:
            logger.warning(
                "Firebase credentials file not found at %s",
                settings.FIREBASE_CREDENTIALS_PATH,
            )
        except Exception as e:
            logger.warning("Failed to load Firebase credentials from file: %s", e)

    if cred_obj is None:
        logger.info("No Firebase credentials configured, Firebase disabled")
        return

    try:
        _firebase_app = firebase_admin.initialize_app(cred_obj)
        logger.info("Firebase initialized successfully")
    except Exception as e:
        logger.warning("Firebase init failed: %s", e)


def firebase_available() -> bool:
    return _firebase_app is not None


async def send_push(
    token: str,
    title: str,
    body: str,
    data: dict | None = None,
    topic: str | None = None,
) -> bool:
    """Send an FCM push notification. Returns False gracefully when unconfigured."""
    try:
        if not firebase_available():
            logger.warning("FCM not configured, skipping push")
            return False
        message = messaging.Message(
            token=token,
            topic=topic,
            notification=messaging.Notification(title=title, body=body),
            data={str(k): str(v) for k, v in (data or {}).items()},
            android=messaging.AndroidConfig(priority="high"),
        )
        response = messaging.send(message)
        logger.info("FCM sent: %s", response)
        return True
    except Exception as e:
        logger.warning("FCM send failed: %s", e)
        return False


async def verify_firebase_token(id_token: str) -> dict | None:
    try:
        decoded = firebase_auth.verify_id_token(id_token)
        return decoded
    except Exception:
        return None


async def verify_google_id_token(id_token: str) -> dict | None:
    """Keyless Google ID token verification via Google's public tokeninfo endpoint."""
    import httpx

    try:
        async with httpx.AsyncClient(timeout=10) as client:
            response = await client.get(
                "https://oauth2.googleapis.com/tokeninfo",
                params={"id_token": id_token},
            )
        if response.status_code != 200:
            return None
        data = response.json()
        if data.get("email_verified") not in (True, "true") or not data.get("email"):
            return None
        if settings.GOOGLE_CLIENT_ID and data.get("aud") != settings.GOOGLE_CLIENT_ID:
            return None
        return {
            "uid": data.get("sub"),
            "email": data.get("email"),
            "name": data.get("name"),
        }
    except Exception:
        return None


async def get_firebase_user(uid: str) -> dict | None:
    try:
        user = firebase_auth.get_user(uid)
        return {
            "uid": user.uid,
            "email": user.email,
            "phone": user.phone_number,
            "name": user.display_name,
        }
    except Exception:
        return None


async def create_firebase_user(email: str, password: str, name: str) -> dict | None:
    try:
        user = firebase_auth.create_user(
            email=email, password=password, display_name=name
        )
        return {"uid": user.uid, "email": user.email}
    except Exception:
        return None
