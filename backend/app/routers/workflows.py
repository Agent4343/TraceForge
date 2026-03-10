import base64
import hashlib
from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.template import Template
from app.models.user import User
from app.models.workflow import (
    AuditLogEntry,
    FormResponse,
    SignatureRecord,
    StepAssignment,
    Workflow,
)
from app.schemas.workflow import (
    AuditLogOut,
    FormResponseInput,
    FormResponseOut,
    HandoverRequest,
    PDFExportOut,
    SignStepRequest,
    SignatureOut,
    StepAssignmentOut,
    StepStatusUpdate,
    WorkflowCreate,
    WorkflowOut,
)

router = APIRouter(prefix="/workflows", tags=["workflows"])


# ── Helpers ──────────────────────────────────────────────────────────────────


def _workflow_out(w: Workflow) -> WorkflowOut:
    return WorkflowOut(
        id=w.id,
        organization_id=w.organization_id,
        template_id=w.template_id,
        template_version=w.template_version,
        name=w.name,
        site_id=w.site_id,
        status=w.status,
        priority=w.priority,
        created_by=w.created_by,
        due_date=w.due_date.isoformat() if w.due_date else None,
        created_at=w.created_at.isoformat(),
        completed_at=w.completed_at.isoformat() if w.completed_at else None,
        pdf_url=w.pdf_url,
        pdf_hash=w.pdf_hash,
    )


def _step_out(s: StepAssignment) -> StepAssignmentOut:
    return StepAssignmentOut(
        id=s.id,
        workflow_id=s.workflow_id,
        step_number=s.step_number,
        step_name=s.step_name,
        assigned_to=s.assigned_to,
        assigned_by=s.assigned_by,
        status=s.status,
        due_date=s.due_date.isoformat() if s.due_date else None,
        assigned_at=s.assigned_at.isoformat(),
        completed_at=s.completed_at.isoformat() if s.completed_at else None,
        is_locked=s.is_locked,
        locked_at=s.locked_at.isoformat() if s.locked_at else None,
    )


def _audit_out(e: AuditLogEntry) -> AuditLogOut:
    return AuditLogOut(
        id=e.id,
        workflow_id=e.workflow_id,
        step_number=e.step_number,
        actor_id=e.actor_id,
        actor_name=e.actor_name,
        actor_role=e.actor_role,
        action=e.action,
        entity_type=e.entity_type,
        entity_id=e.entity_id,
        metadata=e.metadata_json,
        timestamp=e.timestamp.isoformat(),
        device_id=e.device_id,
    )


async def _add_audit(
    db: AsyncSession,
    *,
    workflow_id: UUID,
    step_number: int | None,
    user: User,
    action: str,
    entity_type: str,
    entity_id: UUID,
    metadata_json: str = "{}",
    device_id: str = "server",
):
    entry = AuditLogEntry(
        workflow_id=workflow_id,
        step_number=step_number,
        actor_id=user.id,
        actor_name=user.display_name,
        actor_role=user.role,
        action=action,
        entity_type=entity_type,
        entity_id=entity_id,
        metadata_json=metadata_json,
        device_id=device_id,
    )
    db.add(entry)


# ── Workflow CRUD ────────────────────────────────────────────────────────────


