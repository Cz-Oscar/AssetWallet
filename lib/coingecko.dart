// // import 'dart:async';
// // import 'dart:convert';
// // import 'package:http/http.dart' as http;

// // class CoinGeckoDataManager {
// //   static final CoinGeckoDataManager _instance =
// //       CoinGeckoDataManager._internal();
// //   factory CoinGeckoDataManager() => _instance;

// //   CoinGeckoDataManager._internal();

// //   DateTime? _lastFetchTime; // Czas ostatniego pobrania danych
// //   Map<String, dynamic>? _cachedData; // Przechowywane dane z API

// //   final Duration refreshInterval =
// //       const Duration(minutes: 1); // Czas odświeżania
// //   final StreamController<Map<String, dynamic>> _dataStreamController =
// //       StreamController.broadcast();

// //   Stream<Map<String, dynamic>> get dataStream => _dataStreamController.stream;

// //   Future<Map<String, dynamic>> fetchData({bool forceRefresh = false}) async {
// //     final now = DateTime.now();

// //     // Pobieraj dane tylko, jeśli minął czas odświeżania lub wymuszone odświeżenie
// //     if (_cachedData == null ||
// //         _lastFetchTime == null ||
// //         now.difference(_lastFetchTime!) > refreshInterval ||
// //         forceRefresh) {
// //       _cachedData = await _fetchFromApi(); // Pobranie danych z API
// //       _lastFetchTime = now;
// //       _dataStreamController.add(_cachedData!); // Emituj nowe dane
// //     }

// //     return _cachedData!;
// //   }

// //   Future<Map<String, dynamic>> _fetchFromApi() async {
// //     const url =
// //         'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum&vs_currencies=usd';

// //     try {
// //       final response = await http.get(Uri.parse(url));
// //       if (response.statusCode == 200) {
// //         final data = jsonDecode(response.body) as Map<String, dynamic>;
// //         print("Pobrane dane z CoinGecko: $data");
// //         return data;
// //       } else {
// //         throw Exception(
// //             'Błąd w zapytaniu do CoinGecko: ${response.statusCode}');
// //       }
// //     } catch (e) {
// //       print("Błąd podczas pobierania danych z CoinGecko: $e");
// //       throw e;
// //     }
// //   }

// //   void dispose() {
// //     _dataStreamController.close();
// //   }
// // }

// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter_asset_wallet/services/api_service.dart';
// import 'package:http/http.dart' as http;

// class CoinGeckoDataManager {
//   static final CoinGeckoDataManager _instance =
//       CoinGeckoDataManager._internal();
//   factory CoinGeckoDataManager() => _instance;

//   CoinGeckoDataManager._internal();

//   final Duration refreshInterval =
//       const Duration(minutes: 1); // Cache na 1 minutę
//   DateTime? _lastFetchTime; // Czas ostatniego pobrania danych
//   Map<String, double>? _cachedPrices; // Cache cen
//   Map<String, String>? _symbolToIdMap; // Cache symbol → ID
//   final ApiService _apiService = ApiService(); // Referencja do ApiService

//   final StreamController<Map<String, double>> _dataStreamController =
//       StreamController.broadcast();

//   Stream<Map<String, double>> get dataStream => _dataStreamController.stream;

//   /// Pobieranie aktualnych cen kryptowalut
//   Future<Map<String, double>> fetchData({
//     List<String> symbols = const [],
//     bool forceRefresh = false,
//   }) async {
//     final now = DateTime.now();

//     if (_cachedPrices != null &&
//         _lastFetchTime != null &&
//         now.difference(_lastFetchTime!) < refreshInterval &&
//         !forceRefresh) {
//       return _cachedPrices!;
//     }

//     if (_symbolToIdMap == null) {
//       _symbolToIdMap = await _apiService.fetchCryptoSymbolToIdMap();
//       print(
//           "Mapa symbol → ID: ${_symbolToIdMap!.entries.take(10)}"); // Debuguj pierwsze 10 elementów
//     }

//     final ids = symbols
//         .map((symbolWithName) {
//           final id = _symbolToIdMap![symbolWithName.toLowerCase()] ?? 'unknown';
//           print("Symbol|Name: $symbolWithName → ID: $id");
//           return id;
//         })
//         .where((id) => id != 'unknown')
//         .toList();

//     if (ids.isEmpty) {
//       print("Brak ID do pobrania cen.");
//       return {};
//     }

//     _cachedPrices = await _apiService.getCurrentPrices(ids);
//     _lastFetchTime = now;

//     _dataStreamController.add(_cachedPrices!);
//     return _cachedPrices!;
//   }

//   void dispose() {
//     _dataStreamController.close();
//   }
// }
