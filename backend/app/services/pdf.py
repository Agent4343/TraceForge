"""PDF generation service using WeasyPrint and Jinja2."""

import base64
import hashlib
import logging
from datetime import datetime, timezone
from pathlib import Path
from uuid import UUID

from jinja2 import Environment, FileSystemLoader
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.template import Template
from app.models.user import Organization, User
from app.models.workflow import (
    AuditLogEntry,
    FormResponse,
    SignatureRecord,
    StepAssignment,
    Workflow,
)

logger = logging.getLogger(__name__)

_template_dir = Path(settings.pdf_templates_dir)
_jinja_env = Environment(loader=FileSystemLoader(str(_template_dir)), autoescape=True)


async def render_workflow_pdf(db: AsyncSession, workflow_id: UUID) -> tuple[bytes, str]:
    """Render a workflow report as a PDF.

    Returns:
        Tuple of (pdf_bytes, content_hash_hex).
    """
    # Load workflow
    wf_result = await db.execute(select(Workflow).where(Workflow.id == workflow_id))
    workflow = wf_result.scalar_one()

    # Load org
    org_result = await db.execute(select(Organization).where(Organization.id == workflow.organization_id))
    org = org_result.scalar_one()

    # Load template name
    tmpl_result = await db.execute(select(Template).where(Template.id == workflow.template_id))
    template = tmpl_result.scalar_one()

    # Load step assignments
    steps_result = await db.execute(
        select(StepAssignment)
        .where(StepAssignment.workflow_id == workflow_id)
        .order_by(StepAssignment.step_number)
    )
    step_assignments = steps_result.scalars().all()

    # Build step data with responses, signatures, and assignee names
    steps_data = []
    for sa in step_assignments:
        # Assignee name
        user_result = await db.execute(select(User).where(User.id == sa.assigned_to))
        assignee = user_result.scalar_one_or_none()

        # Responses for this step
        resp_result = await db.execute(
            select(FormResponse)
            .where(FormResponse.workflow_id == workflow_id, FormResponse.step_number == sa.step_number)
            .order_by(FormResponse.timestamp)
        )
        responses = resp_result.scalars().all()

        # Signature for this step
        sig_result = await db.execute(
            select(SignatureRecord)
            .where(SignatureRecord.workflow_id == workflow_id, SignatureRecord.step_number == sa.step_number)
            .order_by(SignatureRecord.timestamp.desc())
        )
        signature = sig_result.scalar_one_or_none()

        sig_data = None
        if signature:
            sig_data = {
                "signer_name": signature.signer_name,
                "signer_role": signature.signer_role,
                "attestation_text": signature.attestation_text,
                "image_base64": base64.b64encode(signature.signature_image_data).decode("utf-8"),
                "timestamp": signature.timestamp.isoformat(),
                "mfa_verified": signature.mfa_verified,
                "content_hash": signature.content_hash,
            }

        steps_data.append({
            "step_number": sa.step_number,
            "step_name": sa.step_name,
            "status": sa.status,
            "assignee_name": assignee.display_name if assignee else "Unknown",
            "responses": [
                {
                    "field_id": str(r.field_id),
                    "field_label": r.field_label,
                    "value": r.value,
                    "timestamp": r.timestamp.isoformat(),
                }
                for r in responses
            ],
            "signature": sig_data,
        })

    # Audit entries
    audit_result = await db.execute(
        select(AuditLogEntry)
        .where(AuditLogEntry.workflow_id == workflow_id)
        .order_by(AuditLogEntry.timestamp)
    )
    audit_entries = [
        {
            "timestamp": e.timestamp.isoformat(),
            "actor_name": e.actor_name,
            "actor_role": e.actor_role,
            "action": e.action,
            "step_number": e.step_number,
        }
        for e in audit_result.scalars().all()
    ]

    # Compute content hash over all data
    hash_parts = [str(workflow.id), workflow.name, workflow.status]
    for sd in steps_data:
        hash_parts.append(f"{sd['step_number']}:{sd['status']}")
        for r in sd["responses"]:
            hash_parts.append(f"{r['field_id']}={r['value']}")
        if sd["signature"]:
            hash_parts.append(sd["signature"]["content_hash"])
    content_hash = hashlib.sha256("|".join(hash_parts).encode()).hexdigest()

    # Render HTML
    generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    jinja_template = _jinja_env.get_template("workflow_report.html")
    html = jinja_template.render(
        workflow=workflow,
        org_name=org.name,
        template_name=template.name,
        steps=steps_data,
        audit_entries=audit_entries,
        content_hash=content_hash,
        generated_at=generated_at,
    )

    # Convert HTML to PDF
    from weasyprint import HTML

    pdf_bytes = HTML(string=html).write_pdf()

    return pdf_bytes, content_hash
