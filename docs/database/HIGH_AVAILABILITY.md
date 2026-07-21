# High Availability Architecture — NeuroBleed Alert

## Architecture Overview

```
                          ┌──────────────┐
                          │   HAProxy     │
                          │  (Load Balancer)│
                          └──────┬───────┘
                                 │
                    ┌────────────┼────────────┐
                    │            │            │
              ┌─────▼────┐ ┌────▼────┐ ┌────▼────┐
              │ PgBouncer │ │ PgBouncer │ │ PgBouncer │
              │  (active) │ │ (standby) │ │ (standby) │
              └─────┬────┘ └────┬────┘ └────┬────┘
                    │            │            │
              ┌─────▼────────────┴────────────▼─────┐
              │            Patroni + etcd            │
              │         (Cluster management)          │
              └─────────────────┬───────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
  ┌─────▼──────┐         ┌─────▼──────┐         ┌─────▼──────┐
  │  Primary   │◄──sync──► Standby 1  │◄──sync──► Standby 2  │
  │  (RW)      │         │  (RO)      │         │  (RO)      │
  └─────┬──────┘         └────────────┘         └────────────┘
        │
        │ async (streaming)
  ┌─────▼──────┐
  │  DR Replica │  (different region)
  │  (RO)      │
  └────────────┘
```

## Components

### 1. PostgreSQL — Primary + 2 Standbys (Synchronous)

- **Synchronous commit**: `remote_write` — ensures zero data loss on primary failure
- **WAL sender processes**: `max_wal_senders = 10`
- **Standby configuration**:
  ```ini
  synchronous_standby_names = 'FIRST 2 (standby1, standby2)'
  hot_standby = on
  hot_standby_feedback = on
  ```
- **Replication slots**: Physical slots for each standby to prevent WAL cleanup before replica consumes it

### 2. PgBouncer — Connection Pooling

- **Mode**: Transaction pooling
  ```ini
  pool_mode = transaction
  max_client_conn = 500
  default_pool_size = 25
  reserve_pool_size = 5
  reserve_pool_timeout = 3
  ```
- Two instances: active + standby
- Health-checked by HAProxy every 5 seconds
- Auth: `auth_type = scram-sha-256`
- TLS: `server_tls_sslmode = require`

### 3. Patroni + etcd — Auto-Failover

- **etcd cluster**: 3 nodes for quorum
- **Patroni configuration**:
  ```yaml
  loop_wait: 10
  ttl: 30
  retry_timeout: 10
  maximum_lag_on_failover: 1048576  # 1 MB
  ```
- **Failover conditions**: Primary unreachable for 3 consecutive health checks (30s)
- **Automatic rejoin**: Failed primary converted to standby via `pg_rewind`

### 4. HAProxy — Load Balancing

```
frontend pg_frontend
    bind *:5432
    option pgsql-check user health_checker
    default_backend pg_backend

backend pg_backend
    option pgsql-check user health_checker
    server primary 10.0.1.10:6432 check port=6432
    server standby1 10.0.1.11:6432 check port=6432
    server standby2 10.0.1.12:6432 check port=6432
```

Writes routed to primary; reads balanced across standbys via connection string configuration.

### 5. Zero-Downtime Upgrades

- Minor version: Rolling restart via Patroni switchover
- Major version: `pg_upgrade` with logical replication
- Schema migrations: `pt-online-schema-change` pattern with zero-downtime
- Fallback: `pg_rewind` on failed upgrade attempt

## DR Site

- **Location**: Different region / availability zone
- **Replication**: Asynchronous streaming replication
- **Network**: Direct Connect / VPN with 1 Gbps minimum
- **Standby**: Hot standby, available for read queries (reporting/monitoring)
- **Promotion**: Manual via Patroni when primary region confirmed lost
- **RPO**: < 5 minutes (async)
- **RTO**: < 1 hour

## Recovery Objectives

| Metric | Primary Region | DR Region |
|--------|----------------|-----------|
| RPO | < 1 second | < 5 minutes |
| RTO | < 30 seconds | < 1 hour |
| Durability | Synchronous commit | WAL archive |

## Monitoring

- **Patroni REST API**: `/health`, `/patroni`, `/cluster` — scraped every 10s
- **Replication lag**: Tracked via `pg_stat_replication` — alert if `write_lag > 10KB` or `replay_lag > 30s`
- **PgBouncer stats**: `SHOW STATS`, `SHOW POOLS` — alert if active connections > 80% of pool
- **HAProxy stats**: Socket stats — alert on backend downtime
- **etcd health**: Leader changes and cluster member health

## Operational Runbooks

### Switchover (Planned)
```bash
patronictl switchover postgres-cluster
# Follow prompts to demote primary and promote target standby
```

### Failover (Unplanned)
```bash
patronictl failover postgres-cluster
# or automatic via etcd lease expiry
```

### Rejoin Failed Node
```bash
patronictl reinit postgres-cluster <node-name>
# Patroni re-clones from existing replica via pg_basebackup
```

## Testing Schedule

- Monthly: Switchover exercise (rotate primary role among all nodes)
- Quarterly: Full failover + DR promotion drill
- Bi-annual: Disaster recovery exercise (simulate region failure)
- Annual: Capacity planning review

---

*Last updated: 2026-07-16*
