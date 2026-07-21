# Connection Pooling

## PgBouncer Configuration

PgBouncer sits between the application and PostgreSQL to manage connection pooling efficiently.

### Recommended `pgbouncer.ini`

```ini
[databases]
neurobleed = host=localhost port=5432 dbname=neurobleed

[pgbouncer]
listen_addr = 127.0.0.1
listen_port = 6432
auth_type = scram-sha-256
auth_file = /etc/pgbouncer/userlist.txt

pool_mode = transaction
max_client_conn = 200
default_pool_size = 25
min_pool_size = 5
reserve_pool_size = 10
reserve_pool_timeout = 5.0

max_db_connections = 50
max_user_connections = 50

server_idle_timeout = 600
client_idle_timeout = 0
query_timeout = 30
```

### Pool Mode: `transaction`

Each transaction acquires a connection from the pool and returns it on commit/rollback. This balances throughput with resource usage.

## Connection Pool Sizing Formula

```
pool_size = (core_count * 2) + effective_spindle_count
```

Where `effective_spindle_count` = number of physical disks (or 1 for SSDs).

### Environment-Specific Sizing

| Environment | Cores | Spindles | Formula | Pool Size | Max Overflow |
|-------------|-------|----------|---------|-----------|--------------|
| Development | 4     | 1 (SSD)  | (4*2)+1 | 9         | 5            |
| Staging     | 8     | 2 (SSD)  | (8*2)+2 | 18        | 10           |
| Production  | 16    | 4 (SSD)  | (16*2)+4| 36        | 20           |
| High-Traffic| 32    | 8 (NVMe) | (32*2)+8| 72        | 30           |

### SQLAlchemy Configuration

In `app/database.py`:

```python
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=False,
    pool_size=36,
    max_overflow=20,
    pool_pre_ping=True,
    pool_recycle=3600,
)
```

### Key Parameters

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| `pool_size` | 36 | Base pool for production (16 cores). |
| `max_overflow` | 20 | Burst capacity (up to 56 total). |
| `pool_pre_ping` | True | Verify connection before use. |
| `pool_recycle` | 3600s | Prevent connection staleness. |

## Pool Tuning Per Environment

### Development

```python
engine = create_async_engine(
    settings.DATABASE_URL,
    pool_size=5,
    max_overflow=3,
    pool_pre_ping=True,
)
```

### Staging

```python
engine = create_async_engine(
    settings.DATABASE_URL,
    pool_size=18,
    max_overflow=10,
    pool_pre_ping=True,
    pool_recycle=3600,
)
```

### Production

```python
engine = create_async_engine(
    settings.DATABASE_URL,
    pool_size=36,
    max_overflow=20,
    pool_pre_ping=True,
    pool_recycle=1800,
    pool_use_lifo=True,  # LIFO for better connection reuse
)
```

## Monitoring Pool Metrics

### SQLAlchemy Event Handlers

```python
from sqlalchemy import event

@event.listens_for(engine, "checkout")
def receive_checkout(dbapi_connection, connection_record, connection_proxy):
    print(f"Connection checkout. Pool size: {engine.pool.size()}")

@event.listens_for(engine, "checkin")
def receive_checkin(dbapi_connection, connection_record):
    print(f"Connection checkin. Available: {engine.pool.checkedin()}")
```

### PostgreSQL Monitoring Queries

```sql
-- Current connections by state
SELECT state, count(*) FROM pg_stat_activity
WHERE datname = 'neurobleed' GROUP BY state;

-- Connection count by application
SELECT application_name, count(*) FROM pg_stat_activity
WHERE datname = 'neurobleed' GROUP BY application_name;

-- Idle in transaction (blocking)
SELECT pid, state, query_start, wait_event, query
FROM pg_stat_activity
WHERE state = 'idle in transaction' AND datname = 'neurobleed';
```

### Prometheus Metrics

Expose pool metrics via `prometheus_client`:

```python
from prometheus_client import Gauge

pool_size_gauge = Gauge("db_pool_size", "Current DB pool size")
pool_overflow_gauge = Gauge("db_pool_overflow", "Current overflow connections")
pool_checkedout = Gauge("db_pool_checkedout", "Currently checked-out connections")
```

## Troubleshooting Pool Exhaustion

### Symptoms

- `TimeoutError: QueuePool limit of size X overflow Y reached`
- Increased API latency
- `OperationalError: server closed the connection unexpectedly`

### Immediate Actions

1. **Check active connections**:
   ```sql
   SELECT count(*) FROM pg_stat_activity WHERE state = 'active';
   ```

2. **Kill idle transactions**:
   ```sql
   SELECT pg_terminate_backend(pid) FROM pg_stat_activity
   WHERE state = 'idle in transaction'
   AND age(now(), query_start) > interval '5 minutes';
   ```

3. **Temporarily increase `max_overflow`** if traffic spike is expected.

### Root Cause Investigation

- Look for unclosed sessions (missing `await session.close()`).
- Check for long-running queries (`pg_stat_activity.query`).
- Verify PgBouncer `pool_mode` is `transaction` (not `session`).
- Ensure `expire_on_commit=False` is set to avoid implicit refreshes.

### Prevention

- Always use `async with async_session() as session:` pattern.
- Set `pool_recycle` to avoid stale connections.
- Use PgBouncer in `transaction` mode for web workloads.
- Alert on `pool.checkedin() < pool_size * 0.2` (pool nearly exhausted).
