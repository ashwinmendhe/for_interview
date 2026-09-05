import requests
import json

URL = " http://127.0.0.1:8000/deviceapi"

def get_data(id=None):
    data = {}
    if id is not None:
        data = {'id': id}
        json_data = json.dumps(data)
    print(f"----11--- {json_data}")
    r = requests.get(url=URL, data= json_data)

    data = r.json()
    print(data)

get_data(1)
