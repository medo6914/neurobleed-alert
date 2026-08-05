"""Run Alembic migrations at application startup (idempotent)."""

import logging
import os
import subprocess
import sys
from pathlib import Path

logger = logging.getLogger(__name__)

_BACKEND_DIR = Path(__file__).resolve().parents[2]


def run_migrations() -> bool:
    """Run `alembic upgrade head` in the backend directory. Returns True on success."""
    try:
        result = subprocess.run(
            [sys.executable, "-m", "alembic", "upgrade", "head"],
            cwd=str(_BACKEND_DIR),
            capture_output=True,
            text=True,
            timeout=300,
        )
        if result.returncode == 0:
            logger.info("Alembic migrations applied successfully")
            return True
        logger.error(
            "Alembic migration failed: %s",
            result.stderr.strip() or result.stdout.strip(),
        )
        return False
    except Exception as e:
        logger.error("Alembic migration run error: %s", e)
        return False


def migrations_pending() -> bool:
    try:
        result = subprocess.run(
            [sys.executable, "-m", "alembic", "current"],
            cwd=str(_BACKEND_DIR),
            capture_output=True,
            text=True,
            timeout=120,
        )
        return result.returncode != 0
    except Exception:
        return False
