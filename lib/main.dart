import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'src/app/ai_models_client.dart';
import 'src/app/app_appearance.dart';
import 'src/app/app_agent_settings.dart';
import 'src/app/app_ai_settings.dart';
import 'src/app/app_dream_settings.dart';
import 'src/app/app_editor_settings.dart';
import 'src/app/app_localizations.dart';
import 'src/app/app_settings_store.dart';
import 'src/app/app_storage_settings.dart';
import 'src/app/app_theme.dart';
import 'src/app/system_fonts.dart';
import 'src/book_lab/book_deconstruction_workflow.dart';
import 'src/dashboard/dashboard_mapper.dart';
import 'src/dashboard/dashboard_models.dart';
import 'src/dashboard/dashboard_screen.dart';
import 'src/dashboard/new_novel_dialog.dart';
import 'src/data/dashboard_repository.dart';
import 'src/settings/settings_dialog.dart';

const _textFileExtensions = ['txt', 'md', 'markdown', 'epub', 'html', 'htm'];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(DashboardApp(repository: DashboardRepository.local()));
}

class DashboardApp extends StatefulWidget {
  const DashboardApp({
    super.key,
    required this.repository,
  });

  final DashboardRepository repository;

  @override
  State<DashboardApp> createState() => _DashboardAppState();
}

class _DashboardAppState extends State<DashboardApp> {
  AppLanguage _language = AppLanguage.zhCn;
  AppAppearance _appearance = const AppAppearance();
  AppEditorSettings _editorSettings = const AppEditorSettings();
  AppAiSettings _aiSettings = const AppAiSettings();
  AppAgentSettings _agentSettings = const AppAgentSettings();
  AppDreamSettings _dreamSettings = const AppDreamSettings();
  AppStorageSettings _storageSettings = const AppStorageSettings();
  final _settingsStore = AppSettingsStore.local();
  Timer? _storageBackupTimer;

  @override
  void initState() {
    super.initState();
    _loadPersistedSettings();
    _loadSystemFonts();
  }

