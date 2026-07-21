# Database Performance Targets

## 1. Performance Budget

### 1.1 Query Time Targets

| Operation | Target (P50) | Target (P99) | SLA |
|-----------|-------------|-------------|-----|
| Simple SELECT by PK | < 5ms | < 20ms | 99.9% |
| SELECT by indexed column | < 10ms | < 50ms | 99.9% |
| SELECT with JOIN (2-3 tables) | < 30ms | < 100ms | 99.5% |
| INSERT single row | < 10ms | < 30ms | 99.9% |
| INSERT batch (100-1000 rows) | < 100ms | < 500ms | 99.5% |
| UPDATE by PK | < 10ms | < 30ms | 99.9% |
| Soft DELETE by PK | < 10ms | < 30ms | 99.9% |
| Paginated list (page size=50) | < 50ms | < 200ms | 99.5% |
| Time series range query (1h) | < 100ms | < 500ms | 99.5% |
| Time series range query (24h) | < 500ms | < 2s | 99.0% |
| Full-text search (knowledge_base) | < 200ms | < 1s | 99.0% |
| Aggregation query (COUNT, AVG) | < 100ms | < 500ms | 99.5% |
| Cursor pagination | < 20ms | < 80ms | 99.5% |

### 1.2 Throughput Targets

| Metric | Target | Peak |
|--------|--------|------|
| Reads per second (TPS read) | 5,000 | 20,000 |
| Writes per second (TPS write) | 1,000 | 5,000 |
| Sensor readings insert rate | 500/sec | 2,000/sec |
| Concurrent connections | 200 | 500 |
| Connection pool utilization | < 70% | < 85% |

### 1.3 Resource Budget

| Resource | Per-query budget | Notes |
|----------|-----------------|-------|
| CPU | < 5ms/query | Index scans preferred over seq scans |
| Memory | < 100MB/query | Work_mem = 64MB per operation |
| IOPS | < 100/query | Minimize random page reads |
| Network | < 10KB/response | Project only needed columns |

---

## 2. Index Strategy Impact

| Table | Key Index | Expected Improvement |
|-------|-----------|---------------------|
| `sensor_readings` | (patient_id, timestamp DESC) | 95% reduction in time-series queries |
| `sensor_readings` | (risk_level, timestamp DESC) | 90% reduction for triage queries |
| `alerts` | (patient_id, severity, created_at DESC) | 90% reduction for alert list queries |
| `alerts` | (is_acknowledged, created_at DESC) | 85% reduction for unacknowledged alert queries |
| `alerts` | (is_resolved, created_at DESC) | 85% reduction for unresolved alert queries |
| `ai_reports` | (patient_id, report_type, created_at DESC) | 90% reduction for report history queries |
| `audit_logs` | (user_id, action, created_at DESC) | 95% reduction for user audit trail queries |

---

## 3. Query Optimization Rules

### 3.1 Always Use
- Cursor-based pagination for lists > 100 results
- `selectinload` for M2M relationships
- `lazy='selectin'` for role/permission loading
- Prepared statements for repeated queries

### 3.2 Never Use
- `SELECT *` in production code
- N+1 queries (detect via SQLAlchemy echo)
- Sequential scans on tables > 10,000 rows
- `OFFSET` pagination on large tables

### 3.3 Connection Pool Configuration

```python
engine = create_async_engine(
    DATABASE_URL,
    pool_size=50,           # Prod: 50 connections
    max_overflow=100,        # Prod: burst up to 100
    pool_pre_ping=True,      # Validate connections before use
    pool_recycle=3600,       # Recycle every hour
    pool_timeout=30,         # Wait 30s before timeout
    echo=False,
)
```

---

## 4. Monitoring

### 4.1 Key Metrics to Track
- `pg_stat_activity` — active queries, wait events
- `pg_stat_user_tables` — seq scans, index scans, dead tuples
- `pg_stat_user_indexes` — index usage frequency
- `pg_stat_statements` — slow queries, top IO consumers
- Connection pool utilization
- Replication lag (if read replicas)

### 4.2 Alert Thresholds
- Query time > 1s (P99): Alert + auto-explain analyze
- Connection pool exhausted: Critical alert
- Replication lag > 10s: Warning
- Dead tuples > 20%: Vacuum trigger
- Disk usage > 80%: Warning, > 90%: Critical
