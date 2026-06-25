import uuid
from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import or_, and_

from app.core.database import get_db
from app.models.user import User
from app.models.connection import Connection
from app.models.audit_log import AuditLog
from app.models.session import Session
from app.schemas.user import UserResponse
from app.auth.dependencies import get_current_user

router = APIRouter()

@router.get("/", response_model=List[UserResponse])
async def get_users(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    # Only return users who have a connection with current_user
    # Connection can be active or blocked, but they are in the "network"
    
    conn_query = select(Connection).where(
        or_(
            Connection.user1_id == current_user.id,
            Connection.user2_id == current_user.id
        )
    )
    conn_result = await db.execute(conn_query)
    connections = conn_result.scalars().all()
    
    if not connections:
        return []
        
    connected_user_ids = []
    for c in connections:
        if c.user1_id == current_user.id:
            connected_user_ids.append(c.user2_id)
        else:
            connected_user_ids.append(c.user1_id)
            
    # Fetch those users
    user_query = select(User).where(
        and_(
            User.id.in_(connected_user_ids),
            User.is_active == True
        )
    )
    user_result = await db.execute(user_query)
    users = user_result.scalars().all()
    
    return users

@router.delete("/me", status_code=status.HTTP_200_OK)
async def delete_my_account(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    # Soft delete: Set is_active = False and anonymize
    current_user.is_active = False
    
    # Anonymize data to protect privacy but maintain referential integrity
    random_id = uuid.uuid4().hex[:8]
    current_user.username = f"Deleted User {random_id}"
    current_user.email = f"deleted_{random_id}@deleted.com"
    current_user.password_hash = "DELETED"
    
    # Delete all active sessions
    from sqlalchemy import delete
    await db.execute(delete(Session).where(Session.user_id == current_user.id))
    
    # Audit log
    audit = AuditLog(user_id=current_user.id, action="account_deleted")
    db.add(audit)
    
    await db.commit()
    return {"msg": "Account successfully deleted"}
