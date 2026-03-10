"""Shared test fixtures using SQLite for fast, isolated tests."""

import asyncio
from uuid import uuid4

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.database import Base, get_db
from app.core.security import hash_password
from app.main import app
from app.models.user import Organization, User

# Use SQLite for tests — no Postgres required
TEST_DB_URL = "sqlite+aiosqlite:///file::memory:?cache=shared&uri=true"

engine = create_async_engine(TEST_DB_URL, echo=False)
TestSession = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(autouse=True)
async def setup_db():
    """Create all tables before each test, drop after."""
    # Import models so metadata is populated
    import app.models.user  # noqa: F401
    import app.models.template  # noqa: F401
    import app.models.workflow  # noqa: F401

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture
async def db_session():
    async with TestSession() as session:
        yield session


async def _override_get_db():
    async with TestSession() as session:
        yield session


@pytest_asyncio.fixture
async def client():
    app.dependency_overrides[get_db] = _override_get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def seed_org(db_session: AsyncSession) -> Organization:
    org = Organization(name="Test Corp", slug="test-corp", industry="Testing")
    db_session.add(org)
    await db_session.commit()
    await db_session.refresh(org)
    return org


@pytest_asyncio.fixture
async def seed_admin(db_session: AsyncSession, seed_org: Organization) -> User:
    user = User(
        organization_id=seed_org.id,
        email="admin@test.io",
        display_name="Admin User",
        password_hash=hash_password("password123"),
        role="admin",
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user


@pytest_asyncio.fixture
async def seed_worker(db_session: AsyncSession, seed_org: Organization) -> User:
    user = User(
        organization_id=seed_org.id,
        email="worker@test.io",
        display_name="Worker User",
        password_hash=hash_password("password123"),
        role="worker",
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user


@pytest_asyncio.fixture
async def admin_token(seed_admin: User) -> str:
    from app.core.security import create_access_token

    return create_access_token(seed_admin.id, seed_admin.organization_id)


@pytest_asyncio.fixture
async def worker_token(seed_worker: User) -> str:
    from app.core.security import create_access_token

    return create_access_token(seed_worker.id, seed_worker.organization_id)
