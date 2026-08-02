import pytest

pytest.skip("Requires FastAPI client fixture + analytics endpoints",
            allow_module_level=True)


@pytest.mark.anyio
async def test_analytics_overview(client):
    await client.post("/v1/auth/register", json={
        "email": "analytics_doc@test.com", "password": "pass123",
        "full_name": "Dr. Analytics", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "analytics_doc@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    response = await client.get("/v1/analytics/overview",
                                headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 200
    data = response.json()
    assert "total_patients" in data
    assert "total_devices" in data
    assert "total_alerts" in data
    assert "total_hospitals" in data
    assert "total_users" in data
    assert "bed_occupancy_rate" in data


@pytest.mark.anyio
async def test_analytics_patients(client):
    await client.post("/v1/auth/register", json={
        "email": "analytics_doc2@test.com", "password": "pass123",
        "full_name": "Dr. Analytics2", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "analytics_doc2@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    response = await client.get("/v1/analytics/patients",
                                headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 200
    data = response.json()
    assert "total" in data
    assert "active" in data
    assert "admitted_today" in data
    assert "discharged_today" in data
    assert "male" in data
    assert "female" in data
    assert "average_age" in data
    assert "average_length_of_stay_days" in data
    assert "admissions_by_month" in data
    assert "discharges_by_month" in data
    assert "by_department" in data


@pytest.mark.anyio
async def test_analytics_devices(client):
    await client.post("/v1/auth/register", json={
        "email": "analytics_doc3@test.com", "password": "pass123",
        "full_name": "Dr. Analytics3", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "analytics_doc3@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    response = await client.get("/v1/analytics/devices",
                                headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 200
    data = response.json()
    assert "total" in data
    assert "online" in data
    assert "average_battery" in data
    assert "by_type" in data
    assert "by_status" in data


@pytest.mark.anyio
async def test_analytics_alerts(client):
    await client.post("/v1/auth/register", json={
        "email": "analytics_doc4@test.com", "password": "pass123",
        "full_name": "Dr. Analytics4", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "analytics_doc4@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    response = await client.get("/v1/analytics/alerts",
                                headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 200
    data = response.json()
    assert "total" in data
    assert "critical" in data
    assert "high" in data
    assert "medium" in data
    assert "low" in data
    assert "unacknowledged" in data
    assert "average_response_time_minutes" in data
    assert "by_type" in data
    assert "by_severity" in data
    assert "by_day" in data


@pytest.mark.anyio
async def test_analytics_hospitals(client):
    await client.post("/v1/auth/register", json={
        "email": "analytics_doc5@test.com", "password": "pass123",
        "full_name": "Dr. Analytics5", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "analytics_doc5@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    response = await client.get("/v1/analytics/hospitals",
                                headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 200
    data = response.json()
    assert "total_hospitals" in data
    assert "total_beds" in data
    assert "occupied_beds" in data
    assert "hospitals" in data


@pytest.mark.anyio
async def test_analytics_system_health(client):
    await client.post("/v1/auth/register", json={
        "email": "analytics_doc6@test.com", "password": "pass123",
        "full_name": "Dr. Analytics6", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "analytics_doc6@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    response = await client.get("/v1/analytics/system-health",
                                headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 200
    data = response.json()
    assert "total_requests_24h" in data
    assert "active_web_sockets" in data
    assert "avg_response_time_ms" in data
    assert "error_rate_24h" in data
    assert "uptime_hours" in data


@pytest.mark.anyio
async def test_analytics_activity_feed(client):
    await client.post("/v1/auth/register", json={
        "email": "analytics_doc7@test.com", "password": "pass123",
        "full_name": "Dr. Analytics7", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "analytics_doc7@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    response = await client.get("/v1/analytics/activity-feed?limit=10",
                                headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 200
    assert isinstance(response.json(), list)
