import pytest

pytest.skip("Requires FastAPI client fixture", allow_module_level=True)

ALERT_PAYLOAD = {
    "alert_type": "icp_elevated",
    "severity": "high",
    "message": "Elevated ICP detected",
    "patient_id": None,
    "device_id": None,
}


@pytest.mark.anyio
async def test_create_alert(client):
    await client.post("/v1/auth/register", json={
        "email": "alert_doc@test.com", "password": "pass123",
        "full_name": "Dr. Alert", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "alert_doc@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    # Create patient first
    pat = await client.post("/v1/patients/", json={
        "full_name": "Alert Patient", "date_of_birth": "1980-05-10",
        "gender": "male",
    }, headers={"Authorization": f"Bearer {token}"})
    patient_id = pat.json()["id"]

    payload = {**ALERT_PAYLOAD, "patient_id": patient_id}
    response = await client.post(
        "/v1/alerts/", json=payload,
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["alert_type"] == "icp_elevated"
    assert data["severity"] == "high"
    assert data["patient_id"] == patient_id
    assert "id" in data


@pytest.mark.anyio
async def test_list_alerts_filter_by_severity(client):
    await client.post("/v1/auth/register", json={
        "email": "alert_doc2@test.com", "password": "pass123",
        "full_name": "Dr. Alert2", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "alert_doc2@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    response = await client.get(
        "/v1/alerts/?severity=high",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200


@pytest.mark.anyio
async def test_acknowledge_alert(client):
    await client.post("/v1/auth/register", json={
        "email": "alert_doc3@test.com", "password": "pass123",
        "full_name": "Dr. Alert3", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "alert_doc3@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    pat = await client.post("/v1/patients/", json={
        "full_name": "Ack Patient", "date_of_birth": "1990-01-01",
        "gender": "female",
    }, headers={"Authorization": f"Bearer {token}"})
    patient_id = pat.json()["id"]

    alert = await client.post("/v1/alerts/", json={
        **ALERT_PAYLOAD, "patient_id": patient_id,
    }, headers={"Authorization": f"Bearer {token}"})
    alert_id = alert.json()["id"]

    response = await client.post(
        f"/v1/alerts/{alert_id}/acknowledge",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    assert response.json()["is_acknowledged"] is True


@pytest.mark.anyio
async def test_resolve_alert(client):
    await client.post("/v1/auth/register", json={
        "email": "alert_doc4@test.com", "password": "pass123",
        "full_name": "Dr. Alert4", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "alert_doc4@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    pat = await client.post("/v1/patients/", json={
        "full_name": "Resolve Patient", "date_of_birth": "1975-03-20",
        "gender": "male",
    }, headers={"Authorization": f"Bearer {token}"})
    patient_id = pat.json()["id"]

    alert = await client.post("/v1/alerts/", json={
        **ALERT_PAYLOAD, "patient_id": patient_id,
    }, headers={"Authorization": f"Bearer {token}"})
    alert_id = alert.json()["id"]

    response = await client.post(
        f"/v1/alerts/{alert_id}/resolve",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    assert response.json()["is_resolved"] is True
    assert response.json()["resolved_at"] is not None
