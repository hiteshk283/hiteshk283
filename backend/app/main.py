from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.database import engine
from app.models.base import Base

from app.auth.routes import router as auth_router
from app.websocket.routes import router as ws_router
from app.api.messages import router as messages_router
from app.api.notifications import router as notifications_router
from app.api.users import router as users_router
from app.api.connections import router as connections_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create all tables on startup
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    # Could clean up connections here if needed

app = FastAPI(
    title=settings.app_name,
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins for development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix="/auth", tags=["auth"])
app.include_router(messages_router, prefix="/api/messages", tags=["messages"])
app.include_router(notifications_router, prefix="/api/notifications", tags=["notifications"])
app.include_router(users_router, prefix="/api/users", tags=["users"])
app.include_router(connections_router, prefix="/api/connections", tags=["connections"])
app.include_router(ws_router, tags=["websocket"])

@app.get("/")
def read_root():
    return {"message": "Welcome to Control Center API"}


@app.get("/healthz", tags=["Health"])
def health_check():
    return {"status": "ok"}
