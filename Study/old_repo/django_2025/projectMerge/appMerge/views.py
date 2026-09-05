from django.shortcuts import render
from .models import DeviceModel
from .serializers import DeviceSerializers
from rest_framework.generics import GenericAPIView
from rest_framework.mixins import ListModelMixin, CreateModelMixin, RetrieveModelMixin,DestroyModelMixin, UpdateModelMixin
# Create your views here.

## List and create - PK not requred

class LCDeviceApi(GenericAPIView, ListModelMixin, CreateModelMixin):
    queryset = DeviceModel.objects.all()
    serializer_class = DeviceSerializers

    def get(self, request, *args, **kwargs):
        return self.list(request, *args, **kwargs)

    def post(self,request, *args, **kwargs):
        return self.create(request, *args, **kwargs)    
    
## Retrieve , update, and delete - PK requred


class UGDDeviceApi(GenericAPIView, UpdateModelMixin, DestroyModelMixin, RetrieveModelMixin):
    queryset = DeviceModel.objects.all()
    serializer_class = DeviceSerializers
    
    def put(self,request, *args, **kwargs):
        return self.update(request, *args, **kwargs)
    
    def get(self,request, *args, **kwargs):
        return self.retrieve(request, *args, **kwargs)
    
    def delete(self,request, *args, **kwargs):
        return self.destroy(request, *args, **kwargs)
    
    