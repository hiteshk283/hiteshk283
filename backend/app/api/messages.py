import json
from typing import List, Optional
from uuid import UUID
from fastapi import APIRouter, Depends, status, HTTPException, BackgroundTasks
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

@router.delete("/{receiver_id}", status_code=status.HTTP_200_OK)
async def delete_chat_history(
    receiver_id: UUID,
    db: AsyncSession = Depends(get_db), 
    current_user: User = Depends(get_current_user)
):
    from sqlalchemy import delete
    # Delete all messages between current_user and receiver_id
    query = delete(Message).where(
        or_(
            and_(Message.sender_id == current_user.id, Message.receiver_id == receiver_id),
            and_(Message.sender_id == receiver_id, Message.receiver_id == current_user.id)
        )
    )
    await db.execute(query)
    
    # Audit log
    audit = AuditLog(user_id=current_user.id, action=f"deleted_chat_with_{receiver_id}")
    db.add(audit)
    
    await db.commit()
    return {"msg": "Chat history deleted"}

@router.post("/", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
async def send_message(
    msg_in: MessageCreate, 
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db), 
    current_user: User = Depends(get_current_user)
):
    if not msg_in.receiver_id:
        raise HTTPException(status_code=400, detail="Global chat is disabled. receiver_id is required.")
        
    receiver_result = await db.execute(select(User).where(User.id == msg_in.receiver_id))
    receiver = receiver_result.scalars().first()
    if not receiver:
        raise HTTPException(status_code=404, detail="Receiver not found.")
        
    is_ai_message = getattr(receiver, 'is_ai', False)

    # Check connection status
    conn_result = await db.execute(
        select(Connection).where(
            or_(
                and_(Connection.user1_id == current_user.id, Connection.user2_id == msg_in.receiver_id),
                and_(Connection.user1_id == msg_in.receiver_id, Connection.user2_id == current_user.id)
            )
        )
    )
    connection = conn_result.scalars().first()

    if not is_ai_message:
        if not connection:
            raise HTTPException(status_code=403, detail="You are not connected to this user.")
            
    if connection and connection.status != "active":
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
        
    if is_ai_message:
        async def process_ai_reply(ai_user: User, human_user: User, user_text: str):
            from app.services.ai_agent_service import generate_ai_response_stream
            from app.core.database import AsyncSessionLocal
            import uuid
            
            ai_message_id = uuid.uuid4()
            accumulated_text = ""
            
            async for chunk in generate_ai_response_stream(ai_user.username, user_text):
                accumulated_text += chunk
                
                ai_msg_data = {
                    "type": "message_chunk",
                    "data": {
                        "id": str(ai_message_id),
                        "sender_id": str(ai_user.id),
                        "receiver_id": str(human_user.id),
                        "message_text": chunk,
                        "done": False
                    }
                }
                await manager.send_personal_message(json.dumps(ai_msg_data), human_user.id)
            
            async with AsyncSessionLocal() as session:
                ai_message = Message(
                    id=ai_message_id,
                    sender_id=ai_user.id,
                    receiver_id=human_user.id,
                    message_text=accumulated_text
                )
                session.add(ai_message)
                await session.commit()
                await session.refresh(ai_message)
                
                done_msg_data = {
                    "type": "message_chunk",
                    "data": {
                        "id": str(ai_message.id),
                        "sender_id": str(ai_message.sender_id),
                        "receiver_id": str(ai_message.receiver_id),
                        "message_text": "",
                        "done": True,
                        "created_at": ai_message.created_at.isoformat()
                    }
                }
                await manager.send_personal_message(json.dumps(done_msg_data), human_user.id)
                
        background_tasks.add_task(process_ai_reply, receiver, current_user, msg_in.message_text)
    
    return new_message
