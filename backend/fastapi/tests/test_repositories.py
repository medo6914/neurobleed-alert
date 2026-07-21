import uuid
from datetime import date, datetime, timedelta, timezone

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.enums import (
    HospitalType, UserRole, Gender, BloodType, RiskLevel,
    Severity, AlertType, DeviceType, DeviceStatus, ReportType,
    OrganizationType, KnowledgeUpdateAction,
)
from app.repositories.repositories import (
    AIReportRepository,
    AlertRepository,
    DepartmentRepository,
    DeviceRepository,
    KnowledgeBaseRepository,
    KnowledgeUpdateLogRepository,
    OrganizationRepository,
    PatientRepository,
    PermissionRepository,
    RefreshTokenRepository,
    RoleRepository,
    SessionRepository,
    SensorReadingRepository,
    UserRepository,
)


class TestHospitalRepository:
    async def test_create(self, hospital_repo):
        hospital = await hospital_repo.create({
            "name": "City Hospital",
            "email": f"city.{uuid.uuid4()}@example.com",
            "license_number": f"LIC-{uuid.uuid4().hex[:8].upper()}",
            "hospital_type": HospitalType.GENERAL,
        })
        assert hospital.id is not None
        assert hospital.name == "City Hospital"

    async def test_get(self, hospital_repo, seeded_hospital):
        fetched = await hospital_repo.get(seeded_hospital.id)
        assert fetched is not None
        assert fetched.id == seeded_hospital.id

    async def test_get_not_found(self, hospital_repo):
        fetched = await hospital_repo.get(uuid.uuid4())
        assert fetched is None

    async def test_update(self, hospital_repo, seeded_hospital):
        updated = await hospital_repo.update(seeded_hospital.id, {"name": "Updated Hospital"})
        assert updated is not None
        assert updated.name == "Updated Hospital"

    async def test_update_not_found(self, hospital_repo):
        updated = await hospital_repo.update(uuid.uuid4(), {"name": "Nope"})
        assert updated is None

    async def test_soft_delete(self, hospital_repo, seeded_hospital):
        deleted = await hospital_repo.delete(seeded_hospital.id, soft=True)
        assert deleted is True
        fetched = await hospital_repo.get(seeded_hospital.id)
        assert fetched is None
        fetched_include = await hospital_repo.db.execute(
            select(hospital_repo.model).where(hospital_repo.model.id == seeded_hospital.id)
        )
        obj = fetched_include.scalar_one_or_none()
        assert obj is not None
        assert obj.is_deleted is True

    async def test_hard_delete(self, hospital_repo, seeded_hospital):
        deleted = await hospital_repo.delete(seeded_hospital.id, soft=False)
        assert deleted is True
        fetched = await hospital_repo.get(seeded_hospital.id)
        assert fetched is None

    async def test_delete_not_found(self, hospital_repo):
        assert await hospital_repo.delete(uuid.uuid4()) is False

    async def test_count(self, hospital_repo, seeded_hospital):
        count = await hospital_repo.count()
        assert count >= 1

    async def test_exists(self, hospital_repo, seeded_hospital):
        assert await hospital_repo.exists(seeded_hospital.id) is True
        assert await hospital_repo.exists(uuid.uuid4()) is False

    async def test_get_multi(self, hospital_repo, seeded_hospital):
        hospitals = await hospital_repo.get_multi()
        assert len(hospitals) >= 1

    async def test_paginate(self, hospital_repo, seeded_hospital):
        page = await hospital_repo.paginate(page=1, per_page=10)
        assert page.total >= 1
        assert page.page == 1
        assert page.per_page == 10
        assert page.total_pages >= 1

    async def test_cursor_paginate(self, hospital_repo, seeded_hospital):
        cursor_page = await hospital_repo.cursor_paginate(limit=10)
        assert cursor_page.total >= 1
        assert len(cursor_page.items) >= 1

    async def test_unique_email_constraint(self, hospital_repo, seeded_hospital):
        with pytest.raises(Exception):
            await hospital_repo.create({
                "name": "Duplicate",
                "email": seeded_hospital.email,
                "license_number": f"LIC-{uuid.uuid4().hex[:8].upper()}",
            })

    async def test_unique_license_constraint(self, hospital_repo, seeded_hospital):
        with pytest.raises(Exception):
            await hospital_repo.create({
                "name": "Duplicate",
                "email": f"dup.{uuid.uuid4()}@example.com",
                "license_number": seeded_hospital.license_number,
            })

    async def test_get_with_relations(self, hospital_repo, seeded_hospital, seeded_user):
        hospital = await hospital_repo.get_with_relations(seeded_hospital.id)
        assert hospital is not None
        assert len(hospital.users) >= 1

    async def test_empty_get_multi(self, hospital_repo):
        await hospital_repo.db.execute(
            select(hospital_repo.model).where(hospital_repo.model.id != uuid.uuid4())
        )


