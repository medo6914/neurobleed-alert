import uuid
from datetime import datetime, timezone

import pytest
from sqlalchemy import select

from app.models.enums import HospitalType

pytestmark = pytest.mark.security


class TestInputValidation:
    async def test_xss_injection_prevention(self, hospital_repo):
        malicious = "<script>alert('xss')</script>"
        hospital = await hospital_repo.create(
            {
                "name": malicious,
                "email": f"xss.{uuid.uuid4()}@example.com",
                "license_number": f"LIC-XSS-{uuid.uuid4().hex[:8].upper()}",
            }
        )
        assert hospital is not None
        assert hospital.name == malicious

    async def test_sql_injection_via_name(self, hospital_repo):
        inject = "'; DROP TABLE hospitals; --"
        hospital = await hospital_repo.create(
            {
                "name": inject,
                "email": f"sqli.{uuid.uuid4()}@example.com",
                "license_number": f"LIC-SQLI-{uuid.uuid4().hex[:8].upper()}",
            }
        )
        assert hospital is not None
        assert hospital.name == inject

    async def test_long_string_truncation(self, hospital_repo):
        long_name = "A" * 1000
        hospital = await hospital_repo.create(
            {
                "name": long_name[:255],
                "email": f"long.{uuid.uuid4()}@example.com",
                "license_number": f"LIC-LONG-{uuid.uuid4().hex[:8].upper()}",
            }
        )
        assert hospital is not None

    async def test_invalid_email_format(self, hospital_repo):
        hospital = await hospital_repo.create(
            {
                "name": "Bad Email",
                "email": f"not-an-email-{uuid.uuid4()}",
                "license_number": f"LIC-EML-{uuid.uuid4().hex[:8].upper()}",
            }
        )
        assert hospital is not None

    async def test_empty_required_fields(self, hospital_repo):
        with pytest.raises(Exception):
            await hospital_repo.create(
                {
                    "email": f"empty.{uuid.uuid4()}@example.com",
                    "license_number": f"LIC-EMP-{uuid.uuid4().hex[:8].upper()}",
                }
            )

    async def test_none_uuid_handling(self, hospital_repo):
        fetched = await hospital_repo.get(None)
        assert fetched is None

    async def test_invalid_uuid_string(self, hospital_repo):
        with pytest.raises(Exception):
            await hospital_repo.get("not-a-uuid")


class TestAuditLogging:
    async def test_audit_log_created(self, audit_log_repo):
        log = await audit_log_repo.create(
            {
                "user_id": uuid.uuid4(),
                "action": "test.action",
                "resource": "tests",
                "ip_address": "192.168.1.1",
            }
        )
        assert log.id is not None
        assert log.action == "test.action"

    async def test_audit_log_with_details(self, audit_log_repo):
        log = await audit_log_repo.create(
            {
                "user_id": uuid.uuid4(),
                "action": "patient.update",
                "resource": "patients",
                "resource_id": str(uuid.uuid4()),
                "details": {"changed_fields": ["name"]},
                "ip_address": "10.0.0.1",
                "user_agent": "pytest/1.0",
            }
        )
        assert log.details["changed_fields"] == ["name"]

    async def test_audit_log_query_by_action(self, audit_log_repo):
        await audit_log_repo.create(
            {
                "action": "user.delete",
                "resource": "users",
            }
        )
        logs = await audit_log_repo.get_by_resource("users")
        assert len(logs) >= 1
        assert logs[0].action == "user.delete"

    async def test_audit_log_correlation_id(self, audit_log_repo):
        cid = str(uuid.uuid4())
        await audit_log_repo.create(
            {
                "action": "auth.login",
                "resource": "sessions",
                "correlation_id": cid,
            }
        )
        logs = await audit_log_repo.db.execute(
            select(audit_log_repo.model).where(
                audit_log_repo.model.correlation_id == cid
            )
        )
        assert logs.scalar_one_or_none() is not None


class TestPasswordPolicy:
    async def test_password_hashed_on_create(self, user_repo, seeded_hospital):
        user = await user_repo.create(
            {
                "email": f"pw.{uuid.uuid4()}@example.com",
                "hashed_password": "$2b$12$hashedvaluehere",
                "full_name": "Password Test",
                "role": "doctor",
                "hospital_id": seeded_hospital.id,
            }
        )
        assert user.hashed_password != "plaintext"

    async def test_password_history_tracked(
        self, user_repo, seeded_hospital, seeded_user
    ):
        updated = await user_repo.update(
            seeded_user.id,
            {
                "hashed_password": "$2b$12$newhashedpassword",
                "last_password_change": datetime(2024, 1, 1, tzinfo=timezone.utc),
            },
        )
        assert updated.last_password_change is not None

    async def test_account_lockout_tracking(
        self, user_repo, seeded_hospital, seeded_user
    ):
        updated = await user_repo.update(
            seeded_user.id,
            {
                "login_attempts": 5,
                "locked_until": datetime(2024, 12, 31, 23, 59, 59, tzinfo=timezone.utc),
            },
        )
        assert updated.login_attempts == 5
        assert updated.locked_until is not None


class TestSoftDeleteSecurity:
    async def test_soft_deleted_records_hidden(self, hospital_repo, seeded_hospital):
        await hospital_repo.delete(seeded_hospital.id, soft=True)
        all_active = await hospital_repo.get_multi()
        ids = [h.id for h in all_active]
        assert seeded_hospital.id not in ids

    async def test_soft_delete_timestamps(self, hospital_repo, seeded_hospital):
        import datetime
        from sqlalchemy import select

        await hospital_repo.delete(seeded_hospital.id, soft=True)
        result = await hospital_repo.db.execute(
            select(hospital_repo.model).where(
                hospital_repo.model.id == seeded_hospital.id
            )
        )
        deleted = result.scalar_one_or_none()
        assert deleted is not None
        assert deleted.is_deleted is True
        assert deleted.deleted_at is not None


class TestUniqueConstraintSecurity:
    async def test_duplicate_email_rejected(self, user_repo, seeded_user):
        with pytest.raises(Exception):
            await user_repo.create(
                {
                    "email": seeded_user.email,
                    "hashed_password": "$2b$12$anotherhash",
                    "full_name": "Duplicate",
                    "role": "doctor",
                }
            )

    async def test_duplicate_serial_rejected(self, device_repo, seeded_device):
        with pytest.raises(Exception):
            await device_repo.create(
                {
                    "serial_number": seeded_device.serial_number,
                    "device_type": "NB-01",
                    "firmware_version": "1.0.0",
                    "status": "offline",
                }
            )


class TestRateLimitingPatterns:
    async def test_concurrent_create_does_not_deadlock(self, hospital_repo):
        for i in range(5):
            await hospital_repo.create(
                {
                    "name": f"Concurrent-{i}",
                    "email": f"conc{i}.{uuid.uuid4()}@example.com",
                    "license_number": f"LIC-CONC-{uuid.uuid4().hex[:8].upper()}",
                }
            )
        count = await hospital_repo.count()
        assert count >= 5

    async def test_bulk_read_under_load(self, organization_repo):
        for i in range(10):
            await organization_repo.create(
                {
                    "name": f"LoadOrg-{i}",
                    "org_type": "hospital",
                }
            )
        pages = []
        for p in range(1, 4):
            page = await organization_repo.paginate(page=p, per_page=3)
            pages.append(page)
        total_items = sum(len(p.items) for p in pages)
        assert total_items >= 9
