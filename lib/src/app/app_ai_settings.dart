import 'package:flutter/foundation.dart';

@immutable
class AppAiProviderSettings {
  const AppAiProviderSettings({
    required this.id,
    this.name = 'Provider 1',
    this.enabled = false,
    this.apiKey = '',
    this.baseUrl = '',
    this.selectedModel = '',
    this.availableModels = const [],
  });

  final String id;
  final String name;
  final bool enabled;
  final String apiKey;
  final String baseUrl;
  final String selectedModel;
  final List<String> availableModels;

  bool get isReady =>
      enabled &&
      apiKey.trim().isNotEmpty &&
      baseUrl.trim().isNotEmpty &&
      selectedModel.trim().isNotEmpty &&
      availableModels.contains(selectedModel);

  AppAiProviderSettings copyWith({
    String? id,
    String? name,
    bool? enabled,
    String? apiKey,
    String? baseUrl,
    String? selectedModel,
    List<String>? availableModels,
  }) {
    return AppAiProviderSettings(
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      selectedModel: selectedModel ?? this.selectedModel,
      availableModels: availableModels ?? this.availableModels,
    );
  }

  AppAiProviderSettings addModels(List<String> models) {
    final nextModels = <String>[...availableModels];
    for (final rawModel in models) {
      final model = rawModel.trim();
      if (model.isNotEmpty && !nextModels.contains(model)) {
        nextModels.add(model);
      }
    }
    final selected =
        selectedModel.isNotEmpty && nextModels.contains(selectedModel)
            ? selectedModel
            : nextModels.isEmpty
                ? ''
                : nextModels.first;
    return copyWith(
      selectedModel: selected,
      availableModels: List.unmodifiable(nextModels),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'enabled': enabled,
      'apiKey': apiKey,
      'baseUrl': baseUrl,
      'selectedModel': selectedModel,
      'availableModels': availableModels,
    };
  }

  factory AppAiProviderSettings.fromJson(Map<String, Object?> json) {
    final models = _stringList(json['availableModels']);
    final selectedModel = (json['selectedModel'] as String? ?? '').trim();
    return AppAiProviderSettings(
      id: json['id'] as String? ?? 'provider-1',
      name: json['name'] as String? ?? 'Provider 1',
      enabled: json['enabled'] as bool? ?? false,
      apiKey: json['apiKey'] as String? ?? '',
      baseUrl: json['baseUrl'] as String? ?? '',
      selectedModel: models.contains(selectedModel) ? selectedModel : '',
      availableModels: List.unmodifiable(models),
    );
  }
}

@immutable
class AppAiSettings {
  const AppAiSettings({
    this.providers = const [
      AppAiProviderSettings(id: 'provider-1'),
    ],
  });

  final List<AppAiProviderSettings> providers;

  List<String> get activeModels {
    final seen = <String>{};
    final models = <String>[];
    for (final provider in providers) {
      if (!provider.enabled) {
        continue;
      }
      for (final model in provider.availableModels) {
        if (seen.add(model)) {
          models.add(model);
        }
      }
    }
    return List.unmodifiable(models);
  }

  bool get isReady => providers.any((provider) => provider.isReady);

  AppAiSettings copyWith({
    List<AppAiProviderSettings>? providers,
  }) {
    return AppAiSettings(
      providers: providers ?? this.providers,
    );
  }

  AppAiSettings updateProvider(AppAiProviderSettings provider) {
    return copyWith(
      providers: [
        for (final item in providers)
          if (item.id == provider.id) provider else item,
      ],
    );
  }

  AppAiSettings addProvider() {
    final index = providers.length + 1;
    return copyWith(
      providers: List.unmodifiable([
        ...providers,
        AppAiProviderSettings(
          id: 'provider-$index-${DateTime.now().millisecondsSinceEpoch}',
          name: 'Provider $index',
        ),
      ]),
    );
  }

  AppAiSettings removeProvider(String providerId) {
    if (providers.length <= 1) {
      return this;
    }
    return copyWith(
      providers: List.unmodifiable([
        for (final provider in providers)
          if (provider.id != providerId) provider,
      ]),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'providers': [for (final provider in providers) provider.toJson()],
    };
  }

  factory AppAiSettings.fromJson(Map<String, Object?> json) {
    final rawProviders = json['providers'];
    if (rawProviders is List) {
      final providers = rawProviders
          .whereType<Map>()
          .map((item) => AppAiProviderSettings.fromJson(
                item.cast<String, Object?>(),
              ))
          .toList(growable: false);
      if (providers.isNotEmpty) {
        return AppAiSettings(providers: List.unmodifiable(providers));
      }
    }

    final legacyModels = _stringList(json['availableModels']);
    if (json.containsKey('apiKey') ||
        json.containsKey('baseUrl') ||
        legacyModels.isNotEmpty) {
      return AppAiSettings(
        providers: [
          AppAiProviderSettings(
            id: 'provider-1',
            enabled: _stringList(json['enabledModels']).isNotEmpty,
            apiKey: json['apiKey'] as String? ?? '',
            baseUrl: json['baseUrl'] as String? ?? '',
            selectedModel: json['selectedModel'] as String? ?? '',
            availableModels: legacyModels,
          ),
        ],
      );
    }

    return const AppAiSettings();
  }
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const [];
  }
  final seen = <String>{};
  final items = <String>[];
  for (final item in value) {
    if (item is! String) {
      continue;
    }
    final trimmed = item.trim();
    if (trimmed.isNotEmpty && seen.add(trimmed)) {
      items.add(trimmed);
    }
  }
  return items;
}
