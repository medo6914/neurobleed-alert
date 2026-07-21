import pytest

pytestmark = pytest.mark.migration


class TestMigrationUpgrade:
    async def test_upgrade_and_downgrade(self):
        from alembic.config import Config
        from alembic.script import ScriptDirectory
        from alembic.migration import MigrationContext
        from sqlalchemy import create_engine

        engine = create_engine("sqlite://", echo=False)
        alembic_cfg = Config()
        alembic_cfg.set_main_option("script_location", "alembic")
        alembic_cfg.set_main_option("sqlalchemy.url", "sqlite://")

        script = ScriptDirectory.from_config(alembic_cfg)
        heads = script.get_heads()
        assert len(heads) >= 1, "No migration heads found"

        with engine.begin() as conn:
            mc = MigrationContext.configure(conn)
            current_rev = mc.get_current_revision()
            assert current_rev is None

    @pytest.mark.skip(reason="PostgreSQL-specific ALTER CONSTRAINT not supported on SQLite")
    async def test_upgrade_creates_tables(self):
        from alembic.config import Config
        from alembic import command
        from sqlalchemy import create_engine, inspect

        engine = create_engine("sqlite://", echo=False)
        alembic_cfg = Config()
        alembic_cfg.set_main_option("script_location", "alembic")
        alembic_cfg.set_main_option("sqlalchemy.url", "sqlite://")
        command.upgrade(alembic_cfg, "head")

        inspector = inspect(engine)
        tables = inspector.get_table_names()
        essential = {"hospitals", "users", "patients", "alerts", "sensor_readings"}
        missing = essential - set(tables)
        assert not missing, f"Migration missing tables: {missing}"

    @pytest.mark.skip(reason="PostgreSQL-specific ALTER CONSTRAINT not supported on SQLite")
    async def test_downgrade_removes_tables(self):
        from alembic.config import Config
        from alembic import command
        from sqlalchemy import create_engine, inspect

        engine = create_engine("sqlite://", echo=False)
        alembic_cfg = Config()
        alembic_cfg.set_main_option("script_location", "alembic")
        alembic_cfg.set_main_option("sqlalchemy.url", "sqlite://")
        command.upgrade(alembic_cfg, "head")
        command.downgrade(alembic_cfg, "-1")

        inspector = inspect(engine)
        inspector.get_table_names()

    @pytest.mark.skip(reason="PostgreSQL-specific ALTER CONSTRAINT not supported on SQLite")
    async def test_upgrade_is_idempotent(self):
        from alembic.config import Config
        from alembic import command
        from sqlalchemy import create_engine, inspect

        engine = create_engine("sqlite://", echo=False)
        alembic_cfg = Config()
        alembic_cfg.set_main_option("script_location", "alembic")
        alembic_cfg.set_main_option("sqlalchemy.url", "sqlite://")
        command.upgrade(alembic_cfg, "head")
        tables_before = set(inspect(engine).get_table_names())
        command.upgrade(alembic_cfg, "head")
        tables_after = set(inspect(engine).get_table_names())
        assert tables_before == tables_after, "Upgrade is not idempotent"

    @pytest.mark.skip(reason="PostgreSQL-specific ALTER CONSTRAINT not supported on SQLite")
    async def test_downgrade_all_the_way(self):
        from alembic.config import Config
        from alembic import command
        from sqlalchemy import create_engine, inspect

        engine = create_engine("sqlite://", echo=False)
        alembic_cfg = Config()
        alembic_cfg.set_main_option("script_location", "alembic")
        alembic_cfg.set_main_option("sqlalchemy.url", "sqlite://")
        command.upgrade(alembic_cfg, "head")

        from alembic.script import ScriptDirectory
        script = ScriptDirectory.from_config(alembic_cfg)
        revisions = list(script.walk_revisions("base", "heads"))
        for _ in revisions:
            command.downgrade(alembic_cfg, "-1")

        tables = inspect(engine).get_table_names()
        assert len(tables) == 0, "Not all tables dropped after full downgrade"
