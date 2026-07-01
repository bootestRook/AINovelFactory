import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ai_novel_factory/src/app/ai_models_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('createOpenAiCompatibleChatCompletion posts chat request', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);

    final requests = <Map<String, Object?>>[];
    unawaited(() async {
      await for (final request in server) {
        final body = await utf8.decodeStream(request);
        requests.add(jsonDecode(body) as Map<String, Object?>);
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'choices': [
            {
              'message': {'content': '真实拆书结果'}
            }
          ],
          'usage': {
            'prompt_tokens': 11,
            'completion_tokens': 7,
            'total_tokens': 18,
            'prompt_tokens_details': {'cached_tokens': 3}
          }
        }));
        await request.response.close();
      }
    }());

    final result = await createOpenAiCompatibleChatCompletion(
      apiKey: 'key',
      baseUrl: 'http://${server.address.host}:${server.port}/v1',
      model: 'model-a',
      messages: const [
        {'role': 'user', 'content': '开始拆书'}
      ],
    );

    expect(result.content, '真实拆书结果');
    expect(result.usage?.inputTokens, 11);
    expect(result.usage?.outputTokens, 7);
    expect(result.usage?.cacheReadTokens, 3);
    expect(result.usage?.totalTokens, 18);
    expect(requests.single['model'], 'model-a');
    expect(requests.single['messages'], isA<List>());
  });
}
