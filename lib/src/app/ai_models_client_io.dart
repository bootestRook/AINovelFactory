import 'dart:convert';
import 'dart:io';

Future<List<String>> fetchOpenAiCompatibleModels({
  required String apiKey,
  required String baseUrl,
}) async {
  final endpoint = _modelsEndpoint(baseUrl);
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 12);

  try {
    final request = await client.getUrl(endpoint);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');

    final response = await request.close();
    final body = await utf8.decodeStream(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiModelFetchException(
          'Model request failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(body);
    final models = <String>{};
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) {
        for (final item in data) {
          if (item is Map) {
            final id = item['id'];
            if (id is String && id.trim().isNotEmpty) {
              models.add(id.trim());
            }
          }
        }
      }
    }

    if (models.isEmpty) {
      throw const AiModelFetchException('No models returned by this endpoint.');
    }

    return models.toList()..sort();
  } on AiModelFetchException {
    rethrow;
  } on FormatException {
    throw const AiModelFetchException('Model response is not valid JSON.');
  } on Object catch (error) {
    throw AiModelFetchException('Unable to fetch models: $error');
  } finally {
    client.close(force: true);
  }
}

Future<String> createOpenAiCompatibleChatCompletion({
  required String apiKey,
  required String baseUrl,
  required String model,
  required List<Map<String, String>> messages,
  double temperature = 0.2,
}) async {
  final endpoint = _chatCompletionsEndpoint(baseUrl);
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 20);

  try {
    final request = await client.postUrl(endpoint);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
    request.add(utf8.encode(jsonEncode({
      'model': model,
      'temperature': temperature,
      'messages': [
        for (final message in messages)
          {
            'role': message['role'],
            'content': message['content'],
          },
      ],
    })));

    final response = await request.close();
    final body = await utf8.decodeStream(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiModelFetchException(
        'Chat request failed: ${response.statusCode} $body',
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final choices = decoded['choices'];
      if (choices is List && choices.isNotEmpty) {
        final first = choices.first;
        if (first is Map) {
          final message = first['message'];
          if (message is Map && message['content'] is String) {
            return (message['content'] as String).trim();
          }
          if (first['text'] is String) {
            return (first['text'] as String).trim();
          }
        }
      }
    }
    throw const AiModelFetchException('Chat response has no content.');
  } on AiModelFetchException {
    rethrow;
  } on FormatException {
    throw const AiModelFetchException('Chat response is not valid JSON.');
  } on Object catch (error) {
    throw AiModelFetchException('Unable to run chat completion: $error');
  } finally {
    client.close(force: true);
  }
}

Uri _modelsEndpoint(String baseUrl) {
  final raw = baseUrl.trim();
  final uri = Uri.tryParse(raw);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    throw const AiModelFetchException(
        'Base URL must include http:// or https://.');
  }

  if (uri.path.endsWith('/models')) {
    return uri;
  }

  final path =
      uri.path.endsWith('/') ? '${uri.path}models' : '${uri.path}/models';
  return uri.replace(path: path);
}

Uri _chatCompletionsEndpoint(String baseUrl) {
  final raw = baseUrl.trim();
  final uri = Uri.tryParse(raw);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    throw const AiModelFetchException(
        'Base URL must include http:// or https://.');
  }
  if (uri.path.endsWith('/chat/completions')) {
    return uri;
  }
  if (uri.path.endsWith('/models')) {
    return uri.replace(
        path: uri.path.replaceFirst(RegExp(r'/models$'), '/chat/completions'));
  }
  final path = uri.path.endsWith('/')
      ? '${uri.path}chat/completions'
      : '${uri.path}/chat/completions';
  return uri.replace(path: path);
}

class AiModelFetchException implements Exception {
  const AiModelFetchException(this.message);

  final String message;

  @override
  String toString() => message;
}
