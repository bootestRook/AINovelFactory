import 'package:flutter/foundation.dart';

enum AppBackupFrequency {
  manual,
  daily,
  weekly,
  monthly,
}

@immutable
class AppStorageSettings {
  const AppStorageSettings({
    this.changeRetentionDays = 30,
    this.backupDirectory = '',
    this.backupFrequency = AppBackupFrequency.manual,
    this.lastBackupAt,
  });

  final int changeRetentionDays;
  final String backupDirectory;
  final AppBackupFrequency backupFrequency;
  final DateTime? lastBackupAt;

  AppStorageSettings copyWith({
    int? changeRetentionDays,
    String? backupDirectory,
    AppBackupFrequency? backupFrequency,
    DateTime? lastBackupAt,
  }) {
    return AppStorageSettings(
      changeRetentionDays: changeRetentionDays ?? this.changeRetentionDays,
      backupDirectory: backupDirectory ?? this.backupDirectory,
      backupFrequency: backupFrequency ?? this.backupFrequency,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
    );
  }
}
