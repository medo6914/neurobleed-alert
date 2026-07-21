import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Table, Column, func
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


role_permission = Table(
    "role_permissions",
    Base.metadata,
    Column("role_id", ForeignKey("roles.id", ondelete="CASCADE"), primary_key=True),
    Column("permission_id", ForeignKey("permissions.id", ondelete="CASCADE"), primary_key=True),
    Column("created_at", DateTime(timezone=True), server_default=func.now(), nullable=False),
)
