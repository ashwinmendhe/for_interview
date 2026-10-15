from fastapi import FastAPI, HTTPException, Depends, Header
from pydantic import BaseModel, Field, ConfigDict
from database import engine, Base, get_db
from models import Product as ProductModel
from sqlalchemy.orm import Session


app = FastAPI()

Base.metadata.create_all(bind=engine)

def get_app_name():
    return "This is Product management App"

def get_client_type(client_type: str = Header(...)):
    return client_type


class ProductCreate(BaseModel):
    name: str = Field(min_length=3, max_lenght= 50)
    price: float = Field(gt=0)
    category: str = Field(min_length=2, max_length=30)


class ProductResponse(BaseModel):
    id: int
    name: str
    price: float
    category: str
    model_config = ConfigDict(from_attributes=True)


datas = [
    {
        "id": 1,
        "name": "iPhone 15",
        "price": 70000,
        "category": "Mobile"
    },
    {
        "id": 2,
        "name": "MacBook Air",
        "price": 100000,
        "category": "Laptop"
    }
]

@app.get("/test")
def test(client_type: str = Depends(get_client_type)):
    return {
        "client_type" : client_type
    }

@app.get("/")
def home(app_name: str = Depends(get_app_name)):
    return {"msg": "welcom to product",
            "app_name": app_name}

# @app.get("/products", response_model = list[ProductResponse])
# def get_products():
#     return datas

# @app.get("/products/{product_id}", response_model=ProductResponse)
# def get_product(product_id: int):
#     for data in datas:
#         if data["id"] == product_id:
#             return data
#     raise HTTPException(
#         status_code=404,
#         detail="Product not found"
#       )


# @app.post("/products", response_model=ProductResponse)
# def create_product(product: ProductCreate):
#     new_data = {
#         "id": len(datas) +1,
#         "name": product.name,
#         "price": product.price,
#         "category": product.category
#     }

#     datas.append(new_data)
#     return new_data

# @app.put("/products/{product_id}", response_model=ProductResponse)
# def update_product(product_id: int, product: ProductCreate):
#     for data in datas:
#         print(type(product), product)
#         if data["id"] == product_id:
#             data["name"] = product.name
#             data["price"] = product.price
#             data["category"] = product.category
#             return data
#     raise HTTPException(
#         status_code=404,
#         detail="producr not found"
#     )

# @app.delete("/products/{product_id}")
# def delete_product(product_id:int):
#     for data in datas:
#         if data["id"] == product_id:
#             datas.remove(data)
#             return {"data deleted": "yes"}
#     raise HTTPException(
#         status_code=404,
#         detail="product not found"
#     )




@app.post("/products", response_model=ProductResponse)
def DBcreate_Product(product: ProductCreate, db: Session = Depends(get_db)):
    new_product = ProductModel(
        name = product.name,
        price = product.price,
        category = product.category
    )
    db.add(new_product)
    db.commit()
    db.refresh(new_product)
    return new_product


@app.get("/products", response_model=list[ProductResponse])
def DBget_product(db: Session = Depends(get_db)):
    products = db.query(ProductModel).all()
    return products

@app.get("/products/{product_id}", response_model=ProductResponse)
def DBget_byid_product(product_id: int, db: Session = Depends(get_db)):
    product = db.query(ProductModel).filter(ProductModel.id == product_id).first()
    if product is None:
        raise HTTPException(status_code=404, detail="Product Not found")
    return product

@app.put("/products", response_model=ProductResponse)
def DBupdate_product(product_id:int, product: ProductCreate, db: Session = Depends(get_db)):
    updateProduct = db.query(ProductModel).filter(ProductModel.id == product_id).first()
    if updateProduct is None:
        raise HTTPException(status_code=404, detail="Product Not found")

    updateProduct.name = product.name
    updateProduct.price = product.price
    updateProduct.category = product.category
    db.commit()
    db.refresh(updateProduct)
    return updateProduct

@app.delete("/products/{product_id}")
def DBdelete_product(product_id: int, db: Session = Depends(get_db)):
    delete_data = db.query(ProductModel).filter(ProductModel.id == product_id).first()
    if delete_data is None:
        raise HTTPException(status_code=404, detail="Product Not found")
    db.delete(delete_data)
    db.commit()
    return {
        "msg": "data delted"
    }



