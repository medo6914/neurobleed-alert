-- ============================================================
-- PRODUCTION PERFORMANCE TUNING
-- Settings for 1M+ user tier, NeuroBleed Alert workload.
-- Apply via: pg_ctl reload  OR  SELECT pg_reload_conf();
-- ============================================================

-- Connections & Memory
ALTER SYSTEM SET max_connections = '200';
ALTER SYSTEM SET shared_buffers = '2GB';
ALTER SYSTEM SET effective_cache_size = '6GB';
ALTER SYSTEM SET maintenance_work_mem = '512MB';
ALTER SYSTEM SET work_mem = '32MB';
ALTER SYSTEM SET temp_buffers = '32MB';

-- Checkpoint Tuning
ALTER SYSTEM SET checkpoint_completion_target = '0.95';
ALTER SYSTEM SET checkpoint_timeout = '15min';
ALTER SYSTEM SET max_wal_size = '8GB';
ALTER SYSTEM SET min_wal_size = '2GB';
ALTER SYSTEM SET wal_buffers = '64MB';

-- I/O Concurrency
ALTER SYSTEM SET effective_io_concurrency = '200';
ALTER SYSTEM SET random_page_cost = '1.1';
ALTER SYSTEM SET parallel_setup_cost = '100';
ALTER SYSTEM SET parallel_tuple_cost = '0.1';
ALTER SYSTEM SET max_parallel_workers_per_gather = '4';
ALTER SYSTEM SET max_parallel_workers = '8';
ALTER SYSTEM SET max_worker_processes = '16';

-- Planner / Optimizer
ALTER SYSTEM SET default_statistics_target = '500';
ALTER SYSTEM SET from_collapse_limit = '8';
ALTER SYSTEM SET join_collapse_limit = '8';
ALTER SYSTEM SET plan_cache_mode = 'force_custom_plan';

-- Statement Timeouts
ALTER SYSTEM SET statement_timeout = '30000';
ALTER SYSTEM SET idle_in_transaction_session_timeout = '60000';
ALTER SYSTEM SET lock_timeout = '15000';

-- Autovacuum (high-volume tables: sensor_readings, alerts, audit_logs)
ALTER SYSTEM SET autovacuum = 'on';
ALTER SYSTEM SET autovacuum_max_workers = '5';
ALTER SYSTEM SET autovacuum_naptime = '30s';
ALTER SYSTEM SET autovacuum_vacuum_threshold = '500';
ALTER SYSTEM SET autovacuum_vacuum_scale_factor = '0.01';
ALTER SYSTEM SET autovacuum_vacuum_cost_limit = '2000';
ALTER SYSTEM SET autovacuum_vacuum_cost_delay = '10';
ALTER SYSTEM SET autovacuum_freeze_max_age = '200000000';

-- WAL & Replication
ALTER SYSTEM SET wal_level = 'replica';
ALTER SYSTEM SET max_wal_senders = '10';
ALTER SYSTEM SET wal_keep_size = '1024';
ALTER SYSTEM SET archive_mode = 'on';
ALTER SYSTEM SET archive_timeout = '300';

-- Per-table autovacuum overrides for high-volume tables
-- These are applied as comments — run individually per table:
--
-- ALTER TABLE sensor_readings SET (autovacuum_vacuum_scale_factor = 0.005, autovacuum_analyze_scale_factor = 0.002, autovacuum_vacuum_cost_limit = 1000);
-- ALTER TABLE alerts SET (autovacuum_vacuum_scale_factor = 0.01, autovacuum_analyze_scale_factor = 0.005, autovacuum_vacuum_cost_limit = 500);
-- ALTER TABLE audit_logs SET (autovacuum_vacuum_scale_factor = 0.01, autovacuum_analyze_scale_factor = 0.005, autovacuum_vacuum_cost_limit = 500);
