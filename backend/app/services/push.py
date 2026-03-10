"""Push notification service for APNs."""

import json
import logging
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.user import User

logger = logging.getLogger(__name__)


async def send_push(
    db: AsyncSession,
    user_id: UUID,
    notification_type: str,
    title: str,
    body: str,
    workflow_id: UUID | None = None,
):
    """Send a push notification to a user via APNs."""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None or not user.device_token:
        return

    payload = {
        "aps": {
            "alert": {"title": title, "body": body},
            "sound": "default",
            "badge": 1,
        },
        "type": notification_type,
    }
    if workflow_id:
        payload["workflow_id"] = str(workflow_id)

    # TODO: integrate with PyAPNs2 when APNs credentials are configured
    if not settings.apns_key_id:
        logger.info("APNs not configured — push skipped: %s -> %s", notification_type, user.email)
        return

    try:
        from apns2.client import APNsClient, NotificationPriority
        from apns2.payload import Payload

        apns_payload = Payload(
            alert={"title": title, "body": body},
            sound="default",
            badge=1,
            custom={"type": notification_type, "workflow_id": str(workflow_id) if workflow_id else None},
        )
        client = APNsClient(
            settings.apns_key_path,
            use_sandbox=settings.apns_use_sandbox,
            use_alternative_port=False,
        )
        client.send_notification(
            user.device_token,
            apns_payload,
            topic=settings.apns_bundle_id,
            priority=NotificationPriority.Immediate,
        )
    except Exception:
        logger.exception("Failed to send push notification to %s", user.email)


async def notify_step_assigned(db: AsyncSession, assignee_id: UUID, workflow_name: str, step_name: str, workflow_id: UUID):
    await send_push(
        db, assignee_id,
        notification_type="step_assigned",
        title="New Task Assigned",
        body=f"You've been assigned '{step_name}' on {workflow_name}",
        workflow_id=workflow_id,
    )


async def notify_step_due_soon(db: AsyncSession, assignee_id: UUID, task_name: str, hours: int, workflow_id: UUID):
    await send_push(
        db, assignee_id,
        notification_type="step_due_soon",
        title="Task Due Soon",
        body=f"{task_name} is due in {hours} hours",
        workflow_id=workflow_id,
    )


async def notify_handover(db: AsyncSession, to_user_id: UUID, from_name: str, workflow_name: str, workflow_id: UUID):
    await send_push(
        db, to_user_id,
        notification_type="handover_received",
        title="Handover Received",
        body=f"{from_name} handed over a task on {workflow_name}",
        workflow_id=workflow_id,
    )


async def notify_workflow_complete(db: AsyncSession, creator_id: UUID, workflow_name: str, workflow_id: UUID):
    await send_push(
        db, creator_id,
        notification_type="workflow_complete",
        title="Workflow Complete",
        body=f"{workflow_name} has been completed",
        workflow_id=workflow_id,
    )
