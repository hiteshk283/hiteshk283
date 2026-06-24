from sqlalchemy.ext.asyncio import AsyncSession
from app.models.audit_log import AuditLog
from uuid import UUID
from typing import Optional

async def log_audit_action(db: AsyncSession, action: str, user_id: Optional[UUID] = None, details: dict = None):
    audit = AuditLog(
        user_id=user_id,
        action=action,
        details=details
    )
    db.add(audit)
    await db.commit()
