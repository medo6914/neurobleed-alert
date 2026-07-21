import uuid
import hashlib
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import secrets

from app.database import get_db
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_access_token,
    decode_refresh_token,
)
from app.core.password_policy import validate_password
from app.core.firebase import verify_firebase_token, create_firebase_user
from app.core.twilio import send_otp_sms, send_emergency_alert
from app.core.dependencies import get_current_user, require_permission
from app.core.rbac import Permission
from app.core.session_store import (
    store_session,
    validate_session,
    invalidate_session,
    invalidate_user_sessions,
    get_active_sessions,
)
from app.models.user import User
from app.models.refresh_token import RefreshToken
from app.schemas.user import (
    UserCreate,
    UserLogin,
    GoogleLoginRequest,
    OtpRequest,
    OtpVerifyRequest,
    EmergencySmsRequest,
    RefreshRequest,
    ForgotPasswordRequest,
    ResetPasswordRequest,
    VerifyEmailRequest,
    SendPhoneVerificationRequest,
    VerifyPhoneRequest,
    UserUpdateRequest,
    TokenResponse,
    UserResponse,
    SessionResponse,
)

router = APIRouter(prefix="/auth", tags=["auth"])

_otp_store: dict[str, dict] = {}
_phone_verify_store: dict[str, dict] = {}
_reset_store: dict[str, dict] = {}
_verify_email_store: dict[str, dict] = {}
CODE_EXPIRY_SECONDS = 300


def _clean_expired_stores():
    now = datetime.now(timezone.utc)
    for store in [_otp_store, _phone_verify_store, _reset_store, _verify_email_store]:
        expired = [
            k
            for k, v in store.items()
            if (now - v["created_at"]).total_seconds() > CODE_EXPIRY_SECONDS
        ]
        for k in expired:
            del store[k]


def _generate_code() -> str:
    return str(secrets.randbelow(900000) + 100000)


