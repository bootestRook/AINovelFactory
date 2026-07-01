import 'package:ai_novel_factory/src/app/app_localizations.dart';
import 'package:ai_novel_factory/src/app/app_agent_settings.dart';
import 'package:ai_novel_factory/src/app/app_appearance.dart';
import 'package:ai_novel_factory/src/app/app_ai_settings.dart';
import 'package:ai_novel_factory/src/app/app_dream_settings.dart';
import 'package:ai_novel_factory/src/app/app_editor_settings.dart';
import 'package:ai_novel_factory/src/app/app_theme.dart';
import 'package:ai_novel_factory/src/app/app_storage_settings.dart';
import 'package:ai_novel_factory/src/data/dashboard_repository.dart';
import 'package:ai_novel_factory/src/settings/settings_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('settings dialog opens on general page and switches sections',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const _SettingsHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('打开设置'));
    await tester.pumpAndSettle();

    for (final label in [
      '通用',
      '外观',
      '编辑器',
      'AI助手',
      'AI供应商',
      '智能体',
      '梦境',
      '用量',
      '存储',
      '关于',
    ]) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('语言'), findsOneWidget);
    expect(find.text('简体中文'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('General'), findsWidgets);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Choose the application interface language.'),
        findsOneWidget);

    await tester.tap(find.text('Appearance').first);
    await tester.pumpAndSettle();

    expect(find.text('Theme Mode'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Mirroric'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('select-field-Theme')));
    await tester.pumpAndSettle();

    expect(find.text('Manuscript'), findsWidgets);
    expect(
      find.text('Warm parchment with indigo ink, like a scholar\'s manuscript'),
      findsOneWidget,
    );
    await tester.tap(find.text('Manuscript').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Editor').first);
    await tester.pumpAndSettle();

    expect(find.text('Editor Font'), findsOneWidget);
    expect(find.text('Georgia'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('select-field-Editor Font')));
    await tester.pumpAndSettle();

    expect(find.text('SimSun'), findsOneWidget);
    await tester.tap(find.text('Georgia').last, warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Enter custom font family'),
      'My Custom Font',
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('My Custom Font'), findsOneWidget);

    await tester.ensureVisible(find.text('Line Color'));
    await tester.pumpAndSettle();

    expect(find.text('Line Color'), findsOneWidget);
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.palette_outlined).last);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.expand_less), findsOneWidget);

    await tester.tap(find.text('AI Providers').first);
    await tester.pumpAndSettle();

    expect(find.text('API Key'), findsOneWidget);
    expect(find.text('Base URL'), findsOneWidget);
    expect(find.text('Fetch Models'), findsOneWidget);
    expect(find.text('Model'), findsWidgets);
    expect(find.text('Add Custom'), findsOneWidget);
    expect(find.text('Language'), findsNothing);

    await tester.tap(find.text('Agents').first);
    await tester.pumpAndSettle();

    expect(find.text('拆书 Agent'), findsOneWidget);
    expect(find.text('世界观构建师'), findsOneWidget);
    expect(find.text('正文写手'), findsOneWidget);
    expect(find.text('读者模拟'), findsOneWidget);
    expect(find.text('Fetch models first'), findsWidgets);

    await tester.tap(find.text('Usage').first);
    await tester.pumpAndSettle();

    expect(find.text('Token Usage'), findsOneWidget);
    expect(find.text('Daily Token Usage'), findsOneWidget);
    expect(find.text('Usage Details'), findsOneWidget);
    expect(find.text('No usage records'), findsOneWidget);

    await tester.tap(find.text('Storage').first);
    await tester.pumpAndSettle();

    expect(find.text('Change History Retention'), findsOneWidget);
    expect(find.text('Backup Directory'), findsOneWidget);
    expect(find.text('Backup Frequency'), findsWidgets);
    expect(find.text('Back Up Now'), findsOneWidget);
  });

  testWidgets('agent model page can assign a fetched model', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const _SettingsHarness(
        initialAiSettings: AppAiSettings(
          providers: [
            AppAiProviderSettings(
              id: 'test-provider',
              enabled: true,
              apiKey: 'key',
              baseUrl: 'https://api.example.com/v1',
              selectedModel: 'model-a',
              availableModels: ['model-a', 'model-b'],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('打开设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('智能体').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('select-field-拆书 Agent')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('model-b').last);
    await tester.pumpAndSettle();

    expect(find.text('model-b'), findsWidgets);
    expect(find.text('00 拆书总控 Agent'), findsOneWidget);
    expect(find.text('01 文本清洗 Agent'), findsOneWidget);
    expect(find.text('11 拆书质检 Agent'), findsOneWidget);
    expect(find.text('实验性写作 Agent'), findsOneWidget);
    expect(find.text('继承拆书 Agent'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('select-field-01 文本清洗 Agent')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('model-a').last);
    await tester.pumpAndSettle();

    expect(find.text('model-a'), findsWidgets);
  });

  testWidgets('dream cleanup requires a selected model before enabling',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const _SettingsHarness(
        initialAiSettings: AppAiSettings(
          providers: [
            AppAiProviderSettings(
              id: 'test-provider',
              enabled: true,
              apiKey: 'key',
              baseUrl: 'https://api.example.com/v1',
              selectedModel: 'dream-model',
              availableModels: ['dream-model'],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('打开设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dreams').first);
    await tester.pumpAndSettle();

    expect(find.text('Cleanup Model'), findsWidgets);
    expect(find.text('Never run'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dream-memory-cleanup-switch')));
    await tester.pump();

    expect(find.text('Choose a cleanup model first.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('select-field-Cleanup Model')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('dream-model').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('dream-memory-cleanup-switch')));
    await tester.pumpAndSettle();

    final enabledSwitch = tester.widget<Switch>(
      find.byKey(const ValueKey('dream-memory-cleanup-switch')),
    );
    expect(enabledSwitch.value, isTrue);
  });
  testWidgets('usage page displays recorded provider and model usage',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _SettingsHarness(
        initialAiSettings: AppAiSettings(
          providers: [
            AppAiProviderSettings(
              id: 'test-provider',
              name: 'api.example.com',
              enabled: true,
              apiKey: 'key',
              baseUrl: 'https://api.example.com/v1',
              selectedModel: 'usage-model',
              availableModels: ['usage-model'],
            ),
          ],
        ),
        initialUsageRecords: [
          AiUsageRecord(
            providerId: 'test-provider',
            providerName: 'api.example.com',
            model: 'usage-model',
            inputTokens: 120,
            outputTokens: 45,
            cacheReadTokens: 8,
            cacheWriteTokens: 3,
            totalTokens: 168,
            createdAt: DateTime.now(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('打开设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usage').first);
    await tester.pumpAndSettle();

    expect(find.text('api.example.com'), findsWidgets);
    expect(find.text('usage-model'), findsWidgets);
    expect(find.text('168'), findsWidgets);
    expect(find.text('120'), findsWidgets);
    expect(find.text('45'), findsWidgets);
  });

  testWidgets('ai provider edits provider blocks and can add a provider',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const _SettingsHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(OutlinedButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI Providers').first);
    await tester.pumpAndSettle();

    expect(find.text('Book Concurrency'), findsOneWidget);
    expect(find.byKey(const ValueKey('select-field-Book Concurrency')),
        findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('ai-api-key-field-provider-1')),
      'test-key',
    );
    await tester.enterText(
      find.byKey(const ValueKey('ai-base-url-field-provider-1')),
      'https://api.example.com/v1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('ai-custom-model-field-provider-1')),
      'manual-model',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('ai-add-model-button-provider-1')),
    );
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('ai-add-model-button-provider-1')));
    await tester.pumpAndSettle();

    expect(find.text('manual-model'), findsWidgets);
    expect(find.byKey(const ValueKey('select-field-Provider 1-model')),
        findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('ai-provider-enabled-provider-1')),
    );
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('ai-provider-enabled-provider-1')));
    await tester.pumpAndSettle();

    expect(find.text('Provider ready'), findsOneWidget);

    await tester
        .ensureVisible(find.byKey(const ValueKey('ai-add-provider-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ai-add-provider-button')));
    await tester.pumpAndSettle();

    expect(find.text('Provider 2'), findsWidgets);

    await tester.ensureVisible(
      find.byKey(const ValueKey('ai-delete-selected-provider-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('ai-delete-selected-provider-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('Provider 2'), findsNothing);
    expect(find.text('Provider 1'), findsWidgets);
  });

  testWidgets('storage page changes frequency and requires backup directory',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const _SettingsHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(OutlinedButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Storage').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('storage-retention-field')),
      '45',
    );
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('select-field-Backup Frequency')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weekly').last);
    await tester.pumpAndSettle();

    expect(find.text('45'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('storage-backup-now-button')));
    await tester.pump();

    expect(find.text('Choose a backup directory first.'), findsOneWidget);
  });
}

class _SettingsHarness extends StatefulWidget {
  const _SettingsHarness({
    this.initialAiSettings = const AppAiSettings(),
    this.initialUsageRecords = const [],
  });

  final AppAiSettings initialAiSettings;
  final List<AiUsageRecord> initialUsageRecords;

  @override
  State<_SettingsHarness> createState() => _SettingsHarnessState();
}

class _SettingsHarnessState extends State<_SettingsHarness> {
  AppLanguage _language = AppLanguage.zhCn;
  AppAppearance _appearance = const AppAppearance();
  AppEditorSettings _editorSettings = const AppEditorSettings();
  late AppAiSettings _aiSettings = widget.initialAiSettings;
  AppAgentSettings _agentSettings = const AppAgentSettings();
  AppDreamSettings _dreamSettings = const AppDreamSettings();
  AppStorageSettings _storageSettings = const AppStorageSettings();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightFor(_appearance.visualTheme),
      darkTheme: AppTheme.darkFor(_appearance.visualTheme),
      themeMode: _appearance.themeMode,
      locale: _language.locale,
      supportedLocales: AppLanguage.values.map((language) => language.locale),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: OutlinedButton(
                onPressed: () => showSettingsDialog(
                  context,
                  language: _language,
                  onLanguageChanged: (language) {
                    setState(() => _language = language);
                  },
                  appearance: _appearance,
                  onAppearanceChanged: (appearance) {
                    setState(() => _appearance = appearance);
                  },
                  editorSettings: _editorSettings,
                  onEditorSettingsChanged: (settings) {
                    setState(() => _editorSettings = settings);
                  },
                  aiSettings: _aiSettings,
                  onAiSettingsChanged: (settings) {
                    setState(() => _aiSettings = settings);
                  },
                  agentSettings: _agentSettings,
                  onAgentSettingsChanged: (settings) {
                    setState(() => _agentSettings = settings);
                  },
                  dreamSettings: _dreamSettings,
                  onDreamSettingsChanged: (settings) {
                    setState(() => _dreamSettings = settings);
                  },
                  storageSettings: _storageSettings,
                  onStorageSettingsChanged: (settings) {
                    setState(() => _storageSettings = settings);
                  },
                  onBackupNow: (directory) async => '$directory/test.sqlite',
                  onRestoreBackup: (_) async {},
                  loadUsageRecords: () async => widget.initialUsageRecords,
                ),
                child: const Text('打开设置'),
              ),
            ),
          );
        },
      ),
    );
  }
}
