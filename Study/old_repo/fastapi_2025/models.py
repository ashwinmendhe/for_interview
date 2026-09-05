from pydantic import BaseModel

class Address(BaseModel):
    id: int
    name: str
    age : int
    address : str
    coordinates : float
    

