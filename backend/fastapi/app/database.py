import asyncio
import sys

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase

from app.config import settings

if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())


_url = settings.DATABASE_URL

if _url.startswith("postgresql"):
    if not _url.startswith("postgresql+asyncpg"):
        _url = _url.replace("postgresql://", "postgresql+asyncpg://", 1)
    engine = create_async_engine(
        _url,
        echo=False,
        pool_size=10,
        max_overflow=20,
        pool_pre_ping=True,
        pool_recycle=1800,
        pool_timeout=30,
    )
elif _url.startswith("sqlite"):
    engine = create_async_engine(_url, echo=False)
else:
    raise RuntimeError(f"Unsupported DATABASE_URL scheme: {_url.split('://')[0]}")

async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


async def get_db():
    async with async_session() as session:
        try:
            yield session
        finally:
            await session.close()


async def check_database() -> bool:
    """Verify live connectivity by executing SELECT 1."""
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        return True
    except Exception:
        return False


async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        if _url.startswith("postgresql"):
            for stmt in [
                "ALTER TABLE hospitals ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION",
                "ALTER TABLE hospitals ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION",
                "ALTER TABLE devices ADD COLUMN IF NOT EXISTS fcm_token TEXT",
            ]:
                await conn.execute(text(stmt))
        elif _url.startswith("sqlite"):
            for table, column, ddl in (
                (
                    "hospitals",
                    "latitude",
                    "ALTER TABLE hospitals ADD COLUMN latitude REAL",
                ),
                (
                    "hospitals",
                    "longitude",
                    "ALTER TABLE hospitals ADD COLUMN longitude REAL",
                ),
                (
                    "devices",
                    "fcm_token",
                    "ALTER TABLE devices ADD COLUMN fcm_token TEXT",
                ),
            ):
                has = await conn.execute(
                    text(
                        f"SELECT COUNT(*) FROM pragma_table_info('{table}') WHERE name = '{column}'"
                    )
                )
                if has.scalar() == 0:
                    await conn.execute(text(ddl))
