from fastapi import FastAPI, Depends
from models import Address
from database import session, engine
import database_models
from sqlalchemy.orm import Session
from fastapi.middleware.cors import CORSMiddleware


app = FastAPI()

app.add_middleware(
    CORSMiddleware, allow_origins=[], allow_methods = ["*"]
)

database_models.Base.metadata.create_all(bind=engine)



addr = [Address(id=1, name="ashwin", age=35, address="shreeeam chowk", coordinates=23.09),
        Address(id=6, name="ashwin1", age=34, address="shreeeam chowk1", coordinates=24.09),
        Address(id=5, name="ashwin2", age=36, address="shreeeam chowk2", coordinates=25.09)]


def init_db(addr):
    db = session()
    count = db.query(database_models.Address).count
    if count == 0:
        for adr in addr:
            db.add(database_models.Address(**adr.model_dump()))
        db.commit()

init_db(addr)


def get_db():
    db = session()
    try:
        yield db
    finally:
        db.close()




@app.get("/address")
def get_all_address(db: Session = Depends(get_db)):
    db_address = db.query(database_models.Address).all()
    return db_address

@app.get("/address/{id}")
def get_address_id(id:int, db : Session=Depends(get_db)):
    db_address = db.query(database_models.Address).filter(database_models.Address.id==id).first()
    if db_address:
        return db_address
    return "product not found"

@app.post("/address")
def add_address(address: Address, db : Session=Depends(get_db)):
    db_address = db.add(database_models.Address(**address.model_dump()))
    db.commit()
    return address


@app.put("/address")
def update_address(id:int, address: Address, db: Session = Depends(get_db)):
    db_address = db.query(database_models.Address).filter(database_models.Address.id==id).first()
    if db_address:
        db_address.name = address.name
        db_address.age = address.age
        db_address.address = address.address
        db_address.coordinates = address.coordinates

        db.commit()
        return "adress updated"
    else:
        return "No address found"
    


@app.delete("/address")
def delete_address(id:int,address: Address, db: Session = Depends(get_db) ):
    db_address = db.query(database_models.Address).filter(database_models.Address.id==id).first()
    if db_address:
        db.delete(db_address)
        db.commit()
        return "deleted"
    else:
        return "Address not found"

