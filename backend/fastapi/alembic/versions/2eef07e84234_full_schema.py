"""full_schema

Revision ID: 2eef07e84234
Revises: 1eef07e84233
Create Date: 2026-07-14 17:00:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = "2eef07e84234"
down_revision: Union[str, None] = "1eef07e84233"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _create_enums():
    sa.Enum(
        "admin",
        "doctor",
        "nurse",
        "technician",
        "patient",
        "emergency",
        name="userrole",
    ).create(op.get_bind())
    sa.Enum("male", "female", "other", name="gender").create(op.get_bind())
    sa.Enum("A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-", name="bloodtype").create(
        op.get_bind()
    )
    sa.Enum("low", "medium", "high", "critical", "unknown", name="risklevel").create(
        op.get_bind()
    )
    sa.Enum("low", "medium", "high", "critical", name="severity").create(op.get_bind())
    sa.Enum(
        "icp_elevated",
        "desaturation",
        "bradycardia",
        "tachycardia",
        "hypotension",
        "hypertension",
        "arrhythmia",
        "system",
        "general",
        name="alerttype",
    ).create(op.get_bind())
    sa.Enum("NB-01", "NB-02", name="devicetype").create(op.get_bind())
    sa.Enum("online", "offline", "error", "maintenance", name="devicestatus").create(
        op.get_bind()
    )
    sa.Enum(
        "risk_assessment",
        "bleeding_detection",
        "icp_prediction",
        "herniation_prediction",
        name="reporttype",
    ).create(op.get_bind())
    sa.Enum("low", "medium", "high", name="icprisk").create(op.get_bind())
    sa.Enum("low", "medium", "high", name="herniationrisk").create(op.get_bind())
    sa.Enum(
        "general", "specialized", "teaching", "clinic", "research", name="hospitaltype"
    ).create(op.get_bind())
    sa.Enum(
        "hospital",
        "clinic",
        "research_center",
        "government",
        "insurance",
        "pharma",
        name="organizationtype",
    ).create(op.get_bind())
    sa.Enum(
        "create",
        "update",
        "delete",
        "publish",
        "unpublish",
        name="knowledgeupdateaction",
    ).create(op.get_bind())


def _drop_enums():
    op.execute("DROP TYPE IF EXISTS knowledgeupdateaction CASCADE")
    op.execute("DROP TYPE IF EXISTS organizationtype CASCADE")
    op.execute("DROP TYPE IF EXISTS hospitaltype CASCADE")
    op.execute("DROP TYPE IF EXISTS herniationrisk CASCADE")
    op.execute("DROP TYPE IF EXISTS icprisk CASCADE")
    op.execute("DROP TYPE IF EXISTS reporttype CASCADE")
    op.execute("DROP TYPE IF EXISTS devicestatus CASCADE")
    op.execute("DROP TYPE IF EXISTS devicetype CASCADE")
    op.execute("DROP TYPE IF EXISTS alerttype CASCADE")
    op.execute("DROP TYPE IF EXISTS severity CASCADE")
    op.execute("DROP TYPE IF EXISTS risklevel CASCADE")
    op.execute("DROP TYPE IF EXISTS bloodtype CASCADE")
    op.execute("DROP TYPE IF EXISTS gender CASCADE")
    op.execute("DROP TYPE IF EXISTS userrole CASCADE")


def upgrade() -> None:
    _create_enums()

    op.create_table(
        "roles",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(length=50), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("is_system", sa.Boolean(), server_default="0", nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("(CURRENT_TIMESTAMP)"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("(CURRENT_TIMESTAMP)"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_roles_name"), "roles", ["name"], unique=True)

    op.create_table(
        "permissions",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("codename", sa.String(length=100), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("resource", sa.String(length=50), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("(CURRENT_TIMESTAMP)"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_permissions_codename"), "permissions", ["codename"], unique=True
    )

    op.create_table(
        "role_permissions",
        sa.Column("role_id", sa.Uuid(), nullable=False),
        sa.Column("permission_id", sa.Uuid(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("(CURRENT_TIMESTAMP)"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["role_id"], ["roles.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(
            ["permission_id"], ["permissions.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("role_id", "permission_id"),
    )

    op.create_table(
        "user_roles",
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("role_id", sa.Uuid(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("(CURRENT_TIMESTAMP)"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["role_id"], ["roles.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("user_id", "role_id"),
    )

    op.create_table(
        "sessions",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("token_hash", sa.String(length=255), nullable=False),
        sa.Column("refresh_token_hash", sa.String(length=255), nullable=True),
        sa.Column("ip_address", sa.String(length=50), nullable=True),
        sa.Column("user_agent", sa.Text(), nullable=True),
        sa.Column("device_info", sa.String(length=255), nullable=True),
        sa.Column("is_active", sa.Boolean(), server_default="1", nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("(CURRENT_TIMESTAMP)"),
            nullable=False,
        ),
        sa.Column("last_activity_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_sessions_user_id"), "sessions", ["user_id"], unique=False)
    op.create_index(
        op.f("ix_sessions_token_hash"), "sessions", ["token_hash"], unique=False
    )

    op.create_table(
        "refresh_tokens",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("token_hash", sa.String(length=255), nullable=False),
        sa.Column("device_info", sa.String(length=255), nullable=True),
        sa.Column("ip_address", sa.String(length=50), nullable=True),
        sa.Column("is_revoked", sa.Boolean(), server_default="0", nullable=False),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("(CURRENT_TIMESTAMP)"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_refresh_tokens_user_id"), "refresh_tokens", ["user_id"], unique=False
    )
    op.create_index(
        op.f("ix_refresh_tokens_token_hash"),
        "refresh_tokens",
        ["token_hash"],
        unique=False,
    )

    op.create_table(
        "departments",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("hospital_id", sa.Uuid(), nullable=True),
        sa.Column("is_active", sa.Boolean(), server_default="1", nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("(CURRENT_TIMESTAMP)"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("(CURRENT_TIMESTAMP)"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["hospital_id"], ["hospitals.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_departments_hospital_id"), "departments", ["hospital_id"], unique=False
    )

    op.create_table(
        "organizations",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column(
            "org_type",
            sa.Enum(
                "hospital",
                "clinic",
                "research_center",
                "government",
                "insurance",
                "pharma",
                name="organizationtype",
            ),
            nullable=False,
        ),
        sa.Column("address", sa.Text(), nullable=True),
        sa.Column("phone", sa.String(length=50), nullable=True),
        sa.Column("email", sa.String(length=255), nullable=True),
        sa.Column("license_number", sa.String(length=100), nullable=True),
        sa.Column("tax_id", sa.String(length=100), nullable=True),
        sa.Column("website", sa.String(length=500), nullable=True),
        sa.Column("is_active", sa.Boolean(), server_default="1", nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("(CURRENT_TIMESTAMP)"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("(CURRENT_TIMESTAMP)"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("license_number"),
    )

    op.add_column(
        "hospitals",
        sa.Column(
            "hospital_type",
            sa.Enum(
                "general",
                "specialized",
                "teaching",
                "clinic",
                "research",
                name="hospitaltype",
            ),
            nullable=True,
        ),
    )
    op.add_column(
        "hospitals",
        sa.Column("is_deleted", sa.Boolean(), server_default="0", nullable=False),
    )
    op.add_column(
        "hospitals", sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True)
    )
    op.add_column("hospitals", sa.Column("deleted_by_id", sa.Uuid(), nullable=True))
    op.add_column(
        "hospitals",
        sa.Column("version", sa.Integer(), server_default="1", nullable=False),
    )
    op.add_column("hospitals", sa.Column("created_by_id", sa.Uuid(), nullable=True))
    op.add_column("hospitals", sa.Column("updated_by_id", sa.Uuid(), nullable=True))
    op.add_column(
        "hospitals",
        sa.Column("fhir_resource_type", sa.String(length=50), nullable=True),
    )
    op.add_column(
        "hospitals", sa.Column("fhir_id", sa.String(length=100), nullable=True)
    )
    op.drop_constraint("uq_hospitals_email", "hospitals", type_="unique")
    op.drop_constraint("uq_hospitals_license_number", "hospitals", type_="unique")
    op.create_index(op.f("ix_hospitals_email"), "hospitals", ["email"], unique=True)
    op.create_index(
        op.f("ix_hospitals_license_number"),
        "hospitals",
        ["license_number"],
        unique=True,
    )
    op.alter_column("hospitals", "address", nullable=True)
    op.alter_column("hospitals", "phone", nullable=True)
    op.create_foreign_key(
        "fk_hospitals_deleted_by_id",
        "hospitals",
        "users",
        ["deleted_by_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_foreign_key(
        "fk_hospitals_created_by_id",
        "hospitals",
        "users",
        ["created_by_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_foreign_key(
        "fk_hospitals_updated_by_id",
        "hospitals",
        "users",
        ["updated_by_id"],
        ["id"],
        ondelete="SET NULL",
    )

    op.add_column(
        "users",
        sa.Column("is_mfa_enabled", sa.Boolean(), server_default="0", nullable=False),
    )
    op.add_column(
        "users", sa.Column("mfa_secret", sa.String(length=100), nullable=True)
    )
    op.add_column(
        "users",
        sa.Column("last_password_change", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column("users", sa.Column("password_history", sa.JSON(), nullable=True))
    op.add_column(
        "users",
        sa.Column("login_attempts", sa.Integer(), server_default="0", nullable=False),
    )
    op.add_column(
        "users", sa.Column("locked_until", sa.DateTime(timezone=True), nullable=True)
    )
    op.add_column(
        "users",
        sa.Column("is_deleted", sa.Boolean(), server_default="0", nullable=False),
    )
    op.add_column(
        "users", sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True)
    )
    op.add_column("users", sa.Column("deleted_by_id", sa.Uuid(), nullable=True))
    op.add_column(
        "users", sa.Column("version", sa.Integer(), server_default="1", nullable=False)
    )
    op.create_foreign_key(
        "fk_users_deleted_by_id",
        "users",
        "users",
        ["deleted_by_id"],
        ["id"],
        ondelete="SET NULL",
    )

    op.add_column("patients", sa.Column("mrn", sa.String(length=50), nullable=True))
    op.add_column("patients", sa.Column("email", sa.String(length=255), nullable=True))
    op.add_column(
        "patients",
        sa.Column("emergency_contact_relation", sa.String(length=50), nullable=True),
    )
    op.add_column("patients", sa.Column("height_cm", sa.Float(), nullable=True))
    op.add_column("patients", sa.Column("weight_kg", sa.Float(), nullable=True))
    op.add_column(
        "patients",
        sa.Column("discharge_date", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column("patients", sa.Column("department_id", sa.Uuid(), nullable=True))
    op.add_column(
        "patients",
        sa.Column("is_deleted", sa.Boolean(), server_default="0", nullable=False),
    )
    op.add_column(
        "patients", sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True)
    )
    op.add_column("patients", sa.Column("deleted_by_id", sa.Uuid(), nullable=True))
    op.add_column(
        "patients",
        sa.Column("version", sa.Integer(), server_default="1", nullable=False),
    )
    op.add_column("patients", sa.Column("created_by_id", sa.Uuid(), nullable=True))
    op.add_column("patients", sa.Column("updated_by_id", sa.Uuid(), nullable=True))
    op.add_column(
        "patients", sa.Column("fhir_resource_type", sa.String(length=50), nullable=True)
    )
    op.add_column(
        "patients", sa.Column("fhir_id", sa.String(length=100), nullable=True)
    )
    op.add_column(
        "patients", sa.Column("icd10_code", sa.String(length=20), nullable=True)
    )
    op.add_column(
        "patients", sa.Column("snomed_ct_code", sa.String(length=20), nullable=True)
    )
    op.add_column(
        "patients", sa.Column("loinc_code", sa.String(length=20), nullable=True)
    )
    op.create_index(op.f("ix_patients_mrn"), "patients", ["mrn"], unique=True)
    op.create_foreign_key(
        "fk_patients_department_id",
        "patients",
        "departments",
        ["department_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_foreign_key(
        "fk_patients_deleted_by_id",
        "patients",
        "users",
        ["deleted_by_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_foreign_key(
        "fk_patients_created_by_id",
        "patients",
        "users",
        ["created_by_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_foreign_key(
        "fk_patients_updated_by_id",
        "patients",
        "users",
        ["updated_by_id"],
        ["id"],
        ondelete="SET NULL",
    )

    op.add_column(
        "devices", sa.Column("device_name", sa.String(length=255), nullable=True)
    )
    op.add_column(
        "devices", sa.Column("mac_address", sa.String(length=50), nullable=True)
    )
    op.add_column("devices", sa.Column("hospital_id", sa.Uuid(), nullable=True))
    op.add_column(
        "devices",
        sa.Column("is_deleted", sa.Boolean(), server_default="0", nullable=False),
    )
    op.add_column(
        "devices", sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True)
    )
    op.add_column("devices", sa.Column("deleted_by_id", sa.Uuid(), nullable=True))
    op.add_column(
        "devices",
        sa.Column("version", sa.Integer(), server_default="1", nullable=False),
    )
    op.add_column("devices", sa.Column("created_by_id", sa.Uuid(), nullable=True))
    op.add_column("devices", sa.Column("updated_by_id", sa.Uuid(), nullable=True))
    op.add_column(
        "devices", sa.Column("fhir_resource_type", sa.String(length=50), nullable=True)
    )
    op.add_column("devices", sa.Column("fhir_id", sa.String(length=100), nullable=True))
    op.create_unique_constraint("uq_devices_mac_address", "devices", ["mac_address"])
    op.create_foreign_key(
        "fk_devices_hospital_id",
        "devices",
        "hospitals",
        ["hospital_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_foreign_key(
        "fk_devices_deleted_by_id",
        "devices",
        "users",
        ["deleted_by_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_foreign_key(
        "fk_devices_created_by_id",
        "devices",
        "users",
        ["created_by_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_foreign_key(
        "fk_devices_updated_by_id",
        "devices",
        "users",
        ["updated_by_id"],
        ["id"],
        ondelete="SET NULL",
    )

    op.add_column(
        "sensor_readings",
        sa.Column("fhir_resource_type", sa.String(length=50), nullable=True),
    )
    op.add_column(
        "sensor_readings", sa.Column("fhir_id", sa.String(length=100), nullable=True)
    )
    op.add_column(
        "sensor_readings", sa.Column("icd10_code", sa.String(length=20), nullable=True)
    )
    op.add_column(
        "sensor_readings",
        sa.Column("snomed_ct_code", sa.String(length=20), nullable=True),
    )
    op.add_column(
        "sensor_readings", sa.Column("loinc_code", sa.String(length=20), nullable=True)
    )

    op.alter_column("alerts", "acknowledged", new_column_name="is_acknowledged")
    op.add_column(
        "alerts",
        sa.Column("is_resolved", sa.Boolean(), server_default="0", nullable=False),
    )
    op.add_column("alerts", sa.Column("resolved_by", sa.Uuid(), nullable=True))
    op.add_column(
        "alerts", sa.Column("resolved_at", sa.DateTime(timezone=True), nullable=True)
    )
    op.add_column("alerts", sa.Column("resolution_notes", sa.Text(), nullable=True))
    op.add_column("alerts", sa.Column("extra_data", sa.JSON(), nullable=True))
    op.add_column(
        "alerts",
        sa.Column("is_deleted", sa.Boolean(), server_default="0", nullable=False),
    )
    op.add_column(
        "alerts", sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True)
    )
    op.add_column("alerts", sa.Column("deleted_by_id", sa.Uuid(), nullable=True))
    op.add_column(
        "alerts", sa.Column("version", sa.Integer(), server_default="1", nullable=False)
    )
    op.add_column(
        "alerts", sa.Column("fhir_resource_type", sa.String(length=50), nullable=True)
    )
    op.add_column("alerts", sa.Column("fhir_id", sa.String(length=100), nullable=True))
    op.add_column(
        "alerts", sa.Column("icd10_code", sa.String(length=20), nullable=True)
    )
    op.add_column(
        "alerts", sa.Column("snomed_ct_code", sa.String(length=20), nullable=True)
    )
    op.add_column(
        "alerts", sa.Column("loinc_code", sa.String(length=20), nullable=True)
    )
    op.create_foreign_key(
        "fk_alerts_resolved_by",
        "alerts",
        "users",
        ["resolved_by"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_foreign_key(
        "fk_alerts_deleted_by_id",
        "alerts",
        "users",
        ["deleted_by_id"],
        ["id"],
        ondelete="SET NULL",
    )

    op.add_column(
        "ai_reports", sa.Column("bleeding_type", sa.String(length=100), nullable=True)
    )
    op.add_column(
        "ai_reports",
        sa.Column(
            "icp_risk", sa.Enum("low", "medium", "high", name="icprisk"), nullable=True
        ),
    )
    op.add_column(
        "ai_reports",
        sa.Column(
            "herniation_risk",
            sa.Enum("low", "medium", "high", name="herniationrisk"),
            nullable=True,
        ),
    )
    op.add_column("ai_reports", sa.Column("features", sa.JSON(), nullable=True))
    op.add_column("ai_reports", sa.Column("input_data", sa.JSON(), nullable=True))
    op.add_column("ai_reports", sa.Column("raw_output", sa.JSON(), nullable=True))
    op.add_column("ai_reports", sa.Column("reviewed_by", sa.Uuid(), nullable=True))
    op.add_column(
        "ai_reports",
        sa.Column("reviewed_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        "ai_reports",
        sa.Column("is_reviewed", sa.Boolean(), server_default="0", nullable=False),
    )
    op.add_column(
        "ai_reports",
        sa.Column("is_deleted", sa.Boolean(), server_default="0", nullable=False),
    )
    op.add_column(
        "ai_reports", sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True)
    )
    op.add_column("ai_reports", sa.Column("deleted_by_id", sa.Uuid(), nullable=True))
    op.add_column(
        "ai_reports",
        sa.Column("version", sa.Integer(), server_default="1", nullable=False),
    )
    op.add_column("ai_reports", sa.Column("created_by_id", sa.Uuid(), nullable=True))
    op.add_column("ai_reports", sa.Column("updated_by_id", sa.Uuid(), nullable=True))
    op.add_column(
        "ai_reports",
        sa.Column("fhir_resource_type", sa.String(length=50), nullable=True),
    )
    op.add_column(
        "ai_reports", sa.Column("fhir_id", sa.String(length=100), nullable=True)
    )
    op.add_column(
        "ai_reports", sa.Column("icd10_code", sa.String(length=20), nullable=True)
    )
    op.add_column(
        "ai_reports", sa.Column("snomed_ct_code", sa.String(length=20), nullable=True)
    )
    op.add_column(
        "ai_reports", sa.Column("loinc_code", sa.String(length=20), nullable=True)
    )
    op.create_foreign_key(
        "fk_ai_reports_reviewed_by",
        "ai_reports",
        "users",
        ["reviewed_by"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_foreign_key(
        "fk_ai_reports_deleted_by_id",
        "ai_reports",
        "users",
        ["deleted_by_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_foreign_key(
        "fk_ai_reports_created_by_id",
        "ai_reports",
        "users",
        ["created_by_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_foreign_key(
        "fk_ai_reports_updated_by_id",
        "ai_reports",
        "users",
        ["updated_by_id"],
        ["id"],
        ondelete="SET NULL",
    )

    op.alter_column("knowledge_base", "is_active", new_column_name="is_published")
    op.add_column(
        "knowledge_base",
        sa.Column("is_deleted", sa.Boolean(), server_default="0", nullable=False),
    )
    op.add_column(
        "knowledge_base",
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        "knowledge_base", sa.Column("deleted_by_id", sa.Uuid(), nullable=True)
    )
    op.add_column(
        "knowledge_base",
        sa.Column("version", sa.Integer(), server_default="1", nullable=False),
    )
    op.add_column(
        "knowledge_base", sa.Column("created_by_id", sa.Uuid(), nullable=True)
    )
    op.add_column(
        "knowledge_base", sa.Column("updated_by_id", sa.Uuid(), nullable=True)
    )
    op.add_column(
        "knowledge_base",
        sa.Column("fhir_resource_type", sa.String(length=50), nullable=True),
    )
    op.add_column(
        "knowledge_base", sa.Column("fhir_id", sa.String(length=100), nullable=True)
    )
    op.create_foreign_key(
        "fk_knowledge_base_deleted_by_id",
        "knowledge_base",
        "users",
        ["deleted_by_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_foreign_key(
        "fk_knowledge_base_created_by_id",
        "knowledge_base",
        "users",
        ["created_by_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_foreign_key(
        "fk_knowledge_base_updated_by_id",
        "knowledge_base",
        "users",
        ["updated_by_id"],
        ["id"],
        ondelete="SET NULL",
    )

    op.rename_table("knowledge_update_log", "knowledge_update_logs")
    op.add_column(
        "knowledge_update_logs", sa.Column("changes", sa.JSON(), nullable=True)
    )
    op.drop_column("knowledge_update_logs", "performed_by")
    op.add_column(
        "knowledge_update_logs", sa.Column("performed_by", sa.Uuid(), nullable=True)
    )
    op.alter_column("knowledge_update_logs", "knowledge_id", nullable=False)
    op.create_foreign_key(
        "fk_knowledge_update_logs_performed_by",
        "knowledge_update_logs",
        "users",
        ["performed_by"],
        ["id"],
        ondelete="SET NULL",
    )

    op.add_column(
        "audit_logs", sa.Column("correlation_id", sa.String(length=100), nullable=True)
    )
    op.add_column(
        "audit_logs",
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("(CURRENT_TIMESTAMP)"),
            nullable=False,
        ),
    )
    op.create_index(
        op.f("ix_audit_logs_correlation_id"),
        "audit_logs",
        ["correlation_id"],
        unique=False,
    )

    op.create_index(
        "ix_sensor_readings_patient_timestamp",
        "sensor_readings",
        ["patient_id", sa.text("timestamp DESC")],
    )
    op.create_index(
        "ix_sensor_readings_device_timestamp",
        "sensor_readings",
        ["device_id", sa.text("timestamp DESC")],
    )
    op.create_index(
        "ix_sensor_readings_risk_level_timestamp",
        "sensor_readings",
        ["risk_level", sa.text("timestamp DESC")],
    )

    op.create_index(
        "ix_alerts_patient_severity",
        "alerts",
        ["patient_id", "severity", sa.text("created_at DESC")],
    )
    op.create_index(
        "ix_alerts_unacknowledged",
        "alerts",
        ["is_acknowledged", sa.text("created_at DESC")],
    )
    op.create_index(
        "ix_alerts_unresolved", "alerts", ["is_resolved", sa.text("created_at DESC")]
    )

    op.create_index(
        "ix_ai_reports_patient_type",
        "ai_reports",
        ["patient_id", "report_type", sa.text("created_at DESC")],
    )
    op.create_index(
        "ix_ai_reports_risk_score", "ai_reports", [sa.text("risk_score DESC")]
    )

    op.create_index("ix_knowledge_base_category", "knowledge_base", ["category"])
    op.create_index(
        "ix_knowledge_base_published",
        "knowledge_base",
        ["is_published", sa.text("created_at DESC")],
    )

    op.create_index(
        "ix_audit_logs_user_action",
        "audit_logs",
        ["user_id", "action", sa.text("created_at DESC")],
    )
    op.create_index(
        "ix_audit_logs_resource", "audit_logs", ["resource", sa.text("created_at DESC")]
    )


def downgrade() -> None:
    op.drop_index("ix_audit_logs_resource", table_name="audit_logs")
    op.drop_index("ix_audit_logs_user_action", table_name="audit_logs")
    op.drop_index("ix_knowledge_base_published", table_name="knowledge_base")
    op.drop_index("ix_knowledge_base_category", table_name="knowledge_base")
    op.drop_index("ix_ai_reports_risk_score", table_name="ai_reports")
    op.drop_index("ix_ai_reports_patient_type", table_name="ai_reports")
    op.drop_index("ix_alerts_unresolved", table_name="alerts")
    op.drop_index("ix_alerts_unacknowledged", table_name="alerts")
    op.drop_index("ix_alerts_patient_severity", table_name="alerts")
    op.drop_index(
        "ix_sensor_readings_risk_level_timestamp", table_name="sensor_readings"
    )
    op.drop_index("ix_sensor_readings_device_timestamp", table_name="sensor_readings")
    op.drop_index("ix_sensor_readings_patient_timestamp", table_name="sensor_readings")
    op.drop_index("ix_audit_logs_correlation_id", table_name="audit_logs")

    op.drop_constraint(
        "fk_knowledge_update_logs_performed_by",
        "knowledge_update_logs",
        type_="foreignkey",
    )
    op.alter_column("knowledge_update_logs", "knowledge_id", nullable=True)
    op.drop_column("knowledge_update_logs", "performed_by")
    op.add_column(
        "knowledge_update_logs",
        sa.Column("performed_by", sa.String(length=255), nullable=True),
    )
    op.drop_column("knowledge_update_logs", "changes")
    op.rename_table("knowledge_update_logs", "knowledge_update_log")

    op.drop_constraint(
        "fk_knowledge_base_updated_by_id", "knowledge_base", type_="foreignkey"
    )
    op.drop_constraint(
        "fk_knowledge_base_created_by_id", "knowledge_base", type_="foreignkey"
    )
    op.drop_constraint(
        "fk_knowledge_base_deleted_by_id", "knowledge_base", type_="foreignkey"
    )
    op.drop_column("knowledge_base", "fhir_id")
    op.drop_column("knowledge_base", "fhir_resource_type")
    op.drop_column("knowledge_base", "updated_by_id")
    op.drop_column("knowledge_base", "created_by_id")
    op.drop_column("knowledge_base", "version")
    op.drop_column("knowledge_base", "deleted_by_id")
    op.drop_column("knowledge_base", "deleted_at")
    op.drop_column("knowledge_base", "is_deleted")
    op.alter_column("knowledge_base", "is_published", new_column_name="is_active")

    op.drop_constraint("fk_ai_reports_updated_by_id", "ai_reports", type_="foreignkey")
    op.drop_constraint("fk_ai_reports_created_by_id", "ai_reports", type_="foreignkey")
    op.drop_constraint("fk_ai_reports_deleted_by_id", "ai_reports", type_="foreignkey")
    op.drop_constraint("fk_ai_reports_reviewed_by", "ai_reports", type_="foreignkey")
    op.drop_column("ai_reports", "loinc_code")
    op.drop_column("ai_reports", "snomed_ct_code")
    op.drop_column("ai_reports", "icd10_code")
    op.drop_column("ai_reports", "fhir_id")
    op.drop_column("ai_reports", "fhir_resource_type")
    op.drop_column("ai_reports", "updated_by_id")
    op.drop_column("ai_reports", "created_by_id")
    op.drop_column("ai_reports", "version")
    op.drop_column("ai_reports", "deleted_by_id")
    op.drop_column("ai_reports", "deleted_at")
    op.drop_column("ai_reports", "is_deleted")
    op.drop_column("ai_reports", "is_reviewed")
    op.drop_column("ai_reports", "reviewed_at")
    op.drop_column("ai_reports", "reviewed_by")
    op.drop_column("ai_reports", "raw_output")
    op.drop_column("ai_reports", "input_data")
    op.drop_column("ai_reports", "features")
    op.drop_column("ai_reports", "herniation_risk")
    op.drop_column("ai_reports", "icp_risk")
    op.drop_column("ai_reports", "bleeding_type")

    op.drop_constraint("fk_alerts_deleted_by_id", "alerts", type_="foreignkey")
    op.drop_constraint("fk_alerts_resolved_by", "alerts", type_="foreignkey")
    op.drop_column("alerts", "loinc_code")
    op.drop_column("alerts", "snomed_ct_code")
    op.drop_column("alerts", "icd10_code")
    op.drop_column("alerts", "fhir_id")
    op.drop_column("alerts", "fhir_resource_type")
    op.drop_column("alerts", "version")
    op.drop_column("alerts", "deleted_by_id")
    op.drop_column("alerts", "deleted_at")
    op.drop_column("alerts", "is_deleted")
    op.drop_column("alerts", "extra_data")
    op.drop_column("alerts", "resolution_notes")
    op.drop_column("alerts", "resolved_at")
    op.drop_column("alerts", "resolved_by")
    op.drop_column("alerts", "is_resolved")
    op.alter_column("alerts", "is_acknowledged", new_column_name="acknowledged")

    op.drop_column("sensor_readings", "loinc_code")
    op.drop_column("sensor_readings", "snomed_ct_code")
    op.drop_column("sensor_readings", "icd10_code")
    op.drop_column("sensor_readings", "fhir_id")
    op.drop_column("sensor_readings", "fhir_resource_type")

    op.drop_constraint("fk_devices_updated_by_id", "devices", type_="foreignkey")
    op.drop_constraint("fk_devices_created_by_id", "devices", type_="foreignkey")
    op.drop_constraint("fk_devices_deleted_by_id", "devices", type_="foreignkey")
    op.drop_constraint("fk_devices_hospital_id", "devices", type_="foreignkey")
    op.drop_constraint("uq_devices_mac_address", "devices", type_="unique")
    op.drop_column("devices", "fhir_id")
    op.drop_column("devices", "fhir_resource_type")
    op.drop_column("devices", "updated_by_id")
    op.drop_column("devices", "created_by_id")
    op.drop_column("devices", "version")
    op.drop_column("devices", "deleted_by_id")
    op.drop_column("devices", "deleted_at")
    op.drop_column("devices", "is_deleted")
    op.drop_column("devices", "hospital_id")
    op.drop_column("devices", "mac_address")
    op.drop_column("devices", "device_name")

    op.drop_constraint("fk_patients_updated_by_id", "patients", type_="foreignkey")
    op.drop_constraint("fk_patients_created_by_id", "patients", type_="foreignkey")
    op.drop_constraint("fk_patients_deleted_by_id", "patients", type_="foreignkey")
    op.drop_constraint("fk_patients_department_id", "patients", type_="foreignkey")
    op.drop_index("ix_patients_mrn", table_name="patients")
    op.drop_column("patients", "loinc_code")
    op.drop_column("patients", "snomed_ct_code")
    op.drop_column("patients", "icd10_code")
    op.drop_column("patients", "fhir_id")
    op.drop_column("patients", "fhir_resource_type")
    op.drop_column("patients", "updated_by_id")
    op.drop_column("patients", "created_by_id")
    op.drop_column("patients", "version")
    op.drop_column("patients", "deleted_by_id")
    op.drop_column("patients", "deleted_at")
    op.drop_column("patients", "is_deleted")
    op.drop_column("patients", "department_id")
    op.drop_column("patients", "discharge_date")
    op.drop_column("patients", "weight_kg")
    op.drop_column("patients", "height_cm")
    op.drop_column("patients", "emergency_contact_relation")
    op.drop_column("patients", "email")
    op.drop_column("patients", "mrn")

    op.drop_constraint("fk_users_deleted_by_id", "users", type_="foreignkey")
    op.drop_column("users", "version")
    op.drop_column("users", "deleted_by_id")
    op.drop_column("users", "deleted_at")
    op.drop_column("users", "is_deleted")
    op.drop_column("users", "locked_until")
    op.drop_column("users", "login_attempts")
    op.drop_column("users", "password_history")
    op.drop_column("users", "last_password_change")
    op.drop_column("users", "mfa_secret")
    op.drop_column("users", "is_mfa_enabled")

    op.drop_constraint("fk_hospitals_updated_by_id", "hospitals", type_="foreignkey")
    op.drop_constraint("fk_hospitals_created_by_id", "hospitals", type_="foreignkey")
    op.drop_constraint("fk_hospitals_deleted_by_id", "hospitals", type_="foreignkey")
    op.alter_column("hospitals", "phone", nullable=False)
    op.alter_column("hospitals", "address", nullable=False)
    op.drop_index("ix_hospitals_license_number", table_name="hospitals")
    op.drop_index("ix_hospitals_email", table_name="hospitals")
    op.create_unique_constraint(
        "uq_hospitals_license_number", "hospitals", ["license_number"]
    )
    op.create_unique_constraint("uq_hospitals_email", "hospitals", ["email"])
    op.drop_column("hospitals", "fhir_id")
    op.drop_column("hospitals", "fhir_resource_type")
    op.drop_column("hospitals", "updated_by_id")
    op.drop_column("hospitals", "created_by_id")
    op.drop_column("hospitals", "version")
    op.drop_column("hospitals", "deleted_by_id")
    op.drop_column("hospitals", "deleted_at")
    op.drop_column("hospitals", "is_deleted")
    op.drop_column("hospitals", "hospital_type")

    op.drop_table("organizations")
    op.drop_index("ix_departments_hospital_id", table_name="departments")
    op.drop_table("departments")
    op.drop_index("ix_refresh_tokens_token_hash", table_name="refresh_tokens")
    op.drop_index("ix_refresh_tokens_user_id", table_name="refresh_tokens")
    op.drop_table("refresh_tokens")
    op.drop_index("ix_sessions_token_hash", table_name="sessions")
    op.drop_index("ix_sessions_user_id", table_name="sessions")
    op.drop_table("sessions")
    op.drop_table("user_roles")
    op.drop_table("role_permissions")
    op.drop_index("ix_permissions_codename", table_name="permissions")
    op.drop_table("permissions")
    op.drop_index("ix_roles_name", table_name="roles")
    op.drop_table("roles")

    _drop_enums()
