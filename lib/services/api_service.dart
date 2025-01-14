import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApiService {
  // Base URL dla API
  final String baseUrl = 'https://api.coingecko.com/api/v3';
  Map<String, String>? _symbolToIdMap;

  // Mapowanie symbolu kryptowaluty na ID z CoinGecko
  Future<Map<String, String>> fetchCryptoSymbolToIdMap() async {
    if (_symbolToIdMap != null) {
      return _symbolToIdMap!;
    }
    try {
      final response = await http
          .get(Uri.parse('https://api.coingecko.com/api/v3/coins/list'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;

        // Tworzenie mapy symbol → ID
        final Map<String, String> symbolToIdMap = {};
        for (var item in data) {
          final symbol = item['symbol']?.toLowerCase() ?? '';
          final name = item['name'] ?? '';
          final id = item['id'] ?? '';

          if (symbol.isNotEmpty && name.isNotEmpty && id.isNotEmpty) {
            symbolToIdMap['$symbol|$name'] = id;
          }
        }

        // Debug: Sprawdź pierwsze 10 wpisów
        print(
            "Mapa symbol → ID (pierwsze 10): ${symbolToIdMap.entries.take(10)}");
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
    print("Zapytanie getCurrentPrices dla ID: $ids");
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

  Future<Map<String, List<double>>> getHistoricalPricesWithFirebase(
      String userId, List<String> ids, int days) async {
    final Map<String, List<double>> historicalPrices = {};

    for (final id in ids) {
      // Sprawdź Firebase
      final cachedPrices = await getHistoricalPricesFromFirebase(userId, id);
      if (cachedPrices != null) {
        historicalPrices[id] = cachedPrices;
        continue;
      }

      // Jeśli brak danych w Firebase, pobierz z API
      final apiData = await getHistoricalPrices([id], days);
      if (apiData.containsKey(id)) {
        historicalPrices[id] = apiData[id]!;
        // Zapisz do Firebase
        await saveHistoricalPricesToFirebase(userId, id, apiData[id]!);
      }
    }

    return historicalPrices;
  }

  Future<Map<String, List<double>>> getHistoricalPrices(
      List<String> ids, int days) async {
    final Map<String, List<double>> historicalPrices = {};

    for (final id in ids) {
      final url =
          'https://api.coingecko.com/api/v3/coins/$id/market_chart?vs_currency=usd&days=$days';
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final prices = data['prices'] as List<dynamic>;

          // Mapuj ceny na listę z datami
          final List<Map<DateTime, double>> dailyPrices = prices.map((entry) {
            final timestamp = entry[0] as int;
            final price = entry[1] as double;
            final date = DateTime.fromMillisecondsSinceEpoch(timestamp).toUtc();
            return {date: price};
          }).toList();

          // Wybierz ostatnią cenę każdego dnia (grupowanie po dniu)
          final Map<String, double> groupedPrices = {};
          for (var entry in dailyPrices) {
            final date = entry.keys.first;
            final price = entry.values.first;

            // Klucz to tylko data w formacie YYYY-MM-DD
            final dateString = "${date.year}-${date.month}-${date.day}";
            groupedPrices[dateString] = price;
          }

          // Konwertuj zmapowane ceny na listę (sortowana według daty)
          final sortedPrices = groupedPrices.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));

          // Wybierz tylko ostatnie `days` ceny
          historicalPrices[id] =
              sortedPrices.map((entry) => entry.value).take(days).toList();
        } else {
          print("Błąd w zapytaniu dla ID: $id, Status: ${response.statusCode}");
        }
      } catch (e) {
        print("Błąd podczas pobierania danych historycznych dla ID: $id, $e");
      }
    }

    return historicalPrices;
  }

  Future<List<double>?> getHistoricalPricesFromFirebase(
      String userId, String id) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('historicalPrices')
          .doc(id)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final prices = List<double>.from(data?['prices'] ?? []);
        // print("Pobrano historyczne dane dla $id z Firebase: $prices");
        return prices;
      } else {
        print("Brak danych historycznych dla $id w Firebase");
        return null;
      }
    } catch (e) {
      print("Błąd podczas pobierania danych historycznych dla $id: $e");
      return null;
    }
  }

  Future<void> saveHistoricalPricesToFirebase(
      String userId, String id, List<double> prices) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('historicalPrices')
          .doc(id)
          .set({
        'prices': prices,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
      print("Zapisano historyczne dane dla $id do Firebase");
    } catch (e) {
      print("Błąd podczas zapisywania danych historycznych dla $id: $e");
    }
  }

  // Pobieranie danych o kryptowalutach z backendu
  Future<List<Map<String, dynamic>>> getAssetsWithLogos() async {
    final firebaseService = FirebaseService();

    // Spróbuj pobrać dane z Firebase
    final cachedAssets =
        await firebaseService.getFromFirebase('cryptocurrencies');
    if (cachedAssets.isNotEmpty) {
      print("Pobrano kryptowaluty z Firebase");
      return cachedAssets;
    }

    // Jeśli brak danych w Firebase, pobierz z API
    print("Pobieram kryptowaluty z API");
    final url = Uri.parse("http://127.0.0.1:8000/api/get-assets/");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        final symbolToIdMap = await fetchCryptoSymbolToIdMap();

        final allAssets = data.map<Map<String, dynamic>>((item) {
          final symbol = item['symbol']?.toLowerCase() ?? '';
          final name = item['name'] ?? '';

          final key = '$symbol|$name';
          final id = symbolToIdMap[key] ?? 'unknown';

          // Debug: Sprawdź symbol, nazwę i wynik mapowania
          if (id == 'unknown') {
            print(
                "Nie znaleziono ID dla: Symbol: $symbol, Nazwa: $name, Klucz: $key");
          }

          return {
            'id': id,
            'symbol': symbol,
            'name': name,
            'image': item['image'] ?? 'https://via.placeholder.com/40',
          };
        }).toList();

        // Zapisz do Firebase
        await firebaseService.saveToFirebase('cryptocurrencies', allAssets);
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
    final firebaseService = FirebaseService();

    // Spróbuj pobrać dane z Firebase
    final cachedExchanges = await firebaseService.getFromFirebase('exchanges');
    if (cachedExchanges.isNotEmpty) {
      print("Pobrano giełdy z Firebase");
      return cachedExchanges;
    }

    // Jeśli brak danych w Firebase, pobierz z API
    print("Pobieram giełdy z API");
    final url = Uri.parse("http://127.0.0.1:8000/api/get-exchanges/");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        final exchanges = data.map<Map<String, dynamic>>((item) {
          return {
            'id': item['id'] ?? 'unknown',
            'name': item['name'] ?? '',
            'image': item['image'] ?? 'https://via.placeholder.com/40',
          };
        }).toList();

        // Zapisz do Firebase
        await firebaseService.saveToFirebase('exchanges', exchanges);
        return exchanges;
      } else {
        throw Exception("Nie udało się pobrać listy giełd z serwera.");
      }
    } catch (e) {
      print("Błąd pobierania giełd: $e");
      return [];
    }
  }
}