@router.get("", response_model=list[WorkflowOut])
async def list_workflows(
    page: int = Query(1, ge=1),
    per_page: int = Query(25, ge=1, le=100),
    status_filter: str | None = Query(None, alias="status"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = select(Workflow).where(Workflow.organization_id == current_user.organization_id)
    if status_filter:
        query = query.where(Workflow.status == status_filter)
    query = query.order_by(Workflow.created_at.desc()).offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(query)
    return [_workflow_out(w) for w in result.scalars().all()]


@router.get("/{workflow_id}", response_model=WorkflowOut)
async def get_workflow(
    workflow_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Workflow).where(
            Workflow.id == workflow_id,
            Workflow.organization_id == current_user.organization_id,
        )
    )
    wf = result.scalar_one_or_none()
    if wf is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Workflow not found")
    return _workflow_out(wf)


@router.post("", response_model=WorkflowOut, status_code=status.HTTP_201_CREATED)
async def create_workflow(
    body: WorkflowCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Fetch template
    tmpl_result = await db.execute(
        select(Template).where(
            Template.id == body.template_id,
            Template.organization_id == current_user.organization_id,
        )
    )
    template = tmpl_result.scalar_one_or_none()
    if template is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Template not found")

    workflow = Workflow(
        organization_id=current_user.organization_id,
        template_id=template.id,
        template_version=template.version,
        name=body.name,
        site_id=body.site_id,
        priority=body.priority,
        due_date=body.due_date,
        created_by=current_user.id,
        status="in_progress",
    )
    db.add(workflow)
    await db.flush()

    # Create step assignments
    steps = template.steps or []
    for sa_input in body.step_assignments:
        matching_step = next((s for s in steps if s.get("stepNumber") == sa_input.step_number), None)
        step_name = matching_step.get("name", f"Step {sa_input.step_number}") if matching_step else f"Step {sa_input.step_number}"

        assignment = StepAssignment(
            workflow_id=workflow.id,
            step_number=sa_input.step_number,
            step_name=step_name,
            assigned_to=sa_input.assigned_to,
            assigned_by=current_user.id,
            due_date=sa_input.due_date,
            status="todo" if sa_input.step_number == 1 else "locked",
            is_locked=sa_input.step_number != 1,
        )
        db.add(assignment)

    await _add_audit(
        db,
        workflow_id=workflow.id,
        step_number=None,
        user=current_user,
        action="workflow_created",
        entity_type="workflow",
        entity_id=workflow.id,
    )

    await db.commit()
    await db.refresh(workflow)
    return _workflow_out(workflow)


# ── Steps ────────────────────────────────────────────────────────────────────


@router.patch("/{workflow_id}/steps/{step_number}", response_model=StepAssignmentOut)
async def update_step_status(
    workflow_id: UUID,
    step_number: int,
    body: StepStatusUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(StepAssignment).where(
            StepAssignment.workflow_id == workflow_id,
            StepAssignment.step_number == step_number,
        )
    )
    step = result.scalar_one_or_none()
    if step is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Step not found")

    step.status = body.status
    if body.status == "complete":
        step.completed_at = datetime.now(timezone.utc)
        # Unlock next step
        next_result = await db.execute(
            select(StepAssignment).where(
                StepAssignment.workflow_id == workflow_id,
                StepAssignment.step_number == step_number + 1,
            )
        )
        next_step = next_result.scalar_one_or_none()
        if next_step:
            next_step.is_locked = False
            next_step.status = "todo"
            await _add_audit(
                db,
                workflow_id=workflow_id,
                step_number=step_number + 1,
                user=current_user,
                action="step_unlocked",
                entity_type="step",
                entity_id=next_step.id,
            )

    await db.commit()
    await db.refresh(step)
    return _step_out(step)


# ── Responses ────────────────────────────────────────────────────────────────


@router.post(
    "/{workflow_id}/steps/{step_number}/responses",
    response_model=list[FormResponseOut],
    status_code=status.HTTP_201_CREATED,
)
async def submit_responses(
    workflow_id: UUID,
    step_number: int,
    body: list[FormResponseInput],
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    created: list[FormResponse] = []
    for item in body:
        resp = FormResponse(
            workflow_id=workflow_id,
            step_number=step_number,
            field_id=item.field_id,
            field_label="",  # Could look up from template
            value=item.value,
            responded_by=current_user.id,
            device_id=item.device_id,
            timestamp=item.timestamp or datetime.now(timezone.utc),
        )
        db.add(resp)
        created.append(resp)

    await _add_audit(
        db,
        workflow_id=workflow_id,
        step_number=step_number,
        user=current_user,
        action="field_response_submitted",
        entity_type="response",
        entity_id=workflow_id,
        device_id=body[0].device_id if body else "server",
    )

    await db.commit()
    for r in created:
        await db.refresh(r)

    return [
        FormResponseOut(
            id=r.id,
            workflow_id=r.workflow_id,
            step_number=r.step_number,
            field_id=r.field_id,
            field_label=r.field_label,
            value=r.value,
            responded_by=r.responded_by,
            device_id=r.device_id,
            timestamp=r.timestamp.isoformat(),
        )
        for r in created
    ]


# ── Signatures ───────────────────────────────────────────────────────────────


@router.post(
    "/{workflow_id}/steps/{step_number}/sign",
    response_model=SignatureOut,
    status_code=status.HTTP_201_CREATED,
)
async def sign_step(
    workflow_id: UUID,
    step_number: int,
    body: SignStepRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    sig = SignatureRecord(
        workflow_id=workflow_id,
        step_number=step_number,
        signer_id=current_user.id,
        signer_name=current_user.display_name,
        signer_role=current_user.role,
        signature_image_data=base64.b64decode(body.signature_image_base64),
        attestation_text=body.attestation_text,
        device_id=body.device_id,
        timestamp=body.timestamp or datetime.now(timezone.utc),
        ip_address=request.client.host if request.client else None,
        mfa_verified=body.mfa_verified,
        content_hash=body.content_hash,
    )
    db.add(sig)

    await _add_audit(
        db,
        workflow_id=workflow_id,
        step_number=step_number,
        user=current_user,
        action="step_signed",
        entity_type="signature",
        entity_id=sig.id,
        device_id=body.device_id,
    )

    await db.commit()
    await db.refresh(sig)
    return SignatureOut(
        id=sig.id,
        workflow_id=sig.workflow_id,
        step_number=sig.step_number,
        signer_id=sig.signer_id,
        signer_name=sig.signer_name,
        signer_role=sig.signer_role,
        attestation_text=sig.attestation_text,
        timestamp=sig.timestamp.isoformat(),
        mfa_verified=sig.mfa_verified,
        content_hash=sig.content_hash,
    )


# ── Handover ─────────────────────────────────────────────────────────────────


@router.post("/{workflow_id}/handover", response_model=StepAssignmentOut)
async def handover_step(
    workflow_id: UUID,
    body: HandoverRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(StepAssignment).where(
            StepAssignment.workflow_id == workflow_id,
            StepAssignment.step_number == body.step_number,
        )
    )
    step = result.scalar_one_or_none()
    if step is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Step not found")

    step.assigned_to = body.to_user_id
    step.assigned_by = current_user.id
    step.assigned_at = datetime.now(timezone.utc)
    step.status = "todo"

    await _add_audit(
        db,
        workflow_id=workflow_id,
        step_number=body.step_number,
        user=current_user,
        action="handover_initiated",
        entity_type="step",
        entity_id=step.id,
        metadata_json=f'{{"to_user_id": "{body.to_user_id}", "note": "{body.note}"}}',
    )

    await db.commit()
    await db.refresh(step)
    return _step_out(step)


# ── Audit Trail ──────────────────────────────────────────────────────────────


@router.get("/{workflow_id}/audit", response_model=list[AuditLogOut])
async def get_audit_trail(
    workflow_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(AuditLogEntry)
        .where(AuditLogEntry.workflow_id == workflow_id)
        .order_by(AuditLogEntry.timestamp.desc())
    )
    return [_audit_out(e) for e in result.scalars().all()]


# ── PDF Export ───────────────────────────────────────────────────────────────


@router.post("/{workflow_id}/export/pdf", response_model=PDFExportOut)
async def export_pdf(
    workflow_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Workflow).where(
            Workflow.id == workflow_id,
            Workflow.organization_id == current_user.organization_id,
        )
    )
    wf = result.scalar_one_or_none()
    if wf is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Workflow not found")

    # Generate hash from workflow data
    hash_input = f"{wf.id}|{wf.name}|{wf.status}|{wf.created_at.isoformat()}"
    pdf_hash = hashlib.sha256(hash_input.encode()).hexdigest()

    # TODO: actually render PDF and upload to S3
    pdf_url = f"https://api.formflow.io/pdfs/{wf.id}.pdf"

    wf.pdf_url = pdf_url
    wf.pdf_hash = pdf_hash

    await _add_audit(
        db,
        workflow_id=workflow_id,
        step_number=None,
        user=current_user,
        action="pdf_generated",
        entity_type="pdf",
        entity_id=workflow_id,
        metadata_json=f'{{"hash": "{pdf_hash}"}}',
    )

    await db.commit()
    return PDFExportOut(
        pdf_url=pdf_url,
        pdf_hash=pdf_hash,
        generated_at=datetime.now(timezone.utc).isoformat(),
    )
