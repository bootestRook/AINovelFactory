Future<List<String>> fetchOpenAiCompatibleModels({
  required String apiKey,
  required String baseUrl,
}) async {
  throw const AiModelFetchException('This platform cannot fetch models.');
}

Future<String> createOpenAiCompatibleChatCompletion({
  required String apiKey,
  required String baseUrl,
  required String model,
  required List<Map<String, String>> messages,
  double temperature = 0.2,
}) async {
  throw const AiModelFetchException(
      'This platform cannot run chat completion.');
}

class AiModelFetchException implements Exception {
  const AiModelFetchException(this.message);

  final String message;

  @override
  String toString() => message;
}