class TestUserRepository:
    async def test_create(self, user_repo, seeded_hospital):
        user = await user_repo.create({
            "email": f"test.{uuid.uuid4()}@example.com",
            "hashed_password": "$2b$12$hash",
            "full_name": "Test Doctor",
            "role": UserRole.DOCTOR,
            "hospital_id": seeded_hospital.id,
        })
        assert user.id is not None
        assert user.email is not None

    async def test_get_by_email(self, user_repo, seeded_user):
        fetched = await user_repo.get_by_email(seeded_user.email)
        assert fetched is not None
        assert fetched.id == seeded_user.id

    async def test_get_by_email_not_found(self, user_repo):
        fetched = await user_repo.get_by_email("nonexistent@example.com")
        assert fetched is None

    async def test_get_by_firebase_uid(self, user_repo, seeded_user):
        firebase_uid = f"fb-{uuid.uuid4().hex}"
        await user_repo.update(seeded_user.id, {"firebase_uid": firebase_uid})
        fetched = await user_repo.get_by_firebase_uid(firebase_uid)
        assert fetched is not None
        assert fetched.firebase_uid == firebase_uid

    async def test_get_user_with_roles(self, user_repo, seeded_user, role_repo, seeded_role):
        user = await user_repo.get_user_with_roles(seeded_user.id)
        assert user is not None

    async def test_unique_email(self, user_repo, seeded_user):
        with pytest.raises(Exception):
            await user_repo.create({
                "email": seeded_user.email,
                "hashed_password": "$2b$12$hash2",
                "full_name": "Duplicate",
                "role": UserRole.NURSE,
            })

    async def test_fk_hospital_constraint(self, user_repo):
        with pytest.raises(Exception):
            await user_repo.create({
                "email": f"no.hosp.{uuid.uuid4()}@example.com",
                "hashed_password": "$2b$12$hash",
                "full_name": "No Hospital",
                "role": UserRole.DOCTOR,
                "hospital_id": uuid.uuid4(),
            })

    async def test_update_user(self, user_repo, seeded_user):
        updated = await user_repo.update(seeded_user.id, {"full_name": "Updated Name"})
        assert updated.full_name == "Updated Name"

    async def test_soft_delete_user(self, user_repo, seeded_user):
        await user_repo.delete(seeded_user.id, soft=True)
        fetched = await user_repo.get(seeded_user.id)
        assert fetched is None


class TestPatientRepository:
    async def test_create(self, patient_repo, seeded_hospital):
        patient = await patient_repo.create({
            "mrn": f"MRN-{uuid.uuid4().hex[:8].upper()}",
            "full_name": "Jane Doe",
            "date_of_birth": date(1985, 5, 20),
            "gender": Gender.FEMALE,
            "hospital_id": seeded_hospital.id,
        })
        assert patient.id is not None
        assert patient.full_name == "Jane Doe"

    async def test_get_by_mrn(self, patient_repo, seeded_patient):
        fetched = await patient_repo.get_by_mrn(seeded_patient.mrn)
        assert fetched is not None
        assert fetched.id == seeded_patient.id

    async def test_search_by_name(self, patient_repo, seeded_patient):
        results = await patient_repo.search_by_name("John")
        assert len(results) >= 1

    async def test_search_by_name_no_results(self, patient_repo):
        results = await patient_repo.search_by_name("NonExistentNameXYZ")
        assert len(results) == 0

    async def test_get_patients_by_hospital(self, patient_repo, seeded_patient, seeded_hospital):
        patients = await patient_repo.get_patients_by_hospital(seeded_hospital.id)
        assert len(patients) >= 1

    async def test_unique_mrn(self, patient_repo, seeded_patient):
        with pytest.raises(Exception):
            await patient_repo.create({
                "mrn": seeded_patient.mrn,
                "full_name": "Duplicate",
                "date_of_birth": date(1990, 1, 1),
                "gender": Gender.MALE,
            })


