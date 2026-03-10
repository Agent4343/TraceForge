from uuid import UUID

from pydantic import BaseModel


class TemplateCreate(BaseModel):
    name: str
    fields: list[dict] = []
    steps: list[dict] = []


class TemplateUpdate(BaseModel):
    name: str | None = None
    fields: list[dict] | None = None
    steps: list[dict] | None = None
    status: str | None = None


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
