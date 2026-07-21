"""seed_data

Revision ID: 3eef07e84235
Revises: 2eef07e84234
Create Date: 2026-07-14 17:00:01.000000

"""
import uuid
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.sql import text


revision: str = '3eef07e84235'
down_revision: Union[str, None] = '2eef07e84234'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


ROLES = [
    {"id": "a1b2c3d4-0001-4000-8000-000000000001", "name": "admin", "description": "System administrator with full access", "is_system": True},
    {"id": "a1b2c3d4-0001-4000-8000-000000000002", "name": "doctor", "description": "Medical doctor", "is_system": True},
    {"id": "a1b2c3d4-0001-4000-8000-000000000003", "name": "nurse", "description": "Nursing staff", "is_system": True},
    {"id": "a1b2c3d4-0001-4000-8000-000000000004", "name": "technician", "description": "Device technician", "is_system": True},
    {"id": "a1b2c3d4-0001-4000-8000-000000000005", "name": "patient", "description": "Patient account", "is_system": True},
    {"id": "a1b2c3d4-0001-4000-8000-000000000006", "name": "emergency", "description": "Emergency responder", "is_system": True},
]

PERMISSIONS = [
    {"id": "b1c2d3e4-0001-4000-8000-000000000001", "codename": "patient:list", "name": "List Patients", "resource": "patient"},
    {"id": "b1c2d3e4-0001-4000-8000-000000000002", "codename": "patient:view", "name": "View Patient", "resource": "patient"},
    {"id": "b1c2d3e4-0001-4000-8000-000000000003", "codename": "patient:create", "name": "Create Patient", "resource": "patient"},
    {"id": "b1c2d3e4-0001-4000-8000-000000000004", "codename": "patient:update", "name": "Update Patient", "resource": "patient"},
    {"id": "b1c2d3e4-0001-4000-8000-000000000005", "codename": "patient:delete", "name": "Delete Patient", "resource": "patient"},
    {"id": "b1c2d3e4-0001-4000-8000-000000000006", "codename": "device:list", "name": "List Devices", "resource": "device"},
    {"id": "b1c2d3e4-0001-4000-8000-000000000007", "codename": "device:view", "name": "View Device", "resource": "device"},
    {"id": "b1c2d3e4-0001-4000-8000-000000000008", "codename": "device:create", "name": "Create Device", "resource": "device"},
    {"id": "b1c2d3e4-0001-4000-8000-000000000009", "codename": "device:update", "name": "Update Device", "resource": "device"},
    {"id": "b1c2d3e4-0001-4000-8000-000000000010", "codename": "device:delete", "name": "Delete Device", "resource": "device"},
    {"id": "b1c2d3e4-0001-4000-8000-000000000011", "codename": "monitoring:view", "name": "View Monitoring", "resource": "monitoring"},
    {"id": "b1c2d3e4-0001-4000-8000-000000000012", "codename": "alert:list", "name": "List Alerts", "resource": "alert"},
    {"id": "b1c2d3e4-0001-4000-8000-000000000013", "codename": "alert:acknowledge", "name": "Acknowledge Alert", "resource": "alert"},
    {"id": "b1c2d3e4-0001-4000-8000-000000000014", "codename": "report:view", "name": "View Report", "resource": "report"},
    {"id": "b1c2d3e4-0001-4000-8000-000000000015", "codename": "report:create", "name": "Create Report", "resource": "report"},
    {"id": "b1c2d3e4-0001-4000-8000-000000000016", "codename": "user:list", "name": "List Users", "resource": "user"},
    {"id": "b1c2d3e4-0001-4000-8000-000000000017", "codename": "user:create", "name": "Create User", "resource": "user"},
    {"id": "b1c2d3e4-0001-4000-8000-000000000018", "codename": "user:manage", "name": "Manage Users", "resource": "user"},
    {"id": "b1c2d3e4-0001-4000-8000-000000000019", "codename": "admin:access", "name": "Admin Access", "resource": "admin"},
    {"id": "b1c2d3e4-0001-4000-8000-000000000020", "codename": "settings:view", "name": "View Settings", "resource": "settings"},
    {"id": "b1c2d3e4-0001-4000-8000-000000000021", "codename": "settings:update", "name": "Update Settings", "resource": "settings"},
]

ROLE_PERMISSION_MAP = {
    "admin": [p["codename"] for p in PERMISSIONS],
    "doctor": [
        "patient:list", "patient:view", "patient:create", "patient:update",
        "device:list", "device:view",
        "monitoring:view",
        "alert:list", "alert:acknowledge",
        "report:view", "report:create",
        "user:list",
    ],
    "nurse": [
        "patient:list", "patient:view",
        "monitoring:view",
        "alert:list", "alert:acknowledge",
    ],
    "technician": [
        "device:list", "device:view", "device:create", "device:update",
        "monitoring:view",
    ],
    "patient": [],
    "emergency": [
        "patient:view",
        "monitoring:view",
        "alert:list",
    ],
}


def upgrade() -> None:
    conn = op.get_bind()

    for role in ROLES:
        conn.execute(
            text(
                """INSERT INTO roles (id, name, description, is_system, created_at, updated_at)
                   VALUES (:id, :name, :description, :is_system, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                   ON CONFLICT (name) DO NOTHING"""
            ),
            role,
        )

    for perm in PERMISSIONS:
        conn.execute(
            text(
                """INSERT INTO permissions (id, codename, name, description, resource, created_at)
                   VALUES (:id, :codename, :name, :description, :resource, CURRENT_TIMESTAMP)
                   ON CONFLICT (codename) DO NOTHING"""
            ),
            {**perm, "description": None},
        )

    role_rows = conn.execute(text("SELECT id, name FROM roles")).fetchall()
    role_ids = {row.name: row.id for row in role_rows}

    perm_rows = conn.execute(text("SELECT id, codename FROM permissions")).fetchall()
    perm_ids = {row.codename: row.id for row in perm_rows}

    for role_name, perm_codenames in ROLE_PERMISSION_MAP.items():
        role_id = role_ids.get(role_name)
        if not role_id:
            continue
        for codename in perm_codenames:
            perm_id = perm_ids.get(codename)
            if not perm_id:
                continue
            conn.execute(
                text(
                    """INSERT INTO role_permissions (role_id, permission_id, created_at)
                       VALUES (:role_id, :permission_id, CURRENT_TIMESTAMP)
                       ON CONFLICT DO NOTHING"""
                ),
                {"role_id": role_id, "permission_id": perm_id},
            )

    admin_role_id = role_ids.get("admin")
    if admin_role_id:
        conn.execute(
            text(
                """INSERT INTO user_roles (user_id, role_id, created_at)
                   SELECT u.id, :role_id, CURRENT_TIMESTAMP
                   FROM users u
                   WHERE u.role = 'admin'
                   ON CONFLICT DO NOTHING"""
            ),
            {"role_id": admin_role_id},
        )


def downgrade() -> None:
    conn = op.get_bind()
    conn.execute(text("DELETE FROM role_permissions"))
    conn.execute(text("DELETE FROM permissions"))
    conn.execute(text("DELETE FROM user_roles"))
    conn.execute(text("DELETE FROM roles"))
