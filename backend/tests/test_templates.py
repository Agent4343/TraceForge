"""Tests for template CRUD endpoints."""

import pytest
from httpx import AsyncClient

from app.models.user import User


@pytest.mark.asyncio
async def test_create_template(client: AsyncClient, admin_token: str, seed_admin: User):
    resp = await client.post("/templates", json={
        "name": "Safety Check",
        "fields": [{"id": "f1", "type": "text", "label": "Notes"}],
        "steps": [{"stepNumber": 1, "name": "Inspection"}],
    }, headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 201
    data = resp.json()
    assert data["name"] == "Safety Check"
    assert data["status"] == "draft"
    assert data["version"] == 1
    assert len(data["fields"]) == 1


@pytest.mark.asyncio
async def test_list_templates(client: AsyncClient, admin_token: str, seed_admin: User):
    # Create one
    await client.post("/templates", json={
        "name": "Template A",
        "fields": [],
        "steps": [],
    }, headers={"Authorization": f"Bearer {admin_token}"})

    resp = await client.get("/templates", headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["total"] >= 1
    assert len(data["items"]) >= 1
    assert data["page"] == 1


@pytest.mark.asyncio
async def test_update_template(client: AsyncClient, admin_token: str, seed_admin: User):
    create_resp = await client.post("/templates", json={
        "name": "Original",
        "fields": [],
        "steps": [],
    }, headers={"Authorization": f"Bearer {admin_token}"})
    template_id = create_resp.json()["id"]

    resp = await client.put(f"/templates/{template_id}", json={
        "name": "Updated",
        "status": "active",
    }, headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 200
    assert resp.json()["name"] == "Updated"
    assert resp.json()["status"] == "active"
    assert resp.json()["version"] == 2


@pytest.mark.asyncio
async def test_duplicate_template(client: AsyncClient, admin_token: str, seed_admin: User):
    create_resp = await client.post("/templates", json={
        "name": "Base Template",
        "fields": [{"id": "f1", "type": "text"}],
        "steps": [{"stepNumber": 1, "name": "Step 1"}],
    }, headers={"Authorization": f"Bearer {admin_token}"})
    template_id = create_resp.json()["id"]

    resp = await client.post(f"/templates/{template_id}/duplicate",
                             headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 201
    data = resp.json()
    assert data["name"] == "Base Template (Copy)"
    assert data["status"] == "draft"
    assert data["id"] != template_id
