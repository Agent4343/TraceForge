from enum import Enum
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


class UserRole(str, Enum):
    admin = "admin"
    manager = "manager"
    worker = "worker"
    viewer = "viewer"


class UserOut(BaseModel):
    id: UUID
    organization_id: UUID
    email: str
    display_name: str
    role: str
    mfa_enabled: bool
    device_id: str | None
    is_active: bool
    created_at: str
    last_active_at: str | None

    model_config = {"from_attributes": True}


class UserUpdate(BaseModel):
    role: UserRole | None = None
    is_active: bool | None = None


class DeviceTokenUpdate(BaseModel):
    device_token: str = Field(max_length=512)


class InviteItem(BaseModel):
    email: EmailStr
    role: UserRole


class InviteRequest(BaseModel):
    invites: list[InviteItem] = Field(min_length=1, max_length=50)
    custom_message: str | None = Field(None, max_length=500)


class InviteResponse(BaseModel):
    sent: int
    failed: list[str] = []
