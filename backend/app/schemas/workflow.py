from datetime import datetime
from enum import Enum
from typing import Generic, TypeVar
from uuid import UUID

from pydantic import BaseModel, Field

T = TypeVar("T")


class PaginatedResponse(BaseModel, Generic[T]):
    """Wrapper for paginated list responses."""
    items: list[T]
    total: int
    page: int
    per_page: int
    pages: int


class WorkflowPriority(str, Enum):
    standard = "standard"
    high = "high"
    critical = "critical"


class StepStatus(str, Enum):
    locked = "locked"
    todo = "todo"
    in_progress = "in_progress"
    signed = "signed"
    complete = "complete"


class StepAssignmentInput(BaseModel):
    step_number: int = Field(ge=1, le=100)
    assigned_to: UUID
    due_date: datetime | None = None


class WorkflowCreate(BaseModel):
    template_id: UUID
    name: str = Field(min_length=1, max_length=255)
    site_id: UUID | None = None
    due_date: datetime | None = None
    priority: WorkflowPriority = WorkflowPriority.standard
    step_assignments: list[StepAssignmentInput] = Field(default=[], max_length=50)


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
    status: StepStatus


class FormResponseInput(BaseModel):
    field_id: UUID
    value: str = Field(max_length=50000)
    timestamp: datetime | None = None
    device_id: str = Field(default="", max_length=255)


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


# Max 500KB base64 signature (decodes to ~375KB PNG)
MAX_SIGNATURE_BASE64_LENGTH = 500_000


class SignStepRequest(BaseModel):
    signature_image_base64: str = Field(max_length=MAX_SIGNATURE_BASE64_LENGTH)
    attestation_text: str = Field(min_length=1, max_length=1000)
    timestamp: datetime | None = None
    device_id: str = Field(default="", max_length=255)
    content_hash: str = Field(default="", max_length=128)
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
    step_number: int = Field(ge=1, le=100)
    to_user_id: UUID
    note: str = Field(max_length=2000)
    context_photo_base64: str | None = Field(None, max_length=MAX_SIGNATURE_BASE64_LENGTH)


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
