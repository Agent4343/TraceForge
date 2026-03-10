"""Seed script to populate database with initial data for development."""

import asyncio

from sqlalchemy import select

from app.core.database import async_session, engine, Base
from app.core.security import hash_password
from app.models.user import Organization, User
from app.models.template import Template
import app.models.workflow  # noqa: F401 — ensure tables are registered


async def seed():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with async_session() as db:
        # Check if already seeded
        result = await db.execute(select(Organization))
        if result.scalar_one_or_none():
            print("Database already seeded.")
            return

        # Organization
        org = Organization(name="Oceanic Energy Ltd", slug="oceanic-energy", industry="Oil & Gas")
        db.add(org)
        await db.flush()

        # Users
        users = {
            "admin": User(
                organization_id=org.id, email="admin@oceanic.io", display_name="Alex Chen",
                password_hash=hash_password("admin123"), role="admin",
            ),
            "manager": User(
                organization_id=org.id, email="sarah@oceanic.io", display_name="Sarah Kim",
                password_hash=hash_password("manager123"), role="manager",
            ),
            "worker": User(
                organization_id=org.id, email="mike@oceanic.io", display_name="Mike Torres",
                password_hash=hash_password("worker123"), role="worker",
            ),
            "viewer": User(
                organization_id=org.id, email="viewer@oceanic.io", display_name="Dana Park",
                password_hash=hash_password("viewer123"), role="viewer",
            ),
        }
        for u in users.values():
            db.add(u)
        await db.flush()

        # Templates
        safety_template = Template(
            organization_id=org.id,
            name="Pre-Job Safety Assessment",
            status="active",
            version=1,
            fields=[
                {"id": "f1", "stepNumber": 1, "type": "text", "label": "Job Description", "required": True, "order": 1},
                {"id": "f2", "stepNumber": 1, "type": "dropdown", "label": "Risk Level", "required": True, "order": 2,
                 "options": ["Low", "Medium", "High", "Critical"]},
                {"id": "f3", "stepNumber": 1, "type": "photo", "label": "Site Photos", "required": False, "order": 3, "maxPhotos": 5},
                {"id": "f4", "stepNumber": 1, "type": "signature", "label": "Supervisor Signature", "required": True, "order": 4,
                 "attestationText": "I confirm this job safety assessment is accurate."},
                {"id": "f5", "stepNumber": 2, "type": "yesNo", "label": "PPE Verified", "required": True, "order": 1},
                {"id": "f6", "stepNumber": 2, "type": "text", "label": "Additional Notes", "required": False, "order": 2},
                {"id": "f7", "stepNumber": 2, "type": "signature", "label": "HSE Sign-Off", "required": True, "order": 3,
                 "attestationText": "I confirm this safety review meets HSE standards."},
            ],
            steps=[
                {"stepNumber": 1, "name": "Site Assessment", "requiresSignature": True},
                {"stepNumber": 2, "name": "HSE Review", "requiresSignature": True},
            ],
            created_by=users["manager"].id,
        )

        handover_template = Template(
            organization_id=org.id,
            name="Shift Handover Checklist",
            status="active",
            version=1,
            fields=[
                {"id": "h1", "stepNumber": 1, "type": "text", "label": "Outstanding Items", "required": True, "order": 1},
                {"id": "h2", "stepNumber": 1, "type": "dropdown", "label": "Plant Status", "required": True, "order": 2,
                 "options": ["Normal", "Abnormal", "Shutdown", "Startup"]},
                {"id": "h3", "stepNumber": 1, "type": "signature", "label": "Outgoing Operator", "required": True, "order": 3},
                {"id": "h4", "stepNumber": 2, "type": "yesNo", "label": "All Items Acknowledged", "required": True, "order": 1},
                {"id": "h5", "stepNumber": 2, "type": "signature", "label": "Incoming Operator", "required": True, "order": 2,
                 "attestationText": "I confirm I have received this shift handover."},
            ],
            steps=[
                {"stepNumber": 1, "name": "Outgoing Shift Report", "requiresSignature": True},
                {"stepNumber": 2, "name": "Incoming Shift Acknowledgment", "requiresSignature": True},
            ],
            created_by=users["manager"].id,
        )

        db.add(safety_template)
        db.add(handover_template)

        await db.commit()
        print("Database seeded successfully.")
        print(f"  Organization: {org.name} ({org.id})")
        for role, user in users.items():
            print(f"  {role}: {user.email} / {role}123")


if __name__ == "__main__":
    asyncio.run(seed())
