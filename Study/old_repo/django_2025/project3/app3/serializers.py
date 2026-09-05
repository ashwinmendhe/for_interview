from .models import Device
from rest_framework import serializers

class DeviceSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=100)
    version = serializers.FloatField()
    brand = serializers.CharField(max_length=100)

    def create(self, validate_data):
        return Device.objects.create(**validate_data)
    def update(self, instance, validated_data):
        instance.name = validated_data.get('name', instance.name)
        instance.version = validated_data.get('version', instance.version)
        instance.brand = validated_data.get('version', instance.brand)
        

    
