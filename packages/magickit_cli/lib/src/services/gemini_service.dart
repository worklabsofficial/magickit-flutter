import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  final String apiKey;
  final String model;

  GeminiService({
    required this.apiKey,
    this.model = 'gemini-2.5-flash',
  });

  /// Kirim pesan ke Gemini dengan optional image (base64).
  Future<String> sendMessage({
    required String systemPrompt,
    required String userMessage,
    String? base64Image,
    String? imageMediaType,
  }) async {
    final parts = <Map<String, dynamic>>[];

    if (base64Image != null) {
      parts.add({
        'inline_data': {
          'mime_type': imageMediaType ?? 'image/png',
          'data': base64Image,
        },
      });
    }

    parts.add({'text': userMessage});

    final response = await http.post(
      Uri.parse('$_baseUrl/models/$model:generateContent'),
      headers: {
        'x-goog-api-key': apiKey,
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'system_instruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': parts,
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      final error = _parseError(response.body);
      throw GeminiException(
        statusCode: response.statusCode,
        message: error,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return '';
    }

    final content = (candidates.first as Map<String, dynamic>)['content'];
    if (content is! Map<String, dynamic>) return '';

    final contentParts = content['parts'];
    if (contentParts is! List) return '';

    final texts = contentParts
        .whereType<Map<String, dynamic>>()
        .map((part) => part['text'])
        .whereType<String>()
        .toList();

    return texts.join();
  }

  String _parseError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return (data['error'] as Map<String, dynamic>?)?['message'] as String? ??
          body;
    } catch (_) {
      return body;
    }
  }
}

class GeminiException implements Exception {
  final int statusCode;
  final String message;

  const GeminiException({required this.statusCode, required this.message});

  @override
  String toString() => 'GeminiException($statusCode): $message';
}
