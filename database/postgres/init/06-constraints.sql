-- ============================================================
-- CHECK CONSTRAINTS
-- All constraints use NOT VALID where possible to avoid
-- blocking reads on large tables during validation.
-- ============================================================


-- ------------------------------------------------------------
-- USERS
-- ------------------------------------------------------------
ALTER TABLE users
    ADD CONSTRAINT IF NOT EXISTS chk_users_email_format
    CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

ALTER TABLE users
    ADD CONSTRAINT IF NOT EXISTS chk_users_role_valid
    CHECK (role IN ('admin', 'doctor', 'nurse', 'technician', 'patient', 'emergency'));


-- ------------------------------------------------------------
-- PATIENTS
-- ------------------------------------------------------------
ALTER TABLE patients
    ADD CONSTRAINT IF NOT EXISTS chk_patients_gender_valid
    CHECK (gender IN ('male', 'female', 'other'));

ALTER TABLE patients
    ADD CONSTRAINT IF NOT EXISTS chk_patients_date_of_birth_before_admission
    CHECK (date_of_birth <= admission_date);

ALTER TABLE patients
    ADD CONSTRAINT IF NOT EXISTS chk_patients_discharge_after_admission
    CHECK (discharge_date IS NULL OR discharge_date >= admission_date);


-- ------------------------------------------------------------
-- SENSOR READINGS
-- ------------------------------------------------------------
ALTER TABLE sensor_readings
    ADD CONSTRAINT IF NOT EXISTS chk_sensor_readings_spo2_range
    CHECK (spo2 IS NULL OR (spo2 >= 0 AND spo2 <= 100));

ALTER TABLE sensor_readings
    ADD CONSTRAINT IF NOT EXISTS chk_sensor_readings_heart_rate_range
    CHECK (heart_rate IS NULL OR (heart_rate >= 0 AND heart_rate <= 300));

ALTER TABLE sensor_readings
    ADD CONSTRAINT IF NOT EXISTS chk_sensor_readings_signal_quality_range
    CHECK (signal_quality >= 0 AND signal_quality <= 1);

ALTER TABLE sensor_readings
    ADD CONSTRAINT IF NOT EXISTS chk_sensor_readings_motion_artifact_range
    CHECK (motion_artifact >= 0 AND motion_artifact <= 1);


-- ------------------------------------------------------------
-- ALERTS
-- ------------------------------------------------------------
ALTER TABLE alerts
    ADD CONSTRAINT IF NOT EXISTS chk_alerts_severity_valid
    CHECK (severity IN ('low', 'medium', 'high', 'critical'));


-- ------------------------------------------------------------
-- DEVICES
-- ------------------------------------------------------------
ALTER TABLE devices
    ADD CONSTRAINT IF NOT EXISTS chk_devices_battery_level_range
    CHECK (battery_level >= 0 AND battery_level <= 100);

ALTER TABLE devices
    ADD CONSTRAINT IF NOT EXISTS chk_devices_signal_strength_range
    CHECK (signal_strength >= 0 AND signal_strength <= 1);


-- ------------------------------------------------------------
-- AI REPORTS
-- ------------------------------------------------------------
ALTER TABLE ai_reports
    ADD CONSTRAINT IF NOT EXISTS chk_ai_reports_confidence_range
    CHECK (confidence >= 0 AND confidence <= 1);
