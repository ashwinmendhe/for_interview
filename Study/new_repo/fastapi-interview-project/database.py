from sqlalchemy import create_engine, URL
from sqlalchemy.orm import sessionmaker, declarative_base


# DATABASE_URL = "postgresql://postgres:password@localhost:5432/fastapi_products"
database_url = URL.create(
    "postgresql+psycopg2",
    username="postgres",
    password="Ashwin@11",
    host="localhost",
    port=5432,
    database="dhive-main",
)
engine = create_engine(database_url)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()