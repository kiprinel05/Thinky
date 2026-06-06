"""Integration tests for /auth routes via TestClient."""
import pytest
from jose import jwt

from core.config import settings

API = settings.API_V1_STR  # "/api/v1"


# Helpers --------------------------------------------------------------------

def _register_payload(**overrides):
    base = {
        "username": "cipri",
        "email": "cipri@example.com",
        "password": "secret123",
        "confirm_password": "secret123",
    }
    base.update(overrides)
    return base


# /auth/register -------------------------------------------------------------

class TestRegisterRoute:
    def test_register_returns_201_and_token(self, client):
        # Act
        resp = client.post(f"{API}/auth/register", json=_register_payload())
        # Assert
        assert resp.status_code == 201
        body = resp.json()
        assert body["is_guest"] is False
        assert body["email"] == "cipri@example.com"
        assert body["username"] == "cipri"
        # Token is a valid JWT signed with our test SECRET_KEY.
        payload = jwt.decode(
            body["access_token"], settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        assert payload["email"] == "cipri@example.com"

    def test_register_with_duplicate_email_returns_400(self, client):
        client.post(f"{API}/auth/register", json=_register_payload())
        # Same email, different username
        resp = client.post(
            f"{API}/auth/register",
            json=_register_payload(username="other"),
        )
        assert resp.status_code == 400
        assert "Email" in resp.json()["detail"]

    def test_register_with_invalid_payload_returns_422(self, client):
        resp = client.post(
            f"{API}/auth/register",
            json=_register_payload(password="abc", confirm_password="abc"),
        )
        assert resp.status_code == 422


# /auth/login ----------------------------------------------------------------

class TestLoginRoute:
    def test_login_with_correct_credentials_returns_token(self, client):
        client.post(f"{API}/auth/register", json=_register_payload())
        resp = client.post(
            f"{API}/auth/login",
            json={"email": "cipri@example.com", "password": "secret123"},
        )
        assert resp.status_code == 200
        assert resp.json()["is_guest"] is False

    def test_login_with_wrong_password_returns_401(self, client):
        client.post(f"{API}/auth/register", json=_register_payload())
        resp = client.post(
            f"{API}/auth/login",
            json={"email": "cipri@example.com", "password": "wrongpass"},
        )
        assert resp.status_code == 401

    def test_login_for_unknown_user_returns_401(self, client):
        resp = client.post(
            f"{API}/auth/login",
            json={"email": "ghost@example.com", "password": "whatever1"},
        )
        assert resp.status_code == 401


# /auth/guest ----------------------------------------------------------------

class TestGuestRoute:
    def test_register_guest_returns_201_with_token(self, client):
        resp = client.post(f"{API}/auth/guest", json={"name": "Ana"})
        assert resp.status_code == 201
        body = resp.json()
        assert body["is_guest"] is True
        assert body["guest_name"] == "Ana"

    def test_register_guest_rejects_empty_name(self, client):
        resp = client.post(f"{API}/auth/guest", json={"name": "  "})
        assert resp.status_code == 422


# /auth/me -------------------------------------------------------------------

class TestMeRoute:
    def test_me_without_token_returns_401(self, client):
        resp = client.get(f"{API}/auth/me")
        assert resp.status_code == 401

    def test_me_with_authed_client_returns_user(self, authed_client):
        client, user = authed_client
        resp = client.get(f"{API}/auth/me")
        assert resp.status_code == 200
        body = resp.json()
        assert body["id"] == user.id
        assert body["email"] == user.email
        assert body["is_admin"] is False
