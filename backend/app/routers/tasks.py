from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.models.workflow import StepAssignment
from app.schemas.workflow import StepAssignmentOut

router = APIRouter(prefix="/tasks", tags=["tasks"])


@router.get("/mine", response_model=list[StepAssignmentOut])
async def my_tasks(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(StepAssignment)
        .where(
            StepAssignment.assigned_to == current_user.id,
            StepAssignment.status.in_(["todo", "in_progress"]),
        )
        .order_by(StepAssignment.due_date.asc().nullslast())
    )
    assignments = result.scalars().all()
    return [
        StepAssignmentOut(
            id=s.id,
            workflow_id=s.workflow_id,
            step_number=s.step_number,
            step_name=s.step_name,
            assigned_to=s.assigned_to,
            assigned_by=s.assigned_by,
            status=s.status,
            due_date=s.due_date.isoformat() if s.due_date else None,
            assigned_at=s.assigned_at.isoformat(),
            completed_at=s.completed_at.isoformat() if s.completed_at else None,
            is_locked=s.is_locked,
            locked_at=s.locked_at.isoformat() if s.locked_at else None,
        )
        for s in assignments
    ]
