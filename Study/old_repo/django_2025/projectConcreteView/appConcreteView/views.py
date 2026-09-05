from .models import DeviceModel
from .serializers import DeviceSerializers
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView


class DeviceAPI(ListCreateAPIView):
    queryset = DeviceModel.objects.all()
    serializer_class = DeviceSerializers

class DeviceUAPI(RetrieveUpdateDestroyAPIView):
    queryset = DeviceModel.objects.all()
    serializer_class = DeviceSerializers

