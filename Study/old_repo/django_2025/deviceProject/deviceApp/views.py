from django.shortcuts import render
from rest_framework.response import Response
from .models import DeviceModel
from .serializers import DeviceSerializer
from rest_framework import status
from rest_framework.views import APIView

# Create your views here.

class DeviceAPI(APIView):
    def get(self, request, pk=None, format=None):
        id=pk
        if id is not None:
            device = DeviceModel.objects.get(id=id)
            serializer = DeviceSerializer(device)
            return Response(serializer.data)
        device = DeviceModel.objects.all()
        serializer = DeviceSerializer(device, many=True)
        return Response(serializer.data)
    
    def post(self,request, format=None):
        serializer = DeviceSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({'msg':'created'})
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def put(self,request, pk, format=None):
        id = pk
        device = DeviceModel.objects.get(id=id)
        serializer = DeviceSerializer(instance=device, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response({'msg':'Prtial update'})
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    def delete(self,request, pk, format=None):
        id=pk
        device = DeviceModel.objects.get(id=id)
        device.delete()
        return Response({'msg':'Item Deleted Successfully'})