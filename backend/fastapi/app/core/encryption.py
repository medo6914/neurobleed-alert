import base64
import hashlib
import json
import logging
import os
from typing import Any

from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

from app.config import settings

logger = logging.getLogger(__name__)

_SALT = b"neurobleed_encryption_salt_v1"


def _derive_fernet_key(secret_key: str, salt: bytes = _SALT) -> bytes:
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(), length=32, salt=salt, iterations=600_000
    )
    return base64.urlsafe_b64encode(kdf.derive(secret_key.encode("utf-8")))


def _get_fernet() -> Fernet:
    key = _derive_fernet_key(settings.SECRET_KEY)
    return Fernet(key)


def encrypt_value(plain_text: str | None) -> str | None:
    if plain_text is None:
        return None
    f = _get_fernet()
    return f.encrypt(plain_text.encode("utf-8")).decode("utf-8")


def decrypt_value(cipher_text: str | None) -> str | None:
    if cipher_text is None:
        return None
    f = _get_fernet()
    return f.decrypt(cipher_text.encode("utf-8")).decode("utf-8")


def encrypt_json(data: dict[str, Any] | None) -> str | None:
    if data is None:
        return None
    f = _get_fernet()
    return f.encrypt(json.dumps(data, default=str).encode("utf-8")).decode("utf-8")


def decrypt_json(cipher_text: str | None) -> dict[str, Any] | None:
    if cipher_text is None:
        return None
    f = _get_fernet()
    raw = f.decrypt(cipher_text.encode("utf-8"))
    return json.loads(raw.decode("utf-8"))


def hash_for_indexing(value: str | None) -> str | None:
    if value is None:
        return None
    raw = hashlib.sha256(
        (value.lower().strip() + _SALT.decode()).encode("utf-8")
    ).hexdigest()
    return raw
