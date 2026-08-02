import pytest

pytest.skip("Requires FastAPI client fixture + analytics endpoint",
            allow_module_level=True)


@pytest.mark.anyio
async def test_analytics_overview_shape(client):
    """Validate the overview response contains all required keys."""
    await client.post("/v1/auth/register", json={
        "email": "shape_doc@test.com", "password": "pass123",
        "full_name": "Dr. Shape", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "shape_doc@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    resp = await client.get("/v1/analytics/overview",
                            headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    data = resp.json()
    required_fields = [
        "total_patients", "active_patients", "total_devices",
        "online_devices", "total_alerts", "critical_alerts",
        "total_hospitals", "total_users", "reports_generated",
        "bed_occupancy_rate",
    ]
    for field in required_fields:
        assert field in data, f"Missing field: {field}"


@pytest.mark.anyio
async def test_analytics_patient_shape(client):
    """Validate the patient analytics response shape."""
    await client.post("/v1/auth/register", json={
        "email": "pat_shape@test.com", "password": "pass123",
        "full_name": "Dr. PatShape", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "pat_shape@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    resp = await client.get("/v1/analytics/patients",
                            headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    data = resp.json()
    required = [
        "total", "active", "admitted_today", "discharged_today",
        "male", "female", "average_age", "average_length_of_stay_days",
        "admissions_by_month", "discharges_by_month", "by_department",
    ]
    for field in required:
        assert field in data, f"Missing field: {field}"


@pytest.mark.anyio
async def test_analytics_device_shape(client):
    """Validate the device analytics response shape."""
    await client.post("/v1/auth/register", json={
        "email": "dev_shape@test.com", "password": "pass123",
        "full_name": "Dr. DevShape", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "dev_shape@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    resp = await client.get("/v1/analytics/devices",
                            headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    data = resp.json()
    required = [
        "total", "online", "offline", "error", "maintenance",
        "sleeping", "updating", "average_battery", "low_battery_count",
        "by_type", "by_status",
    ]
    for field in required:
        assert field in data, f"Missing field: {field}"


@pytest.mark.anyio
async def test_analytics_alert_shape(client):
    """Validate the alert analytics response shape."""
    await client.post("/v1/auth/register", json={
        "email": "alert_shape@test.com", "password": "pass123",
        "full_name": "Dr. AlertShape", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "alert_shape@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    resp = await client.get("/v1/analytics/alerts",
                            headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    data = resp.json()
    required = [
        "total", "critical", "high", "medium", "low",
        "unacknowledged", "average_response_time_minutes",
        "by_type", "by_severity", "by_day",
    ]
    for field in required:
        assert field in data, f"Missing field: {field}"


@pytest.mark.anyio
async def test_analytics_hospital_shape(client):
    """Validate the hospital analytics response shape."""
    await client.post("/v1/auth/register", json={
        "email": "hosp_shape@test.com", "password": "pass123",
        "full_name": "Dr. HospShape", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "hosp_shape@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    resp = await client.get("/v1/analytics/hospitals",
                            headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    data = resp.json()
    required = ["total_hospitals", "total_beds", "occupied_beds", "hospitals"]
    for field in required:
        assert field in data, f"Missing field: {field}"


@pytest.mark.anyio
async def test_analytics_system_health_shape(client):
    """Validate the system health response shape."""
    await client.post("/v1/auth/register", json={
        "email": "sys_shape@test.com", "password": "pass123",
        "full_name": "Dr. SysShape", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "sys_shape@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    resp = await client.get("/v1/analytics/system-health",
                            headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    data = resp.json()
    required = [
        "total_requests_24h", "active_web_sockets", "avg_response_time_ms",
        "error_rate_24h", "database_connections", "cache_hit_rate",
        "uptime_hours", "recent_errors", "service_status",
    ]
    for field in required:
        assert field in data, f"Missing field: {field}"
