import 'dart:io';

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import 'dashboard_models.dart';

class DashboardActions {
  const DashboardActions({
    required this.createNovel,
    required this.importNovel,
    required this.openProject,
    required this.toggleTheme,
    this.openAiConfig,
  });

  final VoidCallback createNovel;
  final VoidCallback importNovel;
  final ValueChanged<NovelSummary> openProject;
  final VoidCallback toggleTheme;
  final VoidCallback? openAiConfig;
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.state,
    required this.actions,
    required this.searchController,
    required this.onSearchChanged,
  });

  final DashboardViewState state;
  final DashboardActions actions;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          _TopBar(
            onToggleTheme: actions.toggleTheme,
            onOpenAiConfig: actions.openAiConfig,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1224),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 34, 24, 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '欢迎回来',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: colors.text,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatDate(state.today),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: colors.muted),
                        ),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 920;
                            final primary = _PrimaryWorkCard(
                              state: state,
                              actions: actions,
                              fillAvailableHeight: wide,
                            );
                            final stats = _StatsColumn(state: state);

                            if (!wide) {
                              return Column(
                                children: [
                                  primary,
                                  const SizedBox(height: 16),
                                  stats,
                                ],
                              );
                            }

                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(flex: 3, child: primary),
                                  const SizedBox(width: 24),
                                  Expanded(flex: 2, child: stats),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 44),
                        _ProjectsSection(
                          state: state,
                          actions: actions,
                          searchController: searchController,
                          onSearchChanged: onSearchChanged,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return '${date.year}年${date.month}月${date.day}日 · ${weekdays[date.weekday - 1]}';
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onToggleTheme,
    this.onOpenAiConfig,
  });

  final VoidCallback onToggleTheme;
  final VoidCallback? onOpenAiConfig;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          bottom: BorderSide(color: colors.line),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1224),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.brand,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '墨',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI 小说工坊',
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '智能小说创作平台',
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  tooltip: isDarkMode ? '切换浅色模式' : '切换深色模式',
                  onPressed: onToggleTheme,
                  icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                ),
                if (onOpenAiConfig != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onOpenAiConfig,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('AI 配置'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryWorkCard extends StatelessWidget {
  const _PrimaryWorkCard({
    required this.state,
    required this.actions,
    required this.fillAvailableHeight,
  });

  final DashboardViewState state;
  final DashboardActions actions;
  final bool fillAvailableHeight;

  @override
  Widget build(BuildContext context) {
    final recentNovel = _recentNovel();
    final colors = AppPalette.of(context);

    final content = Stack(
      fit: StackFit.expand,
      children: [
        _HeroBackground(novel: recentNovel),
        Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _StatusLabel(text: _statusText()),
              const SizedBox(height: 18),
              Text(
                _titleText(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                _metaText(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.muted,
                    ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (state.mode == DashboardMode.firstUse) ...[
                    _PrimaryButton(
                      icon: Icons.add,
                      label: '新建小说',
                      onPressed: actions.createNovel,
                    ),
                    _SecondaryButton(
                      icon: Icons.upload_file,
                      label: '导入小说',
                      onPressed: actions.importNovel,
                    ),
                  ] else if (recentNovel != null)
                    _PrimaryButton(
                      icon: Icons.edit,
                      label: '继续写作',
                      onPressed: () => actions.openProject(recentNovel),
                    )
                  else
                    _PrimaryButton(
                      icon: Icons.add,
                      label: '新建小说',
                      onPressed: actions.createNovel,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    return _CardShell(
      key: const ValueKey('dashboard-primary-work-card'),
      minHeight: 290,
      child: fillAvailableHeight
          ? content
          : SizedBox(
              height: 290,
              child: content,
            ),
    );
  }

  NovelSummary? _recentNovel() {
    final recent = state.recentWriting;
    if (recent == null) {
      return null;
    }

    for (final novel in state.novels) {
      if (novel.id == recent.novelId) {
        return novel;
      }
    }
    return null;
  }

  String _statusText() {
    switch (state.mode) {
      case DashboardMode.loading:
        return '正在加载';
      case DashboardMode.firstUse:
        return '开始创作';
      case DashboardMode.noRecentWriting:
        return '选择项目';
      case DashboardMode.searchEmpty:
      case DashboardMode.populated:
        return '继续上次';
    }
  }

  String _titleText() {
    switch (state.mode) {
      case DashboardMode.loading:
        return '正在读取本地创作数据';
      case DashboardMode.firstUse:
        return '还没有小说项目';
      case DashboardMode.noRecentWriting:
        return '选择一本小说继续创作';
      case DashboardMode.searchEmpty:
      case DashboardMode.populated:
        return state.recentWriting?.novelTitle ?? '选择一本小说继续创作';
    }
  }

  String _metaText() {
    switch (state.mode) {
      case DashboardMode.loading:
        return '请稍候';
      case DashboardMode.firstUse:
        return '创建或导入一个小说项目后，可以在这里继续写作。';
      case DashboardMode.noRecentWriting:
        return '${state.projectCount} 个项目 · 总字数 ${_formatWords(state.totalWordCount)}';
      case DashboardMode.searchEmpty:
      case DashboardMode.populated:
        final chapterTitle = state.recentWriting?.chapterTitle;
        final suffix = chapterTitle == null || chapterTitle.isEmpty
            ? ''
            : ' · $chapterTitle';
        return '${state.projectCount} 个项目 · 总字数 ${_formatWords(state.totalWordCount)}$suffix';
    }
  }
}

class _StatsColumn extends StatelessWidget {
  const _StatsColumn({required this.state});

  final DashboardViewState state;

  @override
  Widget build(BuildContext context) {
    final goal = state.writingGoal;
    final colors = AppPalette.of(context);

    return Column(
      key: const ValueKey('dashboard-stats-column'),
      children: [
        _StatCard(
          title: '今日写作目标',
          value: goal == null
              ? '未设置'
              : '${_formatWords(goal.currentWords)} / ${_formatWords(goal.targetWords)}',
          icon: Icons.track_changes,
          child: goal == null
              ? Text(
                  '没有今日目标',
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 12,
                  ),
                )
              : LinearProgressIndicator(
                  value: goal.targetWords <= 0
                      ? 0.0
                      : (goal.currentWords / goal.targetWords)
                          .clamp(0.0, 1.0)
                          .toDouble(),
                  backgroundColor: colors.line,
                  color: colors.brand,
                ),
        ),
        const SizedBox(height: 16),
        _StatCard(
          title: '小说项目',
          value: state.projectCount.toString(),
          icon: Icons.menu_book,
          iconColor: colors.brand,
        ),
        const SizedBox(height: 16),
        _StatCard(
          title: '总字数',
          value: _formatWords(state.totalWordCount),
          icon: Icons.trending_up,
          iconColor: colors.success,
        ),
      ],
    );
  }
}

class _ProjectsSection extends StatelessWidget {
  const _ProjectsSection({
    required this.state,
    required this.actions,
    required this.searchController,
    required this.onSearchChanged,
  });

  final DashboardViewState state;
  final DashboardActions actions;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final title = Text(
              '我的小说',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
            );

            final actionsRow = Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (state.showProjectSearch)
                  SizedBox(
                    width: compact ? constraints.maxWidth : 260,
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      decoration: const InputDecoration(
                        isDense: true,
                        prefixIcon: Icon(Icons.search, size: 18),
                        hintText: '搜索小说...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                _SecondaryButton(
                  icon: Icons.upload_file,
                  label: '导入小说',
                  onPressed: actions.importNovel,
                ),
                _PrimaryButton(
                  icon: Icons.add,
                  label: '新建小说',
                  onPressed: actions.createNovel,
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: 16),
                  actionsRow,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                title,
                const Spacer(),
                actionsRow,
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        if (state.mode == DashboardMode.firstUse)
          _EmptyProjects(actions: actions)
        else if (state.mode == DashboardMode.searchEmpty)
          _SearchEmpty(query: state.searchQuery)
        else
          _ProjectGrid(state: state, actions: actions),
      ],
    );
  }
}

class _ProjectGrid extends StatelessWidget {
  const _ProjectGrid({
    required this.state,
    required this.actions,
  });

  final DashboardViewState state;
  final DashboardActions actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 980
            ? 3
            : width >= 640
                ? 2
                : 1;
        final gap = 18.0;
        final tileWidth = (width - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final novel in state.visibleNovels)
              SizedBox(
                width: tileWidth,
                child: _ProjectCard(
                  novel: novel,
                  onTap: () => actions.openProject(novel),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.novel,
    required this.onTap,
  });

  final NovelSummary novel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 122,
              width: double.infinity,
              child: _NovelCover(novel: novel),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    novel.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    novel.summary.isEmpty ? '暂无简介' : novel.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "${_formatWords(novel.wordCount)} · ${_novelTags(novel)}",
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  const _EmptyProjects({required this.actions});

  final DashboardActions actions;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return _CardShell(
      minHeight: 190,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.library_books_outlined,
                color: colors.muted,
                size: 34,
              ),
              const SizedBox(height: 14),
              Text(
                '暂无小说项目',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '创建或导入一个小说项目后，会显示在这里。',
                style: TextStyle(color: colors.muted),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _PrimaryButton(
                    icon: Icons.add,
                    label: '新建小说',
                    onPressed: actions.createNovel,
                  ),
                  _SecondaryButton(
                    icon: Icons.upload_file,
                    label: '导入小说',
                    onPressed: actions.importNovel,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchEmpty extends StatelessWidget {
  const _SearchEmpty({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return _CardShell(
      minHeight: 150,
      child: Center(
        child: Text(
          '没有匹配“${query.trim()}”的小说项目',
          style: TextStyle(color: colors.muted),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.child,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return _CardShell(
      minHeight: 112,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  icon,
                  color: iconColor ?? colors.muted,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              value,
              style: TextStyle(
                color: colors.text,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (child != null) ...[
              const SizedBox(height: 16),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    super.key,
    required this.child,
    this.minHeight = 0,
  });

  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _HeroBackground extends StatelessWidget {
  const _HeroBackground({required this.novel});

  final NovelSummary? novel;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        _NovelCover(novel: novel),
        Container(color: colors.heroOverlay),
      ],
    );
  }
}

class _NovelCover extends StatelessWidget {
  const _NovelCover({required this.novel});

  final NovelSummary? novel;

  @override
  Widget build(BuildContext context) {
    final coverPath = novel?.coverPath;
    if (coverPath != null && coverPath.isNotEmpty) {
      final file = File(coverPath);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF172033),
            Color(0xFFE8E9EC),
            Color(0xFFFFF1EE),
          ],
        ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Text(
      text,
      style: TextStyle(
        color: colors.brand,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: colors.text,
        foregroundColor: colors.card,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.text,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        side: BorderSide(color: colors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

String _formatWords(int words) {
  if (words < 10000) {
    return words.toString();
  }
  final value = words / 10000;
  final text = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$text万';
}

String _novelTags(NovelSummary novel) {
  final tags = [
    if (novel.category.isNotEmpty) novel.category,
    if (novel.workType.isNotEmpty) novel.workType,
    ...novel.tags,
    if (novel.category.isEmpty &&
        novel.workType.isEmpty &&
        novel.tags.isEmpty &&
        novel.status.isNotEmpty)
      novel.status,
  ];
  return tags.isEmpty ? '未设置类型' : tags.join(' · ');
}
