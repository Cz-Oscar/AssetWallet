import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApiService {
  // Base URL for API
  final String baseUrl = 'https://api.coingecko.com/api/v3';
  Map<String, String>? _symbolToIdMap;

// Mapping cryptocurrency symbol to CoinGecko ID
  Future<Map<String, String>> fetchCryptoSymbolToIdMap() async {
    if (_symbolToIdMap != null) {
      return _symbolToIdMap!;
    }
    try {
      final response = await http
          .get(Uri.parse('https://api.coingecko.com/api/v3/coins/list'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;

// Creating a symbol → ID map
        final Map<String, String> symbolToIdMap = {};
        for (var item in data) {
          final symbol = item['symbol']?.toLowerCase() ?? '';
          final name = item['name'] ?? '';
          final id = item['id'] ?? '';

          if (symbol.isNotEmpty && name.isNotEmpty && id.isNotEmpty) {
            symbolToIdMap['$symbol|$name'] = id;
          }
        }
        return symbolToIdMap;
      } else {
        throw Exception("API zwróciło błąd: ${response.statusCode}");
      }
    } catch (e) {
      print("Błąd podczas pobierania mapy symbol → ID: $e");
      return {};
    }
  }

  // actual crypto price
  Future<Map<String, double>> getCurrentPrices(List<String> ids) async {
    // print("Zapytanie getCurrentPrices dla ID: $ids");
    try {
      final joinedIds = ids.where((id) => id.isNotEmpty).join(',');
      // print("Wysyłanie zapytania dla ID: $joinedIds");

      final response = await http.get(Uri.parse(
          'https://api.coingecko.com/api/v3/simple/price?ids=$joinedIds&vs_currencies=usd'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // print("Otrzymane dane cenowe: $data");

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
      // check Firebase
      final cachedPrices = await getHistoricalPricesFromFirebase(userId, id);
      if (cachedPrices != null) {
        historicalPrices[id] = cachedPrices;
        continue;
      }

      // if firebase is empty get from API
      final apiData = await getHistoricalPrices([id], days);
      if (apiData.containsKey(id)) {
        historicalPrices[id] = apiData[id]!;
        // save to Firebase
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

// Map prices to a list with dates
          final List<Map<DateTime, double>> dailyPrices = prices.map((entry) {
            final timestamp = entry[0] as int;
            final price = entry[1] as double;
            final date = DateTime.fromMillisecondsSinceEpoch(timestamp).toUtc();
            return {date: price};
          }).toList();

// Select the last price of each day (grouping by day)
          final Map<String, double> groupedPrices = {};
          for (var entry in dailyPrices) {
            final date = entry.keys.first;
            final price = entry.values.first;

// The key is only the date in YYYY-MM-DD format
            final dateString = "${date.year}-${date.month}-${date.day}";
            groupedPrices[dateString] = price;
          }

// Convert mapped prices to a list (sorted by date)
          final sortedPrices = groupedPrices.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));

// Select only the last `days` prices
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
        // print("Brak danych historycznych dla $id w Firebase");
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
      // print("Zapisano historyczne dane dla $id do Firebase");
    } catch (e) {
      print("Błąd podczas zapisywania danych historycznych dla $id: $e");
    }
  }

  //get data from backend
  Future<List<Map<String, dynamic>>> getAssetsWithLogos() async {
    final firebaseService = FirebaseService();

    final cachedAssets =
        await firebaseService.getFromFirebase('cryptocurrencies');
    if (cachedAssets.isNotEmpty) {
      // print("Pobrano kryptowaluty z Firebase");
      return cachedAssets;
    }

    // print("Pobieram kryptowaluty z API");
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

        // save to Firebase
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

// Helper function: Retrieve the symbol → ID map from CoinGecko
  Future<Map<String, String>> fetchSymbolToIdMap() async {
    try {
      final response = await http
          .get(Uri.parse("https://api.coingecko.com/api/v3/coins/list"));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

// Map symbol → ID
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

// Fetching exchange data from the backend
  Future<List<Map<String, dynamic>>> getExchanges() async {
    final firebaseService = FirebaseService();

// Try to fetch data from Firebase
    final cachedExchanges = await firebaseService.getFromFirebase('exchanges');
    if (cachedExchanges.isNotEmpty) {
      // print("Pobrano giełdy z Firebase");
      return cachedExchanges;
    }

    // if not in firebase get from API
    // print("Pobieram giełdy z API");
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
