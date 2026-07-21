# Data Retention Policy

## 1. Purpose

This policy defines retention periods, deletion strategies, and archival rules for all data stored in the NeuroBleed Alert database. Compliance with medical regulations (HIPAA, GDPR, Saudi Health Law) is required.

---

## 2. Retention Periods by Table

| Table | Retention Period | Deletion Strategy | Justification |
|-------|-----------------|-------------------|---------------|
| `sensor_readings` | 2 years (active), 5 years (archive) | Soft delete → archival → physical delete after 5y | Medical monitoring data — 5 years per Saudi Health Law |
| `alerts` | 5 years | Soft delete → physical delete | Alert records required for medico-legal review |
| `ai_reports` | 10 years | Soft delete → physical delete | AI diagnostic reports — extended retention for model audit |
| `patients` | 30 years after last visit | Soft delete → archival → physical delete after 30y | Medical records — Saudi Health Law mandates 25-30 years |
| `users` | 7 years after account deactivation | Soft delete → physical delete | HR/staff records |
| `hospitals` | Indefinite (business entity) | Soft delete only | Organizational records — never fully deleted |
| `organizations` | Indefinite | Soft delete only | Same as hospitals |
| `departments` | Indefinite | Soft delete only | Same as hospitals |
| `devices` | Lifetime of device + 2 years | Soft delete → physical delete | Device lifecycle tracking |
| `audit_logs` | 10 years | Physical delete (no soft delete) | Regulatory requirement for audit trails |
| `sessions` | 90 days after expiry | Physical delete (cron job) | Session security — short retention |
| `refresh_tokens` | 90 days after expiry | Physical delete (cron job) | Token security |
| `knowledge_base` | Indefinite | Soft delete only | Medical knowledge — never deleted |
| `knowledge_update_logs` | 10 years | Physical delete | Change tracking for knowledge base |
| `roles` | Indefinite | Soft delete only | RBAC structure — never deleted |
| `permissions` | Indefinite | Soft delete only | RBAC structure — never deleted |

---

## 3. Deletion Strategies

### 3.1 Soft Delete

Tables with `SoftDeleteMixin` have:
- `is_deleted` (bool) — marks record as deleted
- `deleted_at` (timestamp) — when deletion occurred
- `deleted_by_id` (FK → users) — who deleted

Soft-deleted records are filtered out by default in all queries:
```python
query = query.where(SoftDeleteMixin.is_deleted == False)
```

### 3.2 Permanent Delete

Records are physically deleted only after the full retention period expires. A scheduled job runs:

```
Cron: Daily at 02:00 AM
Job: data_retention_enforcer.py
```

### 3.3 Archival

Before permanent deletion, data is archived to cold storage:
1. Export to Parquet format
2. Compress with Zstandard
3. Upload to S3 Glacier / Azure Archive Storage
4. Retention: 10 years in archive

---

## 4. Medical Records Retention (Saudi Health Law)

- **Patient records**: 25 years from last visit (Ministry of Health regulation)
- **Radiology/imaging**: 10 years
- **Lab results**: 10 years
- **Surgical reports**: 25 years
- **AI-generated diagnostic reports**: 10 years
- **Vital signs monitoring**: 5 years

---

## 5. Implementation

### 5.1 Retention Enforcer Job

```python
# Scheduled task — runs daily
async def enforce_data_retention():
    cutoff_date = datetime.utcnow() - timedelta(days=RETENTION_DAYS[table])
    await db.execute(delete(Table).where(Table.created_at < cutoff_date))
```

### 5.2 Archival Pipeline

```python
async def archive_table(table_name, cutoff_date):
    data = await db.execute(select(Table).where(Table.created_at < cutoff_date))
    parquet_file = convert_to_parquet(data)
    compressed = zstd_compress(parquet_file)
    upload_to_cold_storage(compressed, path=f"{table_name}/{cutoff_date.isoformat()}.zst")
    await db.execute(soft_delete(Table).where(Table.created_at < cutoff_date))
```

---

## 6. GDPR Right to Erasure

When a patient exercises "Right to Erasure":
1. Anonymize `patients` record (nullify PII fields, keep medical UUID reference)
2. Anonymize `users` record if patient user
3. Keep medical records (SensorReading, Alert, AIReport) with anonymized patient reference
4. Mark anonymization in `audit_logs`

---

## 7. HIPAA Compliance

- Minimum Necessary Standard: Access controls per Role
- Retention: 6 years (HIPAA minimum)
- NeuroBleed over-retains per Saudi law (more restrictive)
- Encryption at rest and in transit for all PII/PHI
