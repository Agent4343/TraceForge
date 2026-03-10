"""Tests for authentication endpoints."""

import pytest
import pytest_asyncio
from httpx import AsyncClient

from app.models.user import User


@pytest.mark.asyncio
async def test_login_success(client: AsyncClient, seed_admin: User):
    resp = await client.post("/auth/login", json={
        "email": "admin@test.io",
        "password": "password123",
    })
    assert resp.status_code == 200
    data = resp.json()
    assert data["user"]["email"] == "admin@test.io"
    assert data["access_token"]
    assert data["refresh_token"]
    assert data["requires_mfa"] is False


@pytest.mark.asyncio
async def test_login_invalid_password(client: AsyncClient, seed_admin: User):
    resp = await client.post("/auth/login", json={
        "email": "admin@test.io",
        "password": "wrongpassword",
    })
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_login_nonexistent_user(client: AsyncClient):
    resp = await client.post("/auth/login", json={
        "email": "nobody@test.io",
        "password": "password123",
    })
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_refresh_token(client: AsyncClient, seed_admin: User):
    # Login first
    login_resp = await client.post("/auth/login", json={
        "email": "admin@test.io",
        "password": "password123",
    })
    refresh_tok = login_resp.json()["refresh_token"]

    # Refresh
    resp = await client.post("/auth/refresh", json={"refresh_token": refresh_tok})
    assert resp.status_code == 200
    data = resp.json()
    assert data["access_token"]
    assert data["refresh_token"]


@pytest.mark.asyncio
async def test_refresh_invalid_token(client: AsyncClient):
    resp = await client.post("/auth/refresh", json={"refresh_token": "invalid"})
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_logout(client: AsyncClient, admin_token: str):
    resp = await client.post("/auth/logout", headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 204


@pytest.mark.asyncio
async def test_forgot_password_always_succeeds(client: AsyncClient):
    resp = await client.post("/auth/forgot-password", json={"email": "nobody@test.io"})
    assert resp.status_code == 204
