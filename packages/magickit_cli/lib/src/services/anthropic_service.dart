import 'dart:convert';
import 'package:http/http.dart' as http;

class AnthropicService {
  static const _baseUrl = 'https://api.anthropic.com/v1';
  static const _apiVersion = '2023-06-01';

  final String apiKey;
  final String model;
  final int maxTokens;

  AnthropicService({
    required this.apiKey,
    this.model = 'claude-sonnet-4-6',
    this.maxTokens = 8192,
  });

  /// Kirim pesan ke Claude dengan optional image (base64).
  Future<String> sendMessage({
    required String systemPrompt,
    required String userMessage,
    String? base64Image,
    String? imageMediaType,
  }) async {
    final content = <Map<String, dynamic>>[];

    if (base64Image != null) {
      content.add({
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': imageMediaType ?? 'image/png',
          'data': base64Image,
        },
      });
    }

    content.add({'type': 'text', 'text': userMessage});

    final response = await http.post(
      Uri.parse('$_baseUrl/messages'),
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': _apiVersion,
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'max_tokens': maxTokens,
        'system': systemPrompt,
        'messages': [
          {'role': 'user', 'content': content},
        ],
      }),
    );

    if (response.statusCode != 200) {
      final error = _parseError(response.body);
      throw AnthropicException(
        statusCode: response.statusCode,
        message: error,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final responseContent = data['content'] as List<dynamic>;
    return (responseContent.first as Map<String, dynamic>)['text'] as String;
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

class AnthropicException implements Exception {
  final int statusCode;
  final String message;

  const AnthropicException({required this.statusCode, required this.message});

  @override
  String toString() => 'AnthropicException($statusCode): $message';
}
