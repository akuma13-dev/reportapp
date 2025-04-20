import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiServices {
  static const String _baseUrl = "https://transapi-2sgz.onrender.com";

  static Future<Map<String, dynamic>> translateAndAnalyze({
    required String text,
    required String from,
    required String to,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/translate_and_analyze"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "text": text,
          "src": from,
          "dest": to,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "translated_text": "Error: ${response.statusCode}",
          "romaji": ""
        };
      }
    } catch (e) {
      return {
        "translated_text": "Gagal konek ke server!",
        "romaji": ""
      };
    }
  }
}
