import json
import asyncio
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from jose import jwt, JWTError

from app.core.config import settings
from app.core.database import AsyncSessionLocal
from app.websocket.manager import manager
from app.models.audit_log import AuditLog
from app.schemas.auth import TokenPayload

router = APIRouter()

async def get_ws_user_id(token: str):
    try:
        payload = jwt.decode(token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm])
        token_data = TokenPayload(**payload)
        if payload.get("type") == "refresh":
            return None
        return token_data.sub
    except JWTError:
        return None

@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket, token: str = Query(...)):
    user_id_str = await get_ws_user_id(token)
    if not user_id_str:
        await websocket.close(code=1008) # Policy Violation
        return

    import uuid
    user_id = uuid.UUID(user_id_str)

    await manager.connect(websocket, user_id)
    
    # Audit connect
    async with AsyncSessionLocal() as db:
        audit = AuditLog(user_id=user_id, action="ws_connect")
        db.add(audit)
        await db.commit()

    try:
        while True:
            # heartbeat ping/pong or just listen
            data = await websocket.receive_text()
            # We can parse json if needed, for heartbeat {"type": "ping"} -> send {"type": "pong"}
            try:
                msg_data = json.loads(data)
                if msg_data.get("type") == "ping":
                    await websocket.send_text(json.dumps({"type": "pong"}))
            except json.JSONDecodeError:
                pass
            
    except WebSocketDisconnect:
        manager.disconnect(websocket, user_id)
        # Audit disconnect
        async with AsyncSessionLocal() as db:
            audit = AuditLog(user_id=user_id, action="ws_disconnect")
            db.add(audit)
            await db.commit()
