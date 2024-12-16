import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  Future<List<String>> getAssets() async {
    final response =
        await http.get(Uri.parse('http://127.0.0.1:8000/api/get-assets/'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['assets']);
    } else {
      throw Exception('nie udalo sie pobrac aktywow');
    }
  }
}
