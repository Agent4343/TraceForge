from enum import Enum
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    device_id: str | None = Field(None, max_length=255)


class MFAVerifyRequest(BaseModel):
    code: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")
    session_token: str


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str = Field(min_length=8, max_length=128)


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
