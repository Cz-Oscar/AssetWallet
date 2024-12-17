import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  //metoda do pobierania danych o kryptowalutach

  Future<List<Map<String, dynamic>>> getAssetsWithLogos() async {
    final url = Uri.parse("http://127.0.0.1:8000/api/get-assets/");
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>(); // Konwersja na listę map
      } else {
        throw Exception(
            "Nie udało się pobrać danych o kryptowalutach z serwera.");
      }
    } catch (e) {
      print("Błąd pobierania danych o kryptowalutach: $e");
      return [];
    }
  }

  // metoda do pobierania danych o giełdach
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
