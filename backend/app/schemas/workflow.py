from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class StepAssignmentInput(BaseModel):
    step_number: int
    assigned_to: UUID
    due_date: datetime | None = None


class WorkflowCreate(BaseModel):
    template_id: UUID
    name: str
    site_id: UUID | None = None
    due_date: datetime | None = None
    priority: str = "standard"
    step_assignments: list[StepAssignmentInput] = []


class WorkflowOut(BaseModel):
    id: UUID
    organization_id: UUID
    template_id: UUID
    template_version: int
    name: str
    site_id: UUID | None
    status: str
    priority: str
    created_by: UUID
    due_date: str | None
    created_at: str
    completed_at: str | None
    pdf_url: str | None
    pdf_hash: str | None

    model_config = {"from_attributes": True}


class StepAssignmentOut(BaseModel):
    id: UUID
    workflow_id: UUID
    step_number: int
    step_name: str
    assigned_to: UUID
    assigned_by: UUID
    status: str
    due_date: str | None
    assigned_at: str
    completed_at: str | None
    is_locked: bool
    locked_at: str | None

    model_config = {"from_attributes": True}


class StepStatusUpdate(BaseModel):
    status: str


class FormResponseInput(BaseModel):
    field_id: UUID
    value: str
    timestamp: datetime | None = None
    device_id: str = ""


class FormResponseOut(BaseModel):
    id: UUID
    workflow_id: UUID
    step_number: int
    field_id: UUID
    field_label: str
    value: str
    responded_by: UUID
    device_id: str
    timestamp: str

    model_config = {"from_attributes": True}


class SignStepRequest(BaseModel):
    signature_image_base64: str
    attestation_text: str
    timestamp: datetime | None = None
    device_id: str = ""
    content_hash: str = ""
    mfa_verified: bool = False


class SignatureOut(BaseModel):
    id: UUID
    workflow_id: UUID
    step_number: int
    signer_id: UUID
    signer_name: str
    signer_role: str
    attestation_text: str
    timestamp: str
    mfa_verified: bool
    content_hash: str

    model_config = {"from_attributes": True}


class HandoverRequest(BaseModel):
    step_number: int
    to_user_id: UUID
    note: str
    context_photo_base64: str | None = None


class AuditLogOut(BaseModel):
    id: UUID
    workflow_id: UUID
    step_number: int | None
    actor_id: UUID
    actor_name: str
    actor_role: str
    action: str
    entity_type: str
    entity_id: UUID
    metadata: str
    timestamp: str
    device_id: str

    model_config = {"from_attributes": True}


class PDFExportOut(BaseModel):
    pdf_url: str
    pdf_hash: str
    generated_at: str
