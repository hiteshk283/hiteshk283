from datetime import datetime
from pydantic import BaseModel


class CommandSchema(BaseModel):
    id: int
    originator_id: int
    target: str
    payload: str
    status: str
    created_at: datetime
    executed_at: datetime | None

    class Config:
        orm_mode = True
