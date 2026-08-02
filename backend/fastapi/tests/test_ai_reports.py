import pytest

pytest.skip("Requires FastAPI client fixture + AI endpoints",
            allow_module_level=True)


@pytest.mark.anyio
async def test_ai_risk_assessment(client):
    await client.post("/v1/auth/register", json={
        "email": "ai_doc@test.com", "password": "pass123",
        "full_name": "Dr. AI", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "ai_doc@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    pat = await client.post("/v1/patients/", json={
        "full_name": "AI Patient", "date_of_birth": "1978-09-22",
        "gender": "male",
    }, headers={"Authorization": f"Bearer {token}"})
    patient_id = pat.json()["id"]

    response = await client.post(
        f"/v1/ai/risk-assess/{patient_id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code in (200, 201)
    data = response.json()
    assert "risk_score" in data or "risk_level" in data


@pytest.mark.anyio
async def test_ai_report_list(client):
    await client.post("/v1/auth/register", json={
        "email": "ai_doc2@test.com", "password": "pass123",
        "full_name": "Dr. AI2", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "ai_doc2@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    response = await client.get("/v1/ai/reports",
                                headers={"Authorization": f"Bearer {token}"})
    assert response.status_code == 200
    assert isinstance(response.json(), list)


@pytest.mark.anyio
async def test_ai_report_detail(client):
    await client.post("/v1/auth/register", json={
        "email": "ai_doc3@test.com", "password": "pass123",
        "full_name": "Dr. AI3", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "ai_doc3@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    pat = await client.post("/v1/patients/", json={
        "full_name": "AI Patient3", "date_of_birth": "2000-01-15",
        "gender": "female",
    }, headers={"Authorization": f"Bearer {token}"})
    patient_id = pat.json()["id"]

    await client.post(f"/v1/ai/risk-assess/{patient_id}",
                      headers={"Authorization": f"Bearer {token}"})

    reports = await client.get("/v1/ai/reports",
                               headers={"Authorization": f"Bearer {token}"})
    if reports.json():
        report_id = reports.json()[0]["id"]
        detail = await client.get(f"/v1/ai/reports/{report_id}",
                                  headers={"Authorization": f"Bearer {token}"})
        assert detail.status_code == 200
        assert detail.json()["id"] == report_id


@pytest.mark.anyio
async def test_ai_report_review(client):
    await client.post("/v1/auth/register", json={
        "email": "ai_doc4@test.com", "password": "pass123",
        "full_name": "Dr. AI4", "role": "doctor",
    })
    login = await client.post("/v1/auth/login", json={
        "email": "ai_doc4@test.com", "password": "pass123",
    })
    token = login.json()["access_token"]

    pat = await client.post("/v1/patients/", json={
        "full_name": "AI Patient4", "date_of_birth": "1965-03-30",
        "gender": "male",
    }, headers={"Authorization": f"Bearer {token}"})
    patient_id = pat.json()["id"]

    await client.post(f"/v1/ai/risk-assess/{patient_id}",
                      headers={"Authorization": f"Bearer {token}"})

    reports = await client.get("/v1/ai/reports",
                               headers={"Authorization": f"Bearer {token}"})
    if reports.json():
        report_id = reports.json()[0]["id"]
        review = await client.post(
            f"/v1/ai/reports/{report_id}/review",
            json={"is_reviewed": True, "review_notes": "Confirmed by specialist"},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert review.status_code == 200
        assert review.json()["is_reviewed"] is True
        assert review.json()["review_notes"] == "Confirmed by specialist"
