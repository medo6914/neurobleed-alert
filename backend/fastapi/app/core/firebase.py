import firebase_admin
from firebase_admin import credentials, auth as firebase_auth
from app.config import settings

_firebase_app = None


def init_firebase():
    global _firebase_app
    if _firebase_app is None and settings.FIREBASE_CREDENTIALS_PATH:
        cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        _firebase_app = firebase_admin.initialize_app(cred)


async def verify_firebase_token(id_token: str) -> dict | None:
    try:
        decoded = firebase_auth.verify_id_token(id_token)
        return decoded
    except Exception:
        return None


async def get_firebase_user(uid: str) -> dict | None:
    try:
        user = firebase_auth.get_user(uid)
        return {"uid": user.uid, "email": user.email, "phone": user.phone_number, "name": user.display_name}
    except Exception:
        return None


async def create_firebase_user(email: str, password: str, name: str) -> dict | None:
    try:
        user = firebase_auth.create_user(email=email, password=password, display_name=name)
        return {"uid": user.uid, "email": user.email}
    except Exception:
        return None
