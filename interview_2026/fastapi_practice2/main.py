from fastapi import FastAPI, Depends
from models import Product
from database import SessionLocal, engine
import database_model
from sqlalchemy.orm import Session

app = FastAPI()

database_model.Base.metadata.create_all(bind=engine)

all_datas = [
    Product(id=1, name="phone", description="budget phone", price=99, quantity=10 ),
    Product(id=2, name="laptop", description="this is laptop", price=9999.123, quantity=2 ),
]

def init_db():
    db = SessionLocal()
    count = db.query(database_model.Product).count
    if count == 0:
        for data in all_datas:
            db.add(database_model.Product(**data.model_dump()))
        db.commit()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


init_db()

@app.get("/product")
def get_all(db: Session = Depends(get_db)):
    db_product = db.query(database_model.Product).all()
    return db_product

@app.get("/product/{id}")
def get_id(id:int, db:Session = Depends(get_db)):
    db_product = db.query(database_model.Product).filter(database_model.Product.id==id).first()
    if db_product:
        return db_product
    else:
        return "Not Found in db"

@app.post("/product")
def create_data(product: Product, db: Session = Depends(get_db)):
   db.add(database_model.Product(**product.model_dump()))
   db.commit()
   return product
    

@app.put("/product")
def update_data(id:int, product: Product, db: Session = Depends(get_db())):
    df_product = db.query(database_model.Product).filter(database_model.Product.id==id).first()
    if df_product:
        df_product.name = product.name
        db.commit()
        return "update"
    else:
        return "not found"


@app.delete("/product")
def delete_data(id:int):
    for i in range(len(all_datas)):
        if all_datas[i].id == id:
            del all_datas[i]
            return "deleted"
    return "not found"




# DB_NAME=dhive-main
# DB_USERNAME=postgres
# DB_PASSWORD=Ashwin@11