class TestDeviceRepository:
    async def test_create(self, device_repo, seeded_hospital, seeded_patient):
        device = await device_repo.create({
            "device_name": "Monitor-01",
            "device_type": DeviceType.NB_01,
            "serial_number": f"SN-{uuid.uuid4().hex[:8].upper()}",
            "firmware_version": "1.0.0",
            "hospital_id": seeded_hospital.id,
            "patient_id": seeded_patient.id,
            "status": DeviceStatus.ONLINE,
        })
        assert device.id is not None

    async def test_get_by_serial(self, device_repo, seeded_device):
        fetched = await device_repo.get_by_serial(seeded_device.serial_number)
        assert fetched is not None

    async def test_get_devices_by_hospital(self, device_repo, seeded_device, seeded_hospital):
        devices = await device_repo.get_devices_by_hospital(seeded_hospital.id)
        assert len(devices) >= 1

    async def test_unique_serial(self, device_repo, seeded_device):
        with pytest.raises(Exception):
            await device_repo.create({
                "serial_number": seeded_device.serial_number,
                "device_type": DeviceType.NB_02,
                "firmware_version": "1.0.0",
                "status": DeviceStatus.OFFLINE,
            })

    async def test_unique_mac_address(self, device_repo, seeded_device):
        mac = "AA:BB:CC:DD:EE:FF"
        await device_repo.update(seeded_device.id, {"mac_address": mac})
        with pytest.raises(Exception):
            await device_repo.create({
                "serial_number": f"SN-{uuid.uuid4().hex[:8].upper()}",
                "mac_address": mac,
                "device_type": DeviceType.NB_01,
                "firmware_version": "1.0.0",
                "status": DeviceStatus.OFFLINE,
            })


class TestSensorReadingRepository:
    async def test_create(self, sensor_reading_repo, seeded_patient, seeded_device):
        reading = await sensor_reading_repo.create({
            "patient_id": seeded_patient.id,
            "device_id": seeded_device.id,
            "timestamp": datetime.now(timezone.utc),
            "spo2": 97.0,
            "heart_rate": 75.0,
            "rso2": 65.0,
            "risk_score": 0.05,
            "risk_level": RiskLevel.LOW,
            "signal_quality": 0.98,
            "motion_artifact": 0.01,
        })
        assert reading.id is not None

    async def test_get_readings_by_patient_range(
        self, sensor_reading_repo, seeded_sensor_reading, seeded_patient
    ):
        readings = await sensor_reading_repo.get_readings_by_patient_range(
            seeded_patient.id,
            from_date=datetime.now(timezone.utc) - timedelta(hours=1),
            to_date=datetime.now(timezone.utc) + timedelta(hours=1),
        )
        assert len(readings) >= 1

    async def test_get_readings_empty_range(self, sensor_reading_repo, seeded_patient):
        readings = await sensor_reading_repo.get_readings_by_patient_range(
            seeded_patient.id,
            from_date=datetime(2020, 1, 1),
            to_date=datetime(2020, 1, 2),
        )
        assert len(readings) == 0

    async def test_fk_patient_constraint(self, sensor_reading_repo, seeded_device):
        with pytest.raises(Exception):
            await sensor_reading_repo.create({
                "patient_id": uuid.uuid4(),
                "device_id": seeded_device.id,
                "timestamp": datetime.now(timezone.utc),
                "spo2": 98.0,
                "heart_rate": 70.0,
                "risk_level": RiskLevel.UNKNOWN,
                "signal_quality": 0.5,
                "motion_artifact": 0.0,
            })


