from django.shortcuts import render
from .models import Device
from .serializers import DeviceSerializer
from rest_framework.parsers import JSONParser
from rest_framework.renderers import JSONRenderer
from django.http import HttpResponse
import io
# Create your views here.

def device_api(request):
    if request.method == 'GET':
        json_data = request.body
        stream = io.BytesIO(json_data)
        pythondata = JSONParser().parse(stream)
        id = pythondata.get('id', None)
        if id is not None:
            device= Device.objects.get(id=id)
            serialize = DeviceSerializer(device)
            json_data = JSONRenderer().render(serialize)
            return HttpResponse(json_data, content_type = 'application/json')
        device = Device.objects.all()
        serialize = DeviceSerializer(device, many=True)
        json_data = JSONRenderer().render(serialize)
        return HttpResponse(json_data, content_type = 'application/json')
    
    if request.method == 'POST':
        json_data=request.body
        stream = io.BytesIO(json_data)
        pythondata = JSONParser().parse(stream)
        serialize = DeviceSerializer(data=pythondata)
        if serialize.is_valid():
            serialize.save()
            res = {'msg':'created'}
            json_data = JSONRenderer().render(res)
            return HttpResponse(json_data, content_type='application/json')
        json_data = JSONRenderer().render(serialize.errors)
        return HttpResponse(json_data, content_type='application/json')
    if request.method == 'PUT':
        json_data = request.body
        stream = io.BytesIO(json_data)
        pythondata = JSONParser().parse(stream)
        id = pythondata('id', None)
        device = Device.objects.get(id=id)
        serialize = DeviceSerializer(device,data =pythondata, partial=True)
        if serialize.is_valid():
            serialize.save()
            res = {'msg':'updated'}
            json_data = JSONRenderer().render(res)
            return HttpResponse(json_data, content_type='application/json')
        json_data = JSONRenderer().render(serialize.errors)
            

