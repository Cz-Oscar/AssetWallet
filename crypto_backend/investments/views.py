from django.shortcuts import render
import requests
from django.http import JsonResponse

# Create your views here.


def get_binance_assets(request):
    url = "https://api.binance.com/api/v3/exchangeInfo"
    response = requests.get(url)
    if response.status_code == 200:
        symbols = response.json()['symbols']
        # get unique assets
        assets = list(set([symbol['baseAsset'] for symbol in symbols]))
        assets.sort()  # alphabetic sort
        return JsonResponse({'assets': assets, }, safe=False)
    return JsonResponse({"error": "nie udalo sie pobrac danytch z binance"}, status=500)
