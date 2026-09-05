from django.shortcuts import render
from rest_framework.response import Response
from app4.models import Device
from app4.serializers import DeviceSerializer
from rest_framework import status
from rest_framework.views import APIView


# Create your views here.
print(Device.objects.all())
class DeviceAPI(APIView):
    def get(self, request, pk=None, format=None):
        id = pk
        if id is not None:
            device = Device.objects.get(id=id)
            serializer = DeviceSerializer(device)
            return Response(serializer.data)
        device = Device.object.all()
        serializer = DeviceSerializer(device, many=True)
        return Response(serializer.data)
    
    def post(self,request,format=None):
        serializer = DeviceSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({'msg':'Created'}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def put(self, resquest, pk=None, format=None):
        id = pk
        device = Device.objects.get(pk=id)
        serializer = DeviceSerializer(device, data=resquest.data)
        if serializer.is_valid():
            serializer.save()
            return Response({'msg':'updated'})
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def patch(self, resquest, pk=None, format=None):
        id = pk
        device = Device.objects.get(pk=id)
        serializer = DeviceSerializer(device, data=resquest.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response({'msg':'updated'})
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def delete(self,request, pk , format=None):
        id = pk
        device = Device.objects.get(pk=id)
        device.delete()
        return Response({"msg":"Data deleted"})
    
    