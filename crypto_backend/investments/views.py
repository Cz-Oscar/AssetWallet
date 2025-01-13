from django.shortcuts import render
import requests
from django.http import JsonResponse
from django.core.cache import cache
# Create your views here.


def get_assets_from_coingecko(request):
    # Sprawdź, czy dane są w cache
    cached_data = cache.get('assets_data')
    if cached_data:
        return JsonResponse(cached_data, safe=False)

    url = "https://api.coingecko.com/api/v3/coins/markets"
    params = {
        'vs_currency': "usd",
        "order": "market_cap_desc",
        "per_page": 100,
        "page": 1,
        "sparkline": False,
    }

    try:
        response = requests.get(url, params=params)
        if response.status_code == 200:
            data = response.json()
            simplified_data = [
                {
                    "symbol": asset.get("symbol", ""),
                    "name": asset.get("name", ""),
                    "image": asset.get("image", "")
                }
                for asset in data
            ]

            # Zapisz dane w cache na 5 minut
            cache.set('assets_data', simplified_data, timeout=300)
            return JsonResponse(simplified_data, safe=False)
        else:
            return JsonResponse({"error": "Nie udało się pobrać danych z CoinGecko."})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


def get_exchanges_with_logos(request):
    # Sprawdź, czy dane są w cache
    cached_data = cache.get('exchanges_data')
    if cached_data:
        return JsonResponse(cached_data, safe=False)

    url = "https://api.coingecko.com/api/v3/exchanges"
    try:
        response = requests.get(url)
        if response.status_code == 200:
            data = response.json()
            simplified_data = [
                {
                    "id": item.get("id", ""),
                    "name": item.get("name", ""),
                    "image": item.get("image", "")  # Logotyp giełdy
                }
                # Odrzucamy puste logotypy
                for item in data if item.get("image")
            ]

            # Zapisz dane w cache na 5 minut
            cache.set('exchanges_data', simplified_data, timeout=300)
            return JsonResponse(simplified_data, safe=False)
        else:
            return JsonResponse({"error": "Nie udało się pobrać giełd z CoinGecko."}, status=500)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)
