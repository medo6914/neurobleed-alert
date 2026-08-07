import asyncio
import subprocess
import sys
import os

def run_cmd(cmd):
    result = subprocess.run(cmd)
    return result.returncode == 0

async def setup_db():
    from sqlalchemy.ext.asyncio import create_async_engine
    from app.database import Base
    import app.models
    from app.config import settings

    url = settings.DATABASE_URL
    if url and url.startswith("postgresql://"):
        url = url.replace("postgresql://", "postgresql+asyncpg://", 1)

    print("Resetting DB schema...")
    engine = create_async_engine(url)
    async with engine.connect() as conn:
        await conn.execute(__import__('sqlalchemy').text("DROP SCHEMA public CASCADE"))
        await conn.execute(__import__('sqlalchemy').text("CREATE SCHEMA public"))
        await conn.commit()
    await engine.dispose()
    print("DB reset complete")

    print("Creating tables from models...")
    engine2 = create_async_engine(url)
    async with engine2.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    await engine2.dispose()
    print("Tables created successfully")

async def main():
    port = os.environ.get("PORT", "8000")
    await setup_db()
    run_cmd([sys.executable, "-m", "app.seed_data"])
    os.execvp(sys.executable, [
        sys.executable, "-m", "uvicorn", "app.main:app",
        "--host", "0.0.0.0",
        "--port", port
    ])

asyncio.run(main())
