CREATE MATERIALIZED VIEW IF NOT EXISTS mv_daily_alerts_summary AS
SELECT
    DATE(a.created_at AT TIME ZONE 'UTC') AS alert_date,
    a.severity,
    COUNT(*) AS alert_count,
    COUNT(*) FILTER (WHERE a.is_acknowledged = TRUE) AS acknowledged_count,
    COUNT(*) FILTER (WHERE a.is_resolved = TRUE) AS resolved_count,
    COUNT(*) FILTER (WHERE a.is_resolved = FALSE AND a.is_acknowledged = FALSE) AS pending_count,
    AVG(a.risk_score) AS avg_risk_score,
    MAX(a.risk_score) AS max_risk_score,
    COUNT(DISTINCT a.patient_id) AS affected_patients,
    COUNT(DISTINCT a.device_id) AS affected_devices,
    NOW() AS refreshed_at
FROM alerts a
WHERE a.deleted_at IS NULL
GROUP BY DATE(a.created_at AT TIME ZONE 'UTC'), a.severity
ORDER BY alert_date DESC, a.severity DESC;

CREATE UNIQUE INDEX IF NOT EXISTS uq_mv_daily_alerts_summary
    ON mv_daily_alerts_summary (alert_date, severity);

COMMENT ON MATERIALIZED VIEW mv_daily_alerts_summary IS 'Daily alert counts aggregated by severity';


CREATE OR REPLACE FUNCTION refresh_mv_daily_alerts_summary()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_alerts_summary;
END;
$$;

COMMENT ON FUNCTION refresh_mv_daily_alerts_summary() IS 'Refreshes mv_daily_alerts_summary (call every 5 minutes via pg_cron or application scheduler)';


CREATE MATERIALIZED VIEW IF NOT EXISTS mv_hospital_stats AS
SELECT
    h.id AS hospital_id,
    h.name AS hospital_name,
    h.hospital_type,
    COUNT(DISTINCT p.id) FILTER (WHERE p.is_active = TRUE AND p.deleted_at IS NULL) AS active_patient_count,
    COUNT(DISTINCT p.id) FILTER (WHERE p.deleted_at IS NULL) AS total_patient_count,
    COUNT(DISTINCT d.id) FILTER (WHERE d.deleted_at IS NULL) AS device_count,
    COUNT(DISTINCT d.id) FILTER (WHERE d.status = 'online' AND d.deleted_at IS NULL) AS online_device_count,
    COUNT(DISTINCT d.id) FILTER (WHERE d.status = 'offline' AND d.deleted_at IS NULL) AS offline_device_count,
    COUNT(DISTINCT a.id) FILTER (WHERE a.is_resolved = FALSE AND a.is_acknowledged = FALSE AND a.deleted_at IS NULL) AS active_alert_count,
    COUNT(DISTINCT a.id) FILTER (WHERE a.severity = 'critical' AND a.is_resolved = FALSE AND a.deleted_at IS NULL) AS critical_alert_count,
    COUNT(DISTINCT u.id) FILTER (WHERE u.deleted_at IS NULL) AS user_count,
    COUNT(DISTINCT dep.id) AS department_count,
    NOW() AS refreshed_at
FROM hospitals h
LEFT JOIN patients p ON p.hospital_id = h.id
LEFT JOIN devices d ON d.hospital_id = h.id
LEFT JOIN alerts a ON a.patient_id = p.id
LEFT JOIN users u ON u.hospital_id = h.id AND u.deleted_at IS NULL
LEFT JOIN departments dep ON dep.hospital_id = h.id
GROUP BY h.id, h.name, h.hospital_type
ORDER BY h.name;

CREATE UNIQUE INDEX IF NOT EXISTS uq_mv_hospital_stats
    ON mv_hospital_stats (hospital_id);

COMMENT ON MATERIALIZED VIEW mv_hospital_stats IS 'Per-hospital aggregate statistics for dashboard';


CREATE OR REPLACE FUNCTION refresh_mv_hospital_stats()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_hospital_stats;
END;
$$;

COMMENT ON FUNCTION refresh_mv_hospital_stats() IS 'Refreshes mv_hospital_stats';


CREATE MATERIALIZED VIEW IF NOT EXISTS mv_risk_distribution AS
SELECT
    sr.risk_level,
    COUNT(DISTINCT sr.patient_id) AS patient_count,
    COUNT(*) AS reading_count,
    MIN(sr.risk_score) AS min_score,
    MAX(sr.risk_score) AS max_score,
    AVG(sr.risk_score) AS avg_score,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sr.risk_score) AS median_score,
    COUNT(*) FILTER (WHERE sr.processed_by_tinyml = TRUE) AS tinyml_processed,
    COUNT(*) FILTER (WHERE sr.processed_by_cloud = TRUE) AS cloud_processed,
    NOW() AS refreshed_at
FROM sensor_readings sr
WHERE sr.id IN (
    SELECT DISTINCT ON (sr2.patient_id) sr2.id
    FROM sensor_readings sr2
    ORDER BY sr2.patient_id, sr2.timestamp DESC
)
GROUP BY sr.risk_level
ORDER BY sr.risk_level;

CREATE UNIQUE INDEX IF NOT EXISTS uq_mv_risk_distribution
    ON mv_risk_distribution (risk_level);

COMMENT ON MATERIALIZED VIEW mv_risk_distribution IS 'Risk score distribution across all active patients (based on latest reading per patient)';


CREATE OR REPLACE FUNCTION refresh_mv_risk_distribution()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_risk_distribution;
END;
$$;

COMMENT ON FUNCTION refresh_mv_risk_distribution() IS 'Refreshes mv_risk_distribution';


CREATE MATERIALIZED VIEW IF NOT EXISTS mv_ai_report_stats AS
SELECT
    ar.report_type,
    COUNT(*) AS report_count,
    COUNT(*) FILTER (WHERE ar.is_reviewed = TRUE) AS reviewed_count,
    COUNT(*) FILTER (WHERE ar.is_reviewed = FALSE) AS unreviewed_count,
    AVG(ar.confidence) AS avg_confidence,
    MIN(ar.confidence) AS min_confidence,
    MAX(ar.confidence) AS max_confidence,
    AVG(ar.risk_score) AS avg_risk_score,
    ar.icp_risk,
    ar.herniation_risk,
    ar.bleeding_type,
    COUNT(DISTINCT ar.patient_id) AS unique_patients,
    DATE(ar.created_at AT TIME ZONE 'UTC') AS report_date,
    NOW() AS refreshed_at
FROM ai_reports ar
WHERE ar.deleted_at IS NULL
GROUP BY ar.report_type, ar.icp_risk, ar.herniation_risk, ar.bleeding_type, DATE(ar.created_at AT TIME ZONE 'UTC')
ORDER BY report_date DESC, report_count DESC;

CREATE UNIQUE INDEX IF NOT EXISTS uq_mv_ai_report_stats
    ON mv_ai_report_stats (report_type, COALESCE(icp_risk, 'none'), COALESCE(herniation_risk, 'none'), COALESCE(bleeding_type, 'none'), report_date);

COMMENT ON MATERIALIZED VIEW mv_ai_report_stats IS 'AI report statistics aggregated by type, risk category, and date';
