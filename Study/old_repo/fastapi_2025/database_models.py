from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import Column , Integer,String, Float


Base = declarative_base()


class Address(Base):
    __tablename__ = "Address"
    id = Column(Integer, primary_key = True, index=True)
    name = Column(String)
    age = Column(Integer)
    address = Column(String)
    coordinates = Column(Float)
    

