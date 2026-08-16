def test_customer_registration(client):
    payload = {
        "email": "newbie@mns.com",
        "password": "Password1234!",
        "full_name": "Newbie Test",
        "phone": "+639170001111"
    }
    response = client.post("/api/v1/auth/register", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["user"]["email"] == "newbie@mns.com"
    assert data["user"]["role"] == "customer"


def test_login_success(client):
    payload = {
        "email": "admin@mns.com",
        "password": "AdminPass123!"
    }
    response = client.post("/api/v1/auth/login", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["user"]["role"] == "admin"


def test_login_invalid_password(client):
    payload = {
        "email": "admin@mns.com",
        "password": "WrongPassword!"
    }
    response = client.post("/api/v1/auth/login", json=payload)
    assert response.status_code == 401


def test_refresh_token_flow(client):
    login_resp = client.post("/api/v1/auth/login", json={"email": "customer@mns.com", "password": "CustomerPass123!"})
    assert login_resp.status_code == 200
    refresh_token = login_resp.json()["refresh_token"]

    # Rotate refresh token
    refresh_resp = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert refresh_resp.status_code == 200
    assert "access_token" in refresh_resp.json()
    assert "refresh_token" in refresh_resp.json()

    # Reusing the old rotated refresh token should fail (single-use)
    replay_resp = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert replay_resp.status_code == 401


def test_get_me(client, customer_headers):
    resp = client.get("/api/v1/auth/me", headers=customer_headers)
    assert resp.status_code == 200
    assert resp.json()["email"] == "customer@mns.com"
