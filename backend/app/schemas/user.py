from pydantic import BaseModel, EmailStr, Field
from uuid import UUID
from datetime import datetime
from typing import Optional

class UserBase(BaseModel):
    email: EmailStr
    username: str

class UserCreate(UserBase):
    password: str = Field(..., min_length=8)
    link_code: Optional[str] = None

class UserResponse(UserBase):
    id: UUID
    is_active: bool
    is_ai: bool = False
    is_admin: bool = False
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
