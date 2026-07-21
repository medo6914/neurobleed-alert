# Backup & Disaster Recovery Plan

> Backup & Disaster Recovery — Complete

---

## Recovery Objectives

| Metric | Target | Rationale |
|--------|--------|-----------|
| **RPO** (Recovery Point Objective) | ≤ 5 minutes | Maximum data loss acceptable |
| **RTO** (Recovery Time Objective) | ≤ 30 minutes | Maximum downtime acceptable |
| **RTO (Critical Alert)** | ≤ 2 minutes | Life-critical alert delivery |
| **RTO (Database)** | ≤ 15 minutes | Full database recovery |

---

## 1. Database Backup Strategy

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PostgreSQL Backup Strategy                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Continuous (WAL Archiving)      Daily (Full Backup)                 │
│  ──────────────────────────      ──────────────────                  │
│  Every 5 minutes: Upload         Every 24h at 02:00:                │
│  WAL segments to S3              pg_dump to S3                      │
│  (point-in-time recovery)        (restore standalone)                │
│                                                                      │
│  Retention: 7 days (WAL)         Retention: 30 days (full)          │
│  Retention: 30 days (monthly)                                        │
│                                                                      │
│  ┌─────────────────┐             ┌─────────────────┐                │
│  │   PostgreSQL    │             │   PostgreSQL    │                │
│  │   Primary       │────────────→│   Backup        │                │
│  │   (Europe)      │  Streaming  │   (Different    │                │
│  │                 │  Replication│    Region)      │                │
│  └─────────────────┘             └─────────────────┘                │
│         │                                                            │
│         │ WAL Archive                                                │
│         ▼                                                            │
│  ┌─────────────────┐                                                 │
│  │   S3 / GCS      │   Encrypted (AES-256) backups                  │
│  │   Object Store  │   Versioned (30-day versioning)                │
│  └─────────────────┘                                                 │
└─────────────────────────────────────────────────────────────────────┘
```

## Implementation

```bash
#!/bin/bash
# scripts/backup.sh

# Configuration
BACKUP_DIR="/backups/postgres"
S3_BUCKET="s3://neurobleed-backups"
RETENTION_DAYS=30
DB_URL="postgresql://neurobleed:${DB_PASSWORD}@localhost:5432/neurobleed"

# 1. Full database backup (compressed + encrypted)
PGPASSWORD="${DB_PASSWORD}" pg_dump \
    -h localhost \
    -U neurobleed \
    -d neurobleed \
    -F custom \
    -Z 9 \
    -f "${BACKUP_DIR}/neurobleed_$(date +%Y%m%d_%H%M%S).dump"

# 2. Encrypt backup
gpg --symmetric --cipher-algo AES256 \
    --passphrase "${BACKUP_PASSPHRASE}" \
    -o "${BACKUP_DIR}/neurobleed_$(date +%Y%m%d).dump.gpg" \
    "${BACKUP_DIR}/neurobleed_$(date +%Y%m%d_%H%M%S).dump"

# 3. Upload to S3
aws s3 cp "${BACKUP_DIR}/neurobleed_$(date +%Y%m%d).dump.gpg" \
    "${S3_BUCKET}/postgres/daily/"

# 4. Cleanup old backups
find "${BACKUP_DIR}" -name "*.dump" -mtime +${RETENTION_DAYS} -delete

# 5. Verify backup integrity (test restore to temp DB)
PGPASSWORD="${DB_PASSWORD}" pg_restore \
    -h localhost \
    -U neurobleed \
    -d neurobleed_verify \
    --exit-on-error \
    "${BACKUP_DIR}/neurobleed_$(date +%Y%m%d).dump.gpg" \
    2>&1 | grep -q "ERROR:" && echo "Backup verification FAILED" || echo "Backup OK"
```

---

## 2. WAL Archiving (Point-in-Time Recovery)

```ini
# postgresql.conf (production)
wal_level = replica
archive_mode = on
archive_command = 'aws s3 cp %p s3://neurobleed-backups/postgres/wal/%f'
archive_timeout = 300           # 5 minutes
max_wal_size = 4GB
min_wal_size = 1GB
```

**Point-in-Time Recovery Steps**:
```bash
# Restore to timestamp
pgbackrest --stanza=neurobleed --type=time \
    --target="2026-07-14 16:30:00+03" \
    --target-action=promote restore

# Or to specific transaction
pgbackrest --stanza=neurobleed --type=xid \
    --target=123456789 restore
```

---

## 3. Database Replication

```yaml
# docker-compose.prod.yml (production)
services:
  postgres-primary:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: neurobleed
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: neurobleed
    volumes:
      - postgres_primary:/var/lib/postgresql/data
      - ./postgres/primary.conf:/etc/postgresql/postgresql.conf
    ports: ["5432:5432"]

  postgres-replica:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: neurobleed
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_replica:/var/lib/postgresql/data
      - ./postgres/replica.conf:/etc/postgresql/postgresql.conf
    depends_on: [postgres-primary]
    ports: ["5433:5432"]
