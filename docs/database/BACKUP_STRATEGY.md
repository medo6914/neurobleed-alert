# Backup Strategy — NeuroBleed Alert

## Overview

PostgreSQL-based backup architecture combining continuous WAL archiving, periodic physical base backups, and point-in-time recovery (PITR) capability.

---

## 1. WAL Archiving (Continuous)

- WAL level: `replica` (required for archiving and replication)
- Archive command: `cp %p /mnt/backups/wal/%f`
- Archive destination: Network-attached storage (NAS) replicated to S3-compatible object store
- WAL retention: Until corresponding base backup + required recovery window expires
- Monitoring: `pg_stat_archiver` — alert if `last_failed_wal` is non-null

```ini
# postgresql.conf
wal_level = replica
archive_mode = on
archive_command = 'pgbackrest --stanza=neurobleed archive-push %p'
archive_timeout = 60
```

## 2. Physical Backups (pg_basebackup)

- Frequency: Daily via cron / Kubernetes CronJob
- Tool: `pg_basebackup` or `pgBackRest`
- Destination: `/mnt/backups/physical/`
- Compression: gzip (level 6)
- Retention: Daily for 7 days, weekly for 4 weeks, monthly for 12 months

```bash
pg_basebackup -h localhost -D /mnt/backups/physical/$(date +%Y%m%d) \
  -Ft -z -P -X fetch
```

## 3. pgBackRest Configuration

```ini
# pgbackrest.conf
[neurobleed]
pg1-path=/var/lib/postgresql/data
pg1-port=5432

[global]
repo1-path=/mnt/backups/pgbackrest
repo1-retention-full=4
repo1-retention-diff=4
repo1-cipher-type=aes-256-cbc
repo1-cipher-pass=  # from vault/KMS
compress-type=zst
compress-level=6
process-max=4
```

### Backup Types

| Type | Schedule | Retention |
|------|----------|-----------|
| Full | Weekly (Sun 02:00) | 4 weeks |
| Differential | Daily (except Sun) | 4 days |
| Incremental | Every 4 hours | — |

## 4. Point-in-Time Recovery (PITR)

### Procedure

1. Shutdown target instance
2. Restore base backup:
   ```bash
   pgbackrest --stanza=neurobleed --type=time \
     --target="2026-07-15 14:30:00 EST" restore
   ```
3. Create `recovery.signal` and configure `recovery.conf`:
   ```ini
   restore_command = 'pgbackrest --stanza=neurobleed archive-get %f "%p"'
   recovery_target_time = '2026-07-15 14:30:00 EST'
   recovery_target_action = promote
   ```
4. Start PostgreSQL — it replays WAL to target time and promotes itself

## 5. Backup Retention Policy

| Window | Schedule | Copies | Storage |
|--------|----------|--------|---------|
| Daily | Every 24h | 7 days | ~50 GB × 7 |
| Weekly | Every Sun | 4 weeks | ~50 GB × 4 |
| Monthly | 1st of month | 12 months | ~50 GB × 12 |
| WAL | Continuous | Until oldest retained base + 7 days | ~10 GB/day |

Total estimated: ~1.2 TB annually with compression.

## 6. Replication

- Architecture: Primary + 2 synchronous hot standbys
- Streaming replication with `synchronous_commit = remote_write`
- `synchronous_standby_names = 'FIRST 2 (standby1, standby2)'`
- WAL senders: `max_wal_senders = 10`

## 7. Failover Procedure

1. Detect primary failure (Patroni/Consul health check — 3 consecutive failures)
2. Promote highest-priority standby:
   ```bash
   pgbackrest --stanza=neurobleed --type=immediate promote
   ```
3. Reconfigure HAProxy to point to new primary
4. Rejoin failed node as replica:
   ```bash
   pgbackrest --stanza=neurobleed --type=standby restore
   ```
5. Verify data consistency (pg_checksums)

## 8. Restore Testing (Quarterly)

- Q1: Full restore to isolated environment + application smoke test
- Q2: PITR to arbitrary timestamp + data integrity check
- Q3: Failover/failback exercise
- Q4: DR site promotion + full application load test

All restore tests MUST be documented with duration, data loss (if any), and remediation steps.

## 9. Disaster Recovery Plan

| Scenario | RPO | RTO | Action |
|----------|-----|-----|--------|
| Primary server failure | 0 (sync) | < 30s | Auto-failover to standby |
| DC outage (primary region) | < 5 min | < 1 hr | Promote DR async replica |
| Data corruption (logical) | Varies | < 2 hr | PITR to pre-corruption time |
| Full region failure | < 15 min | < 4 hr | Restore from offsite backups |

### DR Runbook

1. Alert → on-call DBA acknowledges via PagerDuty
2. Assess scope: is primary recoverable?
3. If no, promote DR standby or restore from backup
4. Validate data with `pg_checksums` and application health check
5. Redirect traffic via DNS failover / HAProxy config
6. Post-mortem within 48 hours

## 10. Backup Monitoring & Alerting

- **pgBackRest check**: `pgbackrest --stanza=neurobleed check` — runs every 15 min
- **WAL archiving lag**: Alert if > 5 min since last WAL archived
- **Backup freshness**: Alert if no successful backup in > 28 hours
- **Backup size anomaly**: Alert if size deviates > 20% from 7-day moving average
- **Replication lag**: Alert if > 10 MB or > 30 seconds behind primary

### Prometheus / Grafana

- `pg_stat_archiver` metrics: `archived_count`, `last_archived_wal`, `failed_archive_count`
- `pg_stat_replication` metrics: `replay_lag`, `write_lag`, `flush_lag`
- Backup job status via `pgbackrest info --output=json`

## 11. Encryption

- **At rest**: Backups encrypted with AES-256-CBC via pgBackRest cipher
- **In transit**: TLS 1.3 for all S3/object-store uploads
- **Key management**: Encryption passphrase stored in AWS KMS / Azure Key Vault, rotated every 90 days
- **WAL files**: Encrypted at rest on backup volume (LUKS/dm-crypt)

---

*Last updated: 2026-07-16*
