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

class AiModelFetchException implements Exception {
  const AiModelFetchException(this.message);

  final String message;

  @override
  String toString() => message;
}
