import requests
import json

URL = " http://127.0.0.1:8000/s"

def get_data(id=None):
    data = {}
    if id is not None:
        data = {'id': id}
        json_data = json.dumps(data)
    print(f"----11--- {json_data}")
    r = requests.get(url=URL, data= json_data)

    data = r.json()
    print(data)

def post_data():
    data = {
        'name': 'note 9',
        'version': 9.1,
        'brand':'redmi'
    }
    json_data = json.dumps(data)
    r = requests.post(url=URL, data = json_data)
    data = r.json()
    return data


def update_data():
    data = {
        'id':1,
        'name': 'note 7.2',
        'brand':'redmi'
    }
    json_data = json.dumps(data)
    r = requests.put(url=URL, data = json_data)
    data = r.json()
    return data
# get_data(1)
update_data()



