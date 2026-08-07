import asyncio
import subprocess
import sys
import os

def run_cmd(cmd):
    result = subprocess.run(cmd)
    return result.returncode == 0

async def reset_and_start():
    port = os.environ.get("PORT", "8000")

    url = os.environ.get("DATABASE_URL", "")
    if url:
        if url.startswith("postgresql://"):
            url = url.replace("postgresql://", "postgresql+asyncpg://", 1)
        print("Trying alembic migration...")
        if not run_cmd(["alembic", "upgrade", "head"]):
            print("Migration failed, resetting DB schema...")
            from sqlalchemy.ext.asyncio import create_async_engine
            from sqlalchemy import text
            engine = create_async_engine(url)
            async with engine.connect() as conn:
                await conn.execute(text("DROP SCHEMA public CASCADE; CREATE SCHEMA public;"))
                await conn.commit()
            await engine.dispose()
            print("DB reset complete, re-running migration...")
            if not run_cmd(["alembic", "upgrade", "head"]):
                print("ERROR: Migration still failed after reset")
                sys.exit(1)

    run_cmd([sys.executable, "-m", "app.seed_data"])
    os.execvp(sys.executable, [
        sys.executable, "-m", "uvicorn", "app.main:app",
        "--host", "0.0.0.0",
        "--port", port
    ])

asyncio.run(reset_and_start())
