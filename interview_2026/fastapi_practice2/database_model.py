from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import Column, Integer, Float, String
Base = declarative_base()

class Product(Base):
    __tablename__ = "Product"
    id = Column(Integer, primary_key=True)
    name = Column(String)
    description = Column(String)
    price = Column(Float)
    quantity = Column(Integer)
