from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, EmailStr


class UserCreate(BaseModel):
    email: str
    password: str
    full_name: str
    role: str = "user"
    phone: str | None = None
    hospital_id: UUID | None = None


class UserLogin(BaseModel):
    email: str
    password: str


class GoogleLoginRequest(BaseModel):
    id_token: str


class OtpRequest(BaseModel):
    phone: str | None = None
    identifier: str | None = None

    def resolved_phone(self) -> str | None:
        return self.phone or self.identifier


class OtpVerifyRequest(BaseModel):
    phone: str | None = None
    identifier: str | None = None
    otp: str | None = None
    code: str | None = None

    def resolved_phone(self) -> str | None:
        return self.phone or self.identifier

    def resolved_code(self) -> str | None:
        return self.otp or self.code


class EmergencySmsRequest(BaseModel):
    patient_name: str
    risk_level: str
    emergency_phone: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str | None = None
    token_type: str = "bearer"
    user_id: UUID
    email: str
    full_name: str
    role: str


class RefreshRequest(BaseModel):
    refresh_token: str


class ForgotPasswordRequest(BaseModel):
    email: str


class ResetPasswordRequest(BaseModel):
    email: str
    code: str
    new_password: str


class VerifyEmailRequest(BaseModel):
    code: str


class SendPhoneVerificationRequest(BaseModel):
    phone: str


class VerifyPhoneRequest(BaseModel):
    phone: str
    code: str


class UserUpdateRequest(BaseModel):
    full_name: str | None = None
    phone: str | None = None
    profile_image_url: str | None = None


class UserResponse(BaseModel):
    id: UUID
    email: str
    full_name: str
    role: str
    phone: str | None
    firebase_uid: str | None
    is_active: bool
    is_email_verified: bool
    is_phone_verified: bool
    profile_image_url: str | None
    hospital_id: UUID | None
    last_login_at: datetime | None
    created_at: datetime

    class Config:
        from_attributes = True


class SessionResponse(BaseModel):
    session_id: str
    is_active: bool = True
    created_at: datetime | None = None
