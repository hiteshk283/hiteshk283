from pydantic import BaseModel
from uuid import UUID
from datetime import datetime

class NotificationResponse(BaseModel):
    id: UUID
    user_id: UUID
    title: str
    body: str
    read_status: bool
    created_at: datetime

    class Config:
        from_attributes = True
