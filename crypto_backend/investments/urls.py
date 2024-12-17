from django.urls import path
from .views import get_assets_from_coingecko
from .views import get_exchanges_with_logos

urlpatterns = [
    path('get-assets/', get_assets_from_coingecko, name='get_assets'),
    path('get-exchanges/', get_exchanges_with_logos, name='get_exchanges'),

]
