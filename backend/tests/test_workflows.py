"""Tests for workflow endpoints."""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.template import Template
from app.models.user import Organization, User


@pytest.fixture
async def seed_template(db_session: AsyncSession, seed_org: Organization, seed_admin: User) -> Template:
    tmpl = Template(
        organization_id=seed_org.id,
        name="Test Template",
        status="active",
        version=1,
        fields=[
            {"id": "f1", "stepNumber": 1, "type": "text", "label": "Notes"},
        ],
        steps=[
            {"stepNumber": 1, "name": "Review"},
            {"stepNumber": 2, "name": "Approval"},
        ],
        created_by=seed_admin.id,
    )
    db_session.add(tmpl)
    await db_session.commit()
    await db_session.refresh(tmpl)
    return tmpl


@pytest.mark.asyncio
async def test_create_workflow(client: AsyncClient, admin_token: str, seed_admin: User, seed_template: Template, seed_worker: User):
    resp = await client.post("/workflows", json={
        "template_id": str(seed_template.id),
        "name": "Job #42",
        "priority": "high",
        "step_assignments": [
            {"step_number": 1, "assigned_to": str(seed_worker.id)},
            {"step_number": 2, "assigned_to": str(seed_admin.id)},
        ],
    }, headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 201
    data = resp.json()
    assert data["name"] == "Job #42"
    assert data["status"] == "in_progress"
    assert data["priority"] == "high"


@pytest.mark.asyncio
async def test_list_workflows(client: AsyncClient, admin_token: str, seed_admin: User, seed_template: Template, seed_worker: User):
    # Create one
    await client.post("/workflows", json={
        "template_id": str(seed_template.id),
        "name": "WF List Test",
        "step_assignments": [
            {"step_number": 1, "assigned_to": str(seed_worker.id)},
        ],
    }, headers={"Authorization": f"Bearer {admin_token}"})

    resp = await client.get("/workflows", headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 200
    assert len(resp.json()) >= 1


@pytest.mark.asyncio
async def test_get_workflow(client: AsyncClient, admin_token: str, seed_admin: User, seed_template: Template, seed_worker: User):
    create_resp = await client.post("/workflows", json={
        "template_id": str(seed_template.id),
        "name": "WF Get Test",
        "step_assignments": [
            {"step_number": 1, "assigned_to": str(seed_worker.id)},
        ],
    }, headers={"Authorization": f"Bearer {admin_token}"})
    wf_id = create_resp.json()["id"]

    resp = await client.get(f"/workflows/{wf_id}", headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 200
    assert resp.json()["id"] == wf_id


@pytest.mark.asyncio
async def test_update_step_status(client: AsyncClient, admin_token: str, seed_admin: User, seed_template: Template, seed_worker: User):
    create_resp = await client.post("/workflows", json={
        "template_id": str(seed_template.id),
        "name": "Step Test",
        "step_assignments": [
            {"step_number": 1, "assigned_to": str(seed_worker.id)},
            {"step_number": 2, "assigned_to": str(seed_admin.id)},
        ],
    }, headers={"Authorization": f"Bearer {admin_token}"})
    wf_id = create_resp.json()["id"]

    # Move step 1 to in_progress
    resp = await client.patch(f"/workflows/{wf_id}/steps/1", json={"status": "in_progress"},
                              headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 200
    assert resp.json()["status"] == "in_progress"

    # Complete step 1 — should unlock step 2
    resp = await client.patch(f"/workflows/{wf_id}/steps/1", json={"status": "complete"},
                              headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 200
    assert resp.json()["status"] == "complete"


@pytest.mark.asyncio
async def test_submit_responses(client: AsyncClient, admin_token: str, seed_admin: User, seed_template: Template, seed_worker: User):
    create_resp = await client.post("/workflows", json={
        "template_id": str(seed_template.id),
        "name": "Response Test",
        "step_assignments": [
            {"step_number": 1, "assigned_to": str(seed_worker.id)},
        ],
    }, headers={"Authorization": f"Bearer {admin_token}"})
    wf_id = create_resp.json()["id"]

    resp = await client.post(f"/workflows/{wf_id}/steps/1/responses", json=[
        {"field_id": "00000000-0000-0000-0000-000000000001", "value": "Looks good", "device_id": "test-device"},
    ], headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 201
    assert len(resp.json()) == 1
    assert resp.json()[0]["value"] == "Looks good"


@pytest.mark.asyncio
async def test_audit_trail(client: AsyncClient, admin_token: str, seed_admin: User, seed_template: Template, seed_worker: User):
    create_resp = await client.post("/workflows", json={
        "template_id": str(seed_template.id),
        "name": "Audit Test",
        "step_assignments": [
            {"step_number": 1, "assigned_to": str(seed_worker.id)},
        ],
    }, headers={"Authorization": f"Bearer {admin_token}"})
    wf_id = create_resp.json()["id"]

    resp = await client.get(f"/workflows/{wf_id}/audit", headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 200
    entries = resp.json()
    assert len(entries) >= 1
    assert entries[0]["action"] == "workflow_created"
