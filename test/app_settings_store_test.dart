import 'dart:io';

import 'package:ai_novel_factory/src/app/app_ai_settings.dart';
import 'package:ai_novel_factory/src/app/app_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppSettingsStore persists AI provider settings locally', () async {
    final dir = await Directory.systemTemp.createTemp('ainovel_settings_test_');
    addTearDown(() => dir.delete(recursive: true));
    final store = AppSettingsStore(
      file: File('${dir.path}${Platform.pathSeparator}settings.json'),
    );

    const settings = AppAiSettings(
      bookDeconstructionConcurrency: 5,
      providers: [
        AppAiProviderSettings(
          id: 'provider-a',
          name: 'DeepSeek',
          enabled: true,
          apiKey: 'secret-key',
          baseUrl: 'https://api.example.com/v1',
          selectedModel: 'model-a',
          availableModels: ['model-a', 'model-b'],
        ),
      ],
    );

    await store.saveAiSettings(settings);
    final loaded = await store.loadAiSettings();

    expect(loaded.providers.single.id, 'provider-a');
    expect(loaded.providers.single.enabled, isTrue);
    expect(loaded.providers.single.apiKey, 'secret-key');
    expect(loaded.providers.single.baseUrl, 'https://api.example.com/v1');
    expect(loaded.providers.single.selectedModel, 'model-a');
    expect(loaded.providers.single.availableModels, ['model-a', 'model-b']);
    expect(loaded.bookDeconstructionConcurrency, 5);
  });

  test('AppAiSettings defaults book deconstruction concurrency to 3', () {
    expect(const AppAiSettings().bookDeconstructionConcurrency, 3);
    expect(
      AppAiSettings.fromJson(const {
        'bookDeconstructionConcurrency': 99,
      }).bookDeconstructionConcurrency,
      8,
    );
  });
}
