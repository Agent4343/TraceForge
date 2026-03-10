from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    verify_password,
)
from app.models.user import User
from app.schemas.auth import (
    AuthResponse,
    ForgotPasswordRequest,
    LoginRequest,
    MFAVerifyRequest,
    RefreshRequest,
    TokenResponse,
    UserOut,
)

router = APIRouter(prefix="/auth", tags=["auth"])


def _user_out(user: User) -> UserOut:
    return UserOut(
        id=user.id,
        organization_id=user.organization_id,
        email=user.email,
        display_name=user.display_name,
        role=user.role,
        mfa_enabled=user.mfa_enabled,
        device_id=user.device_id,
        is_active=user.is_active,
        created_at=user.created_at.isoformat(),
        last_active_at=user.last_active_at.isoformat() if user.last_active_at else None,
    )


@router.post("/login", response_model=AuthResponse)
async def login(body: LoginRequest, request: Request, db: AsyncSession = Depends(get_db)):
    from app.core.rate_limit import auth_rate_limiter

    auth_rate_limiter.check(request)
    result = await db.execute(select(User).where(User.email == body.email, User.is_active.is_(True)))
    user = result.scalar_one_or_none()
    if user is None or not verify_password(body.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    if body.device_id:
        user.device_id = body.device_id
    user.last_active_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(user)

    if user.mfa_enabled:
        # Issue a short-lived session token for MFA verification
        session_token = create_access_token(user.id, user.organization_id)
        return AuthResponse(
            user=_user_out(user),
            access_token=session_token,
            refresh_token="",
            requires_mfa=True,
        )

    access = create_access_token(user.id, user.organization_id)
    refresh = create_refresh_token(user.id, user.organization_id)
    return AuthResponse(user=_user_out(user), access_token=access, refresh_token=refresh)


@router.post("/mfa/verify", response_model=AuthResponse)
async def verify_mfa(body: MFAVerifyRequest, db: AsyncSession = Depends(get_db)):
    payload = decode_token(body.session_token)
    if payload is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid session")

    from uuid import UUID
    user_id = UUID(payload["sub"])
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")

    # Validate TOTP code against stored secret
    if not user.mfa_secret:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="MFA not configured")

    from app.services.mfa import verify_totp_code
    if not verify_totp_code(user.mfa_secret, body.code):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid MFA code")

    access = create_access_token(user.id, user.organization_id)
    refresh = create_refresh_token(user.id, user.organization_id)
    return AuthResponse(user=_user_out(user), access_token=access, refresh_token=refresh)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout():
    # Stateless JWT — client discards tokens. Could add token blocklist later.
    return


@router.post("/forgot-password", status_code=status.HTTP_204_NO_CONTENT)
async def forgot_password(body: ForgotPasswordRequest, db: AsyncSession = Depends(get_db)):
    # Always return 204 to avoid user enumeration
    result = await db.execute(select(User).where(User.email == body.email, User.is_active.is_(True)))
    user = result.scalar_one_or_none()
    if user:
        reset_token = create_access_token(user.id, user.organization_id)
        from app.services.email import send_password_reset_email

        send_password_reset_email(body.email, reset_token)
    return


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(body: RefreshRequest, db: AsyncSession = Depends(get_db)):
    payload = decode_token(body.refresh_token)
    if payload is None or payload.get("type") != "refresh":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")

    from uuid import UUID
    user_id = UUID(payload["sub"])
    org_id = UUID(payload["org"])

    result = await db.execute(select(User).where(User.id == user_id, User.is_active.is_(True)))
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")

    access = create_access_token(user_id, org_id)
    refresh = create_refresh_token(user_id, org_id)
    return TokenResponse(access_token=access, refresh_token=refresh)


# ── MFA Setup ────────────────────────────────────────────────────────────────

from pydantic import BaseModel
from app.core.deps import get_current_user


class MFASetupResponse(BaseModel):
    secret: str
    provisioning_uri: str
    qr_code_base64: str


class MFAEnableRequest(BaseModel):
    code: str


@router.post("/mfa/setup", response_model=MFASetupResponse)
async def setup_mfa(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Generate a new MFA secret and QR code for the user."""
    from app.services.mfa import generate_mfa_secret, generate_provisioning_uri, generate_qr_code_base64

    secret = generate_mfa_secret()
    # Store the secret temporarily — not yet enabled until verified
    current_user.mfa_secret = secret
    await db.commit()

    return MFASetupResponse(
        secret=secret,
        provisioning_uri=generate_provisioning_uri(secret, current_user.email),
        qr_code_base64=generate_qr_code_base64(secret, current_user.email),
    )


@router.post("/mfa/enable", status_code=status.HTTP_204_NO_CONTENT)
async def enable_mfa(
    body: MFAEnableRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Verify a TOTP code and enable MFA for the user."""
    if not current_user.mfa_secret:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Call /auth/mfa/setup first")

    from app.services.mfa import verify_totp_code

    if not verify_totp_code(current_user.mfa_secret, body.code):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid MFA code")

    current_user.mfa_enabled = True
    await db.commit()
