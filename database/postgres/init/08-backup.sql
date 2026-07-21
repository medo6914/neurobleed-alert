-- ============================================================
-- BACKUP & RECOVERY CONFIGURATION
-- PostgreSQL 15+ settings for WAL archiving, replication,
-- and backup retention policies.
-- ============================================================


-- ------------------------------------------------------------
-- WAL ARCHIVING
-- ------------------------------------------------------------

-- Enable WAL archiving (requires server restart or pg_reload_conf())
ALTER SYSTEM SET wal_level = 'replica';
ALTER SYSTEM SET archive_mode = 'on';
ALTER SYSTEM SET archive_command = 'cp %p /var/lib/postgresql/archive/%f';
ALTER SYSTEM SET archive_timeout = '300';         -- 5 minutes
ALTER SYSTEM SET max_wal_senders = '10';          -- for up to 10 replicas
ALTER SYSTEM SET wal_keep_size = '1024';          -- MB to keep for replicas
ALTER SYSTEM SET min_wal_size = '2GB';
ALTER SYSTEM SET max_wal_size = '8GB';


-- ------------------------------------------------------------
-- REPLICATION (pg_hba.conf template)
-- ------------------------------------------------------------

-- Add these entries to pg_hba.conf for replication:
--
-- # Allow replication connections from standby servers
-- host    replication     replicator      10.0.0.0/8             scram-sha-256
-- host    replication     replicator      172.16.0.0/12          scram-sha-256
--
-- Create the replication user (run as superuser):
-- CREATE ROLE replicator WITH LOGIN REPLICATION PASSWORD '<strong_password>';


-- ------------------------------------------------------------
-- BACKUP RETENTION POLICIES
-- ------------------------------------------------------------

-- Create backup metadata table for tracking backup history
CREATE TABLE IF NOT EXISTS backup_catalog (
    id              BIGSERIAL PRIMARY KEY,
    backup_type     TEXT NOT NULL CHECK (backup_type IN ('full', 'incremental', 'wal')),
    backup_label    TEXT,
    backup_file     TEXT NOT NULL,
    file_size_bytes BIGINT,
    checksum        TEXT,
    started_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at    TIMESTAMPTZ,
    status          TEXT NOT NULL DEFAULT 'running' CHECK (status IN ('running', 'completed', 'failed')),
    pg_version      TEXT,
    notes           TEXT
);

COMMENT ON TABLE backup_catalog IS 'Tracks all backups for retention management';

-- Retention policy function: keeps last 7 daily full backups,
-- 30 daily incremental backups, and 90 days of WAL archives.
CREATE OR REPLACE FUNCTION enforce_backup_retention()
RETURNS TABLE (
    deleted_backups   BIGINT,
    freed_space_bytes BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_deleted BIGINT := 0;
    v_freed   BIGINT := 0;
    v_file    TEXT;
BEGIN
    -- Delete full backups older than 7 days beyond the most recent 7
    FOR v_file IN
        SELECT bc.backup_file
        FROM backup_catalog bc
        WHERE bc.backup_type = 'full'
          AND bc.status = 'completed'
          AND bc.completed_at < COALESCE(
                (SELECT MIN(x.completed_at)
                 FROM (
                     SELECT bc2.completed_at
                     FROM backup_catalog bc2
                     WHERE bc2.backup_type = 'full'
                       AND bc2.status = 'completed'
                     ORDER BY bc2.completed_at DESC
                     LIMIT 7
                 ) x
                ),
                NOW()
              )
    LOOP
        BEGIN
            v_deleted := v_deleted + 1;
            DELETE FROM backup_catalog WHERE backup_file = v_file AND backup_type = 'full';
        EXCEPTION WHEN OTHERS THEN
            CONTINUE;
        END;
    END LOOP;

    -- Delete incremental backups older than 30 days
    DELETE FROM backup_catalog
    WHERE backup_type = 'incremental'
      AND status = 'completed'
      AND completed_at < NOW() - INTERVAL '30 days';

    v_deleted := v_deleted + ROW_COUNT;

    -- Delete WAL archive records older than 90 days
    DELETE FROM backup_catalog
    WHERE backup_type = 'wal'
      AND status = 'completed'
      AND completed_at < NOW() - INTERVAL '90 days';

    v_deleted := v_deleted + ROW_COUNT;

    RETURN QUERY SELECT v_deleted, v_freed;
END;
$$;

COMMENT ON FUNCTION enforce_backup_retention() IS 'Removes outdated backup records per retention policy';


-- ------------------------------------------------------------
-- RECOVERY PROCEDURE TEMPLATE
-- ------------------------------------------------------------

COMMENT ON FUNCTION enforce_backup_retention() IS E'
Recovery procedure:
1. Stop PostgreSQL: pg_ctl stop
2. Restore base backup from archive to data directory
3. Restore WAL archive files
4. Create recovery.signal file
5. Configure restore_command in postgresql.conf:
   restore_command = ''cp /var/lib/postgresql/archive/%f %p''
6. Start PostgreSQL: pg_ctl start
7. Verify recovery with: SELECT pg_is_in_recovery();
';
