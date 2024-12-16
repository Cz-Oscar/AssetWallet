from django.urls import path
from .views import get_binance_assets

urlpatterns = [
    path('get-assets/', get_binance_assets, name='get_assets'),
]