  Future<void> _loadPersistedSettings() async {
    final aiSettings = await _settingsStore.loadAiSettings();
    if (!mounted) {
      return;
    }
    setState(() => _aiSettings = aiSettings);
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
    _storageBackupTimer?.cancel();
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
        home: AppAppearanceScope(
          appearance: _appearance,
          child: Builder(
            builder: (context) {
              return _AppearanceBackground(
                appearance: _appearance,
                child: DashboardHome(
                  repository: widget.repository,
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
                  onAiSettingsChanged: _changeAiSettings,
                  agentSettings: _agentSettings,
                  onAgentSettingsChanged: (settings) {
                    setState(() => _agentSettings = settings);
                  },
                  dreamSettings: _dreamSettings,
                  onDreamSettingsChanged: (settings) {
                    setState(() => _dreamSettings = settings);
                  },
                  storageSettings: _storageSettings,
                  onStorageSettingsChanged: _changeStorageSettings,
                  onToggleTheme: () {
                    setState(() {
                      final next =
                          Theme.of(context).brightness == Brightness.dark
                              ? AppThemePreference.light
                              : AppThemePreference.dark;
                      _appearance = _appearance.copyWith(themePreference: next);
                    });
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _changeStorageSettings(AppStorageSettings settings) {
    setState(() => _storageSettings = settings);
    _scheduleStorageBackup(settings);
  }

  void _changeAiSettings(AppAiSettings settings) {
    setState(() => _aiSettings = settings);
    unawaited(_settingsStore.saveAiSettings(settings).catchError((_) {}));
  }

  void _scheduleStorageBackup(AppStorageSettings settings) {
    _storageBackupTimer?.cancel();
    _storageBackupTimer = null;

    final interval = _backupInterval(settings.backupFrequency);
    if (interval == null || settings.backupDirectory.trim().isEmpty) {
      return;
    }

    _storageBackupTimer = Timer.periodic(
      interval,
      (_) => _runScheduledBackup(),
    );
  }

  Future<void> _runScheduledBackup() async {
    final settings = _storageSettings;
    if (settings.backupDirectory.trim().isEmpty ||
        settings.backupFrequency == AppBackupFrequency.manual) {
      return;
    }

    try {
      await widget.repository.backupToDirectory(settings.backupDirectory);
      if (!mounted) {
        return;
      }
      setState(() {
        _storageSettings = _storageSettings.copyWith(
          lastBackupAt: DateTime.now(),
        );
      });
    } catch (_) {
      // The manual backup button reports errors. Scheduled backups stay quiet.
    }
  }

  Duration? _backupInterval(AppBackupFrequency frequency) {
    switch (frequency) {
      case AppBackupFrequency.manual:
        return null;
      case AppBackupFrequency.daily:
        return const Duration(days: 1);
      case AppBackupFrequency.weekly:
        return const Duration(days: 7);
      case AppBackupFrequency.monthly:
        return const Duration(days: 30);
    }
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({
    super.key,
    required this.repository,
    required this.language,
    required this.onLanguageChanged,
    required this.appearance,
    required this.onAppearanceChanged,
    required this.editorSettings,
    required this.onEditorSettingsChanged,
    required this.aiSettings,
    required this.onAiSettingsChanged,
    required this.agentSettings,
    required this.onAgentSettingsChanged,
    required this.dreamSettings,
    required this.onDreamSettingsChanged,
    required this.storageSettings,
    required this.onStorageSettingsChanged,
    required this.onToggleTheme,
  });

  final DashboardRepository repository;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final AppAppearance appearance;
  final ValueChanged<AppAppearance> onAppearanceChanged;
  final AppEditorSettings editorSettings;
  final ValueChanged<AppEditorSettings> onEditorSettingsChanged;
  final AppAiSettings aiSettings;
  final ValueChanged<AppAiSettings> onAiSettingsChanged;
  final AppAgentSettings agentSettings;
  final ValueChanged<AppAgentSettings> onAgentSettingsChanged;
  final AppDreamSettings dreamSettings;
  final ValueChanged<AppDreamSettings> onDreamSettingsChanged;
  final AppStorageSettings storageSettings;
  final ValueChanged<AppStorageSettings> onStorageSettingsChanged;
  final VoidCallback onToggleTheme;

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  final _searchController = TextEditingController();
  DashboardViewState _state = DashboardViewState.loading();
  String? _error;
  bool _showBookDeconstruction = false;
  List<BookDeconstructionProject> _bookDeconstructionProjects = const [];
  int? _activeBookDeconstructionProjectId;
  bool _bookDeconstructionStopRequested = false;
  Future<void>? _bookDeconstructionRun;

  BookDeconstructionProject? get _currentBookDeconstructionProject {
    if (_bookDeconstructionProjects.isEmpty) {
      return null;
    }
    final activeId = _activeBookDeconstructionProjectId;
    if (activeId != null) {
      for (final project in _bookDeconstructionProjects) {
        if (project.id == activeId) {
          return project;
        }
      }
    }
    return _bookDeconstructionProjects.first;
  }

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  void dispose() {
    _bookDeconstructionStopRequested = true;
    _searchController.dispose();
    widget.repository.close();
    super.dispose();
  }

  Future<void> _loadDashboard({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _state = DashboardViewState.loading(today: DateTime.now());
        _error = null;
      });
    }

    try {
      final data = await widget.repository.loadDashboard(
        searchQuery: _searchController.text,
      );
      final bookProjects =
          await widget.repository.loadBookDeconstructionProjects();
      if (!mounted) {
        return;
      }
      setState(() {
        _state = mapDashboardData(data);
        _bookDeconstructionProjects = bookProjects;
        _activeBookDeconstructionProjectId =
            _nextActiveBookProjectId(bookProjects);
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    }
  }

  Future<void> _loadBookDeconstructionProjects({
    bool recoverInterrupted = true,
  }) async {
    final projects = await widget.repository.loadBookDeconstructionProjects(
      recoverInterrupted: recoverInterrupted,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _bookDeconstructionProjects = projects;
      _activeBookDeconstructionProjectId = _nextActiveBookProjectId(projects);
    });
  }

  int? _nextActiveBookProjectId(List<BookDeconstructionProject> projects) {
    if (projects.isEmpty) {
      return null;
    }
    final activeId = _activeBookDeconstructionProjectId;
    if (activeId != null && projects.any((project) => project.id == activeId)) {
      return activeId;
    }
    return projects.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final enteringBreakdown =
            child.key == const ValueKey('book-deconstruction-screen');
        final offset =
            enteringBreakdown ? const Offset(1, 0) : const Offset(-1, 0);
        return SlideTransition(
          position: Tween<Offset>(
            begin: offset,
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
      child: _showBookDeconstruction
          ? BookDeconstructionScreen(
              key: const ValueKey('book-deconstruction-screen'),
              today: _state.today,
              currentProject: _currentBookDeconstructionProject,
              projects: _bookDeconstructionProjects,
              onBack: _closeBookBreakdown,
              onToggleTheme: widget.onToggleTheme,
              onOpenSettings: _openSettings,
              onImportNovel: _importNovelForBookDeconstruction,
              onCreateProject: _createBookDeconstructionProject,
              onStartOrPause: _startOrPauseBookDeconstruction,
              onSelectProject: _selectBookDeconstructionProject,
              onOpenProjectFolder: _openBookDeconstructionProjectFolder,
              onOpenProjectReport: _openBookDeconstructionReport,
              onDeleteProject: _deleteBookDeconstructionProject,
            )
          : DashboardScreen(
              key: const ValueKey('dashboard-screen'),
              state: _state,
              actions: DashboardActions(
                createNovel: _createNovel,
                importNovel: _importNovel,
                openProject: _openProject,
                toggleTheme: widget.onToggleTheme,
                openSettings: _openSettings,
                openBookBreakdown: _openBookBreakdown,
              ),
              searchController: _searchController,
              onSearchChanged: (_) => _loadDashboard(showLoading: false),
            ),
    );

    if (_error == null) {
      return body;
    }

    return Stack(
      children: [
        body,
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: Material(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createNovel() async {
    final draft = await showNewNovelDialog(context);
    if (draft == null) {
      return;
    }

    await widget.repository.createNovel(
      title: draft.title,
      summary: draft.summary,
      category: draft.category,
      workType: draft.workType,
      tags: draft.tags,
      coverPath: draft.coverPath,
    );
    _searchController.clear();
    await _loadDashboard();
  }

  Future<void> _importNovel() async {
    final file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(
          label: context.l10n.text('file.novel'),
          extensions: _textFileExtensions,
        ),
      ],
      confirmButtonText: context.l10n.text('action.importNovel'),
    );
    if (file == null) {
      return;
    }

    try {
      await widget.repository.importNovelFile(file.path);
      _searchController.clear();
      await _loadDashboard();
    } catch (error) {
      _showSnackBar('导入失败：$error');
    }
  }

  Future<void> _importNovelForBookDeconstruction() async {
    final file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(
          label: context.l10n.text('file.novel'),
          extensions: _textFileExtensions,
        ),
      ],
      confirmButtonText: context.l10n.text('action.importNovel'),
    );
    if (file == null) {
      return;
    }

    try {
      final novelId = await widget.repository.importNovelFile(file.path);
      final current = _currentBookDeconstructionProject;
      final projectId = current?.id ??
          await widget.repository.createBookDeconstructionProject(
            novelId: novelId,
          );
      if (current != null) {
        await widget.repository.assignNovelToBookDeconstructionProject(
          projectId: projectId,
          novelId: novelId,
        );
      }
      _activeBookDeconstructionProjectId = projectId;
      _searchController.clear();
      await _loadDashboard(showLoading: false);
    } catch (error) {
      _showSnackBar('导入失败：$error');
    }
  }

  Future<void> _createBookDeconstructionProject() async {
    final current = _currentBookDeconstructionProject;
    if (current != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('新建拆书项目'),
            content: Text('当前正在查看“${current.title}”。要切换到新的拆书项目吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('新建'),
              ),
            ],
          );
        },
      );
      if (confirmed != true) {
        return;
      }
      if (current.isRunning) {
        _bookDeconstructionStopRequested = true;
        await widget.repository.setBookDeconstructionProjectStatus(
          projectId: current.id,
          status: BookDeconstructionProjectStatus.paused,
          currentNodeId: current.currentNodeId,
        );
      }
    }

    final projectId = await widget.repository.createBookDeconstructionProject();
    _activeBookDeconstructionProjectId = projectId;
    await _loadBookDeconstructionProjects();
  }

  void _selectBookDeconstructionProject(int projectId) {
    setState(() {
      _activeBookDeconstructionProjectId = projectId;
    });
  }

  Future<void> _openBookDeconstructionProjectFolder(int projectId) async {
    setState(() {
      _activeBookDeconstructionProjectId = projectId;
    });
    try {
      final path = await widget.repository
          .exportBookDeconstructionProjectFiles(projectId);
      await _openPath(path);
    } catch (error) {
      _showSnackBar('无法打开拆书项目文件夹：$error');
    }
  }

  Future<void> _openBookDeconstructionReport(int projectId) async {
    setState(() {
      _activeBookDeconstructionProjectId = projectId;
    });
    try {
      final path =
          await widget.repository.exportBookDeconstructionReport(projectId);
      await _openReport(path);
    } catch (error) {
      _showSnackBar('无法打开拆书报告：$error');
    }
  }

  Future<void> _deleteBookDeconstructionProject(int projectId) async {
    BookDeconstructionProject? project;
    for (final candidate in _bookDeconstructionProjects) {
      if (candidate.id == projectId) {
        project = candidate;
        break;
      }
    }
    if (project == null) {
      return;
    }
    final targetTitle = project.title;
    final targetIsRunning = project.isRunning;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除拆书项目'),
          content: Text('确定删除“$targetTitle”吗？拆书进度和已生成数据都会移除。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    if (targetIsRunning) {
      _bookDeconstructionStopRequested = true;
    }
    await widget.repository.deleteBookDeconstructionProject(projectId);
    if (_activeBookDeconstructionProjectId == projectId) {
      _activeBookDeconstructionProjectId = null;
    }
    await _loadBookDeconstructionProjects(recoverInterrupted: false);
  }

  Future<void> _startOrPauseBookDeconstruction() async {
    final project = _currentBookDeconstructionProject;
    if (project == null || !project.hasNovel) {
      _showSnackBar('请先导入或选择小说后再开始拆书。');
      return;
    }

    if (project.isRunning) {
      _bookDeconstructionStopRequested = true;
      await widget.repository.setBookDeconstructionProjectStatus(
        projectId: project.id,
        status: BookDeconstructionProjectStatus.paused,
        currentNodeId: project.currentNodeId,
      );
      await _loadBookDeconstructionProjects(recoverInterrupted: false);
      return;
    }

    if (project.status == BookDeconstructionProjectStatus.completed ||
        project.status == BookDeconstructionProjectStatus.failed) {
      await widget.repository.resetBookDeconstructionProject(project.id);
      await _loadBookDeconstructionProjects(recoverInterrupted: false);
    }

    if (_bookDeconstructionRun != null) {
      return;
    }

    _bookDeconstructionStopRequested = false;
    _bookDeconstructionRun = _runBookDeconstruction(project.id).whenComplete(
      () {
        _bookDeconstructionRun = null;
      },
    );
    await _bookDeconstructionRun;
  }

  Future<void> _runBookDeconstruction(int projectId) async {
    await widget.repository.setBookDeconstructionProjectStatus(
      projectId: projectId,
      status: BookDeconstructionProjectStatus.running,
    );
    await _loadBookDeconstructionProjects(recoverInterrupted: false);

    while (mounted && !_bookDeconstructionStopRequested) {
      final projects = await widget.repository.loadBookDeconstructionProjects(
        recoverInterrupted: false,
      );
      final project =
          projects.where((project) => project.id == projectId).first;
      if (!project.hasNovel) {
        await widget.repository.setBookDeconstructionProjectStatus(
          projectId: projectId,
          status: BookDeconstructionProjectStatus.paused,
          currentNodeId: project.currentNodeId,
        );
        _showSnackBar('请先导入或选择小说后再开始拆书。');
        await _loadBookDeconstructionProjects(recoverInterrupted: false);
        return;
      }

      final passed = {
        for (final entry in project.nodeStatuses.entries)
          if (entry.value == BookDeconstructionNodeStatus.passed) entry.key,
      };
      final pending = bookDeconstructionWorkflowNodes
          .where((node) => !passed.contains(node.id))
          .toList();
      if (pending.isEmpty) {
        await widget.repository.setBookDeconstructionProjectStatus(
          projectId: projectId,
          status: BookDeconstructionProjectStatus.completed,
        );
        await _loadBookDeconstructionProjects(recoverInterrupted: false);
        return;
      }

      final ready = pending
          .where((node) => node.dependsOn.every(passed.contains))
          .toList();
      if (ready.isEmpty) {
        await widget.repository.setBookDeconstructionProjectStatus(
          projectId: projectId,
          status: BookDeconstructionProjectStatus.failed,
          currentNodeId: pending.first.id,
        );
        _showSnackBar('拆书流程依赖异常，已暂停。');
        await _loadBookDeconstructionProjects(recoverInterrupted: false);
        return;
      }

      final batch = ready
          .take(widget.aiSettings.bookDeconstructionConcurrency)
          .toList(growable: false);
      for (final node in batch) {
        await widget.repository.updateBookDeconstructionNodeStatus(
          projectId: projectId,
          nodeId: node.id,
          status: BookDeconstructionNodeStatus.running,
        );
      }
      await widget.repository.setBookDeconstructionProjectStatus(
        projectId: projectId,
        status: BookDeconstructionProjectStatus.running,
        currentNodeId: batch.first.id,
      );
      await _loadBookDeconstructionProjects(recoverInterrupted: false);
      await Future<void>.delayed(const Duration(milliseconds: 260));

      if (_bookDeconstructionStopRequested) {
        for (final node in batch) {
          await widget.repository.updateBookDeconstructionNodeStatus(
            projectId: projectId,
            nodeId: node.id,
            status: BookDeconstructionNodeStatus.pending,
            message: 'Paused before completion.',
          );
        }
        break;
      }

      final results = await Future.wait([
        for (final node in batch)
          _runBookDeconstructionNode(projectId: projectId, node: node),
      ]);
      _BookNodeRunFailure? failure;
      for (var i = 0; i < batch.length; i++) {
        final node = batch[i];
        final result = results[i];
        if (result.error != null) {
          failure ??= _BookNodeRunFailure(node, result.error!);
          await widget.repository.updateBookDeconstructionNodeStatus(
            projectId: projectId,
            nodeId: node.id,
            status: BookDeconstructionNodeStatus.failed,
            message: result.error.toString(),
          );
          continue;
        }
        await widget.repository.recordBookDeconstructionNodeOutput(
          projectId: projectId,
          node: node,
          content: result.content!,
        );
        await widget.repository.updateBookDeconstructionNodeStatus(
          projectId: projectId,
          nodeId: node.id,
          status: BookDeconstructionNodeStatus.passed,
        );
      }
      if (failure != null) {
        await widget.repository.setBookDeconstructionProjectStatus(
          projectId: projectId,
          status: BookDeconstructionProjectStatus.failed,
          currentNodeId: failure.node.id,
        );
        _showSnackBar('拆书节点失败：${failure.node.name}。${failure.error}');
        await _loadBookDeconstructionProjects(recoverInterrupted: false);
        return;
      }
      await _loadBookDeconstructionProjects(recoverInterrupted: false);
    }

    if (_bookDeconstructionStopRequested && mounted) {
      final project = _currentBookDeconstructionProject;
      await widget.repository.setBookDeconstructionProjectStatus(
        projectId: projectId,
        status: BookDeconstructionProjectStatus.paused,
        currentNodeId: project?.currentNodeId,
      );
      await _loadBookDeconstructionProjects(recoverInterrupted: false);
    }
  }

  Future<_BookNodeRunResult> _runBookDeconstructionNode({
    required int projectId,
    required BookDeconstructionNode node,
  }) async {
    try {
      if (node.agentId == null) {
        return _BookNodeRunResult(
          content: await widget.repository.buildBookDeconstructionNodeOutput(
            projectId: projectId,
            node: node,
          ),
        );
      }

      final model = _modelForBookAgent(node.agentId!);
      final provider = model == null ? null : _providerForModel(model);
      if (model == null || provider == null) {
        throw StateError('请先在设置里为“${node.name}”或“拆书 Agent”选择可用模型。');
      }

      final prompt = await widget.repository.buildBookDeconstructionAgentPrompt(
        projectId: projectId,
        node: node,
      );
      return _BookNodeRunResult(
        content: await createOpenAiCompatibleChatCompletion(
          apiKey: provider.apiKey.trim(),
          baseUrl: provider.baseUrl.trim(),
          model: model,
          messages: [
            {
              'role': 'system',
              'content': '你是严谨的中文长篇小说拆书专家。只依据用户提供的文本和上游产物分析，不编造不存在的情节。',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
        ),
      );
    } catch (error) {
      return _BookNodeRunResult(error: error);
    }
  }

  String? _modelForBookAgent(String agentId) {
    final configured = widget.agentSettings.effectiveModelFor(
      agentId,
      fallbackAgentId: 'book_breakdown',
    );
    if (configured.trim().isNotEmpty) {
      return configured.trim();
    }
    for (final provider in widget.aiSettings.providers) {
      if (provider.isReady) {
        return provider.selectedModel.trim();
      }
    }
    return null;
  }

  AppAiProviderSettings? _providerForModel(String model) {
    for (final provider in widget.aiSettings.providers) {
      if (!provider.isReady) {
        continue;
      }
      if (provider.availableModels.contains(model) ||
          provider.selectedModel == model) {
        return provider;
      }
    }
    return null;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openPath(String path) async {
    if (Platform.isWindows) {
      await Process.start('explorer.exe', [path]);
      return;
    }
    if (Platform.isMacOS) {
      await Process.start('open', [path]);
      return;
    }
    await Process.start('xdg-open', [path]);
  }

  Future<void> _openReport(String path) async {
    if (Platform.isWindows) {
      await Process.start('notepad.exe', [path]);
      return;
    }
    await _openPath(path);
  }

  void _openProject(NovelSummary novel) {
    if (!widget.aiSettings.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.text('aiProvider.requiredToStart')),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProjectDetailPage(novel: novel),
      ),
    );
  }

  void _openBookBreakdown() {
    setState(() => _showBookDeconstruction = true);
  }

  void _closeBookBreakdown() {
    setState(() => _showBookDeconstruction = false);
  }

  void _openSettings({bool showAgents = false}) {
    showSettingsDialog(
      context,
      language: widget.language,
      onLanguageChanged: widget.onLanguageChanged,
      appearance: widget.appearance,
      onAppearanceChanged: widget.onAppearanceChanged,
      editorSettings: widget.editorSettings,
      onEditorSettingsChanged: widget.onEditorSettingsChanged,
      aiSettings: widget.aiSettings,
      onAiSettingsChanged: widget.onAiSettingsChanged,
      agentSettings: widget.agentSettings,
      onAgentSettingsChanged: widget.onAgentSettingsChanged,
      dreamSettings: widget.dreamSettings,
      onDreamSettingsChanged: widget.onDreamSettingsChanged,
      storageSettings: widget.storageSettings,
      onStorageSettingsChanged: widget.onStorageSettingsChanged,
      onBackupNow: widget.repository.backupToDirectory,
      onRestoreBackup: (path) async {
        await widget.repository.restoreFromBackup(path);
        await _loadDashboard();
      },
      showAgents: showAgents,
    );
  }
}

class _BookNodeRunResult {
  const _BookNodeRunResult({this.content, this.error});

  final String? content;
  final Object? error;
}

class _BookNodeRunFailure {
  const _BookNodeRunFailure(this.node, this.error);

  final BookDeconstructionNode node;
  final Object error;
}

class _AppearanceBackground extends StatelessWidget {
  const _AppearanceBackground({
    required this.appearance,
    required this.child,
  });

  final AppAppearance appearance;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return DecoratedBox(
      decoration: _backgroundDecoration(colors),
      child: child,
    );
  }

  Decoration _backgroundDecoration(AppPalette colors) {
    switch (appearance.backgroundKind) {
      case AppBackgroundKind.none:
        return BoxDecoration(color: colors.background);
      case AppBackgroundKind.solid:
        return BoxDecoration(
          color: appearance.solidBackground.color,
        );
      case AppBackgroundKind.builtIn:
        return BoxDecoration(
          gradient: appearance.builtInBackground.gradient,
        );
      case AppBackgroundKind.custom:
        final path = appearance.customBackgroundPath;
        if (path == null || !File(path).existsSync()) {
          return BoxDecoration(color: colors.background);
        }
        return BoxDecoration(
          color: colors.background,
          image: DecorationImage(
            image: FileImage(File(path)),
            fit: appearance.backgroundFit.boxFit,
            repeat: appearance.backgroundFit == AppBackgroundFit.tile
                ? ImageRepeat.repeat
                : ImageRepeat.noRepeat,
          ),
        );
    }
  }
}

class ProjectDetailPage extends StatelessWidget {
  const ProjectDetailPage({
    super.key,
    required this.novel,
  });

  final NovelSummary novel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final editorSettings = AppEditorSettingsScope.of(context);

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
                Text(
                    novel.summary.isEmpty
                        ? l10n.text('detail.noSummary')
                        : novel.summary,
                    style: TextStyle(
                      fontFamily: editorSettings.fontFamily,
                      fontSize: editorSettings.fontSize,
                      letterSpacing: editorSettings.letterSpacing,
                      height: editorSettings.lineHeight,
                    )),
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
  }
}
