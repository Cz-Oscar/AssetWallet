import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL dla API
  final String baseUrl = 'https://api.coingecko.com/api/v3';

  // Mapowanie symbolu kryptowaluty na ID z CoinGecko
  Future<Map<String, String>> fetchCryptoSymbolToIdMap() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.coingecko.com/api/v3/coins/list'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;

        // Debug: Zobaczmy, co zwraca CoinGecko
        print("Otrzymane dane z CoinGecko: ${data.length} kryptowalut");

        // Stwórz mapę, która uwzględnia zarówno symbol, jak i nazwę
        final Map<String, String> symbolToIdMap = {};

        for (var item in data) {
          final symbol = item['symbol']?.toLowerCase() ?? '';
          final name = item['name'] ?? '';
          final id = item['id'] ?? '';

          // Debug: Szukaj konkretnego symbolu i nazwy
          // if (symbol == 'btc' && name == 'Bitcoin') {
          //   print("Znaleziono właściwe ID dla BTC: $id");
          // }

          // Dodaj tylko unikalne i kompletne dane do mapy
          if (symbol.isNotEmpty && name.isNotEmpty && id.isNotEmpty) {
            symbolToIdMap['$symbol|$name'] = id; // Użyj symbol|nazwa jako klucz
          }
        }

        // print(
        //     "Mapa symbol → ID (pierwsze 10): ${symbolToIdMap.entries.take(10)}");
        return symbolToIdMap;
      } else {
        throw Exception("API zwróciło błąd: ${response.statusCode}");
      }
    } catch (e) {
      print("Błąd podczas pobierania mapy symbol → ID: $e");
      return {};
    }
  }

  // Pobieranie aktualnej ceny dla kryptowaluty
  Future<Map<String, double>> getCurrentPrices(List<String> ids) async {
    try {
      final joinedIds =
          ids.where((id) => id.isNotEmpty).join(','); // Tylko poprawne ID
      print("Wysyłanie zapytania dla ID: $joinedIds");

      final response = await http.get(Uri.parse(
          'https://api.coingecko.com/api/v3/simple/price?ids=$joinedIds&vs_currencies=usd'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print("Otrzymane dane cenowe: $data");

        // Mapowanie {id: cena}
        final Map<String, double> prices = {};
        data.forEach((key, value) {
          if (value['usd'] != null) {
            prices[key] = value['usd'].toDouble();
          }
        });

        return prices;
      } else {
        print("API zwróciło błąd: ${response.statusCode}");
        return {};
      }
    } catch (e) {
      print("Błąd podczas pobierania cen: $e");
      return {};
    }
  }

  // Pobieranie danych o kryptowalutach z backendu
  Future<List<Map<String, dynamic>>> getAssetsWithLogos() async {
    final url = Uri.parse("http://127.0.0.1:8000/api/get-assets/");
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Pobierz mapę symbol → ID z CoinGecko
        final symbolToIdMap = await fetchCryptoSymbolToIdMap();

        // Tworzenie listy z pełnymi danymi
        final allAssets = data.map<Map<String, dynamic>>((item) {
          final symbol =
              item['symbol']?.toLowerCase() ?? ''; // Symbol w małych literach
          final name = item['name'] ?? ''; // Nazwa w oryginalnym formacie

          // Dopasowanie ID na podstawie symbolu i nazwy
          final id = symbolToIdMap['$symbol|$name'] ?? 'unknown';

          // Debug: Wyświetl dopasowanie
          // print("Symbol: $symbol, Name: $name, ID: $id");

          return {
            'id': id,
            'symbol': symbol,
            'name': name,
            'image': item['image'] ?? 'https://via.placeholder.com/40',
          };
        }).toList();

        // Debug: Sprawdź zawartość _allAssets
        // print("Zawartość _allAssets: ${allAssets.take(10)}");
        return allAssets;
      } else {
        throw Exception(
            "Nie udało się pobrać danych o kryptowalutach z serwera.");
      }
    } catch (e) {
      print("Błąd pobierania danych o kryptowalutach: $e");
      return [];
    }
  }

// Pomocnicza funkcja: Pobierz mapę symbol → id z CoinGecko
  Future<Map<String, String>> fetchSymbolToIdMap() async {
    try {
      final response = await http
          .get(Uri.parse("https://api.coingecko.com/api/v3/coins/list"));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Mapuj symbol → id
        return {
          for (var item in data)
            if (item['symbol'] != null && item['id'] != null)
              item['symbol'].toLowerCase(): item['id']
        };
      } else {
        throw Exception("Nie udało się pobrać symboli z CoinGecko");
      }
    } catch (e) {
      print("Błąd pobierania symboli z CoinGecko: $e");
      return {};
    }
  }

  // Pobieranie danych o giełdach z backendu
  Future<List<Map<String, dynamic>>> getExchanges() async {
    final url = Uri.parse("http://127.0.0.1:8000/api/get-exchanges/");
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>(); // Konwersja na listę map
      } else {
        throw Exception("Nie udało się pobrać listy giełd z serwera.");
      }
    } catch (e) {
      print("Błąd pobierania giełd: $e");
      return [];
    }
  }
}
