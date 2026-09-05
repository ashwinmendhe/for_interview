from .models import DeviceModel
from rest_framework.serializers import ModelSerializer


class DeviceSerializer(ModelSerializer):
    class Meta:
        model = DeviceModel
        fields = ['id', 'name', 'version', 'brand']