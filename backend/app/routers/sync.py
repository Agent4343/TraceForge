from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.models.workflow import SyncOperation
from app.schemas.sync import SyncOperationIn, SyncResponse

router = APIRouter(prefix="/sync", tags=["sync"])


@router.post("/operations", response_model=SyncResponse)
async def receive_sync_operation(
    body: SyncOperationIn,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    op = SyncOperation(
        id=body.id,
        organization_id=current_user.organization_id,
        user_id=current_user.id,
        type=body.type,
        entity_type=body.entity_type,
        entity_id=body.entity_id,
        field_id=body.field_id,
        value=body.value,
        timestamp=body.timestamp,
        device_id=body.device_id,
        processed=False,
    )
    db.add(op)

    # Process operation inline for now (could be async via Celery)
    await _process_operation(db, op, current_user)

    op.processed = True
    op.processed_at = datetime.now(timezone.utc)
    await db.commit()

    return SyncResponse(success=True)


async def _process_operation(db: AsyncSession, op: SyncOperation, user: User):
    """Apply the sync operation to the database."""
    from app.models.workflow import FormResponse, StepAssignment

    if op.type == "create_response" and op.field_id and op.value:
        resp = FormResponse(
            workflow_id=op.entity_id,
            step_number=0,  # Could be derived from context
            field_id=op.field_id,
            field_label="",
            value=op.value,
            responded_by=user.id,
            device_id=op.device_id,
            timestamp=op.timestamp,
        )
        db.add(resp)

    elif op.type == "update_response" and op.field_id and op.value:
        from sqlalchemy import select, update

        await db.execute(
            update(FormResponse)
            .where(
                FormResponse.workflow_id == op.entity_id,
                FormResponse.field_id == op.field_id,
            )
            .values(value=op.value, timestamp=op.timestamp)
        )

    elif op.type == "sign_step":
        # Signature data comes via the dedicated sign endpoint; this is a fallback
        pass

    elif op.type == "handover":
        # Handover logic is handled via the dedicated handover endpoint
        pass
