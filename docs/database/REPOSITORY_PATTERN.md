# Repository Pattern

## Architecture Overview

The repository layer abstracts database access behind a clean interface, enabling testability, consistency, and separation of concerns.

```
┌──────────────┐     ┌───────────────────┐     ┌──────────────┐
│   Routers    │ ──▶ │   Repositories    │ ──▶ │   Database   │
│   (FastAPI)  │     │  (Data Access)    │     │  (PostgreSQL)│
└──────────────┘     └───────────────────┘     └──────────────┘
                          │
                    ┌─────┴──────┐
                    │   Models   │
                    │ (SQLAlchemy)│
                    └────────────┘
```

All repositories inherit from `BaseRepository[ModelType]` in `app/repositories/base.py`.

## BaseRepository API Reference

### CRUD Operations

| Method | Signature | Description |
|--------|-----------|-------------|
| `get` | `(id: UUID) -> ModelType \| None` | Fetch by primary key. Applies soft-delete filter. |
| `get_multi` | `(skip: int = 0, limit: int = 100) -> list[ModelType]` | Fetch with offset/limit pagination. |
| `create` | `(obj_in: dict \| BaseModel) -> ModelType` | Insert and refresh. |
| `update` | `(id: UUID, obj_in: dict \| BaseModel) -> ModelType \| None` | Partial update by PK. |
| `delete` | `(id: UUID, soft: bool = True, deleted_by: UUID = None) -> bool` | Soft or hard delete. |

### Query Operations

| Method | Signature | Description |
|--------|-----------|-------------|
| `count` | `(filters: list = None) -> int` | Count filtered rows (excludes soft-deleted). |
| `exists` | `(id: UUID) -> bool` | Check if a row exists by PK. |

### Pagination

| Method | Signature | Description |
|--------|-----------|-------------|
| `paginate` | `(page, per_page, filters, sorts) -> Page` | Offset-based pagination. |
| `cursor_paginate` | `(cursor, limit, **filters) -> CursorPage` | Keyset-based pagination. |

## Custom Repository Methods

Each repository in `app/repositories/repositories.py` extends `BaseRepository` with domain-specific queries:

- **HospitalRepository**: `get_with_relations(id)` — eager-loads users and departments.
- **UserRepository**: `get_by_email`, `get_by_firebase_uid`, `get_user_with_roles`.
- **PatientRepository**: `get_by_mrn`, `search_by_name`, `get_patients_by_hospital`.
- **DeviceRepository**: `get_by_serial`, `get_devices_by_hospital`.
- **SensorReadingRepository**: `get_readings_by_patient_range` — time-range filtered.
- **AlertRepository**: `get_unacknowledged`, `get_unresolved`.
- **AIReportRepository**: `get_reports_by_patient`.
- **KnowledgeBaseRepository**: `search`, `get_by_category`.
- **AuditLogRepository**: `get_by_user`, `get_by_resource`.
- **RoleRepository**: `get_by_name`, `get_with_permissions`.
- **PermissionRepository**: `get_by_codename`.
- **SessionRepository**: `get_active_user_sessions`, `invalidate_session`.
- **RefreshTokenRepository**: `get_by_token_hash`, `revoke_token`.

## Pagination Patterns

### Offset Pagination

Use for UI grids with page selectors:

```python
page = await repo.paginate(page=2, per_page=25)
```

Returns `Page(items, total, page, per_page, total_pages, has_next, has_prev)`.

### Cursor Pagination

Use for time-series or infinite-scroll feeds:

```python
cursor_page = await repo.cursor_paginate(cursor=next_cursor, limit=50)
```

Returns `CursorPage(items, cursor, has_more, total)`. The cursor is a base64-encoded JSON blob containing the last item's PK.

## Filtering and Sorting

Pass SQLAlchemy filter expressions via the `filters` parameter:

```python
from sqlalchemy import or_
filters = [Hospital.hospital_type == "general"]
page = await hospital_repo.paginate(filters=filters)
```

Sort with column expressions:

```python
from sqlalchemy import desc
sorts = [desc(Hospital.created_at)]
page = await hospital_repo.paginate(sorts=sorts)
```

## Transaction Management

Each repository method handles its own commit. For multi-repository transactions, use:

```python
async with db.begin():
    user = await user_repo.create(data)
    await audit_log_repo.create({"action": "user.create", "resource": "users"})
```

## Error Handling

- **Not found**: `get` / `update` / `delete` return `None` / `False` — never raise.
- **Constraint violations**: SQLAlchemy `IntegrityError` propagates up.
- **Soft delete**: Automatically filters out `is_deleted == True` rows unless overridden.
