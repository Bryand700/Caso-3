from __future__ import annotations

from contextlib import contextmanager

from sqlalchemy import create_engine as createEngine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from config import settings


class Base(DeclarativeBase):
    pass


engineOptions = {
    "pool_size": settings.poolSize,
    "max_overflow": 0,
    "pool_pre_ping": True,
    "pool_timeout": 30,
}

engine = createEngine(settings.databaseUrl, **engineOptions)
SessionLocal = sessionmaker(bind=engine, expire_on_commit=False, class_=Session)


@contextmanager
def sessionScope():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()
