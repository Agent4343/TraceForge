from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class SyncOperationIn(BaseModel):
    id: UUID
    type: str
    entity_type: str
    entity_id: UUID
    field_id: UUID | None = None
    value: str | None = None
    timestamp: datetime
    device_id: str
    synced: bool = False
    sync_attempted_at: datetime | None = None
    error_message: str | None = None


class SyncResponse(BaseModel):
    success: bool
