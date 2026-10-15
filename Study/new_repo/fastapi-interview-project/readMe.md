## What is fastapi
FastAPI is a modern Python web framework for building APIs. It is based on Starlette for the web layer and Pydantic for data validation and serialization. It supports async programming and automatically generates OpenAPI documentation.

# FastAPI automatically converts the Python dictionary into JSON.

## Why do you use Pydantic in FastAPI?
Pydantic is used for data validation and serialization. I define the expected structure and types of request data using Pydantic models, and FastAPI automatically validates incoming requests against those models.

200 → successful request
201 → resource created
400 → bad request
401 → unauthenticated
403 → forbidden
404 → resource not found
500 → server error

## 
main.py

FastAPI
   │
   ├── GET /products
   │       ↓
   │   ProductResponse
   │
   ├── GET /products/{id}
   │       ↓
   │   ProductResponse
   │
   ├── POST /products
   │       ↓
   │   ProductCreate
   │
   ├── PUT /products/{id}
   │       ↓
   │   ProductCreate
   │
   └── DELETE /products/{id}
           ↓
       HTTPException

## 
ProductCreate
     ↓
What the client is allowed to send

ProductResponse
     ↓
What the API returns

HTTPException
     ↓
How the API communicates errors


## Dependency Injection Function
Suppose every API needs some common functionality:

database connection
current logged-in user
authentication
configuration
common headers
logging

Instead of writing the same code inside every endpoint, we create a dependency function and let FastAPI provide its result to our endpoint.

## What is dependency injection in FastAPI?
Dependency Injection is a mechanism where FastAPI automatically provides required dependencies to an endpoint using Depends(). It helps us reuse common functionality such as database sessions, authentication and configuration without creating those dependencies manually inside every endpoint.


## Connect FastAPI to PostgreSQL
# Why do we use yield in get_db()?
We use yield to provide the database session to the endpoint and then execute the cleanup code in the finally block after the request is completed, ensuring the session is closed.

## How do you fetch a product by ID using SQLAlchemy?
"I inject a SQLAlchemy session using FastAPI's Depends. Then I query the Product model, use filter() to match the ID, and first() to retrieve the first matching record. If no record is found, first() returns None, so I raise an HTTP 404 exception."