class TestAlertRepository:
    async def test_create(self, alert_repo, seeded_patient, seeded_device, seeded_sensor_reading):
        alert = await alert_repo.create({
            "patient_id": seeded_patient.id,
            "device_id": seeded_device.id,
            "sensor_reading_id": seeded_sensor_reading.id,
            "alert_type": AlertType.DESATURATION,
            "severity": Severity.CRITICAL,
            "risk_score": 0.95,
            "message": "Critical desaturation detected",
        })
        assert alert.id is not None
        assert alert.is_acknowledged is False

    async def test_get_unacknowledged(self, alert_repo, seeded_alert):
        unacked = await alert_repo.get_unacknowledged()
        assert len(unacked) >= 1
        assert all(a.is_acknowledged is False for a in unacked)

    async def test_get_unresolved(self, alert_repo, seeded_alert):
        unresolved = await alert_repo.get_unresolved()
        assert len(unresolved) >= 1
        assert all(a.is_resolved is False for a in unresolved)

    async def test_acknowledge_alert(self, alert_repo, seeded_alert, seeded_user):
        updated = await alert_repo.update(
            seeded_alert.id,
            {"is_acknowledged": True, "acknowledged_by": seeded_user.id, "acknowledged_at": datetime.now(timezone.utc)},
        )
        assert updated.is_acknowledged is True

    async def test_resolve_alert(self, alert_repo, seeded_alert, seeded_user):
        updated = await alert_repo.update(
            seeded_alert.id,
            {"is_resolved": True, "resolved_by": seeded_user.id, "resolved_at": datetime.now(timezone.utc)},
        )
        assert updated.is_resolved is True

    async def test_fk_patient_constraint(self, alert_repo):
        with pytest.raises(Exception):
            await alert_repo.create({
                "patient_id": uuid.uuid4(),
                "alert_type": AlertType.GENERAL,
                "severity": Severity.LOW,
                "message": "Test alert",
            })


class TestAIReportRepository:
    async def test_create(self, ai_report_repo, seeded_patient):
        report = await ai_report_repo.create({
            "patient_id": seeded_patient.id,
            "report_type": ReportType.BLEEDING_DETECTION,
            "risk_score": 0.6,
            "confidence": 0.88,
            "summary": "Bleeding detected",
            "model_version": "1.0.0",
        })
        assert report.id is not None

    async def test_get_reports_by_patient(self, ai_report_repo, seeded_ai_report, seeded_patient):
        reports = await ai_report_repo.get_reports_by_patient(seeded_patient.id)
        assert len(reports) >= 1

    async def test_get_reports_empty(self, ai_report_repo):
        reports = await ai_report_repo.get_reports_by_patient(uuid.uuid4())
        assert len(reports) == 0


class TestKnowledgeBaseRepository:
    async def test_create(self, knowledge_base_repo):
        kb = await knowledge_base_repo.create({
            "title": "Test Article",
            "content": "Test content",
            "category": "general",
            "tags": ["test"],
            "is_published": True,
        })
        assert kb.id is not None

    async def test_search(self, knowledge_base_repo, seeded_knowledge_base):
        results = await knowledge_base_repo.search("ICP")
        assert len(results) >= 1

    async def test_search_no_results(self, knowledge_base_repo):
        results = await knowledge_base_repo.search("zzzznotfound")
        assert len(results) == 0

    async def test_get_by_category(self, knowledge_base_repo, seeded_knowledge_base):
        results = await knowledge_base_repo.get_by_category("protocols")
        assert len(results) >= 1

    async def test_get_by_category_empty(self, knowledge_base_repo):
        results = await knowledge_base_repo.get_by_category("nonexistent")
        assert len(results) == 0

    async def test_unpublished_excluded_from_search(self, knowledge_base_repo):
        unpublished = await knowledge_base_repo.create({
            "title": "Draft",
            "content": "Draft content",
            "category": "drafts",
            "is_published": False,
        })
        results = await knowledge_base_repo.search("Draft")
        assert len(results) == 0


class TestKnowledgeUpdateLogRepository:
    async def test_create(self, knowledge_update_log_repo, seeded_knowledge_base):
        log = await knowledge_update_log_repo.create({
            "knowledge_id": seeded_knowledge_base.id,
            "action": KnowledgeUpdateAction.CREATE,
            "source": "admin",
        })
        assert log.id is not None
        assert log.action == KnowledgeUpdateAction.CREATE

    async def test_crud_cycle(self, knowledge_update_log_repo, seeded_knowledge_base):
        created = await knowledge_update_log_repo.create({
            "knowledge_id": seeded_knowledge_base.id,
            "action": KnowledgeUpdateAction.UPDATE,
        })
        fetched = await knowledge_update_log_repo.get(created.id)
        assert fetched is not None
        await knowledge_update_log_repo.delete(created.id, soft=False)
        assert await knowledge_update_log_repo.get(created.id) is None


