import uuid
from datetime import datetime

from sqlalchemy import String, DateTime, Boolean, ForeignKey, JSON, Integer, func
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.models.mixins import TimestampMixin, SoftDeleteMixin, VersionMixin
from app.models.enums import UserRole


class User(TimestampMixin, SoftDeleteMixin, VersionMixin, Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(
        String(255), unique=True, nullable=False, index=True
    )
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[UserRole] = mapped_column(
        SAEnum(UserRole), nullable=False, default=UserRole.DOCTOR
    )
    phone: Mapped[str | None] = mapped_column(String(50), nullable=True)
    firebase_uid: Mapped[str | None] = mapped_column(
        String(128), nullable=True, index=True
    )
    profile_image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default="1")
    is_email_verified: Mapped[bool] = mapped_column(
        Boolean, default=False, server_default="0"
    )
    is_phone_verified: Mapped[bool] = mapped_column(
        Boolean, default=False, server_default="0"
    )
    is_mfa_enabled: Mapped[bool] = mapped_column(
        Boolean, default=False, server_default="0"
    )
    mfa_secret: Mapped[str | None] = mapped_column(String(100), nullable=True)
    hospital_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("hospitals.id", ondelete="SET NULL"), nullable=True
    )
    last_login_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    last_password_change: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    password_history: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    login_attempts: Mapped[int] = mapped_column(Integer, default=0, server_default="0")
    locked_until: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    notification_preferences: Mapped[dict | None] = mapped_column(JSON, nullable=True)

    hospital = relationship(
        "Hospital", back_populates="users", foreign_keys="User.hospital_id"
    )
    roles: Mapped[list["Role"]] = relationship(
        secondary="user_roles", back_populates="users", lazy="selectin"
    )
    sessions = relationship("Session", back_populates="user", lazy="dynamic")
    refresh_tokens = relationship("RefreshToken", back_populates="user", lazy="dynamic")

    def __repr__(self) -> str:
        return f"<User(id={self.id}, email='{self.email}')>"
