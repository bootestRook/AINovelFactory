import 'dart:convert';
import 'dart:io';

import 'app_ai_settings.dart';

class AppSettingsStore {
  AppSettingsStore({required File file}) : _file = file;

  factory AppSettingsStore.local() {
    return AppSettingsStore(
      file: File(
        '${Directory.current.path}${Platform.pathSeparator}ai_novel_factory_settings.json',
      ),
    );
  }

  final File _file;

  Future<AppAiSettings> loadAiSettings() async {
    try {
      if (!await _file.exists()) {
        return const AppAiSettings();
      }

      final content = await _file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, Object?>) {
        return const AppAiSettings();
      }
      final aiSettings = decoded['aiSettings'];
      if (aiSettings is! Map<String, Object?>) {
        return const AppAiSettings();
      }
      return AppAiSettings.fromJson(aiSettings);
    } on Object {
      return const AppAiSettings();
    }
  }

  Future<void> saveAiSettings(AppAiSettings settings) async {
    await _file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await _file.writeAsString(
      '${encoder.convert({'aiSettings': settings.toJson()})}\n',
    );
  }
}
