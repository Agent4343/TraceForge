from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps import get_current_user, require_role
from app.core.security import hash_password
from app.models.user import User
from app.schemas.user import (
    DeviceTokenUpdate,
    InviteRequest,
    InviteResponse,
    UserOut,
    UserUpdate,
)

router = APIRouter(prefix="/users", tags=["users"])


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


@router.get("", response_model=list[UserOut])
async def list_users(
    role: str | None = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_role("admin", "manager")),
):
    query = select(User).where(User.organization_id == current_user.organization_id)
    if role:
        query = query.where(User.role == role)
    result = await db.execute(query.order_by(User.display_name))
    return [_user_out(u) for u in result.scalars().all()]


@router.post("/invite", response_model=InviteResponse)
async def invite_users(
    body: InviteRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_role("admin")),
):
    sent = 0
    failed: list[str] = []
    for invite in body.invites:
        existing = await db.execute(select(User).where(User.email == invite.email))
        if existing.scalar_one_or_none():
            failed.append(invite.email)
            continue

        user = User(
            organization_id=current_user.organization_id,
            email=invite.email,
            display_name=invite.email.split("@")[0],
            password_hash=hash_password("changeme"),  # TODO: send invite email with temp password
            role=invite.role,
        )
        db.add(user)
        sent += 1

    await db.commit()
    return InviteResponse(sent=sent, failed=failed)


@router.patch("/{user_id}", response_model=UserOut)
async def update_user(
    user_id: UUID,
    body: UserUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_role("admin")),
):
    result = await db.execute(
        select(User).where(User.id == user_id, User.organization_id == current_user.organization_id)
    )
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    if body.role is not None:
        user.role = body.role
    if body.is_active is not None:
        user.is_active = body.is_active

    await db.commit()
    await db.refresh(user)
    return _user_out(user)


@router.patch("/me/device-token", status_code=status.HTTP_204_NO_CONTENT)
async def update_device_token(
    body: DeviceTokenUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    current_user.device_token = body.device_token
    await db.commit()


@router.post("/{user_id}/mfa/reset", status_code=status.HTTP_204_NO_CONTENT)
async def reset_mfa(
    user_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_role("admin")),
):
    result = await db.execute(
        select(User).where(User.id == user_id, User.organization_id == current_user.organization_id)
    )
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    user.mfa_enabled = False
    user.mfa_secret = None
    await db.commit()
