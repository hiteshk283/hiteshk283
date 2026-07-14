import random
import string
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import or_, and_

from app.core.database import get_db
from app.models.user import User
from app.models.link_code import LinkCode
from app.models.connection import Connection
from app.models.audit_log import AuditLog
from app.auth.dependencies import get_current_user

router = APIRouter()

def generate_random_code(length=10):
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

@router.post("/code", status_code=status.HTTP_201_CREATED)
async def generate_code(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    # Generate a unique code
    while True:
        code_str = generate_random_code()
        result = await db.execute(select(LinkCode).where(LinkCode.code == code_str))
        if not result.scalars().first():
            break
            
    new_code = LinkCode(code=code_str, creator_id=current_user.id)
    db.add(new_code)
    
    audit = AuditLog(user_id=current_user.id, action="code_generated")
    db.add(audit)
    
    await db.commit()
    await db.refresh(new_code)
    return {"code": new_code.code}

@router.post("/link", status_code=status.HTTP_200_OK)
async def link_with_code(code: str, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    result = await db.execute(select(LinkCode).where(LinkCode.code == code))
    link_code = result.scalars().first()
    
    if not link_code:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invalid code")
        
    if link_code.is_used:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Code has already been used")
        
    if link_code.creator_id == current_user.id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot use your own code")

    # Check if connection already exists
    conn_result = await db.execute(
        select(Connection).where(
            or_(
                and_(Connection.user1_id == current_user.id, Connection.user2_id == link_code.creator_id),
                and_(Connection.user1_id == link_code.creator_id, Connection.user2_id == current_user.id)
            )
        )
    )
    existing_conn = conn_result.scalars().first()
    if existing_conn:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="You are already connected with this user")

    # Mark code as used
    link_code.is_used = True
    link_code.used_by_id = current_user.id
    
    # Create connection
    new_connection = Connection(
        user1_id=link_code.creator_id,
        user2_id=current_user.id,
        status="active"
    )
    db.add(new_connection)
    
    audit = AuditLog(user_id=current_user.id, action="link_used", details={"creator_id": str(link_code.creator_id)})
    db.add(audit)
    
    await db.commit()
    return {"msg": "Successfully linked"}

@router.post("/{user_id}/block", status_code=status.HTTP_200_OK)
async def block_user(user_id: UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    result = await db.execute(
        select(Connection).where(
            or_(
                and_(Connection.user1_id == current_user.id, Connection.user2_id == user_id),
                and_(Connection.user1_id == user_id, Connection.user2_id == current_user.id)
            )
        )
    )
    connection = result.scalars().first()
    
    if not connection:
        # Check if user exists
        target_user = await db.execute(select(User).where(User.id == user_id))
        if not target_user.scalars().first():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
            
        connection = Connection(
            user1_id=current_user.id,
            user2_id=user_id,
            status="blocked_by_user1"
        )
        db.add(connection)
    else:
        if connection.user1_id == current_user.id:
            connection.status = "blocked_by_user1"
        else:
            connection.status = "blocked_by_user2"
        
    audit = AuditLog(user_id=current_user.id, action="user_blocked", details={"blocked_user": str(user_id)})
    db.add(audit)
    
    # We could send a notification here via WebSocket or Notification DB table
    from app.api.notifications import create_notification
    await create_notification(user_id, "You were blocked", "A user has blocked you.", db)
    
    await db.commit()
    return {"msg": "User blocked"}

@router.post("/{user_id}/unblock", status_code=status.HTTP_200_OK)
async def unblock_user(user_id: UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    result = await db.execute(
        select(Connection).where(
            or_(
                and_(Connection.user1_id == current_user.id, Connection.user2_id == user_id),
                and_(Connection.user1_id == user_id, Connection.user2_id == current_user.id)
            )
        )
    )
    connection = result.scalars().first()
    
    if not connection:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Connection not found")
        
    if (connection.user1_id == current_user.id and connection.status == "blocked_by_user1") or \
       (connection.user2_id == current_user.id and connection.status == "blocked_by_user2"):
        connection.status = "active"
        
    audit = AuditLog(user_id=current_user.id, action="user_unblocked", details={"unblocked_user": str(user_id)})
    db.add(audit)
    
    await db.commit()
    return {"msg": "User unblocked"}
