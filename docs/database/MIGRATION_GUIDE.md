# Migration Guide

## Workflow Overview

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│  Modify  │   │ Generate │   │  Review  │   │  Apply   │
│  Models  │──▶│ Migration│──▶│ & Verify │──▶│ to DB    │
└──────────┘   └──────────┘   └──────────┘   └──────────┘
```

## Creating New Migrations

### Auto-Generate

```bash
cd backend/fastapi
alembic revision --autogenerate -m "add_patient_room_number"
```

This compares the current SQLAlchemy model metadata against the database schema and generates a migration script.

### Manual Revision

```bash
alembic revision -m "custom_data_migration"
```

Use for data migrations, backfills, or complex schema changes that autogenerate cannot handle.

### Migration Script Template

```python
"""add patient room number

Revision ID: a1b2c3d4e5f6
Revises: 9z8y7x6w5v4u
Create Date: 2024-07-16 10:30:00.000000
"""
from alembic import op
import sqlalchemy as sa

revision = "a1b2c3d4e5f6"
down_revision = "9z8y7x6w5v4u"

def upgrade():
    op.add_column("patients", sa.Column("room_number", sa.String(20), nullable=True))
    op.create_index("ix_patients_room", "patients", ["room_number"])

def downgrade():
    op.drop_index("ix_patients_room")
    op.drop_column("patients", "room_number")
```

## Running Migrations

### Apply All Pending

```bash
alembic upgrade head
```

### Apply +N Steps

```bash
alembic upgrade +2
```

### Apply to Specific Revision

```bash
alembic upgrade a1b2c3d4e5f6
```

### Check Current State

```bash
alembic current
alembic history
```

## Rolling Back Migrations

### Rollback One Step

```bash
alembic downgrade -1
```

### Rollback to Specific Revision

```bash
alembic downgrade 9z8y7x6w5v4u
```

### Rollback All

```bash
alembic downgrade base
```

## Merge Conflict Resolution

### Detecting Conflicts

When two developers create branches with overlapping migrations:

```bash
alembic check
```

### Resolving with Merge Point

```bash
alembic merge -m "merge_heads" head1 head2
```

This creates a merge migration that depends on both head revisions.

### Best Practices

- Pull latest `main` and run `alembic upgrade head` before creating migrations.
- Each migration should be small and focused (single concern).
- Avoid editing published migrations that have been deployed.
- Use merge migrations instead of rebasing shared migration branches.

## Production Deployment Checklist

### Pre-Deployment

- [ ] Run `alembic check` to verify no conflicts.
- [ ] Backup the database:
  ```bash
  pg_dump -h localhost -U neurobleed neurobleed > pre_migration_backup.sql
  ```
- [ ] Test migration against staging with production-like data volume.
- [ ] Review migration SQL with `alembic upgrade head --sql` for dry-run.
- [ ] Validate no long-running locks will be acquired.
- [ ] Schedule during maintenance window (low traffic period).

### Deployment

```bash
# 1. Set maintenance mode (if applicable)
# 2. Run migration
alembic upgrade head
# 3. Verify schema
alembic current
# 4. Run smoke tests
# 5. Disable maintenance mode
```

### Post-Deployment

- [ ] Monitor error rates and query latency.
- [ ] Verify application health endpoints.
- [ ] Check for orphaned connections.
- [ ] Run `ANALYZE` to update query planner statistics.
- [ ] Document any manual data fixes applied.

## Zero-Downtime Migration Patterns

### 1. Expand-Contract (Add + Remove)

```python
# Phase 1: Add new column (non-nullable with default)
def upgrade():
    op.add_column("patients", sa.Column("new_status", sa.String(20), server_default="active"))

def upgrade():
    # Phase 2 (separate deployment): Backfill data
    op.execute("UPDATE patients SET new_status = status WHERE new_status IS NULL")

def upgrade():
    # Phase 3 (separate deployment): Drop old column
    op.drop_column("patients", "status")
```

### 2. Concurrent Index Creation

```python
def upgrade():
    op.create_index("ix_patients_new_lookup", "patients", ["hospital_id", "status"],
                    postgresql_concurrently=True)
    # Requires: SET session_replication_role = 'replica'; (outside transaction)
```

### 3. Large Table Migration (Batch)

```python
def upgrade():
    batch_size = 10000
    connection = op.get_bind()
    while True:
        result = connection.execute(
            sa.text("UPDATE patients SET new_col = ... WHERE id IN "
                    "(SELECT id FROM patients WHERE new_col IS NULL LIMIT :batch)"),
            {"batch": batch_size}
        )
        if result.rowcount == 0:
            break
```

### 4. Application-Level Compatibility

- New code must handle both old and new schema during rollout.
- Use feature flags to gate new column usage.
- Ensure rollback plan is validated before deployment.
