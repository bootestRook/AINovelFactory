import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'src/app/app_appearance.dart';
import 'src/app/app_agent_settings.dart';
import 'src/app/app_ai_settings.dart';
import 'src/app/app_dream_settings.dart';
import 'src/app/app_editor_settings.dart';
import 'src/app/app_localizations.dart';
import 'src/app/app_storage_settings.dart';
import 'src/app/app_theme.dart';
import 'src/app/system_fonts.dart';
import 'src/dashboard/dashboard_mapper.dart';
import 'src/dashboard/dashboard_models.dart';
import 'src/dashboard/dashboard_screen.dart';
import 'src/dashboard/new_novel_dialog.dart';
import 'src/settings/settings_dialog.dart';

void main() {
  runApp(const WebPreviewApp());
}

class WebPreviewApp extends StatefulWidget {
  const WebPreviewApp({super.key});

  @override
  State<WebPreviewApp> createState() => _WebPreviewAppState();
}

class _WebPreviewAppState extends State<WebPreviewApp> {
  AppLanguage _language = AppLanguage.zhCn;
  AppAppearance _appearance = const AppAppearance();
  AppEditorSettings _editorSettings = const AppEditorSettings();
  AppAiSettings _aiSettings = const AppAiSettings();
  AppAgentSettings _agentSettings = const AppAgentSettings();
  AppDreamSettings _dreamSettings = const AppDreamSettings();
  AppStorageSettings _storageSettings = const AppStorageSettings();
  final _searchController = TextEditingController();
  var _nextNovelId = 3;
  final _novels = <NovelSummary>[
    NovelSummary(
      id: 1,
      title: '星海档案',
      summary: '失落殖民星上的旧档案正在改写一场战争的结局。',
      status: '构思中',
      category: '科幻',
      workType: '原创',
      tags: const ['星际', '悬疑'],
      coverPath: null,
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      wordCount: 18600,
    ),
    NovelSummary(
      id: 2,
      title: '雾港来信',
      summary: '一封没有署名的信，把侦探带回二十年前的雨夜。',
      status: '连载中',
      category: '推理',
      workType: '原创',
      tags: const ['都市', '案件'],
      coverPath: null,
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      wordCount: 43200,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSystemFonts();
  }

  Future<void> _loadSystemFonts() async {
    final fonts = await loadSystemFontFamilies();
    if (!mounted || fonts.isEmpty) {
      return;
    }
    setState(() {
      _editorSettings = _editorSettings.copyWith(systemFonts: fonts);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppEditorSettingsScope(
      settings: _editorSettings,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: const AppLocalizations(AppLanguage.zhCn).text('app.title'),
        locale: _language.locale,
        supportedLocales: AppLanguage.values.map((language) => language.locale),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        themeMode: _appearance.themeMode,
        theme: AppTheme.lightFor(_appearance.visualTheme),
        darkTheme: AppTheme.darkFor(_appearance.visualTheme),
        home: Builder(
          builder: (context) {
            return AppAppearanceScope(
              appearance: _appearance,
              child: DashboardScreen(
                state: mapDashboardData(_dashboardData()),
                searchController: _searchController,
                onSearchChanged: (_) => setState(() {}),
                actions: DashboardActions(
                  createNovel: _createNovel,
                  importNovel: () => _showMessage(context,
                      context.l10n.text('webPreview.importUnavailable')),
                  openProject: _openProject,
                  openSettings: () => showSettingsDialog(
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
                    onBackupNow: (_) async {
                      throw UnsupportedError(
                        context.l10n.text('webPreview.importUnavailable'),
                      );
                    },
                    onRestoreBackup: (_) async {
                      throw UnsupportedError(
                        context.l10n.text('webPreview.importUnavailable'),
                      );
                    },
                    loadUsageRecords: () async => const [],
                  ),
                  toggleTheme: () {
                    setState(() {
                      final next =
                          Theme.of(context).brightness == Brightness.dark
                              ? AppThemePreference.light
                              : AppThemePreference.dark;
                      _appearance = _appearance.copyWith(themePreference: next);
                    });
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  DashboardData _dashboardData() {
    final totalWordCount = _novels.fold<int>(
      0,
      (total, novel) => total + novel.wordCount,
    );
    final recentNovel = _novels.isEmpty ? null : _novels.first;
    return DashboardData(
      novels: List.unmodifiable(_novels),
      totalWordCount: totalWordCount,
      today: DateTime.now(),
      writingGoal: const WritingGoalSummary(
        targetWords: 3000,
        currentWords: 1260,
      ),
      recentWriting: recentNovel == null
          ? null
          : RecentWriting(
              novelId: recentNovel.id,
              novelTitle: recentNovel.title,
              chapterTitle: '第一章',
              updatedAt: recentNovel.updatedAt,
            ),
      searchQuery: _searchController.text,
    );
  }

  Future<void> _createNovel() async {
    final draft = await showNewNovelDialog(context);
    if (draft == null) {
      return;
    }

    setState(() {
      _novels.insert(
        0,
        NovelSummary(
          id: _nextNovelId++,
          title: draft.title,
          summary: draft.summary,
          status: '新建',
          category: draft.category,
          workType: draft.workType,
          tags: draft.tags,
          coverPath: draft.coverPath,
          updatedAt: DateTime.now(),
          wordCount: 0,
        ),
      );
      _searchController.clear();
    });
  }

  void _openProject(NovelSummary novel) {
    if (!_aiSettings.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.text('aiProvider.requiredToStart')),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          final l10n = context.l10n;

          return Scaffold(
            appBar: AppBar(title: Text(novel.title)),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        novel.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(novel.summary.isEmpty
                          ? l10n.text('detail.noSummary')
                          : novel.summary),
                      const SizedBox(height: 24),
                      Text(l10n.novelDetailLabel(
                        l10n.text('detail.words'),
                        novel.wordCount.toString(),
                      )),
                      const SizedBox(height: 8),
                      Text(l10n.novelDetailLabel(
                        l10n.text('detail.category'),
                        novel.category.isEmpty
                            ? l10n.unsetField('category')
                            : novel.category,
                      )),
                      const SizedBox(height: 8),
                      Text(l10n.novelDetailLabel(
                        l10n.text('detail.workType'),
                        novel.workType.isEmpty
                            ? l10n.unsetField('workType')
                            : novel.workType,
                      )),
                      const SizedBox(height: 8),
                      Text(l10n.novelDetailLabel(
                        l10n.text('detail.tags'),
                        novel.tags.isEmpty
                            ? l10n.unsetField('tags')
                            : novel.tags.join('、'),
                      )),
                      const SizedBox(height: 8),
                      Text(l10n.novelDetailLabel(
                        l10n.text('detail.status'),
                        novel.status.isEmpty
                            ? l10n.unsetField('status')
                            : novel.status,
                      )),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
