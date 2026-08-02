import pytest

pytest.skip("Requires FastAPI client fixture + device endpoints",
            allow_module_level=True)

DEVICE_PAYLOAD = {
    "device_name": "NB-01 Test Monitor",
    "device_type": "nb_01",
    "serial_number": None,
    "firmware_version": "1.0.0",
}


@pytest.mark.anyio
async def test_register_device(client):
    await client.post("/v1/auth/register", json={
        "email": "dev_doc@test.com", "password": "pass123",
        "full_name": "Dr. Device", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "dev_doc@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    response = await client.post("/v1/devices/", json=DEVICE_PAYLOAD,
                                 headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 201
    data = response.json()
    assert data["device_name"] == DEVICE_PAYLOAD["device_name"]
    assert "id" in data


@pytest.mark.anyio
async def test_list_devices(client):
    await client.post("/v1/auth/register", json={
        "email": "dev_doc2@test.com", "password": "pass123",
        "full_name": "Dr. Device2", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "dev_doc2@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    await client.post("/v1/devices/", json=DEVICE_PAYLOAD,
                      headers={"Authorization": f"Bearer {token}"})
    response = await client.get("/v1/devices/",
                                headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 200
    assert len(response.json()) >= 1


@pytest.mark.anyio
async def test_get_device(client):
    await client.post("/v1/auth/register", json={
        "email": "dev_doc3@test.com", "password": "pass123",
        "full_name": "Dr. Device3", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "dev_doc3@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    created = await client.post("/v1/devices/", json=DEVICE_PAYLOAD,
                                headers={"Authorization": f"Bearer {token}"})
    device_id = created.json()["id"]

    response = await client.get(f"/v1/devices/{device_id}",
                                headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 200
    assert response.json()["id"] == device_id


@pytest.mark.anyio
async def test_update_device(client):
    await client.post("/v1/auth/register", json={
        "email": "dev_doc4@test.com", "password": "pass123",
        "full_name": "Dr. Device4", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "dev_doc4@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    created = await client.post("/v1/devices/", json=DEVICE_PAYLOAD,
                                headers={"Authorization": f"Bearer {token}"})
    device_id = created.json()["id"]

    response = await client.put(f"/v1/devices/{device_id}",
                                json={"device_name": "Updated Monitor"},
                                headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 200
    assert response.json()["device_name"] == "Updated Monitor"


@pytest.mark.anyio
async def test_device_diagnostics_log(client):
    await client.post("/v1/auth/register", json={
        "email": "dev_doc5@test.com", "password": "pass123",
        "full_name": "Dr. Device5", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "dev_doc5@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    created = await client.post("/v1/devices/", json=DEVICE_PAYLOAD,
                                headers={"Authorization": f"Bearer {token}"})
    device_id = created.json()["id"]

    diag_payload = {
        "battery_level": 78.5,
        "signal_strength": -62.0,
        "temperature_celsius": 36.8,
        "is_charging": True,
        "lte_signal_dbm": -85.0,
        "sim_status": "ready",
        "ble_connected": True,
        "wifi_signal_dbm": -45.0,
        "memory_usage_percent": 42.0,
        "storage_usage_percent": 35.0,
        "firmware_version": "1.0.0",
        "uptime_seconds": 86400,
        "error_code": None,
    }
    response = await client.post(
        f"/v1/devices/{device_id}/diagnostics/log",
        json=diag_payload,
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 201
    assert response.json()["battery_level"] == 78.5


@pytest.mark.anyio
async def test_device_diagnostics_list(client):
    await client.post("/v1/auth/register", json={
        "email": "dev_doc6@test.com", "password": "pass123",
        "full_name": "Dr. Device6", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "dev_doc6@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    created = await client.post("/v1/devices/", json=DEVICE_PAYLOAD,
                                headers={"Authorization": f"Bearer {token}"})
    device_id = created.json()["id"]

    response = await client.get(
        f"/v1/devices/{device_id}/diagnostics/logs",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200


@pytest.mark.anyio
async def test_device_events_list(client):
    await client.post("/v1/auth/register", json={
        "email": "dev_doc7@test.com", "password": "pass123",
        "full_name": "Dr. Device7", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "dev_doc7@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    created = await client.post("/v1/devices/", json=DEVICE_PAYLOAD,
                                headers={"Authorization": f"Bearer {token}"})
    device_id = created.json()["id"]

    response = await client.get(
        f"/v1/devices/{device_id}/events",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200


@pytest.mark.anyio
async def test_delete_device(client):
    await client.post("/v1/auth/register", json={
        "email": "dev_doc8@test.com", "password": "pass123",
        "full_name": "Dr. Device8", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "dev_doc8@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    created = await client.post("/v1/devices/", json=DEVICE_PAYLOAD,
                                headers={"Authorization": f"Bearer {token}"})
    device_id = created.json()["id"]

    response = await client.delete(f"/v1/devices/{device_id}",
                                   headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 204
