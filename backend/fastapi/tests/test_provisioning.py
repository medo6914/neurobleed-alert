import pytest

pytest.skip(
    "Requires FastAPI client fixture + provisioning endpoints", allow_module_level=True
)


@pytest.mark.anyio
async def test_generate_provisioning_key(client):
    await client.post(
        "/v1/auth/register",
        json={
            "email": "prov_doc@test.com",
            "password": "pass123",
            "full_name": "Dr. Prov",
            "role": "doctor",
        },
    )
    login = await client.post(
        "/v1/auth/login",
        json={
            "email": "prov_doc@test.com",
            "password": "pass123",
        },
    )
    token = login.json()["access_token"]

    response = await client.post(
        "/v1/devices/provisioning/keys",
        json={
            "hospital_id": None,
        },
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 201
    data = response.json()
    assert "id" in data
    assert "key" in data
    assert data["status"] == "active"


@pytest.mark.anyio
async def test_list_provisioning_keys(client):
    await client.post(
        "/v1/auth/register",
        json={
            "email": "prov_doc2@test.com",
            "password": "pass123",
            "full_name": "Dr. Prov2",
            "role": "doctor",
        },
    )
    login = await client.post(
        "/v1/auth/login",
        json={
            "email": "prov_doc2@test.com",
            "password": "pass123",
        },
    )
    token = login.json()["access_token"]

    await client.post(
        "/v1/devices/provisioning/keys",
        json={
            "hospital_id": None,
        },
        headers={"Authorization": f"Bearer {token}"},
    )

    response = await client.get(
        "/v1/devices/provisioning/keys", headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1


@pytest.mark.anyio
async def test_revoke_provisioning_key(client):
    await client.post(
        "/v1/auth/register",
        json={
            "email": "prov_doc3@test.com",
            "password": "pass123",
            "full_name": "Dr. Prov3",
            "role": "doctor",
        },
    )
    login = await client.post(
        "/v1/auth/login",
        json={
            "email": "prov_doc3@test.com",
            "password": "pass123",
        },
    )
    token = login.json()["access_token"]

    created = await client.post(
        "/v1/devices/provisioning/keys",
        json={
            "hospital_id": None,
        },
        headers={"Authorization": f"Bearer {token}"},
    )
    key_id = created.json()["id"]

    response = await client.post(
        f"/v1/devices/provisioning/keys/{key_id}/revoke",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    assert response.json()["status"] == "revoked"


@pytest.mark.anyio
async def test_claim_device(client):
    await client.post(
        "/v1/auth/register",
        json={
            "email": "prov_doc4@test.com",
            "password": "pass123",
            "full_name": "Dr. Prov4",
            "role": "doctor",
        },
    )
    login = await client.post(
        "/v1/auth/login",
        json={
            "email": "prov_doc4@test.com",
            "password": "pass123",
        },
    )
    token = login.json()["access_token"]

    # Create active key
    key_resp = await client.post(
        "/v1/devices/provisioning/keys",
        json={
            "hospital_id": None,
        },
        headers={"Authorization": f"Bearer {token}"},
    )
    provisioning_key = key_resp.json()["key"]

    # Claim device with that key
    response = await client.post(
        "/v1/devices/provisioning/claim",
        json={
            "provisioning_key": provisioning_key,
            "serial_number": "SN-CLAIM-TEST-001",
            "device_name": "Claimed Monitor",
            "device_type": "nb_01",
            "firmware_version": "1.0.0",
        },
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 201
    data = response.json()
    assert "device" in data
    assert data["device"]["serial_number"] == "SN-CLAIM-TEST-001"
    assert data["device"]["status"] == "online"


@pytest.mark.anyio
async def test_claim_device_with_invalid_key(client):
    await client.post(
        "/v1/auth/register",
        json={
            "email": "prov_doc5@test.com",
            "password": "pass123",
            "full_name": "Dr. Prov5",
            "role": "doctor",
        },
    )
    login = await client.post(
        "/v1/auth/login",
        json={
            "email": "prov_doc5@test.com",
            "password": "pass123",
        },
    )
    token = login.json()["access_token"]

    response = await client.post(
        "/v1/devices/provisioning/claim",
        json={
            "provisioning_key": "INVALID-KEY-12345",
            "serial_number": "SN-BAD-KEY-001",
            "device_name": "Bad Device",
            "device_type": "nb_01",
            "firmware_version": "1.0.0",
        },
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 404
