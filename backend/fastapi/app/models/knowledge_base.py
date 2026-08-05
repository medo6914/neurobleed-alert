import uuid

from sqlalchemy import String, Text, Boolean, JSON, func, Index
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base
from app.models.mixins import (
    TimestampMixin,
    SoftDeleteMixin,
    VersionMixin,
    AuditMixin,
    FHIRMixin,
)


class KnowledgeBase(
    TimestampMixin, SoftDeleteMixin, VersionMixin, AuditMixin, FHIRMixin, Base
):
    __tablename__ = "knowledge_base"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    title: Mapped[str] = mapped_column(String(500), nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    source: Mapped[str | None] = mapped_column(String(255), nullable=True)
    category: Mapped[str] = mapped_column(
        String(100), nullable=False, default="general"
    )
    tags: Mapped[dict] = mapped_column(JSON, default=list)
    embedding: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    is_published: Mapped[bool] = mapped_column(
        Boolean, default=True, server_default="1"
    )
    faiss_indexed: Mapped[bool] = mapped_column(
        Boolean, default=False, server_default="0"
    )
    faiss_index_version: Mapped[int] = mapped_column(default=0)

    def __repr__(self) -> str:
        return f"<KnowledgeBase(id={self.id}, title='{self.title[:50]}')>"


Index("ix_knowledge_base_category", KnowledgeBase.category)
Index(
    "ix_knowledge_base_published",
    KnowledgeBase.is_published,
    KnowledgeBase.created_at.desc(),
)
Index("ix_knowledge_base_faiss", KnowledgeBase.faiss_indexed)
