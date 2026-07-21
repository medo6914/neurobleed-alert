import pytest

pytest.skip("Requires FastAPI client fixture", allow_module_level=True)

PATIENT_PAYLOAD = {
    "full_name": "Ahmed Mohamed",
    "date_of_birth": "1965-03-15",
    "gender": "male",
    "phone": "+201234567890",
    "medical_conditions": "Hypertension, Diabetes",
    "medications": "Metformin, Lisinopril",
}


@pytest.mark.anyio
async def test_create_patient(client):
    await client.post("/v1/auth/register", json={
        "email": "doc@test.com", "password": "pass123", "full_name": "Dr. X", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={"email": "doc@test.com", "password": "pass123"})
    token = login.json()["access_token"]

    response = await client.post(
        "/v1/patients/",
        json=PATIENT_PAYLOAD,
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["full_name"] == PATIENT_PAYLOAD["full_name"]
    assert data["medical_conditions"] == PATIENT_PAYLOAD["medical_conditions"]
    assert "id" in data


@pytest.mark.anyio
async def test_list_patients(client):
    await client.post("/v1/auth/register", json={
        "email": "doc2@test.com", "password": "pass123", "full_name": "Dr. Y", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={"email": "doc2@test.com", "password": "pass123"})
    token = login.json()["access_token"]

    await client.post(
        "/v1/patients/", json=PATIENT_PAYLOAD,
        headers={"Authorization": f"Bearer {token}"},
    )

    response = await client.get(
        "/v1/patients/",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 1
