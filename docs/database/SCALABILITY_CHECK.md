# Scalability Check

## Current Design Scalability Limits

Tested against 5 order-of-magnitude growth tiers: **100 → 1,000 → 10,000 → 100,000 → 1,000,000 users**.

---

## 1. Table Scalability Analysis

### Lookup Tables
| Table | Est. Rows (1M users) | Growth Pattern | Scalable? |
|-------|----------------------|----------------|-----------|
| `users` | 1,000,000 | Linear with user count | Yes |
| `roles` | 6-10 | Fixed (RBAC roles) | Yes (static) |
| `permissions` | 21-50 | Fixed (permissions) | Yes (static) |
| `hospitals` | 10,000 | Sub-linear (users/hospital ~100) | Yes |
| `organizations` | 10,000 | Sub-linear | Yes |
| `departments` | 50,000 | 5 depts/hospital | Yes |
| `devices` | 1,000,000 | ~1 device/user | Yes |

### High-Volume Tables
| Table | Est. Rows (1M users, 1 year) | Growth Pattern | Scalable? |
|-------|------------------------------|----------------|-----------|
| `sensor_readings` | 1.5T rows | 50 readings/sec/device × 1M devices | **PARTITION REQUIRED** |
| `alerts` | 10M | 10 alerts/day/patient | Yes (with partitioning) |
| `ai_reports` | 1M | 1 report/10 alerts | Yes |
| `audit_logs` | 100M | 100 actions/user/day | Yes (with partitioning) |
| `sessions` | 10M active | Concurrent sessions | Yes (TTL-based clean-up) |
| `refresh_tokens` | 10M | Token rotation | Yes (TTL-based clean-up) |

---

## 2. Bottleneck: `sensor_readings` Table

At 1M users with devices, `sensor_readings` becomes massive:
- 50 readings/sec/device × 86,400 sec/day × 365 days = **1.58 billion rows/year/device**
- At 1M devices: **1.5 quadrillion rows/year** ← **NOT SCALABLE**

### Mitigation Strategy (Required at >10K users)

```sql
-- Partition by month (required at >10K users)
CREATE TABLE sensor_readings_y2026m01 PARTITION OF sensor_readings
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

-- Partition by hospital_id group (optional sharding)
-- Use CitusDB or TimescaleDB for distributed time-series
```

### TimescaleDB Recommendation (at >100K users)

```sql
-- Convert to hypertable for automatic partitioning
SELECT create_hypertable('sensor_readings', 'timestamp', 
    chunk_time_interval => INTERVAL '1 day');
```

---

## 3. Read Scalability

| Tier | Read Strategy | Expected P99 |
|------|--------------|--------------|
| 100 | Single instance | < 10ms |
| 1,000 | Single + connection pool (50) | < 20ms |
| 10,000 | Single + query optimization | < 50ms |
| 100,000 | Read replica (1-2) + connection pool (200) | < 100ms |
| 1,000,000 | Read replicas (3-5) + Redis cache + CDN | < 200ms |

### Read Replica Architecture (100K+)

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  Write   │ ──→ │  Read 1  │     │  Read 2  │
│  Master  │     │ (recent) │     │ (report) │
└──────────┘     └──────────┘     └──────────┘
     │                │                │
     ↓                ↓                ↓
  ┌───────────────────────────────────────┐
  │         PgBouncer (connection pool)   │
  └───────────────────────────────────────┘
```

---

## 4. Write Scalability

| Tier | Insert Strategy | Expected Throughput |
|------|----------------|-------------------|
| 100 | Direct inserts | 1,000/sec |
| 1,000 | Batch inserts (100/statement) | 5,000/sec |
| 10,000 | Batch inserts + connection pooling | 10,000/sec |
| 100,000 | Partitioned + batch inserts | 50,000/sec |
| 1,000,000 | Async batch + Kafka queue + TimescaleDB | 200,000/sec |

### Write Pipeline (1M tier)

```
Sensor → MQTT → Kafka → Batch consumer → TimescaleDB hypertable
                                         → Redis (hot cache)
                                         → Alert evaluator (streaming)
```

---

## 5. Storage Projection

| Tier | sensor_readings | Total DB | Archive |
|------|----------------|----------|---------|
| 100 | 1.5 GB/month | 5 GB/month | 0.5 TB/5yr |
| 1,000 | 15 GB/month | 50 GB/month | 5 TB/5yr |
| 10,000 | 150 GB/month | 500 GB/month | 50 TB/5yr |
| 100,000 | 1.5 TB/month | 5 TB/month | 500 TB/5yr |
| 1,000,000 | **15 TB/month** | **50 TB/month** | **5 PB/5yr** |

---

## 6. Scaling Recommendations by Tier

### 0-1,000 Users
- Single PostgreSQL instance
- Connection pool: 10-20
- No partitioning
- PgBouncer optional

### 1,000-10,000 Users
- PostgreSQL with `work_mem=128MB`, `shared_buffers=4GB`
- Connection pool: 50-100
- Monthly partitioning for `sensor_readings`
- Read replica (optional)

### 10,000-100,000 Users
- **Required**: TimescaleDB for `sensor_readings`
- 2-3 read replicas
- Connection pool: 200-500
- Redis cache layer for hot data (last 24h readings)
- PgBouncer in transaction mode
- Cursor-based pagination everywhere

### 100,000-1,000,000 Users
- **Required**: TimescaleDB distributed + CitusDB
- 5+ read replicas
- Write: Kafka ingestion pipeline
- Cache: Redis Cluster
- Sharding: by `hospital_id` group
- Archive: S3 Glacier for data > 6 months

---

## 7. Conclusion

| Tier | Status | Action Required |
|------|--------|----------------|
| **100** | ✅ Ready | No changes |
| **1,000** | ✅ Ready | Increase pool size |
| **10,000** | ✅ Ready | Add partitioning |
| **100,000** | ⚠️ Changes needed | TimescaleDB + replicas + cache |
| **1,000,000** | 🔧 Redesign needed | Distributed architecture |

The current design is **scalable to 100,000 users without fundamental redesign**, provided partitioning strategy and read replicas are implemented at the appropriate tiers. Above 100K, a distributed architecture (CitusDB/TimescaleDB + Kafka + Redis Cluster) is required.
