"""Tests for user management endpoints."""

import pytest
from httpx import AsyncClient

from app.models.user import User


@pytest.mark.asyncio
async def test_list_users_as_admin(client: AsyncClient, admin_token: str, seed_admin: User):
    resp = await client.get("/users", headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) >= 1
    assert data[0]["email"] == "admin@test.io"


@pytest.mark.asyncio
async def test_list_users_as_worker_forbidden(client: AsyncClient, worker_token: str, seed_worker: User):
    resp = await client.get("/users", headers={"Authorization": f"Bearer {worker_token}"})
    assert resp.status_code == 403


@pytest.mark.asyncio
async def test_list_users_unauthenticated(client: AsyncClient):
    resp = await client.get("/users")
    assert resp.status_code in (401, 403)


@pytest.mark.asyncio
async def test_invite_user(client: AsyncClient, admin_token: str, seed_admin: User):
    resp = await client.post("/users/invite", json={
        "invites": [{"email": "newguy@test.io", "role": "worker"}],
    }, headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["sent"] == 1
    assert data["failed"] == []


@pytest.mark.asyncio
async def test_invite_duplicate_user(client: AsyncClient, admin_token: str, seed_admin: User):
    resp = await client.post("/users/invite", json={
        "invites": [{"email": "admin@test.io", "role": "worker"}],
    }, headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["sent"] == 0
    assert "admin@test.io" in data["failed"]


@pytest.mark.asyncio
async def test_update_user_role(client: AsyncClient, admin_token: str, seed_admin: User, seed_worker: User):
    resp = await client.patch(
        f"/users/{seed_worker.id}",
        json={"role": "manager"},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert resp.status_code == 200
    assert resp.json()["role"] == "manager"


@pytest.mark.asyncio
async def test_deactivate_user(client: AsyncClient, admin_token: str, seed_admin: User, seed_worker: User):
    resp = await client.patch(
        f"/users/{seed_worker.id}",
        json={"is_active": False},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert resp.status_code == 200
    assert resp.json()["is_active"] is False
