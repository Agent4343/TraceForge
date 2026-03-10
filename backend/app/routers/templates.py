import copy
import math
from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.template import Template
from app.models.user import User
from app.schemas.template import TemplateCreate, TemplateOut, TemplateUpdate
from app.schemas.workflow import PaginatedResponse

router = APIRouter(prefix="/templates", tags=["templates"])


def _template_out(t: Template) -> TemplateOut:
    return TemplateOut(
        id=t.id,
        organization_id=t.organization_id,
        name=t.name,
        status=t.status,
        version=t.version,
        fields=t.fields or [],
        steps=t.steps or [],
        created_by=t.created_by,
        created_at=t.created_at.isoformat(),
        updated_at=t.updated_at.isoformat(),
    )


@router.get("", response_model=PaginatedResponse[TemplateOut])
async def list_templates(
    page: int = Query(1, ge=1),
    per_page: int = Query(25, ge=1, le=100),
    status_filter: str | None = Query(None, alias="status"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    base = select(Template).where(Template.organization_id == current_user.organization_id)
    if status_filter:
        base = base.where(Template.status == status_filter)

    # Total count
    count_result = await db.execute(select(func.count()).select_from(base.subquery()))
    total = count_result.scalar() or 0

    # Paginated items
    query = base.order_by(Template.updated_at.desc()).offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(query)
    items = [_template_out(t) for t in result.scalars().all()]

    return PaginatedResponse(
        items=items,
        total=total,
        page=page,
        per_page=per_page,
        pages=math.ceil(total / per_page) if total > 0 else 0,
    )


@router.post("", response_model=TemplateOut, status_code=status.HTTP_201_CREATED)
async def create_template(
    body: TemplateCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    template = Template(
        organization_id=current_user.organization_id,
        name=body.name,
        fields=body.fields,
        steps=body.steps,
        created_by=current_user.id,
    )
    db.add(template)
    await db.commit()
    await db.refresh(template)
    return _template_out(template)


@router.put("/{template_id}", response_model=TemplateOut)
async def update_template(
    template_id: UUID,
    body: TemplateUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Template).where(
            Template.id == template_id,
            Template.organization_id == current_user.organization_id,
        )
    )
    template = result.scalar_one_or_none()
    if template is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Template not found")

    if body.name is not None:
        template.name = body.name
    if body.fields is not None:
        template.fields = body.fields
    if body.steps is not None:
        template.steps = body.steps
    if body.status is not None:
        template.status = body.status

    template.version += 1
    template.updated_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(template)
    return _template_out(template)


@router.post("/{template_id}/duplicate", response_model=TemplateOut, status_code=status.HTTP_201_CREATED)
async def duplicate_template(
    template_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Template).where(
            Template.id == template_id,
            Template.organization_id == current_user.organization_id,
        )
    )
    original = result.scalar_one_or_none()
    if original is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Template not found")

    duplicate = Template(
        organization_id=current_user.organization_id,
        name=f"{original.name} (Copy)",
        status="draft",
        version=1,
        fields=copy.deepcopy(original.fields),
        steps=copy.deepcopy(original.steps),
        created_by=current_user.id,
    )
    db.add(duplicate)
    await db.commit()
    await db.refresh(duplicate)
    return _template_out(duplicate)
