import json
from typing import List
from uuid import UUID
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import desc

from app.core.database import get_db, AsyncSessionLocal
from app.models.user import User
from app.models.notification import Notification
from app.schemas.notification import NotificationResponse
from app.auth.dependencies import get_current_user
from app.websocket.manager import manager

router = APIRouter()

async def create_notification(user_id: UUID, title: str, body: str):
    async with AsyncSessionLocal() as db:
        notif = Notification(user_id=user_id, title=title, body=body)
        db.add(notif)
        await db.commit()
        await db.refresh(notif)
        
        # Send via WS
        notif_data = {
            "type": "notification",
            "data": {
                "id": str(notif.id),
                "title": notif.title,
                "body": notif.body,
                "read_status": notif.read_status,
                "created_at": notif.created_at.isoformat()
            }
        }
        await manager.send_personal_message(json.dumps(notif_data), user_id)

@router.get("/", response_model=List[NotificationResponse])
async def get_notifications(skip: int = 0, limit: int = 50, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    result = await db.execute(
        select(Notification)
        .where(Notification.user_id == current_user.id)
        .order_by(desc(Notification.created_at))
        .offset(skip)
        .limit(limit)
    )
    return result.scalars().all()
