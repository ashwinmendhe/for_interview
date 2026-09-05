from .models import DeviceModel
from rest_framework import serializers

class DeviceSerializers(serializers.ModelSerializer):
    class Meta:
        model = DeviceModel
        fields = ['id', 'name', 'version', 'brand']