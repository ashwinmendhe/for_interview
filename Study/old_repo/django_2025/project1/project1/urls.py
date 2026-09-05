from django.contrib import admin
from django.urls import path, include
from app1 import views
from rest_framework.routers import DefaultRouter


router = DefaultRouter()

router.register('studentapi', views.StudentModelViewSet, basename='student')

urlpatters = [
    path('admin/', admin.site.urls),
    path('',include(router.urls)),
    path('auth/',include('rest_freamework.urls', namespace='rest_framework'))
]
