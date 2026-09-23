from sqlalchemy.orm import sessionmaker
from sqlalchemy import create_engine
from sqlalchemy.engine import URL

# DATABASE_URL = "postgresql+psycopg2://postgres:Ashwin%4011@localhost:5432/dhive-main"
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