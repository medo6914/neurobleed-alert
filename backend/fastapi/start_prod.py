import asyncio
import subprocess
import sys
import os

async def reset_and_start():
    url = os.environ.get("DATABASE_URL", "")
    if not url:
        print("No DATABASE_URL, skipping reset")
        return

    if url.startswith("postgresql://"):
        url = url.replace("postgresql://", "postgresql+asyncpg://", 1)

    print("Resetting database schema...")
    from sqlalchemy.ext.asyncio import create_async_engine
    from sqlalchemy import text
    engine = create_async_engine(url)
    async with engine.connect() as conn:
        await conn.execute(text("DROP SCHEMA public CASCADE; CREATE SCHEMA public;"))
        await conn.commit()
    await engine.dispose()
    print("DB reset complete")

    subprocess.run(["alembic", "upgrade", "head"], check=True)
    subprocess.run([sys.executable, "-m", "app.seed_data"], check=True)
    subprocess.run([
        sys.executable, "-m", "uvicorn", "app.main:app",
        "--host", "0.0.0.0",
        "--port", os.environ.get("PORT", "8000")
    ], check=True)

asyncio.run(reset_and_start())
