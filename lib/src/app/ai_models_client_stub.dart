Future<List<String>> fetchOpenAiCompatibleModels({
  required String apiKey,
  required String baseUrl,
}) async {
  throw const AiModelFetchException('This platform cannot fetch models.');
}

Future<OpenAiCompatibleChatCompletion> createOpenAiCompatibleChatCompletion({
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

class OpenAiCompatibleChatCompletion {
  const OpenAiCompatibleChatCompletion({
    required this.content,
    required this.usage,
  });

  final String content;
  final OpenAiCompatibleUsage? usage;
}

class OpenAiCompatibleUsage {
  const OpenAiCompatibleUsage({
    required this.inputTokens,
    required this.outputTokens,
    required this.cacheReadTokens,
    required this.cacheWriteTokens,
    required this.totalTokens,
  });

  final int inputTokens;
  final int outputTokens;
  final int cacheReadTokens;
  final int cacheWriteTokens;
  final int totalTokens;
}
