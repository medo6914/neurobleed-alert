# Query Optimization

## Use `selectinload` for Relationships

Avoid N+1 queries by eagerly loading relationships:

```python
# Bad: N+1 queries
stmt = select(Hospital)
hospitals = await db.execute(stmt)
for h in hospitals.scalars():
    _ = h.users  # Triggers a query per hospital

# Good: Eager load with selectinload
from sqlalchemy.orm import selectinload
stmt = (
    select(Hospital)
    .options(selectinload(Hospital.users))
)
hospitals = await db.execute(stmt)
```

### When to Use Each Loading Strategy

| Strategy | Use Case | Behavior |
|----------|----------|----------|
| `selectinload` | To-many relationships | Emits separate SELECT with IN clause |
| `joinedload` | To-one relationships | LEFT JOIN (can cause cartesian products) |
| `contains_eager` | Custom joins | Apply when you manually join |
| `lazy=False` | Always-needed relationships | Set on relationship definition |

## Avoid N+1 Queries

### Detect N+1 with SQLAlchemy Logging

```python
import logging
logging.getLogger("sqlalchemy.engine").setLevel(logging.INFO)
```

### Use `subqueryload` for Deep Hierarchies

```python
stmt = (
    select(Hospital)
    .options(
        selectinload(Hospital.users),
        selectinload(Hospital.departments),
    )
)
```

### Batch Load with `limit` and `offset`

```python
# Efficient chunked loading
for i in range(0, total, 1000):
    chunk = await repo.get_multi(skip=i, limit=1000)
    process(chunk)
```

## Use Specific Column Selection

### Avoid `SELECT *`

```python
# Bad: selects all columns
stmt = select(User)

# Good: selects only needed columns
stmt = select(User.id, User.email, User.full_name)
```

### For Read-Only Queries

```python
from sqlalchemy.orm import load_only
stmt = (
    select(User)
    .options(load_only(User.id, User.email, User.full_name))
)
```

## Batch Operations

### Bulk Insert

```python
# Bad: individual inserts in a loop
for item in items:
    await repo.create(item)

# Good: bulk insert
db.add_all([User(**item) for item in items])
await db.commit()
```

### Bulk Update

```python
await db.execute(
    update(User).where(User.is_active == False).values(locked_until=datetime.utcnow())
)
await db.commit()
```

## Use Proper Pagination

### Offset Pagination (UI Grids)

```python
page = await repo.paginate(page=3, per_page=50)
```

Works well for small datasets (<10K rows) with user-controlled page numbers.

### Cursor Pagination (Time-Series)

```python
cursor_page = await repo.cursor_paginate(cursor=next_cursor, limit=50)
```

Preferred for:
- Real-time sensor readings
- Alert feeds
- Audit logs
- Infinite scroll

Cursor pagination is O(1) on the last row rather than O(N) for offset, and is stable under writes.

## Index Usage Guidelines

### Composite Indexes for Common Queries

```sql
CREATE INDEX ix_sensor_readings_patient_timestamp
ON sensor_readings (patient_id, timestamp DESC);

CREATE INDEX ix_alerts_patient_severity
ON alerts (patient_id, severity, created_at DESC);
```

### Covering Indexes

```sql
CREATE INDEX ix_users_email_active
ON users (email) INCLUDE (full_name, role);
```

### Partial Indexes for Common Filters

```sql
CREATE INDEX ix_alerts_unacknowledged
ON alerts (created_at DESC)
WHERE is_acknowledged = false;

CREATE INDEX ix_knowledge_base_published
ON knowledge_base (category)
WHERE is_published = true;
```

### Index Maintenance

```sql
-- Monitor index usage
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes
WHERE idx_scan = 0;  -- Unused indexes

-- Rebuild fragmented indexes
REINDEX INDEX ix_sensor_readings_patient_timestamp;
```

## EXPLAIN ANALYZE Workflow

### Step 1: Capture the Query

```python
stmt = select(Hospital).where(Hospital.name.ilike("%general%"))
print(stmt.compile(compile_kwargs={"literal_binds": True}))
```

### Step 2: Run EXPLAIN ANALYZE

```sql
EXPLAIN ANALYZE
SELECT * FROM hospitals
WHERE name ILIKE '%general%';
```

### Step 3: Interpret the Output

```
Seq Scan on hospitals  (cost=0.00..12.10 rows=1 width=100) (actual time=0.020..0.030 rows=1 loops=1)
  Filter: (name ~~* '%general%'::text)
  Rows Removed by Filter: 300
Planning Time: 0.100 ms
Execution Time: 0.050 ms
```

### Step 4: Identify Issues

| Red Flag | What It Means | Fix |
|----------|---------------|-----|
| `Seq Scan` on large table | Full table scan | Add index |
| `Rows Removed by Filter` >> returned rows | Poor selectivity | Composite index on filter columns |
| `Sort` without index | Sorting overhead | Index on sort column |
| `Nested Loop` with high rows | Cartesian product from joinedload | Use selectinload instead |
| `Bitmap Heap Scan` high `loops` | Repeated scans | Batch queries |

### Step 5: Apply Fix and Re-analyze

```sql
CREATE INDEX ix_hospitals_name_trgm ON hospitals USING gin (name gin_trgm_ops);
EXPLAIN ANALYZE SELECT * FROM hospitals WHERE name ILIKE '%general%';
```

Look for `Bitmap Index Scan` or `Index Scan` instead of `Seq Scan`.