def _hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def _issue_tokens(user: User) -> TokenResponse:
    token_id = str(uuid.uuid4())
    access_token = create_access_token({
        "sub": str(user.id),
        "role": user.role,
        "firebase_uid": user.firebase_uid,
        "jti": token_id,
    })
    refresh_token = create_refresh_token({"sub": str(user.id)})
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user_id=user.id,
        email=user.email,
        full_name=user.full_name,
        role=user.role,
    )


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(data: UserCreate, db: AsyncSession = Depends(get_db)):
    validate_password(data.password)
    result = await db.execute(select(User).where(User.email == data.email))
    if result.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered")

    firebase_uid = None
    try:
        firebase_user = await create_firebase_user(data.email, data.password, data.full_name)
        firebase_uid = firebase_user.get("uid") if firebase_user else None
    except Exception:
        pass

    user = User(
        email=data.email,
        hashed_password=hash_password(data.password),
        full_name=data.full_name,
        role=data.role or "doctor",
        phone=data.phone,
        hospital_id=data.hospital_id,
        firebase_uid=firebase_uid,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    resp = _issue_tokens(user)
    token_id = decode_access_token(resp.access_token).get("jti")
    if token_id:
        await store_session(user.id, token_id)
    return resp


@router.post("/login", response_model=TokenResponse)
async def login(data: UserLogin, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == data.email))
    user = result.scalar_one_or_none()

    if not user or not verify_password(data.password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is inactive")

    resp = _issue_tokens(user)
    token_id = decode_access_token(resp.access_token).get("jti")
    if token_id:
        await store_session(user.id, token_id)
    return resp


@router.post("/google", response_model=TokenResponse)
async def google_login(data: GoogleLoginRequest, db: AsyncSession = Depends(get_db)):
    decoded = await verify_firebase_token(data.id_token)
    if not decoded:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid Google token")

    email = decoded.get("email")
    firebase_uid = decoded.get("uid")
    name = decoded.get("name", email)

    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()

    if not user:
        user = User(
            email=email,
            hashed_password=hash_password(secrets.token_urlsafe(16)),
            full_name=name,
            role="doctor",
            firebase_uid=firebase_uid,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

    user.firebase_uid = firebase_uid
    await db.commit()

    resp = _issue_tokens(user)
    token_id = decode_access_token(resp.access_token).get("jti")
    if token_id:
        await store_session(user.id, token_id)
    return resp


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(data: RefreshRequest, db: AsyncSession = Depends(get_db)):
    payload = decode_refresh_token(data.refresh_token)
    if payload is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")

    user_id = payload.get("sub")
    if user_id is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")

    user_uuid = uuid.UUID(user_id)
    token_hash = _hash_token(data.refresh_token)

    result = await db.execute(
        select(RefreshToken).where(RefreshToken.token_hash == token_hash)
    )
    stored_token = result.scalar_one_or_none()

    if stored_token:
        if stored_token.is_revoked:
            await invalidate_user_sessions(user_uuid)
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token reuse detected. All sessions revoked.",
            )
        stored_token.is_revoked = True
        stored_token.revoked_at = datetime.now(timezone.utc)

    result = await db.execute(select(User).where(User.id == user_uuid))
    user = result.scalar_one_or_none()
    if user is None or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found or inactive")

    new_refresh = create_refresh_token({"sub": str(user.id)})
    new_hash = _hash_token(new_refresh)
    db.add(RefreshToken(
        user_id=user.id,
        token_hash=new_hash,
        ip_address=None,
        expires_at=datetime.now(timezone.utc),
    ))
    await db.commit()

    token_id = str(uuid.uuid4())
    access_token = create_access_token({
        "sub": str(user.id),
        "role": user.role,
        "firebase_uid": user.firebase_uid,
        "jti": token_id,
    })
    await store_session(user.id, token_id)

    return TokenResponse(
        access_token=access_token,
        refresh_token=new_refresh,
        user_id=user.id,
        email=user.email,
        full_name=user.full_name,
        role=user.role,
    )


@router.post("/logout")
async def logout(
    request: Request,
    current_user: User = Depends(get_current_user),
):
    auth_header = request.headers.get("Authorization")
    if auth_header and auth_header.startswith("Bearer "):
        token = auth_header[7:]
        payload = decode_access_token(token)
        if payload and payload.get("jti"):
            await invalidate_session(payload["jti"])
    await invalidate_user_sessions(current_user.id)
    return {"message": "Logged out successfully"}


@router.post("/forgot-password")
async def forgot_password(data: ForgotPasswordRequest):
    _clean_expired_stores()
    code = _generate_code()
    _reset_store[data.email] = {
        "code": code,
        "created_at": datetime.now(timezone.utc),
        "attempts": 0,
    }
    return {
        "message": "If the email exists, a reset code has been sent.",
        "code_length": 6,
    }


@router.post("/reset-password")
async def reset_password(data: ResetPasswordRequest, db: AsyncSession = Depends(get_db)):
    stored = _reset_store.get(data.email)
    if not stored:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Reset code not found or expired")
    if (datetime.now(timezone.utc) - stored["created_at"]).total_seconds() > CODE_EXPIRY_SECONDS:
        del _reset_store[data.email]
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Reset code expired")

    stored["attempts"] += 1
    if stored["attempts"] > 3:
        del _reset_store[data.email]
        raise HTTPException(status_code=429, detail="Too many failed attempts")

    if stored["code"] != data.code:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid reset code")

    validate_password(data.new_password)
    result = await db.execute(select(User).where(User.email == data.email))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    user.hashed_password = hash_password(data.new_password)
    await db.commit()
    del _reset_store[data.email]

    await invalidate_user_sessions(user.id)

    return {"message": "Password reset successfully"}


@router.post("/verify-email")
async def verify_email(data: VerifyEmailRequest, db: AsyncSession = Depends(get_db)):
    stored = _verify_email_store.get(data.code)
    if not stored:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Verification code not found or expired")
    if (datetime.now(timezone.utc) - stored["created_at"]).total_seconds() > CODE_EXPIRY_SECONDS:
        del _verify_email_store[data.code]
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Verification code expired")

    user_id = stored["user_id"]
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    user.is_email_verified = True
    await db.commit()
    del _verify_email_store[data.code]
    return {"message": "Email verified successfully"}


@router.post("/send-phone-verification")
async def send_phone_verification(data: SendPhoneVerificationRequest):
    _clean_expired_stores()
    code = _generate_code()
    _phone_verify_store[data.phone] = {
        "code": code,
        "created_at": datetime.now(timezone.utc),
        "attempts": 0,
    }
    return {
        "message": "Verification code sent",
        "code_length": 6,
    }


@router.post("/verify-phone")
async def verify_phone(data: VerifyPhoneRequest, db: AsyncSession = Depends(get_db)):
    stored = _phone_verify_store.get(data.phone)
    if not stored:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Verification code not found or expired")
    if (datetime.now(timezone.utc) - stored["created_at"]).total_seconds() > CODE_EXPIRY_SECONDS:
        del _phone_verify_store[data.phone]
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Verification code expired")

    stored["attempts"] += 1
    if stored["attempts"] > 3:
        del _phone_verify_store[data.phone]
        raise HTTPException(status_code=429, detail="Too many failed attempts")

    if stored["code"] != data.code:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid verification code")

    result = await db.execute(select(User).where(User.phone == data.phone))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    user.is_phone_verified = True
    await db.commit()
    del _phone_verify_store[data.phone]
    return {"message": "Phone verified successfully"}


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user


@router.put("/me", response_model=UserResponse)
async def update_me(
    data: UserUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if data.full_name is not None:
        current_user.full_name = data.full_name
    if data.phone is not None:
        current_user.phone = data.phone
    if data.profile_image_url is not None:
        current_user.profile_image_url = data.profile_image_url
    await db.commit()
    await db.refresh(current_user)
    return current_user


@router.get("/sessions", response_model=list[SessionResponse])
async def list_sessions(
    current_user: User = Depends(require_permission(Permission.USER_MANAGE)),
):
    token_jtis = await get_active_sessions(current_user.id)
    return [SessionResponse(session_id=jti, is_active=True) for jti in token_jtis]


@router.delete("/sessions/{session_id}")
async def revoke_session(
    session_id: str,
    current_user: User = Depends(get_current_user),
):
    await invalidate_session(session_id)
    return {"message": "Session revoked"}


@router.post("/sessions/revoke-all")
async def revoke_all_sessions(
    current_user: User = Depends(get_current_user),
):
    count = await invalidate_user_sessions(current_user.id)
    return {"message": f"{count} sessions revoked"}


@router.post("/send-otp")
async def send_otp(data: OtpRequest, request: Request):
    phone = data.phone
    _clean_expired_stores()

    recent = [v for k, v in _otp_store.items() if k == phone]
    if len(recent) >= 5:
        raise HTTPException(status_code=429, detail="Too many OTP requests. Try again later.")

    otp = str(secrets.randbelow(9000) + 1000)
    _otp_store[phone] = {
        "otp": otp,
        "verified": False,
        "created_at": datetime.now(timezone.utc),
        "attempts": 0,
    }
    sent = await send_otp_sms(phone, otp)
    if not sent:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Failed to send OTP")
    return {"message": "OTP sent successfully", "otp_length": 4}


@router.post("/verify-otp", response_model=TokenResponse)
async def verify_otp(data: OtpVerifyRequest, db: AsyncSession = Depends(get_db)):
    phone = data.phone
    otp = data.otp
    stored = _otp_store.get(phone)
    if not stored:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="OTP not found or expired")
    if (datetime.now(timezone.utc) - stored["created_at"]).total_seconds() > CODE_EXPIRY_SECONDS:
        del _otp_store[phone]
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="OTP expired")
    stored["attempts"] += 1
    if stored["attempts"] > 3:
        del _otp_store[phone]
        raise HTTPException(status_code=429, detail="Too many failed attempts")
    if stored["otp"] != otp:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid OTP")
    stored["verified"] = True

    result = await db.execute(select(User).where(User.phone == phone))
    user = result.scalar_one_or_none()

    if not user:
        user = User(
            email=f"{phone}@neurobleed.otp",
            hashed_password=hash_password(secrets.token_urlsafe(16)),
            full_name=f"User {phone[-4:]}",
            role="doctor",
            phone=phone,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

    resp = _issue_tokens(user)
    token_id = decode_access_token(resp.access_token).get("jti")
    if token_id:
        await store_session(user.id, token_id)
    return resp


@router.post("/emergency-sms")
async def emergency_sms(data: EmergencySmsRequest):
    if not data.emergency_phone or len(data.emergency_phone) < 8:
        raise HTTPException(status_code=400, detail="Invalid emergency phone number")
    sent = await send_emergency_alert(data.emergency_phone, data.patient_name, data.risk_level)
    if not sent:
        raise HTTPException(status_code=500, detail="Failed to send emergency SMS")
    return {"message": "Emergency SMS sent"}
