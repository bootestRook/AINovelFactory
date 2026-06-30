import 'package:flutter/foundation.dart';

@immutable
class AppDreamSettings {
  const AppDreamSettings({
    this.memoryCleanupEnabled = false,
    this.intervalHours = 24,
    this.model = '',
    this.lastRunAt,
  });

  final bool memoryCleanupEnabled;
  final int intervalHours;
  final String model;
  final DateTime? lastRunAt;

  AppDreamSettings copyWith({
    bool? memoryCleanupEnabled,
    int? intervalHours,
    String? model,
    DateTime? lastRunAt,
  }) {
    return AppDreamSettings(
      memoryCleanupEnabled: memoryCleanupEnabled ?? this.memoryCleanupEnabled,
      intervalHours: intervalHours ?? this.intervalHours,
      model: model ?? this.model,
      lastRunAt: lastRunAt ?? this.lastRunAt,
    );
  }

  AppDreamSettings pruneUnavailableModels(List<String> availableModels) {
    if (model.isEmpty || availableModels.contains(model)) {
      return this;
    }
    return copyWith(memoryCleanupEnabled: false, model: '');
  }
}
