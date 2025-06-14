import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // buat tipe MIME

class ApiServices {
  static const String _baseUrl = "https://nindogoterbakar.onrender.com";

  // 🔁 Translasi + Analisis Linguistik
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

  // 🔊 Text-to-Speech
  static Future<Uint8List?> textToSpeech({
    required String text,
    required String lang,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/speak"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "text": text,
          "src": lang,
          "dest": lang,
        }),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print("TTS error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("TTS failed: $e");
      return null;
    }
  }

  // 🎙️ Speech-to-Text
  static Future<String?> speechToText(Uint8List audioBytes) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("$_baseUrl/speech_to_text"),
      );

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        audioBytes,
        filename: "audio.wav",
        contentType: MediaType('audio', 'wav'),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['recognized_text'];
      } else {
        print("STT error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("STT failed: $e");
      return null;
    }
  }
}
