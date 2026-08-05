import uuid
from datetime import datetime

from sqlalchemy import String, DateTime, Text, ForeignKey, JSON, func
from sqlalchemy import Enum as SAEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.models.mixins import TimestampMixin
from app.models.enums import KnowledgeUpdateAction


class KnowledgeUpdateLog(TimestampMixin, Base):
    __tablename__ = "knowledge_update_logs"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    knowledge_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("knowledge_base.id", ondelete="CASCADE"), nullable=False, index=True
    )
    action: Mapped[KnowledgeUpdateAction] = mapped_column(
        SAEnum(KnowledgeUpdateAction), nullable=False
    )
    source: Mapped[str | None] = mapped_column(String(255), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    performed_by: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    changes: Mapped[dict | None] = mapped_column(JSON, nullable=True)

    knowledge = relationship("KnowledgeBase")
    performed_by_user = relationship("User")

    def __repr__(self) -> str:
        return f"<KnowledgeUpdateLog(id={self.id}, knowledge_id={self.knowledge_id}, action='{self.action}')>"
