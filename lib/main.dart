import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'src/app/app_theme.dart';
import 'src/dashboard/dashboard_mapper.dart';
import 'src/dashboard/dashboard_models.dart';
import 'src/dashboard/dashboard_screen.dart';
import 'src/dashboard/new_novel_dialog.dart';
import 'src/data/dashboard_repository.dart';

const _textFileTypes = [
  XTypeGroup(
    label: '小说文件',
    extensions: ['txt', 'md', 'markdown', 'epub', 'html', 'htm'],
  ),
];

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
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI 小说工坊',
      themeMode: _themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: DashboardHome(
        repository: widget.repository,
        onToggleTheme: () {
          setState(() {
            _themeMode =
                _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
          });
        },
      ),
    );
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({
    super.key,
    required this.repository,
    required this.onToggleTheme,
  });

  final DashboardRepository repository;
  final VoidCallback onToggleTheme;

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  final _searchController = TextEditingController();
  DashboardViewState _state = DashboardViewState.loading();
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  void dispose() {
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
      if (!mounted) {
        return;
      }
      setState(() {
        _state = mapDashboardData(data);
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

  @override
  Widget build(BuildContext context) {
    final body = DashboardScreen(
      state: _state,
      actions: DashboardActions(
        createNovel: _createNovel,
        importNovel: _importNovel,
        openProject: _openProject,
        toggleTheme: widget.onToggleTheme,
      ),
      searchController: _searchController,
      onSearchChanged: (_) => _loadDashboard(showLoading: false),
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
      acceptedTypeGroups: _textFileTypes,
      confirmButtonText: '导入',
    );
    if (file == null) {
      return;
    }

    await widget.repository.importNovelFile(file.path);
    _searchController.clear();
    await _loadDashboard();
  }

  void _openProject(NovelSummary novel) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProjectDetailPage(novel: novel),
      ),
    );
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
                Text(novel.summary.isEmpty ? '暂无简介' : novel.summary),
                const SizedBox(height: 24),
                Text('字数：${novel.wordCount}'),
                const SizedBox(height: 8),
                Text('分类：${novel.category.isEmpty ? '未设置分类' : novel.category}'),
                const SizedBox(height: 8),
                Text(
                    '作品类型：${novel.workType.isEmpty ? '未设置类型' : novel.workType}'),
                const SizedBox(height: 8),
                Text(
                  '标签：${novel.tags.isEmpty ? '未设置标签' : novel.tags.join('、')}',
                ),
                const SizedBox(height: 8),
                Text("状态：${novel.status.isEmpty ? '未设置状态' : novel.status}"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
