Future<List<String>> fetchOpenAiCompatibleModels({
  required String apiKey,
  required String baseUrl,
}) async {
  throw const AiModelFetchException('This platform cannot fetch models.');
}

class AiModelFetchException implements Exception {
  const AiModelFetchException(this.message);

  final String message;

  @override
  String toString() => message;
}
