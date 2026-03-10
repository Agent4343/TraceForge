from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
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
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
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
        session_token = create_access_token(user.id, user.organization_id)
        return AuthResponse(
            user=_user_out(user),
            access_token="",
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

    # TODO: validate TOTP code against user.mfa_secret
    # For now accept any 6-digit code
    if len(body.code) != 6 or not body.code.isdigit():
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
    # Always return success to avoid user enumeration
    # TODO: send email via SES/SendGrid
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
