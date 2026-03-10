from enum import Enum
from uuid import UUID

from pydantic import BaseModel, Field


class TemplateStatus(str, Enum):
    draft = "draft"
    active = "active"
    archived = "archived"


class TemplateCreate(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    fields: list[dict] = Field(default=[], max_length=100)
    steps: list[dict] = Field(default=[], max_length=50)


class TemplateUpdate(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=255)
    fields: list[dict] | None = Field(None, max_length=100)
    steps: list[dict] | None = Field(None, max_length=50)
    status: TemplateStatus | None = None


class TemplateOut(BaseModel):
    id: UUID
    organization_id: UUID
    name: str
    status: str
    version: int
    fields: list[dict]
    steps: list[dict]
    created_by: UUID
    created_at: str
    updated_at: str

    model_config = {"from_attributes": True}
