import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Thin wrapper over the Gemini `generateContent` REST endpoint. Runs the model
/// in JSON mode and returns the JSON object it produces, already decoded.
///
/// Shared by [OcrService] (image/PDF → service record) and [ScheduleService]
/// (history + driving profile → maintenance schedule).
class GeminiClient {
  static const model = 'gemini-3.1-flash-lite';

  static final Uri _endpoint = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
  );

  /// Sends [parts] (text and/or `inline_data` blocks) to Gemini and returns the
  /// JSON object decoded from the model's response.
  Future<Map<String, dynamic>> generateJson(
    List<Map<String, dynamic>> parts,
  ) async {
    final apiKey = dotenv.env['GEMINI_API'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API key is missing from the .env file.');
    }

    final response = await http.post(
      _endpoint,
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
      },
      body: jsonEncode({
        'contents': [
          {'parts': parts},
        ],
        // Ask Gemini to emit raw JSON rather than prose/markdown.
        'generationConfig': {'responseMimeType': 'application/json'},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gemini request failed (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final text = _extractText(body);
    return jsonDecode(_stripFences(text)) as Map<String, dynamic>;
  }

  /// Pulls the generated text out of the Gemini response envelope.
  String _extractText(Map<String, dynamic> body) {
    final candidates = body['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini returned no candidates: $body');
    }
    final parts = (candidates.first as Map<String, dynamic>)['content']
        ?['parts'] as List<dynamic>?;
    final text = parts?.first is Map<String, dynamic>
        ? (parts!.first as Map<String, dynamic>)['text'] as String?
        : null;
    if (text == null || text.isEmpty) {
      throw Exception('Gemini response had no text: $body');
    }
    return text;
  }

  /// Defensive: strip ```json ... ``` fences in case they slip through.
  String _stripFences(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '');
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3);
      }
    }
    return text.trim();
  }
}
