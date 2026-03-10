from uuid import UUID

from pydantic import BaseModel, EmailStr


class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    device_id: str | None = None


class MFAVerifyRequest(BaseModel):
    code: str
    session_token: str


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class RefreshRequest(BaseModel):
    refresh_token: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str


class AuthResponse(BaseModel):
    user: "UserOut"
    access_token: str
    refresh_token: str
    requires_mfa: bool = False


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


# Resolve forward ref
AuthResponse.model_rebuild()
