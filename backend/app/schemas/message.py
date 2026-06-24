from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import Optional

class MessageCreate(BaseModel):
    message_text: str
    receiver_id: Optional[UUID] = None

class MessageResponse(BaseModel):
    id: UUID
    sender_id: Optional[UUID]
    receiver_id: Optional[UUID] = None
    message_text: str
    created_at: datetime

    class Config:
        from_attributes = True
