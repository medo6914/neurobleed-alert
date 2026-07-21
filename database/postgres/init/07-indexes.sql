-- ============================================================
-- DATABASE-LEVEL INDEX HINTS
-- Complements SQLAlchemy model indexes for query patterns
-- that benefit from partial, expression, or covering indexes.
-- ============================================================


-- ------------------------------------------------------------
-- SENSOR READINGS
-- ------------------------------------------------------------

-- Partial index for unprocessed (edge) sensor readings
-- TinyML workers poll this index to find readings awaiting processing
CREATE INDEX IF NOT EXISTS ix_sensor_readings_unprocessed
    ON sensor_readings (timestamp ASC, patient_id)
    WHERE processed_by_tinyml = FALSE
      AND processed_by_cloud = FALSE;

-- Covering index for common patient query patterns
-- Includes frequently accessed columns to avoid heap lookups
CREATE INDEX IF NOT EXISTS ix_sensor_readings_patient_covering
    ON sensor_readings (patient_id, timestamp DESC)
    INCLUDE (spo2, heart_rate, rso2, risk_score, risk_level, signal_quality, motion_artifact);

-- Partial index for high-risk readings (quick triage queries)
CREATE INDEX IF NOT EXISTS ix_sensor_readings_high_risk
    ON sensor_readings (patient_id, timestamp DESC)
    WHERE risk_level IN ('high', 'critical');


-- ------------------------------------------------------------
-- ALERTS
-- ------------------------------------------------------------

-- Partial index for critical unacknowledged alerts (fastest lookup)
CREATE INDEX IF NOT EXISTS ix_alerts_critical_unacknowledged
    ON alerts (created_at DESC, patient_id)
    WHERE severity = 'critical'
      AND is_acknowledged = FALSE
      AND is_resolved = FALSE
      AND deleted_at IS NULL;

-- Partial index for active unresolved alerts by severity
CREATE INDEX IF NOT EXISTS ix_alerts_active_severity
    ON alerts (severity, created_at DESC)
    WHERE is_resolved = FALSE
      AND deleted_at IS NULL;


-- ------------------------------------------------------------
-- PATIENTS
-- ------------------------------------------------------------

-- Expression index for case-insensitive full-text name search
CREATE INDEX IF NOT EXISTS ix_patients_full_name_trgm
    ON patients USING gin (full_name gin_trgm_ops);

-- Expression index for fast full-name search (prefix match)
CREATE INDEX IF NOT EXISTS ix_patients_full_name_lower
    ON patients (LOWER(full_name) text_pattern_ops);


-- ------------------------------------------------------------
-- DEVICES
-- ------------------------------------------------------------

-- Partial index for online devices (heartbeat/status checks)
CREATE INDEX IF NOT EXISTS ix_devices_online
    ON devices (hospital_id, last_seen DESC)
    WHERE status = 'online' AND deleted_at IS NULL;

-- Partial index for low battery alerts
CREATE INDEX IF NOT EXISTS ix_devices_low_battery
    ON devices (hospital_id, battery_level ASC)
    WHERE battery_level < 20 AND deleted_at IS NULL;


-- ------------------------------------------------------------
-- AUDIT LOGS
-- ------------------------------------------------------------

-- Partial index for recent audit log lookups
CREATE INDEX IF NOT EXISTS ix_audit_logs_recent
    ON audit_logs (created_at DESC)
    WHERE created_at > NOW() - INTERVAL '90 days';


-- ------------------------------------------------------------
-- SESSIONS & REFRESH TOKENS
-- ------------------------------------------------------------

-- Partial index for active sessions cleanup
CREATE INDEX IF NOT EXISTS ix_sessions_active_expires
    ON sessions (expires_at ASC)
    WHERE is_active = TRUE;

-- Partial index for revoked tokens cleanup
CREATE INDEX IF NOT EXISTS ix_refresh_tokens_revoked
    ON refresh_tokens (expires_at ASC)
    WHERE is_revoked = TRUE;
