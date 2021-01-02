from typing import Any

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import as_declarative
from sqlalchemy.orm import sessionmaker

from .config import settings

engine = create_engine(
    settings.SQLALCHEMY_DATABASE_URI,
    pool_pre_ping=True,
    connect_args={"application_name": settings.APP_SYSNAME},
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@as_declarative()
class Base:
    id: Any


# Dependency to get DB session.
def get_db():
    try:
        db = SessionLocal()
        yield db
    finally:
        db.close()
