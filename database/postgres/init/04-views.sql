CREATE OR REPLACE VIEW vw_active_patients AS
SELECT
    p.id,
    p.mrn,
    p.full_name,
    p.date_of_birth,
    p.gender,
    p.admission_date,
    p.bed_number,
    p.is_ihd_suspected,
    h.id AS hospital_id,
    h.name AS hospital_name,
    d.id AS department_id,
    d.name AS department_name,
    dev.id AS device_id,
    dev.serial_number AS device_serial,
    dev.status AS device_status,
    dev.battery_level AS device_battery,
    dev.signal_strength AS device_signal,
    dev.last_seen AS device_last_seen
FROM patients p
LEFT JOIN hospitals h ON h.id = p.hospital_id
LEFT JOIN departments d ON d.id = p.department_id
LEFT JOIN devices dev ON dev.patient_id = p.id
WHERE p.is_active = TRUE
  AND p.deleted_at IS NULL;

COMMENT ON VIEW vw_active_patients IS 'Active patients with hospital, department, and device information';


CREATE OR REPLACE VIEW vw_patient_latest_readings AS
SELECT DISTINCT ON (sr.patient_id)
    sr.patient_id,
    p.mrn,
    p.full_name,
    sr.id AS reading_id,
    sr.spo2,
    sr.heart_rate,
    sr.rso2,
    sr.ir_value,
    sr.red_value,
    sr.signal_quality,
    sr.motion_artifact,
    sr.risk_score,
    sr.risk_level,
    sr.processed_by_tinyml,
    sr.processed_by_cloud,
    sr.timestamp AS reading_timestamp,
    sr.created_at
FROM sensor_readings sr
JOIN patients p ON p.id = sr.patient_id AND p.deleted_at IS NULL
ORDER BY sr.patient_id, sr.timestamp DESC;

COMMENT ON VIEW vw_patient_latest_readings IS 'Latest sensor reading per patient';


CREATE OR REPLACE VIEW vw_unacknowledged_alerts AS
SELECT
    a.id AS alert_id,
    a.alert_type,
    a.severity,
    a.risk_score,
    a.message,
    a.created_at AS alert_created_at,
    a.is_acknowledged,
    a.is_resolved,
    p.id AS patient_id,
    p.mrn,
    p.full_name AS patient_name,
    p.bed_number,
    p.gender,
    p.admission_date,
    h.id AS hospital_id,
    h.name AS hospital_name,
    d.id AS department_id,
    d.name AS department_name,
    dev.serial_number AS device_serial,
    dev.status AS device_status
FROM alerts a
JOIN patients p ON p.id = a.patient_id AND p.deleted_at IS NULL
LEFT JOIN hospitals h ON h.id = p.hospital_id
LEFT JOIN departments d ON d.id = p.department_id
LEFT JOIN devices dev ON dev.id = a.device_id
WHERE a.is_acknowledged = FALSE
  AND a.is_resolved = FALSE
  AND a.deleted_at IS NULL
ORDER BY a.severity DESC, a.created_at DESC;

COMMENT ON VIEW vw_unacknowledged_alerts IS 'Active unacknowledged alerts with patient and device information';


CREATE OR REPLACE VIEW vw_device_status AS
SELECT
    dev.id AS device_id,
    dev.device_name,
    dev.device_type,
    dev.serial_number,
    dev.firmware_version,
    dev.status,
    dev.battery_level,
    dev.signal_strength,
    dev.last_seen,
    dev.is_active,
    CASE
        WHEN dev.last_seen IS NULL THEN 'unknown'
        WHEN dev.last_seen < NOW() - INTERVAL '5 minutes' THEN 'stale'
        WHEN dev.status = 'online' THEN 'healthy'
        WHEN dev.status = 'offline' AND dev.last_seen > NOW() - INTERVAL '1 hour' THEN 'intermittent'
        ELSE dev.status::text
    END AS health_status,
    CASE
        WHEN dev.battery_level < 20 THEN 'critical'
        WHEN dev.battery_level < 50 THEN 'low'
        ELSE 'adequate'
    END AS battery_status,
    CASE
        WHEN dev.signal_strength < 0.3 THEN 'poor'
        WHEN dev.signal_strength < 0.7 THEN 'fair'
        ELSE 'good'
    END AS signal_status,
    h.id AS hospital_id,
    h.name AS hospital_name,
    p.id AS patient_id,
    p.full_name AS patient_name,
    p.mrn
FROM devices dev
LEFT JOIN hospitals h ON h.id = dev.hospital_id
LEFT JOIN patients p ON p.id = dev.patient_id AND p.deleted_at IS NULL
WHERE dev.deleted_at IS NULL
ORDER BY dev.status, dev.battery_level ASC;

COMMENT ON VIEW vw_device_status IS 'Device health status summary with battery and signal quality';


CREATE OR REPLACE VIEW vw_user_roles_permissions AS
SELECT
    u.id AS user_id,
    u.email,
    u.full_name,
    u.role AS primary_role,
    u.is_active AS user_active,
    r.id AS role_id,
    r.name AS role_name,
    r.description AS role_description,
    p.id AS permission_id,
    p.codename AS permission_codename,
    p.name AS permission_name,
    p.resource AS permission_resource,
    h.id AS hospital_id,
    h.name AS hospital_name
FROM users u
LEFT JOIN hospitals h ON h.id = u.hospital_id
LEFT JOIN user_roles ur ON ur.user_id = u.id
LEFT JOIN roles r ON r.id = ur.role_id
LEFT JOIN role_permissions rp ON rp.role_id = r.id
LEFT JOIN permissions p ON p.id = rp.permission_id
WHERE u.deleted_at IS NULL
ORDER BY u.email, r.name, p.codename;

COMMENT ON VIEW vw_user_roles_permissions IS 'User role and permission assignments';
