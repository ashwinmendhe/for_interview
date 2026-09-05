from django.shortcuts import render
import io
from rest_framework.parsers import JSONParser
from .models import Device
from .serializers import DeviceSerializer
from rest_framework.renderers import JSONRenderer
from django.http import HttpResponse


# Create your views here.

def get_data(request):
    if request.method == 'GET':
        json_data = request.body
        stream = io.BytesIO(json_data)
        
        pythondata = JSONParser().parse(stream)
        id = pythondata.get('id', None)
        if id is not None:
            device = Device.objects.get('id')
            serialize = DeviceSerializer(device)
            json_data = JSONRenderer().render(serialize.data)
            return HttpResponse(json_data, content_type= 'application/json')
        device = Device.objects.all()
        serialize = DeviceSerializer(device, many=True)
        json_data = JSONRenderer().render(serialize.data)
        return HttpResponse(json_data, content_type='application/json')





