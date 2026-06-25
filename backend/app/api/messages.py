import json
from typing import List, Optional
from uuid import UUID
from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import desc, or_, and_

from app.core.database import get_db
from app.models.user import User
from app.models.message import Message
from app.models.audit_log import AuditLog
from app.models.connection import Connection
from app.schemas.message import MessageCreate, MessageResponse
from app.auth.dependencies import get_current_user
from app.websocket.manager import manager
from app.api.notifications import create_notification

router = APIRouter()

@router.get("/", response_model=List[MessageResponse])
async def get_messages(
    receiver_id: UUID,
    skip: int = 0, 
    limit: int = 50, 
    db: AsyncSession = Depends(get_db), 
    current_user: User = Depends(get_current_user)
):
    query = select(Message).where(
        or_(
            and_(Message.sender_id == current_user.id, Message.receiver_id == receiver_id),
            and_(Message.sender_id == receiver_id, Message.receiver_id == current_user.id)
        )
    )
        
    result = await db.execute(query.order_by(desc(Message.created_at)).offset(skip).limit(limit))
    messages = result.scalars().all()
    # Reverse to chronological order
    return messages[::-1]

@router.post("/", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
async def send_message(msg_in: MessageCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not msg_in.receiver_id:
        raise HTTPException(status_code=400, detail="Global chat is disabled. receiver_id is required.")
        
    # Check if they are connected and not blocked
    conn_result = await db.execute(
        select(Connection).where(
            or_(
                and_(Connection.user1_id == current_user.id, Connection.user2_id == msg_in.receiver_id),
                and_(Connection.user1_id == msg_in.receiver_id, Connection.user2_id == current_user.id)
            )
        )
    )
    connection = conn_result.scalars().first()
    if not connection:
        raise HTTPException(status_code=403, detail="You are not connected to this user.")
        
    if connection.status != "active":
        raise HTTPException(status_code=403, detail="Cannot send message. Connection is blocked.")

    new_message = Message(
        sender_id=current_user.id,
        receiver_id=msg_in.receiver_id,
        message_text=msg_in.message_text
    )
    db.add(new_message)
    
    # Audit
    audit = AuditLog(user_id=current_user.id, action="message_sent")
    db.add(audit)
    
    await db.commit()
    await db.refresh(new_message)
    
    # Format message for broadcast
    msg_data = {
        "type": "new_message",
        "data": {
            "id": str(new_message.id),
            "sender_id": str(new_message.sender_id),
            "receiver_id": str(new_message.receiver_id) if new_message.receiver_id else None,
            "message_text": new_message.message_text,
            "created_at": new_message.created_at.isoformat()
        }
    }
    
    msg_json = json.dumps(msg_data)
    await manager.send_personal_message(msg_json, msg_in.receiver_id)
    if msg_in.receiver_id != current_user.id:
        await manager.send_personal_message(msg_json, current_user.id)
    
    return new_message
