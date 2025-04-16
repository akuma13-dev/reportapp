import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiServices {
  static const String _baseUrl = "https://transapi-2sgz.onrender.com";

  static Future<String> translateText({
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
          "source_lang": from,
          "target_lang": to,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translated_text'] ?? '';
      } else {
        return "Terjadi kesalahan: ${response.statusCode}";
      }
    } catch (e) {
      return "Gagal terhubung ke server!";
    }
  }
}
