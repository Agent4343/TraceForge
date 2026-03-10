"""Celery worker for async background tasks."""

import asyncio
import logging

from celery import Celery

from app.core.config import settings

logger = logging.getLogger(__name__)

celery_app = Celery(
    "formflow",
    broker=settings.redis_url,
    backend=settings.redis_url,
)

celery_app.conf.update(
    task_serializer="json",
    result_serializer="json",
    accept_content=["json"],
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
    task_acks_late=True,
    worker_prefetch_multiplier=1,
)


def _run_async(coro):
    """Run an async function from a sync Celery task."""
    loop = asyncio.new_event_loop()
    try:
        return loop.run_until_complete(coro)
    finally:
        loop.close()


@celery_app.task(bind=True, max_retries=3, default_retry_delay=60)
def generate_pdf_task(self, workflow_id: str):
    """Generate a PDF for a workflow, upload to S3, and update the DB."""
    from uuid import UUID

    wf_id = UUID(workflow_id)

    async def _do():
        from app.core.database import async_session
        from app.services.pdf import render_workflow_pdf
        from app.services.storage import upload_pdf
        from app.models.workflow import Workflow
        from sqlalchemy import select

        async with async_session() as db:
            pdf_bytes, content_hash = await render_workflow_pdf(db, wf_id)
            pdf_url = upload_pdf(wf_id, pdf_bytes)

            if pdf_url is None:
                # S3 not configured — store hash anyway
                pdf_url = f"/local/workflows/{wf_id}/report.pdf"
                logger.warning("S3 not configured; PDF URL is a placeholder")

            result = await db.execute(select(Workflow).where(Workflow.id == wf_id))
            workflow = result.scalar_one()
            workflow.pdf_url = pdf_url
            workflow.pdf_hash = content_hash
            await db.commit()

            return {"pdf_url": pdf_url, "pdf_hash": content_hash}

    try:
        return _run_async(_do())
    except Exception as exc:
        logger.exception("PDF generation failed for workflow %s", workflow_id)
        raise self.retry(exc=exc)


@celery_app.task(bind=True, max_retries=3, default_retry_delay=30)
def send_email_task(self, to_email: str, subject: str, html_body: str):
    """Send an email asynchronously."""
    from app.services.email import send_email

    try:
        success = send_email(to_email, subject, html_body)
        if not success:
            logger.warning("Email to %s was not sent (transport not configured?)", to_email)
        return {"sent": success}
    except Exception as exc:
        logger.exception("Email task failed for %s", to_email)
        raise self.retry(exc=exc)


@celery_app.task(bind=True, max_retries=3, default_retry_delay=30)
def send_push_task(self, user_id: str, notification_type: str, title: str, body: str, workflow_id: str | None = None):
    """Send a push notification asynchronously."""
    from uuid import UUID

    async def _do():
        from app.core.database import async_session
        from app.services.push import send_push

        uid = UUID(user_id)
        wf_id = UUID(workflow_id) if workflow_id else None
        async with async_session() as db:
            await send_push(db, uid, notification_type, title, body, wf_id)

    try:
        _run_async(_do())
    except Exception as exc:
        logger.exception("Push notification task failed for user %s", user_id)
        raise self.retry(exc=exc)


@celery_app.task
def check_overdue_tasks():
    """Periodic task to check for overdue step assignments and send notifications."""
    from datetime import datetime, timezone

    async def _do():
        from sqlalchemy import select
        from app.core.database import async_session
        from app.models.workflow import StepAssignment, Workflow
        from app.services.push import notify_step_due_soon

        now = datetime.now(timezone.utc)
        async with async_session() as db:
            # Find steps due within 24 hours that haven't been completed
            from datetime import timedelta

            threshold = now + timedelta(hours=24)
            result = await db.execute(
                select(StepAssignment)
                .where(
                    StepAssignment.due_date.isnot(None),
                    StepAssignment.due_date <= threshold,
                    StepAssignment.due_date > now,
                    StepAssignment.status.in_(["todo", "in_progress"]),
                )
            )
            assignments = result.scalars().all()
            for sa in assignments:
                wf_result = await db.execute(select(Workflow).where(Workflow.id == sa.workflow_id))
                wf = wf_result.scalar_one_or_none()
                if wf is None:
                    continue
                hours_left = int((sa.due_date - now).total_seconds() / 3600)
                await notify_step_due_soon(db, sa.assigned_to, sa.step_name, hours_left, sa.workflow_id)

    _run_async(_do())


# Periodic task schedule (Celery Beat)
celery_app.conf.beat_schedule = {
    "check-overdue-tasks-every-hour": {
        "task": "app.worker.check_overdue_tasks",
        "schedule": 3600.0,
    },
}