```

---

## 4. Redis Backup

```bash
# RDB snapshot (every 5 minutes in production)
redis-cli BGSAVE
# Save to: /var/lib/redis/dump.rdb

# AOF persistence (append-only, every 1 second)
# Append to: /var/lib/redis/appendonly.aof

# Backup to S3
aws s3 cp /var/lib/redis/dump.rdb \
    s3://neurobleed-backups/redis/dump_$(date +%Y%m%d_%H%M%S).rdb
```

---

## 5. Disaster Recovery Scenarios

| Scenario | Detection | Recovery Procedure | RTO |
|----------|-----------|-------------------|-----|
| **DB Server Crash** | Prometheus alert (down) | Promote replica to primary | 2 min |
| **Full Region Outage** | External monitoring | Restore from S3 in secondary region | 30 min |
| **Data Corruption** | Application errors | PITR to before corruption | 15 min |
| **Accidental Data Deletion** | Audit log review | PITR to before deletion | 15 min |
| **Redis Data Loss** | Cache miss rate spike | Restore from RDB, rebuild from DB | 5 min |
| **S3 Backup Corruption** | Verification failure | Restore from previous day's backup | 30 min |
| **Credentials Leak** | Security alert | Rotate keys, revoke access, audit | 1 hour |

---

## 6. Recovery Playbook

```bash
# DISASTER RECOVERY PLAYBOOK
# Scenario: Full database loss

# Step 1: Stop application (prevent writes)
docker compose -f docker-compose.prod.yml stop backend ai-gateway

# Step 2: Restore latest full backup from S3
aws s3 cp s3://neurobleed-backups/postgres/daily/neurobleed_20260714.dump.gpg \
    /tmp/restore/neurobleed.dump.gpg

# Step 3: Decrypt
gpg --decrypt --passphrase "${BACKUP_PASSPHRASE}" \
    /tmp/restore/neurobleed.dump.gpg > /tmp/restore/neurobleed.dump

# Step 4: Create new database
createdb -U neurobleed neurobleed_recovered

# Step 5: Restore
pg_restore -U neurobleed -d neurobleed_recovered \
    --exit-on-error /tmp/restore/neurobleed.dump

# Step 6: Apply WAL to point-in-time (if needed)
pgbackrest --stanza=neurobleed --type=time \
    --target="$(date -d '5 minutes ago' -Iseconds)" \
    --db-path=/var/lib/postgresql/data \
    --target-action=promote restore

# Step 7: Verify integrity
psql -U neurobleed -d neurobleed_recovered -c \
    "SELECT count(*) FROM patients; SELECT count(*) FROM sensor_readings;"

# Step 8: Switch application to recovered DB
export DATABASE_URL="postgresql://neurobleed:${DB_PASSWORD}@localhost:5432/neurobleed_recovered"

# Step 9: Start application
docker compose -f docker-compose.prod.yml start backend ai-gateway

# Step 10: Verify application health
curl http://localhost:8000/health/ready
```

---

## 7. Backup Verification Schedule

| Check | Frequency | Action if Failed |
|-------|-----------|-----------------|
| Backup file existence | Every 6 hours | Alert on-call engineer |
| Backup file size (>1GB) | Daily | Verify content, re-run backup |
| Test restore to staging | Weekly | Debug restore process |
| Integrity check (pg_dump verify) | Weekly | Re-run backup, alert team |
| Disaster recovery drill | Monthly | Full simulation, document gaps |
| Compliance audit | Quarterly | Verify retention, encryption, access |

---

## 8. Encryption & Security

```
At Rest:
  - PostgreSQL TDE (Transparent Data Encryption)
  - S3 Server-Side Encryption (AES-256)
  - Backup files encrypted with GPG (AES-256)
  - Redis AOF encryption (optional)

In Transit:
  - TLS 1.2+ for all database connections
  - TLS 1.2+ for S3 uploads/downloads
  - SSH tunnels for replication

Key Management:
  - AWS KMS for S3 encryption keys
  - HashiCorp Vault for DB passwords
  - GPG passphrase stored in Vault
  - Automatic key rotation every 90 days
```

---

## 9. Retention Policy

| Data Type | Retention | Storage | Deletion Method |
|-----------|-----------|---------|-----------------|
| Patient Records | 10 years | PostgreSQL | Soft delete, then purge after 10yr |
| Sensor Readings | 2 years | PostgreSQL (partitioned) | Drop partitions > 2yr |
| AI Reports | 5 years | PostgreSQL | Soft delete |
| Audit Logs | 7 years | PostgreSQL + Archived | Archive to S3, then delete |
| Raw Device Data | 90 days | Object Store (S3) | S3 lifecycle policy |
| Backups (Full) | 30 days | S3 | S3 lifecycle policy |
| Backups (Monthly) | 12 months | S3 Glacier | S3 lifecycle policy |
| Backups (Yearly) | 7 years | S3 Glacier Deep Archive | Manual review |
| Debug Logs | 7 days | Loki | Loki retention |
| Application Logs | 30 days | Loki | Loki retention |
