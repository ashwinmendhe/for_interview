from django.contrib import admin
from .models import DeviceModel

# Register your models here.
@admin.register(DeviceModel)
class DeviceAdmin(admin.ModelAdmin):
    list_display = ['id', 'name', 'version', 'brand']


