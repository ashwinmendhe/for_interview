## Generic API view and Model Mixin

from django.shortcuts import render
from .models import DeviceModel
from .serializers import DeviceSerializer
from rest_framework.generics import GenericAPIView
from rest_framework import status
from rest_framework.mixins import ListModelMixin, CreateModelMixin, RetrieveModelMixin, DestroyModelMixin, UpdateModelMixin


# Create your views here.

class DeviceApi(GenericAPIView, ListModelMixin):
    queryset = DeviceModel.objects.all()
    serializer_class = DeviceSerializer

    def get(self, request, *args, **kwargs):
        return self.list(request, *args, **kwargs)

class DeviceApiCreate(GenericAPIView, CreateModelMixin):
    queryset = DeviceModel.objects.all()
    serializer_class = DeviceSerializer

    def post(self, request, *args, **kwargs):
        return self.create(request, *args, **kwargs)

class DeviceApiRetrieve(GenericAPIView, RetrieveModelMixin):
    queryset = DeviceModel.objects.all()
    serializer_class = DeviceSerializer

    def get(self, request, *args, **kwargs):
        return self.retrieve(request, *args, **kwargs)
    
class DeviceApiUpdate(GenericAPIView, UpdateModelMixin):
    queryset = DeviceModel.objects.all()
    serializer_class = DeviceSerializer

    def put(self, request, *args, **kwargs):
        return self.update(request, *args, **kwargs)
    
class DeviceApiDestroy(GenericAPIView, DestroyModelMixin):
    queryset = DeviceModel.objects.all()
    serializer_class = DeviceSerializer

    def delete(self, request, *args, **kwargs):
        return self.destroy(request, *args, **kwargs)


    
