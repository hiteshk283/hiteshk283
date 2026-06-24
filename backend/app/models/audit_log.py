import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey, JSON
from sqlalchemy.dialects.postgresql import UUID
from app.models.base import Base

class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    action = Column(String, nullable=False, index=True) # e.g., 'user_registration', 'login', 'logout', 'message_sent', 'ws_connect', 'ws_disconnect'
    details = Column(JSON, nullable=True) # Additional info if needed
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
