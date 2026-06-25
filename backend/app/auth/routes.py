from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import delete
from jose import jwt, JWTError

from app.core.database import get_db
from app.core.config import settings
from app.models.user import User
from app.models.session import Session
from app.models.audit_log import AuditLog
from app.schemas.user import UserCreate, UserResponse
from app.schemas.auth import Token, RefreshTokenRequest
from app.auth.security import get_password_hash, verify_password, create_access_token, create_refresh_token
from app.auth.dependencies import get_current_user

from app.models.link_code import LinkCode
from app.models.connection import Connection

router = APIRouter()

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(user_in: UserCreate, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == user_in.email))
    if result.scalars().first():
        raise HTTPException(status_code=400, detail="Email already registered")
        
    result = await db.execute(select(User).where(User.username == user_in.username))
    if result.scalars().first():
        raise HTTPException(status_code=400, detail="Username already registered")
        
    # Validate link_code if provided
    link_code_obj = None
    if user_in.link_code:
        result = await db.execute(select(LinkCode).where(LinkCode.code == user_in.link_code))
        link_code_obj = result.scalars().first()
        if not link_code_obj:
            raise HTTPException(status_code=400, detail="Invalid link code")
        if link_code_obj.is_used:
            raise HTTPException(status_code=400, detail="Link code has already been used")
        
    new_user = User(
        email=user_in.email,
        username=user_in.username,
        password_hash=get_password_hash(user_in.password)
    )
    db.add(new_user)
    await db.flush() # flush to get new_user.id
    
    # Process link code connection
    if link_code_obj:
        link_code_obj.is_used = True
        link_code_obj.used_by_id = new_user.id
        
        new_connection = Connection(
            user1_id=link_code_obj.creator_id,
            user2_id=new_user.id,
            status="active"
        )
        db.add(new_connection)
    
    # Audit log
    audit = AuditLog(user_id=new_user.id, action="user_registration")
    db.add(audit)
    
    await db.commit()
    await db.refresh(new_user)
    return new_user

@router.post("/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: AsyncSession = Depends(get_db)):
    # Using username field from OAuth2 form as email for convenience or username
    result = await db.execute(select(User).where(User.username == form_data.username))
    user = result.scalars().first()
    
    if not user:
        # fallback to email if username not found
        result = await db.execute(select(User).where(User.email == form_data.username))
        user = result.scalars().first()
        
    if not user or not verify_password(form_data.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect username or password")
        
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Inactive user")

    access_token = create_access_token(subject=user.id)
    refresh_token = create_refresh_token(subject=user.id)
    
    # Save refresh token session
    # decoding just to get exp
    payload = jwt.decode(refresh_token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm])
    expires_at = datetime.utcfromtimestamp(payload.get("exp"))
    
    new_session = Session(user_id=user.id, refresh_token=refresh_token, expires_at=expires_at)
    db.add(new_session)
    
    # Audit log
    audit = AuditLog(user_id=user.id, action="login")
    db.add(audit)
    
    await db.commit()
    
    return {"access_token": access_token, "refresh_token": refresh_token, "token_type": "bearer"}

@router.post("/logout")
async def logout(refresh_token_req: RefreshTokenRequest, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_user)):
    # Delete the refresh token session
    await db.execute(delete(Session).where(Session.refresh_token == refresh_token_req.refresh_token))
    
    # Audit log
    audit = AuditLog(user_id=current_user.id, action="logout")
    db.add(audit)
    
    await db.commit()
    return {"msg": "Successfully logged out"}

@router.post("/refresh", response_model=Token)
async def refresh_token(refresh_token_req: RefreshTokenRequest, db: AsyncSession = Depends(get_db)):
    try:
        payload = jwt.decode(refresh_token_req.refresh_token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm])
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token type")
        user_id = payload.get("sub")
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")

    # Check if session exists in DB
    result = await db.execute(select(Session).where(Session.refresh_token == refresh_token_req.refresh_token))
    session = result.scalars().first()
    
    if not session or session.expires_at < datetime.utcnow():
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token expired or invalid")
        
    # Generate new tokens
    new_access_token = create_access_token(subject=user_id)
    new_refresh_token = create_refresh_token(subject=user_id)
    
    # Replace old session
    await db.execute(delete(Session).where(Session.id == session.id))
    
    payload = jwt.decode(new_refresh_token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm])
    expires_at = datetime.utcfromtimestamp(payload.get("exp"))
    
    new_session = Session(user_id=user_id, refresh_token=new_refresh_token, expires_at=expires_at)
    db.add(new_session)
    await db.commit()
    
    return {"access_token": new_access_token, "refresh_token": new_refresh_token, "token_type": "bearer"}