class TestAuditLogRepository:
    async def test_create(self, audit_log_repo):
        log = await audit_log_repo.create({
            "user_id": uuid.uuid4(),
            "action": "user.login",
            "resource": "users",
            "resource_id": str(uuid.uuid4()),
            "details": {"ip": "127.0.0.1"},
            "ip_address": "127.0.0.1",
        })
        assert log.id is not None

    async def test_get_by_user(self, audit_log_repo):
        user_id = uuid.uuid4()
        await audit_log_repo.create({
            "user_id": user_id,
            "action": "user.login",
            "resource": "users",
        })
        logs = await audit_log_repo.get_by_user(user_id)
        assert len(logs) >= 1

    async def test_get_by_resource(self, audit_log_repo):
        await audit_log_repo.create({
            "action": "patient.view",
            "resource": "patients",
            "resource_id": str(uuid.uuid4()),
        })
        logs = await audit_log_repo.get_by_resource("patients")
        assert len(logs) >= 1

    async def test_get_by_resource_with_id(self, audit_log_repo):
        resource_id = str(uuid.uuid4())
        await audit_log_repo.create({
            "action": "patient.view",
            "resource": "patients",
            "resource_id": resource_id,
        })
        logs = await audit_log_repo.get_by_resource("patients", resource_id=resource_id)
        assert len(logs) >= 1

    async def test_empty_results(self, audit_log_repo):
        logs = await audit_log_repo.get_by_user(uuid.uuid4())
        assert len(logs) == 0


class TestRoleRepository:
    async def test_create(self, role_repo):
        role = await role_repo.create({
            "name": f"role_{uuid.uuid4().hex[:8]}",
            "description": "Test role",
            "is_system": False,
        })
        assert role.id is not None

    async def test_get_by_name(self, role_repo, seeded_role):
        fetched = await role_repo.get_by_name(seeded_role.name)
        assert fetched is not None

    async def test_get_by_name_not_found(self, role_repo):
        assert await role_repo.get_by_name("nonexistent_role") is None

    async def test_get_with_permissions(self, role_repo, seeded_role, permission_repo, seeded_permission):
        fetch_perms = await permission_repo.get(seeded_permission.id)
        role = await role_repo.get_with_permissions(seeded_role.id)
        assert role is not None

    async def test_unique_name_constraint(self, role_repo, seeded_role):
        with pytest.raises(Exception):
            await role_repo.create({"name": seeded_role.name})


class TestPermissionRepository:
    async def test_create(self, permission_repo):
        perm = await permission_repo.create({
            "codename": f"test.{uuid.uuid4().hex[:8]}",
            "name": "Test Permission",
            "resource": "tests",
        })
        assert perm.id is not None

    async def test_get_by_codename(self, permission_repo, seeded_permission):
        fetched = await permission_repo.get_by_codename(seeded_permission.codename)
        assert fetched is not None

    async def test_get_by_codename_not_found(self, permission_repo):
        assert await permission_repo.get_by_codename("nonexistent") is None

    async def test_unique_codename_constraint(self, permission_repo, seeded_permission):
        with pytest.raises(Exception):
            await permission_repo.create({
                "codename": seeded_permission.codename,
                "name": "Duplicate",
                "resource": "patients",
            })


class TestSessionRepository:
    async def test_create(self, session_repo, seeded_user):
        session = await session_repo.create({
            "user_id": seeded_user.id,
            "token_hash": f"token_{uuid.uuid4().hex}",
            "is_active": True,
            "expires_at": datetime.now(timezone.utc) + timedelta(hours=24),
        })
        assert session.id is not None

    async def test_get_active_user_sessions(self, session_repo, seeded_user):
        await session_repo.create({
            "user_id": seeded_user.id,
            "token_hash": f"active_{uuid.uuid4().hex}",
            "is_active": True,
            "expires_at": datetime.now(timezone.utc) + timedelta(hours=24),
        })
        active = await session_repo.get_active_user_sessions(seeded_user.id)
        assert len(active) >= 1
        assert all(s.is_active for s in active)

    async def test_invalidate_session(self, session_repo, seeded_user):
        session = await session_repo.create({
            "user_id": seeded_user.id,
            "token_hash": f"inv_{uuid.uuid4().hex}",
            "is_active": True,
            "expires_at": datetime.now(timezone.utc) + timedelta(hours=24),
        })
        result = await session_repo.invalidate_session(session.id)
        assert result is True
        fetched = await session_repo.get(session.id)
        assert fetched.is_active is False

    async def test_invalidate_session_not_found(self, session_repo):
        assert await session_repo.invalidate_session(uuid.uuid4()) is False


