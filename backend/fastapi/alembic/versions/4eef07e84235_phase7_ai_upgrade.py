"""phase7_ai_upgrade

Revision ID: 4eef07e84235
Revises: 3eef07e84235
Create Date: 2026-07-21 12:00:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "4eef07e84235"
down_revision: Union[str, None] = "3eef07e84235"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("ai_reports", sa.Column("explanation", sa.JSON(), nullable=True))
    op.add_column("ai_reports", sa.Column("shap_values", sa.JSON(), nullable=True))
    op.add_column(
        "knowledge_base",
        sa.Column("faiss_indexed", sa.Boolean(), server_default="0", nullable=False),
    )
    op.add_column(
        "knowledge_base",
        sa.Column(
            "faiss_index_version", sa.Integer(), server_default="0", nullable=False
        ),
    )
    op.create_index("ix_knowledge_base_faiss", "knowledge_base", ["faiss_indexed"])


def downgrade() -> None:
    op.drop_index("ix_knowledge_base_faiss", table_name="knowledge_base")
    op.drop_column("knowledge_base", "faiss_index_version")
    op.drop_column("knowledge_base", "faiss_indexed")
    op.drop_column("ai_reports", "shap_values")
    op.drop_column("ai_reports", "explanation")
