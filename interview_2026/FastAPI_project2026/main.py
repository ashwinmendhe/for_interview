from fastapi import FastAPI
from models import Product

app = FastAPI()

@app.get("/")
def greet():
    return "welcom ashwin"

products = [
    Product(id=1, name="phone", description="budget phone", price=99, quantity=10 ),
    Product(id=2, name="laptop", description="this is laptop", price=9999.123, quantity=2 ),
]

@app.get("/products")
def get_all_products():
    return products


@app.get("/product/{id}")
def get_product_by_id(id: int):
    for product in products:
        if product.id == id:
            return product

    return "not found"

@app.post("/product")
def add_product(product: Product):
    products.append(product)


@app.put("/product")
def update_product(id: int, product: Product):
    for i in range(len(products)):
        if products[i].id == id:
            products[i] = product
            return "updated"
    return "not found"


@app.delete("/product")
def delete_product(id:int):
    for i in range(len(products)):
        if products[i].id == id:
            del products[i]
            return "deleted"
    return "not found"


