from django.shortcuts import render
import requests
from django.http import JsonResponse

# Create your views here.


def get_assets_from_coingecko(request):
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
            simplifed_data = [
                {
                    "symbol": asset.get("symbol", ""),
                    "name": asset.get("name", ""),
                    "image": asset.get("image", "")
                }
                for asset in data
            ]
            print(simplifed_data)
            return JsonResponse(simplifed_data, safe=False)
        else:
            return JsonResponse({"error": "nie udalo sie pobrac danytch z CoinGecko"})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


def get_exchanges_with_logos(request):
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
            return JsonResponse(simplified_data, safe=False)
        else:
            return JsonResponse({"error": "Nie udało się pobrać giełd z CoinGecko."}, status=500)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)
