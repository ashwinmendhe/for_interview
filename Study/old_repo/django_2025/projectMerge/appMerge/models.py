from django.db import models

# Create your models here.

class DeviceModel(models.Model):
    name = models.CharField(max_length=100)
    version = models.FloatField()
    brand = models.TextField()
    
