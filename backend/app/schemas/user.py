from uuid import UUID

from pydantic import BaseModel, EmailStr


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
    role: str | None = None
    is_active: bool | None = None


class DeviceTokenUpdate(BaseModel):
    device_token: str


class InviteItem(BaseModel):
    email: EmailStr
    role: str


class InviteRequest(BaseModel):
    invites: list[InviteItem]
    custom_message: str | None = None


class InviteResponse(BaseModel):
    sent: int
    failed: list[str] = []
