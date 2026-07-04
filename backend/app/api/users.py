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
from app.auth.dependencies import get_current_user, get_admin_user

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
    
    connected_user_ids = []
    for c in connections:
        if c.user1_id == current_user.id:
            connected_user_ids.append(c.user2_id)
        else:
            connected_user_ids.append(c.user1_id)
            
    # Fetch those users plus AI users
    if connected_user_ids:
        user_query = select(User).where(
            or_(
                and_(
                    User.id.in_(connected_user_ids),
                    User.is_active == True
                ),
                User.is_ai == True
            )
        )
    else:
        user_query = select(User).where(User.is_ai == True)
        
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

@router.get("/admin/all", response_model=List[UserResponse])
async def get_all_users_admin(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_admin_user)):
    """Admin only: Get all users in the system."""
    result = await db.execute(select(User))
    return result.scalars().all()

@router.delete("/admin/{user_id}", status_code=status.HTTP_200_OK)
async def delete_user_admin(user_id: uuid.UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_admin_user)):
    """Admin only: Delete a user by ID."""
    result = await db.execute(select(User).where(User.id == user_id))
    user_to_delete = result.scalars().first()
    
    if not user_to_delete:
        from fastapi import HTTPException
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        
    from sqlalchemy import delete
    await db.execute(delete(User).where(User.id == user_id))
    
    # Audit log
    audit = AuditLog(user_id=current_user.id, action=f"admin_deleted_user_{user_id}")
    db.add(audit)
    
    await db.commit()
    return {"msg": "User deleted by admin"}
