import pytest

pytest.skip(
    "Requires FastAPI client fixture + emergency endpoints", allow_module_level=True
)


@pytest.mark.anyio
async def test_sos_create(client):
    await client.post(
        "/v1/auth/register",
        json={
            "email": "sos_doc@test.com",
            "password": "pass123",
            "full_name": "Dr. SOS",
            "role": "doctor",
        },
    )
    login = await client.post(
        "/v1/auth/login",
        json={
            "email": "sos_doc@test.com",
            "password": "pass123",
        },
    )
    token = login.json()["access_token"]

    pat = await client.post(
        "/v1/patients/",
        json={
            "full_name": "SOS Patient",
            "date_of_birth": "1985-07-12",
            "gender": "male",
        },
        headers={"Authorization": f"Bearer {token}"},
    )
    patient_id = pat.json()["id"]

    response = await client.post(
        "/v1/emergency/sos",
        json={
            "patient_id": patient_id,
            "alert_type": "cardiac_arrest",
            "location": "ICU Room 4",
            "message": "Patient unresponsive, pulse weak",
        },
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["patient_id"] == patient_id
    assert data["status"] in ("active", "triggered")
    assert "id" in data


@pytest.mark.anyio
async def test_sos_list(client):
    await client.post(
        "/v1/auth/register",
        json={
            "email": "sos_doc2@test.com",
            "password": "pass123",
            "full_name": "Dr. SOS2",
            "role": "doctor",
        },
    )
    login = await client.post(
        "/v1/auth/login",
        json={
            "email": "sos_doc2@test.com",
            "password": "pass123",
        },
    )
    token = login.json()["access_token"]

    response = await client.get(
        "/v1/emergency/sos", headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    assert isinstance(response.json(), list)


@pytest.mark.anyio
async def test_sos_resolve(client):
    await client.post(
        "/v1/auth/register",
        json={
            "email": "sos_doc3@test.com",
            "password": "pass123",
            "full_name": "Dr. SOS3",
            "role": "doctor",
        },
    )
    login = await client.post(
        "/v1/auth/login",
        json={
            "email": "sos_doc3@test.com",
            "password": "pass123",
        },
    )
    token = login.json()["access_token"]

    pat = await client.post(
        "/v1/patients/",
        json={
            "full_name": "SOS Patient3",
            "date_of_birth": "1992-11-05",
            "gender": "female",
        },
        headers={"Authorization": f"Bearer {token}"},
    )
    patient_id = pat.json()["id"]

    sos = await client.post(
        "/v1/emergency/sos",
        json={
            "patient_id": patient_id,
            "alert_type": "seizure",
            "location": "ER Bay 2",
            "message": "Patient seizing",
        },
        headers={"Authorization": f"Bearer {token}"},
    )
    sos_id = sos.json()["id"]

    response = await client.post(
        f"/v1/emergency/sos/{sos_id}/resolve",
        json={"resolution": "Patient stabilized, moved to observation"},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    assert response.json()["status"] == "resolved"
