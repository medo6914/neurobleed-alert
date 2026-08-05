import pytest

pytest.skip("Requires FastAPI client fixture", allow_module_level=True)

REGISTER_PAYLOAD = {
    "email": "doctor@test.com",
    "password": "Testpass123",
    "full_name": "Dr. Test",
    "role": "doctor",
}


@pytest.mark.anyio
async def test_register_user(client):
    response = await client.post("/v1/auth/register", json=REGISTER_PAYLOAD)
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == REGISTER_PAYLOAD["email"]
    assert data["full_name"] == REGISTER_PAYLOAD["full_name"]
    assert data["role"] == REGISTER_PAYLOAD["role"]
    assert "user_id" in data
    assert "password" not in data


@pytest.mark.anyio
async def test_register_duplicate_email(client):
    await client.post("/v1/auth/register", json=REGISTER_PAYLOAD)
    response = await client.post("/v1/auth/register", json=REGISTER_PAYLOAD)
    assert response.status_code == 400
    assert "already registered" in response.json()["detail"]


@pytest.mark.anyio
async def test_login_success(client):
    await client.post("/v1/auth/register", json=REGISTER_PAYLOAD)
    response = await client.post(
        "/v1/auth/login",
        json={
            "email": REGISTER_PAYLOAD["email"],
            "password": REGISTER_PAYLOAD["password"],
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"
    assert data["role"] == REGISTER_PAYLOAD["role"]


@pytest.mark.anyio
async def test_login_wrong_password(client):
    await client.post("/v1/auth/register", json=REGISTER_PAYLOAD)
    response = await client.post(
        "/v1/auth/login",
        json={
            "email": REGISTER_PAYLOAD["email"],
            "password": "wrongpassword",
        },
    )
    assert response.status_code == 401


@pytest.mark.anyio
async def test_refresh_token(client):
    await client.post("/v1/auth/register", json=REGISTER_PAYLOAD)
    login = (
        await client.post(
            "/v1/auth/login",
            json={
                "email": REGISTER_PAYLOAD["email"],
                "password": REGISTER_PAYLOAD["password"],
            },
        )
    ).json()
    response = await client.post(
        "/v1/auth/refresh",
        json={
            "refresh_token": login["refresh_token"],
        },
    )
    assert response.status_code == 200
    assert "access_token" in response.json()


@pytest.mark.anyio
async def test_forgot_password(client):
    await client.post("/v1/auth/register", json=REGISTER_PAYLOAD)
    response = await client.post(
        "/v1/auth/forgot-password",
        json={
            "email": REGISTER_PAYLOAD["email"],
        },
    )
    assert response.status_code == 200
    assert "code_length" in response.json()


@pytest.mark.anyio
async def test_get_me(client):
    await client.post("/v1/auth/register", json=REGISTER_PAYLOAD)
    login = (
        await client.post(
            "/v1/auth/login",
            json={
                "email": REGISTER_PAYLOAD["email"],
                "password": REGISTER_PAYLOAD["password"],
            },
        )
    ).json()
    token = login["access_token"]
    response = await client.get(
        "/v1/auth/me",
        headers={
            "Authorization": f"Bearer {token}",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == REGISTER_PAYLOAD["email"]


@pytest.mark.anyio
async def test_update_me(client):
    await client.post("/v1/auth/register", json=REGISTER_PAYLOAD)
    login = (
        await client.post(
            "/v1/auth/login",
            json={
                "email": REGISTER_PAYLOAD["email"],
                "password": REGISTER_PAYLOAD["password"],
            },
        )
    ).json()
    token = login["access_token"]
    response = await client.put(
        "/v1/auth/me",
        json={
            "full_name": "Dr. Updated",
        },
        headers={
            "Authorization": f"Bearer {token}",
        },
    )
    assert response.status_code == 200
    assert response.json()["full_name"] == "Dr. Updated"


@pytest.mark.anyio
async def test_logout(client):
    await client.post("/v1/auth/register", json=REGISTER_PAYLOAD)
    login = (
        await client.post(
            "/v1/auth/login",
            json={
                "email": REGISTER_PAYLOAD["email"],
                "password": REGISTER_PAYLOAD["password"],
            },
        )
    ).json()
    token = login["access_token"]
    response = await client.post(
        "/v1/auth/logout",
        headers={
            "Authorization": f"Bearer {token}",
        },
    )
    assert response.status_code == 200
    assert response.json()["message"] == "Logged out successfully"
