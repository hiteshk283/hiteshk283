from datetime import datetime


class Command:
    id: int
    originator_id: int
    target: str
    payload: str
    status: str
    created_at: datetime
    executed_at: datetime | None
