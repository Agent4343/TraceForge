from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.core.config import settings
from app.core.database import async_session, engine, Base
from app.core.logging_config import setup_logging
from app.core.middleware import setup_middleware
from app.routers import auth, sync, tasks, templates, users, workflows

setup_logging()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Import all models so Base.metadata knows about them
    import app.models.user  # noqa: F401
    import app.models.template  # noqa: F401
    import app.models.workflow  # noqa: F401

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    await engine.dispose()


app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    root_path="/api/v1",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_tags=[
        {"name": "auth", "description": "Authentication and MFA"},
        {"name": "users", "description": "User management and invitations"},
        {"name": "templates", "description": "Form template CRUD"},
        {"name": "workflows", "description": "Workflow instances, steps, signatures, and audit"},
        {"name": "tasks", "description": "Current user's assigned tasks"},
        {"name": "sync", "description": "Offline sync operations"},
    ],
)

_origins = [o.strip() for o in settings.cors_origins.split(",") if o.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "X-Request-ID"],
)

setup_middleware(app)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(templates.router)
app.include_router(workflows.router)
app.include_router(tasks.router)
app.include_router(sync.router)


@app.get("/health")
async def health():
    """Health check with database connectivity verification."""
    db_ok = False
    try:
        async with async_session() as session:
            await session.execute(text("SELECT 1"))
            db_ok = True
    except Exception:
        pass

    status_val = "healthy" if db_ok else "degraded"
    return {"status": status_val, "database": "connected" if db_ok else "unreachable"}