class TestRefreshTokenRepository:
    async def test_create(self, refresh_token_repo, seeded_user):
        token = await refresh_token_repo.create({
            "user_id": seeded_user.id,
            "token_hash": f"rt_{uuid.uuid4().hex}",
            "is_revoked": False,
            "expires_at": datetime.now(timezone.utc) + timedelta(days=30),
        })
        assert token.id is not None

    async def test_get_by_token_hash(self, refresh_token_repo, seeded_user):
        token_hash = f"rt_{uuid.uuid4().hex}"
        await refresh_token_repo.create({
            "user_id": seeded_user.id,
            "token_hash": token_hash,
            "is_revoked": False,
            "expires_at": datetime.now(timezone.utc) + timedelta(days=30),
        })
        fetched = await refresh_token_repo.get_by_token_hash(token_hash)
        assert fetched is not None
        assert fetched.token_hash == token_hash

    async def test_revoke_token(self, refresh_token_repo, seeded_user):
        token = await refresh_token_repo.create({
            "user_id": seeded_user.id,
            "token_hash": f"rt_revoke_{uuid.uuid4().hex}",
            "is_revoked": False,
            "expires_at": datetime.now(timezone.utc) + timedelta(days=30),
        })
        result = await refresh_token_repo.revoke_token(token.id)
        assert result is True
        fetched = await refresh_token_repo.get(token.id)
        assert fetched.is_revoked is True

    async def test_revoke_token_not_found(self, refresh_token_repo):
        assert await refresh_token_repo.revoke_token(uuid.uuid4()) is False


class TestDepartmentRepository:
    async def test_create(self, department_repo, seeded_hospital):
        dept = await department_repo.create({
            "name": "Neurology",
            "description": "Neurology department",
            "hospital_id": seeded_hospital.id,
        })
        assert dept.id is not None
        assert dept.name == "Neurology"

    async def test_crud_cycle(self, department_repo, seeded_hospital):
        created = await department_repo.create({
            "name": "Cardiology",
            "hospital_id": seeded_hospital.id,
        })
        fetched = await department_repo.get(created.id)
        assert fetched is not None
        updated = await department_repo.update(created.id, {"name": "Cardiology Updated"})
        assert updated.name == "Cardiology Updated"
        deleted = await department_repo.delete(created.id, soft=False)
        assert deleted is True
        assert await department_repo.get(created.id) is None

    async def test_paginate_empty(self, department_repo):
        page = await department_repo.paginate(page=1, per_page=10)
        assert page.total == 0
        assert len(page.items) == 0


class TestOrganizationRepository:
    async def test_create(self, organization_repo):
        org = await organization_repo.create({
            "name": "Test Organization",
            "org_type": OrganizationType.HOSPITAL,
            "email": f"org.{uuid.uuid4()}@example.com",
            "is_active": True,
        })
        assert org.id is not None

    async def test_crud_cycle(self, organization_repo):
        org = await organization_repo.create({
            "name": "HealthOrg",
            "org_type": OrganizationType.RESEARCH_CENTER,
        })
        fetched = await organization_repo.get(org.id)
        assert fetched.name == "HealthOrg"
        updated = await organization_repo.update(org.id, {"name": "HealthOrg Updated"})
        assert updated.name == "HealthOrg Updated"
        await organization_repo.delete(org.id, soft=False)
        assert await organization_repo.get(org.id) is None

    async def test_unique_license(self, organization_repo):
        lic = f"LIC-{uuid.uuid4().hex[:8].upper()}"
        await organization_repo.create({
            "name": "Org1",
            "license_number": lic,
        })
        with pytest.raises(Exception):
            await organization_repo.create({
                "name": "Org2",
                "license_number": lic,
            })

    async def test_paginate_and_sort(self, organization_repo):
        for i in range(5):
            await organization_repo.create({
                "name": f"Org-{i}",
                "org_type": OrganizationType.HOSPITAL,
            })
        page = await organization_repo.paginate(page=1, per_page=3)
        assert page.total >= 5
        assert page.total_pages >= 2
        assert page.has_next is True
        assert page.has_prev is False
        page2 = await organization_repo.paginate(page=2, per_page=3)
        assert page2.has_prev is True
