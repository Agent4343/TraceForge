from datetime import datetime
from enum import Enum
from uuid import UUID

from pydantic import BaseModel, Field


class SyncOperationType(str, Enum):
    create_response = "create_response"
    update_response = "update_response"
    sign_step = "sign_step"
    handover = "handover"


class SyncOperationIn(BaseModel):
    id: UUID
    type: SyncOperationType
    entity_type: str = Field(max_length=50)
    entity_id: UUID
    field_id: UUID | None = None
    value: str | None = Field(None, max_length=50000)
    timestamp: datetime
    device_id: str = Field(max_length=255)
    synced: bool = False
    sync_attempted_at: datetime | None = None
    error_message: str | None = Field(None, max_length=1000)


class SyncResponse(BaseModel):
    success: bool
