"""Tests for task endpoints."""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.template import Template
from app.models.user import Organization, User


@pytest.fixture
async def seed_template(db_session: AsyncSession, seed_org: Organization, seed_admin: User) -> Template:
    tmpl = Template(
        organization_id=seed_org.id,
        name="Task Template",
        status="active",
        version=1,
        fields=[],
        steps=[{"stepNumber": 1, "name": "Do Work"}],
        created_by=seed_admin.id,
    )
    db_session.add(tmpl)
    await db_session.commit()
    await db_session.refresh(tmpl)
    return tmpl


@pytest.mark.asyncio
async def test_my_tasks(client: AsyncClient, admin_token: str, worker_token: str, seed_admin: User, seed_worker: User, seed_template: Template):
    # Create a workflow with step assigned to worker
    await client.post("/workflows", json={
        "template_id": str(seed_template.id),
        "name": "Task WF",
        "step_assignments": [
            {"step_number": 1, "assigned_to": str(seed_worker.id)},
        ],
    }, headers={"Authorization": f"Bearer {admin_token}"})

    # Worker should see their task
    resp = await client.get("/tasks/mine", headers={"Authorization": f"Bearer {worker_token}"})
    assert resp.status_code == 200
    tasks = resp.json()
    assert len(tasks) >= 1
    assert tasks[0]["step_name"] == "Do Work"


@pytest.mark.asyncio
async def test_my_tasks_empty(client: AsyncClient, admin_token: str, seed_admin: User):
    resp = await client.get("/tasks/mine", headers={"Authorization": f"Bearer {admin_token}"})
    assert resp.status_code == 200
    assert resp.json() == []
