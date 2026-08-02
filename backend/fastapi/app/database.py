import asyncio
import sys

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase

from app.config import settings

if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())


_url = settings.DATABASE_URL
if _url and _url.startswith("sqlite"):
    engine = create_async_engine(_url, echo=False)
else:
    engine = create_async_engine(_url, echo=False, pool_size=10, max_overflow=20)

async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


async def get_db():
    async with async_session() as session:
        try:
            yield session
        finally:
            await session.close()


async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        if _url and _url.startswith("postgresql"):
            await conn.execute(
                text(
                    "ALTER TABLE hospitals ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;"
                    "ALTER TABLE hospitals ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;"
                    "ALTER TABLE devices ADD COLUMN IF NOT EXISTS fcm_token TEXT;"
                )
            )
        elif _url and _url.startswith("sqlite"):
            for table, column, ddl in (
                ("hospitals", "latitude", "ALTER TABLE hospitals ADD COLUMN latitude REAL"),
                ("hospitals", "longitude", "ALTER TABLE hospitals ADD COLUMN longitude REAL"),
                ("devices", "fcm_token", "ALTER TABLE devices ADD COLUMN fcm_token TEXT"),
            ):
                has = await conn.execute(
                    text(f"SELECT COUNT(*) FROM pragma_table_info('{table}') WHERE name = '{column}'")
                )
                if has.scalar() == 0:
                    await conn.execute(text(ddl))
