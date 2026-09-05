from rest_framework import serializers
from .models import Device

class DeviceSerializer(serializers.Serializer):
    name =serializers.CharField(max_length=100)
    version =serializers.FloatField()
    brand =serializers.CharField(max_length=100)