import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../app/app_appearance.dart';
import '../app/app_localizations.dart';
import '../app/app_theme.dart';
import '../book_lab/book_deconstruction_workflow.dart';
import 'dashboard_models.dart';

typedef BookExperimentalMessageLoader
    = Future<List<BookExperimentalWritingMessage>> Function(int projectId);
typedef BookExperimentalMessageSender = Future<BookExperimentalWritingMessage>
    Function(int projectId, String message);
typedef BookExperimentalFinalDraftSaver = Future<void> Function(
  int projectId,
  String content,
);

class DashboardActions {
  const DashboardActions({
    required this.createNovel,
    required this.importNovel,
    required this.openProject,
    required this.toggleTheme,
    this.openSettings,
    this.openBookBreakdown,
  });

  final VoidCallback createNovel;
  final VoidCallback importNovel;
  final ValueChanged<NovelSummary> openProject;
  final VoidCallback toggleTheme;
  final VoidCallback? openSettings;
  final VoidCallback? openBookBreakdown;
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
    final appearance = AppAppearanceScope.of(context);

    return Scaffold(
      backgroundColor: appearance.backgroundKind == AppBackgroundKind.none
          ? colors.background
          : Colors.transparent,
      body: Column(
        children: [
          _TopBar(
            onToggleTheme: actions.toggleTheme,
            onOpenSettings: actions.openSettings,
            onOpenBookBreakdown: actions.openBookBreakdown,
          ),
          Expanded(
            child: SingleChildScrollView(
              key: const PageStorageKey<String>('book-deconstruction-scroll'),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1224),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 34, 24, 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.text('dashboard.welcome'),
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
                          context.l10n.date(state.today),
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
}

class BookDeconstructionScreen extends StatelessWidget {
  const BookDeconstructionScreen({
    super.key,
    required this.today,
    this.currentProject,
    this.projects = const [],
    required this.onBack,
    required this.onToggleTheme,
    this.onOpenSettings,
    this.onImportNovel,
    this.onCreateProject,
    this.onStartOrPause,
    this.onSelectProject,
    this.onOpenProjectFolder,
    this.onOpenProjectReport,
    this.onDeleteProject,
    this.onOpenExperimentalWriting,
  });

  final DateTime today;
  final BookDeconstructionProject? currentProject;
  final List<BookDeconstructionProject> projects;
  final VoidCallback onBack;
  final VoidCallback onToggleTheme;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onImportNovel;
  final VoidCallback? onCreateProject;
  final VoidCallback? onStartOrPause;
  final ValueChanged<int>? onSelectProject;
  final ValueChanged<int>? onOpenProjectFolder;
  final ValueChanged<int>? onOpenProjectReport;
  final ValueChanged<int>? onDeleteProject;
  final ValueChanged<int>? onOpenExperimentalWriting;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final appearance = AppAppearanceScope.of(context);
    final nodeStatuses = currentProject?.nodeStatuses ?? const {};

    return Scaffold(
      backgroundColor: appearance.backgroundKind == AppBackgroundKind.none
          ? colors.background
          : Colors.transparent,
      body: Column(
        children: [
          _TopBar(
            onToggleTheme: onToggleTheme,
            onOpenSettings: onOpenSettings,
            onBack: onBack,
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
                          '拆书工作台',
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
                          context.l10n.date(today),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: colors.muted),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '导入一本小说，拆解结构、人物、伏笔与文风指纹',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: colors.muted),
                        ),
                        const SizedBox(height: 22),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 920;
                            final primary = _BookBreakdownStartCard(
                              onImportNovel: onImportNovel,
                              onStartOrPause: onStartOrPause,
                              onOpenExperimentalWriting:
                                  onOpenExperimentalWriting,
                              project: currentProject,
                              nodeStatuses: nodeStatuses,
                            );
                            final stats = _BookBreakdownStatsColumn(
                              project: currentProject,
                            );

                            if (!wide) {
                              return Column(
                                children: [
                                  primary,
                                  const SizedBox(height: 16),
                                  stats,
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 2, child: primary),
                                const SizedBox(width: 24),
                                Expanded(child: stats),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _BookBreakdownProjectsSection(
                          projects: projects,
                          currentProject: currentProject,
                          onImportNovel: onImportNovel,
                          onCreateProject: onCreateProject,
                          onStartOrPause: onStartOrPause,
                          onSelectProject: onSelectProject,
                          onOpenProjectFolder: onOpenProjectFolder,
                          onOpenProjectReport: onOpenProjectReport,
                          onDeleteProject: onDeleteProject,
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
}

Future<void> showBookExperimentalWritingDialog(
  BuildContext context, {
  required BookDeconstructionProject project,
  required BookExperimentalMessageLoader loadMessages,
  required BookExperimentalMessageSender onSendMessage,
  required BookExperimentalFinalDraftSaver onSaveFinalDraft,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => Center(
      child: _BookExperimentalWritingDialog(
        project: project,
        loadMessages: loadMessages,
        onSendMessage: onSendMessage,
        onSaveFinalDraft: onSaveFinalDraft,
        onClose: entry.remove,
      ),
    ),
  );
  overlay.insert(entry);
  return Future.value();
}

class _BookExperimentalWritingDialog extends StatefulWidget {
  const _BookExperimentalWritingDialog({
    required this.project,
    required this.loadMessages,
    required this.onSendMessage,
    required this.onSaveFinalDraft,
    required this.onClose,
  });

  final BookDeconstructionProject project;
  final BookExperimentalMessageLoader loadMessages;
  final BookExperimentalMessageSender onSendMessage;
  final BookExperimentalFinalDraftSaver onSaveFinalDraft;
  final VoidCallback onClose;

  @override
  State<_BookExperimentalWritingDialog> createState() =>
      _BookExperimentalWritingDialogState();
}

class _BookExperimentalWritingDialogState
    extends State<_BookExperimentalWritingDialog> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<BookExperimentalWritingMessage> _messages = const [];
  var _loading = true;
  var _sending = false;
  var _saving = false;
  String? _error;
  String? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _load() async {
    try {
      final messages = await widget.loadMessages(widget.project.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _messages = messages;
        _loading = false;
        _error = null;
      });
      _scrollToLatest();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
      _status = '已发送，正在构建 Skill 上下文并等待 Agent 回复。';
      _messages = [
        ..._messages,
        BookExperimentalWritingMessage(
          projectId: widget.project.id,
          role: 'user',
          content: text,
          createdAt: DateTime.now(),
        ),
      ];
    });
    _controller.clear();
    _scrollToLatest();
    try {
      await widget.onSendMessage(widget.project.id, text);
      final messages = await widget.loadMessages(widget.project.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _messages = messages;
        _status = '回复已保存。';
      });
      _scrollToLatest();
    } catch (error) {
      if (!mounted) {
        return;
      }
      List<BookExperimentalWritingMessage>? messages;
      try {
        messages = await widget.loadMessages(widget.project.id);
      } catch (_) {
        messages = null;
      }
      setState(() {
        if (messages != null) {
          _messages = messages;
        }
        _error = error.toString();
        _status = '生成失败，用户消息已保留，可重试。';
      });
      _scrollToLatest();
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _saveFinalDraft() async {
    final draft = _lastAgentDraft;
    if (draft == null || _saving) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSaveFinalDraft(widget.project.id, draft.content);
      if (mounted) {
        widget.onClose();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  BookExperimentalWritingMessage? get _lastAgentDraft {
    for (final message in _messages.reversed) {
      if (!message.isUser) {
        return message;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final canSave = _lastAgentDraft != null && !_saving && !_sending;

    return Dialog(
      insetPadding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 680),
        child: SizedBox(
          width: 900,
          height: 680,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 14, 14),
                child: Row(
                  children: [
                    Icon(Icons.science_outlined, color: colors.brand, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '实验性写作 Agent',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: colors.text,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '锁定项目：${widget.project.title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: colors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭',
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.line),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _BookExperimentalMessageList(
                        messages: _messages,
                        controller: _scrollController,
                      ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                  child: Text(
                    _error!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (_status != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                  child: Text(
                    _status!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.muted, fontSize: 12),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.enter): _send,
                      },
                      child: TextField(
                        controller: _controller,
                        minLines: 2,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: '例如：自由发挥一个 1500 字都市奇幻开场，重点测试文风和节奏。',
                          filled: true,
                          fillColor: colors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: colors.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: colors.line),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '敲定后会保存到本拆书项目的 experiments/final_draft.md。',
                            style: TextStyle(color: colors.muted, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: canSave ? _saveFinalDraft : null,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.task_alt, size: 18),
                          label: const Text('敲定为最终稿'),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: _sending ? null : _send,
                          icon: _sending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send, size: 18),
                          label: Text(_sending ? '生成中' : '发送'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookExperimentalMessageList extends StatelessWidget {
  const _BookExperimentalMessageList({
    required this.messages,
    required this.controller,
  });

  final List<BookExperimentalWritingMessage> messages;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    if (messages.isEmpty) {
      return Center(
        child: Text(
          '还没有对话。先描述题材、字数、限制，或让 Agent 自由发挥。',
          style: TextStyle(color: colors.muted),
        ),
      );
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.all(18),
      itemCount: messages.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final message = messages[index];
        return Align(
          alignment:
              message.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? colors.text
                    : colors.background.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: message.isUser ? colors.text : colors.line,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.isUser ? '你' : '实验性写作 Agent',
                    style: TextStyle(
                      color: message.isUser ? colors.card : colors.brand,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    message.content,
                    style: TextStyle(
                      color: message.isUser ? colors.card : colors.text,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onToggleTheme,
    this.onOpenSettings,
    this.onOpenBookBreakdown,
    this.onBack,
  });

  final VoidCallback onToggleTheme;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenBookBreakdown;
  final VoidCallback? onBack;

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
                  child: Text(
                    context.l10n.text('brand.mark'),
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
                      context.l10n.text('app.title'),
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.text('app.subtitle'),
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  tooltip: isDarkMode
                      ? context.l10n.text('theme.light')
                      : context.l10n.text('theme.dark'),
                  onPressed: onToggleTheme,
                  icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                ),
                if (onOpenSettings != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onOpenSettings,
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: Text(context.l10n.text('settings')),
                  ),
                ],
                if (onOpenBookBreakdown != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onOpenBookBreakdown,
                    icon: const Icon(Icons.auto_stories_outlined, size: 18),
                    label: Text(context.l10n.text('action.bookBreakdown')),
                  ),
                ],
                if (onBack != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: context.l10n.isEnglish ? 'Back' : '返回',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
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

class _BookBreakdownStartCard extends StatelessWidget {
  const _BookBreakdownStartCard({
    this.onImportNovel,
    this.onStartOrPause,
    this.onOpenExperimentalWriting,
    this.project,
    required this.nodeStatuses,
  });

  final VoidCallback? onImportNovel;
  final VoidCallback? onStartOrPause;
  final ValueChanged<int>? onOpenExperimentalWriting;
  final BookDeconstructionProject? project;
  final Map<String, BookDeconstructionNodeStatus> nodeStatuses;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final title = project?.novelTitle ?? '未选择小说';
    final subtitle = project?.hasNovel ?? false
        ? '拆书项目：${project!.title}'
        : '导入 TXT / EPUB 后开始生成拆书资产。';
    final running = project?.isRunning ?? false;

    return _CardShell(
      minHeight: 390,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '开始拆书',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 128,
                  height: 188,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.line),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.text,
                        colors.brand.withValues(alpha: 0.36),
                        colors.card,
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.auto_stories_outlined,
                    color: colors.card,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 28),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: colors.text,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subtitle,
                        style: TextStyle(color: colors.muted),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '分析目标',
                        style: TextStyle(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final target in _bookBreakdownTargets)
                            _BookBreakdownTargetChip(
                              icon: target.icon,
                              label: target.label,
                              status: _bookBreakdownStatusForNodes(
                                nodeStatuses,
                                target.nodeIds,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 14,
              children: [
                _PrimaryButton(
                  icon: running ? Icons.pause : Icons.play_arrow,
                  label: running ? '暂停拆书' : '开始拆书',
                  onPressed: onStartOrPause ?? () {},
                ),
                _SecondaryButton(
                  icon: Icons.upload_file,
                  label: context.l10n.text('action.importNovel'),
                  onPressed: onImportNovel ?? () {},
                ),
                _SecondaryButton(
                  icon: Icons.science_outlined,
                  label: '实验写作',
                  onPressed: project == null
                      ? () {}
                      : () => onOpenExperimentalWriting?.call(project!.id),
                ),
                const SizedBox(width: 32),
                _BookBreakdownPipeline(nodeStatuses: nodeStatuses),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BookBreakdownTargetData {
  const _BookBreakdownTargetData({
    required this.icon,
    required this.label,
    required this.nodeIds,
  });

  final IconData icon;
  final String label;
  final List<String> nodeIds;
}

class _BookBreakdownPipelineStepData {
  const _BookBreakdownPipelineStepData({
    required this.icon,
    required this.label,
    required this.nodeIds,
  });

  final IconData icon;
  final String label;
  final List<String> nodeIds;
}

const _bookBreakdownTargets = [
  _BookBreakdownTargetData(
    icon: Icons.article_outlined,
    label: '章节拆解',
    nodeIds: ['book_chapter_content'],
  ),
  _BookBreakdownTargetData(
    icon: Icons.travel_explore,
    label: '全书总览',
    nodeIds: ['book_overview'],
  ),
  _BookBreakdownTargetData(
    icon: Icons.account_tree_outlined,
    label: '情节结构',
    nodeIds: ['book_plot_structure'],
  ),
  _BookBreakdownTargetData(
    icon: Icons.groups_outlined,
    label: '人物关系',
    nodeIds: ['book_relationships'],
  ),
  _BookBreakdownTargetData(
    icon: Icons.psychology_alt_outlined,
    label: '伏笔悬念',
    nodeIds: ['foreshadowing_initial', 'foreshadowing_review'],
  ),
  _BookBreakdownTargetData(
    icon: Icons.fingerprint,
    label: '文风指纹',
    nodeIds: [
      'style_chapter_statistics',
      'style_global',
      'style_character_voice',
      'style_scene_voice',
    ],
  ),
  _BookBreakdownTargetData(
    icon: Icons.integration_instructions_outlined,
    label: 'Skill 编译',
    nodeIds: ['book_skill_compile'],
  ),
];

const _bookBreakdownPipelineSteps = [
  _BookBreakdownPipelineStepData(
    icon: Icons.cleaning_services_outlined,
    label: '文本清洗',
    nodeIds: ['book_text_cleaning'],
  ),
  _BookBreakdownPipelineStepData(
    icon: Icons.segment_outlined,
    label: '分章',
    nodeIds: ['gate_1_text_cleaned'],
  ),
  _BookBreakdownPipelineStepData(
    icon: Icons.description_outlined,
    label: '拆解',
    nodeIds: [
      'book_chapter_content',
      'style_chapter_statistics',
      'base_index_normalization',
      'book_plot_structure',
      'book_relationships',
      'foreshadowing_initial',
      'style_global',
      'book_business_mechanism',
      'style_character_voice',
      'style_scene_voice',
      'foreshadowing_review',
      'gate_4_multidimensional_analysis',
    ],
  ),
  _BookBreakdownPipelineStepData(
    icon: Icons.summarize_outlined,
    label: '汇总',
    nodeIds: ['book_overview', 'book_template_distillation'],
  ),
  _BookBreakdownPipelineStepData(
    icon: Icons.ios_share_outlined,
    label: 'Skill 编译',
    nodeIds: ['book_skill_compile', 'book_quality_check'],
  ),
];

BookDeconstructionNodeStatus _bookBreakdownStatusForNodes(
  Map<String, BookDeconstructionNodeStatus> statuses,
  List<String> nodeIds,
) {
  final values = [
    for (final id in nodeIds)
      if (statuses[id] != null) statuses[id]!,
  ];

  if (values.isEmpty) {
    return BookDeconstructionNodeStatus.pending;
  }
  if (values.any((status) => status == BookDeconstructionNodeStatus.running)) {
    return BookDeconstructionNodeStatus.running;
  }
  if (values.any((status) => status == BookDeconstructionNodeStatus.failed)) {
    return BookDeconstructionNodeStatus.failed;
  }
  if (values.length == nodeIds.length &&
      values.every((status) => status == BookDeconstructionNodeStatus.passed)) {
    return BookDeconstructionNodeStatus.passed;
  }
  if (values.length == nodeIds.length &&
      values.every(
        (status) => status == BookDeconstructionNodeStatus.skipped,
      )) {
    return BookDeconstructionNodeStatus.skipped;
  }
  return BookDeconstructionNodeStatus.pending;
}

class _BookBreakdownTargetChip extends StatelessWidget {
  const _BookBreakdownTargetChip({
    required this.icon,
    required this.label,
    required this.status,
  });

  final IconData icon;
  final String label;
  final BookDeconstructionNodeStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Container(
      width: 142,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.line),
        color: colors.card,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.muted, fontSize: 13),
            ),
          ),
          _BookBreakdownStatusIcon(
            key: ValueKey('book-target-status-$label-${status.name}'),
            status: status,
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _BookBreakdownStatusIcon extends StatelessWidget {
  const _BookBreakdownStatusIcon({
    super.key,
    required this.status,
    required this.size,
  });

  final BookDeconstructionNodeStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    return switch (status) {
      BookDeconstructionNodeStatus.running => _RunningStatusIcon(
          color: colors.text,
          size: size,
        ),
      BookDeconstructionNodeStatus.passed => Icon(
          Icons.check_circle,
          size: size,
          color: colors.text,
        ),
      BookDeconstructionNodeStatus.failed => Icon(
          Icons.error,
          size: size,
          color: errorColor,
        ),
      BookDeconstructionNodeStatus.skipped => Icon(
          Icons.remove_circle_outline,
          size: size,
          color: colors.muted,
        ),
      BookDeconstructionNodeStatus.pending => Icon(
          Icons.radio_button_unchecked,
          size: size,
          color: colors.muted,
        ),
    };
  }
}

class _RunningStatusIcon extends StatelessWidget {
  const _RunningStatusIcon({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class _BookBreakdownPipeline extends StatelessWidget {
  const _BookBreakdownPipeline({
    required this.nodeStatuses,
  });

  final Map<String, BookDeconstructionNodeStatus> nodeStatuses;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        for (var i = 0; i < _bookBreakdownPipelineSteps.length; i++) ...[
          _PipelineStep(
            icon: _bookBreakdownPipelineSteps[i].icon,
            label: _bookBreakdownPipelineSteps[i].label,
            status: _bookBreakdownStatusForNodes(
              nodeStatuses,
              _bookBreakdownPipelineSteps[i].nodeIds,
            ),
          ),
          if (i != _bookBreakdownPipelineSteps.length - 1)
            Icon(Icons.arrow_forward, size: 16, color: colors.muted),
        ],
      ],
    );
  }
}

class _PipelineStep extends StatelessWidget {
  const _PipelineStep({
    required this.icon,
    required this.label,
    required this.status,
  });

  final IconData icon;
  final String label;
  final BookDeconstructionNodeStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final running = status == BookDeconstructionNodeStatus.running;
    final failed = status == BookDeconstructionNodeStatus.failed;
    final circleColor = running ? colors.text : colors.card;
    final statusColor = failed ? errorColor : colors.muted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: ValueKey('book-pipeline-status-$label-${status.name}'),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: circleColor,
            border: Border.all(
              color: running
                  ? colors.text
                  : failed
                      ? errorColor
                      : colors.line,
            ),
          ),
          child: Center(
            child: running
                ? _RunningStatusIcon(color: colors.card, size: 18)
                : Icon(icon, size: 18, color: statusColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: running ? colors.text : statusColor,
            fontSize: 12,
            fontWeight: running ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _BookBreakdownStatsColumn extends StatelessWidget {
  const _BookBreakdownStatsColumn({this.project});

  final BookDeconstructionProject? project;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final progress = project?.progress ?? 0;

    return Column(
      children: [
        _BookBreakdownStatCard(
          title: project?.isRunning ?? false ? '当前任务' : '当前进度',
          value: '${(progress * 100).round()}%',
          icon: Icons.track_changes,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: colors.line,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 12),
        _BookBreakdownStatCard(
          title: '已拆章节',
          value: (project?.chapterCount ?? 0).toString(),
          icon: Icons.snippet_folder_outlined,
          iconColor: colors.brand,
        ),
        const SizedBox(height: 12),
        _BookBreakdownStatCard(
          title: '提取角色',
          value: (project?.characterCount ?? 0).toString(),
          icon: Icons.group_outlined,
          iconColor: colors.success,
        ),
        const SizedBox(height: 12),
        _BookBreakdownStatCard(
          title: '风格资产',
          value: (project?.styleAssetCount ?? 0).toString(),
          icon: Icons.fingerprint,
          iconColor: colors.brand,
        ),
      ],
    );
  }
}

class _BookBreakdownStatCard extends StatelessWidget {
  const _BookBreakdownStatCard({
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
      minHeight: 92,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
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
                Icon(icon, color: iconColor ?? colors.muted, size: 20),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: colors.text,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (child != null) ...[
              const SizedBox(height: 10),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

class _BookBreakdownMetricsStrip extends StatelessWidget {
  const _BookBreakdownMetricsStrip({this.project});

  final BookDeconstructionProject? project;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            final metrics = const [
              _CompactMetricData(
                icon: Icons.article_outlined,
                label: '章节文件',
              ),
              _CompactMetricData(
                icon: Icons.groups_outlined,
                label: '人物档案',
              ),
              _CompactMetricData(
                icon: Icons.checklist_rtl,
                label: '伏笔条目',
              ),
              _CompactMetricData(
                icon: Icons.fingerprint,
                label: '风格指纹',
              ),
            ];
            final widgets = [
              _CompactMetric(
                icon: metrics[0].icon,
                label: metrics[0].label,
                value: (project?.chapterCount ?? 0).toString(),
              ),
              _CompactMetric(
                icon: metrics[1].icon,
                label: metrics[1].label,
                value: (project?.characterCount ?? 0).toString(),
              ),
              _CompactMetric(
                icon: metrics[2].icon,
                label: metrics[2].label,
                value: (project?.foreshadowingCount ?? 0).toString(),
              ),
              _CompactMetric(
                icon: metrics[3].icon,
                label: metrics[3].label,
                value: (project?.styleAssetCount ?? 0).toString(),
              ),
            ];

            if (compact) {
              return Wrap(spacing: 24, runSpacing: 12, children: widgets);
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: widgets,
            );
          },
        ),
      ),
    );
  }
}

class _CompactMetricData {
  const _CompactMetricData({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: colors.muted),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: colors.muted, fontSize: 12)),
            Text(
              value,
              style: TextStyle(
                color: colors.text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

const _bookProjectTableHorizontalPadding = 28.0;
const _bookProjectTableMinWidth = 1108.0;
const _bookProjectNameMinWidth = 260.0;
const _bookProjectProgressWidth = 230.0;
const _bookProjectStatusWidth = 170.0;
const _bookProjectUpdatedWidth = 180.0;
const _bookProjectActionWidth = 150.0;
const _bookProjectMenuWidth = 44.0;

double _bookProjectNameWidth(double tableWidth) {
  const fixedWidth = _bookProjectProgressWidth +
      _bookProjectStatusWidth +
      _bookProjectUpdatedWidth +
      _bookProjectActionWidth +
      _bookProjectMenuWidth +
      (_bookProjectTableHorizontalPadding * 2);

  return math.max(_bookProjectNameMinWidth, tableWidth - fixedWidth);
}

class _BookBreakdownProjectsSection extends StatelessWidget {
  const _BookBreakdownProjectsSection({
    required this.projects,
    this.currentProject,
    this.onImportNovel,
    this.onCreateProject,
    this.onStartOrPause,
    this.onSelectProject,
    this.onOpenProjectFolder,
    this.onOpenProjectReport,
    this.onDeleteProject,
  });

  final List<BookDeconstructionProject> projects;
  final BookDeconstructionProject? currentProject;
  final VoidCallback? onImportNovel;
  final VoidCallback? onCreateProject;
  final VoidCallback? onStartOrPause;
  final ValueChanged<int>? onSelectProject;
  final ValueChanged<int>? onOpenProjectFolder;
  final ValueChanged<int>? onOpenProjectReport;
  final ValueChanged<int>? onDeleteProject;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final title = Text(
              '拆书项目',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
            );
            final actions = Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SecondaryButton(
                  icon: Icons.upload_file,
                  label: context.l10n.text('action.importNovel'),
                  onPressed: onImportNovel ?? () {},
                ),
                _PrimaryButton(
                  icon: Icons.add,
                  label: '新建拆书',
                  onPressed: onCreateProject ?? () {},
                ),
              ],
            );

            if (constraints.maxWidth < 920) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      title,
                      const Spacer(),
                      actions,
                    ],
                  ),
                  const SizedBox(height: 12),
                  _BookBreakdownMetricsStrip(project: currentProject),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 126, child: title),
                Expanded(
                  child: _BookBreakdownMetricsStrip(project: currentProject),
                ),
                const SizedBox(width: 18),
                actions,
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _CardShell(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth =
                  math.max(constraints.maxWidth, _bookProjectTableMinWidth);

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      _BookBreakdownProjectTableHeader(tableWidth: tableWidth),
                      Divider(height: 1, color: colors.line),
                      if (projects.isEmpty)
                        SizedBox(
                          height: 126,
                          child: Center(
                            child: Text(
                              '暂无拆书项目',
                              style: TextStyle(color: colors.muted),
                            ),
                          ),
                        )
                      else
                        for (final project in projects) ...[
                          _BookBreakdownProjectRow(
                            project: project,
                            isCurrent: project.id == currentProject?.id,
                            tableWidth: tableWidth,
                            onStartOrPause: onStartOrPause,
                            onSelectProject: onSelectProject,
                            onOpenProjectFolder: onOpenProjectFolder,
                            onOpenProjectReport: onOpenProjectReport,
                            onDeleteProject: onDeleteProject,
                          ),
                          if (project != projects.last)
                            Divider(height: 1, color: colors.line),
                        ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BookBreakdownProjectTableHeader extends StatelessWidget {
  const _BookBreakdownProjectTableHeader({required this.tableWidth});

  final double tableWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _bookProjectTableHorizontalPadding,
        ),
        child: Row(
          children: [
            SizedBox(
              width: _bookProjectNameWidth(tableWidth),
              child: const _TableHeaderText('项目名称'),
            ),
            const SizedBox(
              width: _bookProjectProgressWidth,
              child: _TableHeaderText('进度'),
            ),
            const SizedBox(
              width: _bookProjectStatusWidth,
              child: _TableHeaderText('状态'),
            ),
            const SizedBox(
              width: _bookProjectUpdatedWidth,
              child: _TableHeaderText('更新时间'),
            ),
            const SizedBox(
              width: _bookProjectActionWidth,
              child: _TableHeaderText('操作'),
            ),
            const SizedBox(width: _bookProjectMenuWidth),
          ],
        ),
      ),
    );
  }
}

class _BookBreakdownProjectRow extends StatelessWidget {
  const _BookBreakdownProjectRow({
    required this.project,
    required this.isCurrent,
    required this.tableWidth,
    this.onStartOrPause,
    this.onSelectProject,
    this.onOpenProjectFolder,
    this.onOpenProjectReport,
    this.onDeleteProject,
  });

  final BookDeconstructionProject project;
  final bool isCurrent;
  final double tableWidth;
  final VoidCallback? onStartOrPause;
  final ValueChanged<int>? onSelectProject;
  final ValueChanged<int>? onOpenProjectFolder;
  final ValueChanged<int>? onOpenProjectReport;
  final ValueChanged<int>? onDeleteProject;

  @override
  Widget build(BuildContext context) {
    final progress = (project.progress * 100).round();
    final action = _projectAction(project.status, isCurrent);

    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _bookProjectTableHorizontalPadding,
        ),
        child: Row(
          children: [
            SizedBox(
              width: _bookProjectNameWidth(tableWidth),
              child: Text(
                project.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppPalette.of(context).text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              width: _bookProjectProgressWidth,
              child: _BookProjectProgress(
                progress: project.progress,
                label: '$progress%',
              ),
            ),
            SizedBox(
              width: _bookProjectStatusWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _BookProjectStatusPill(status: project.status),
              ),
            ),
            SizedBox(
              width: _bookProjectUpdatedWidth,
              child: Text(
                _relativeTime(project.updatedAt),
                style: TextStyle(color: AppPalette.of(context).muted),
              ),
            ),
            SizedBox(
              width: _bookProjectActionWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _BookProjectActionButton(
                  icon: action.$2,
                  label: action.$1,
                  onPressed: () {
                    if (project.status ==
                        BookDeconstructionProjectStatus.completed) {
                      onOpenProjectReport?.call(project.id);
                    } else if (isCurrent &&
                        project.status ==
                            BookDeconstructionProjectStatus.paused) {
                      onStartOrPause?.call();
                    } else {
                      onSelectProject?.call(project.id);
                    }
                  },
                ),
              ),
            ),
            SizedBox(
              width: _bookProjectMenuWidth,
              child: _BookProjectMoreMenu(
                isCurrent: isCurrent,
                isCompleted:
                    project.status == BookDeconstructionProjectStatus.completed,
                onSelect: () => onSelectProject?.call(project.id),
                onOpenFolder: () => onOpenProjectFolder?.call(project.id),
                onOpenReport: () => onOpenProjectReport?.call(project.id),
                onDelete: () => onDeleteProject?.call(project.id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookProjectProgress extends StatelessWidget {
  const _BookProjectProgress({
    required this.progress,
    required this.label,
  });

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final value = progress.clamp(0.0, 1.0).toDouble();

    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: TextStyle(
              color: colors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          width: 148,
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: colors.line,
            color: colors.text,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

class _BookProjectMoreMenu extends StatelessWidget {
  const _BookProjectMoreMenu({
    required this.isCurrent,
    required this.isCompleted,
    required this.onSelect,
    required this.onOpenFolder,
    required this.onOpenReport,
    required this.onDelete,
  });

  final bool isCurrent;
  final bool isCompleted;
  final VoidCallback onSelect;
  final VoidCallback onOpenFolder;
  final VoidCallback onOpenReport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return PopupMenuButton<_BookProjectMenuAction>(
      tooltip: '更多',
      icon: Icon(Icons.more_horiz, color: colors.muted),
      onSelected: (action) {
        switch (action) {
          case _BookProjectMenuAction.select:
            onSelect();
          case _BookProjectMenuAction.openFolder:
            onOpenFolder();
          case _BookProjectMenuAction.openReport:
            onOpenReport();
          case _BookProjectMenuAction.delete:
            onDelete();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _BookProjectMenuAction.select,
          enabled: !isCurrent,
          child: const Text('设为当前项目'),
        ),
        const PopupMenuItem(
          value: _BookProjectMenuAction.openFolder,
          child: Text('打开项目文件夹'),
        ),
        PopupMenuItem(
          value: _BookProjectMenuAction.openReport,
          enabled: isCompleted,
          child: const Text('查看报告'),
        ),
        const PopupMenuItem(
          value: _BookProjectMenuAction.delete,
          child: Text('删除项目'),
        ),
      ],
    );
  }
}

enum _BookProjectMenuAction { select, openFolder, openReport, delete }

(String, IconData) _projectAction(
  BookDeconstructionProjectStatus status,
  bool isCurrent,
) {
  if (isCurrent) {
    return switch (status) {
      BookDeconstructionProjectStatus.completed => ('查看报告', Icons.article),
      BookDeconstructionProjectStatus.paused => ('继续拆书', Icons.play_arrow),
      BookDeconstructionProjectStatus.failed => ('查看详情', Icons.error_outline),
      _ => ('进入项目', Icons.open_in_new),
    };
  }

  return switch (status) {
    BookDeconstructionProjectStatus.completed => ('查看报告', Icons.article),
    BookDeconstructionProjectStatus.running => ('进入项目', Icons.open_in_new),
    BookDeconstructionProjectStatus.paused => ('继续拆书', Icons.play_arrow),
    BookDeconstructionProjectStatus.failed => ('查看详情', Icons.error_outline),
    BookDeconstructionProjectStatus.draft => ('进入项目', Icons.open_in_new),
  };
}

class _BookProjectStatusPill extends StatelessWidget {
  const _BookProjectStatusPill({required this.status});

  final BookDeconstructionProjectStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (label, color, background) = switch (status) {
      BookDeconstructionProjectStatus.draft => (
          '待开始',
          const Color(0xFF6B7280),
          const Color(0xFFF3F4F6),
        ),
      BookDeconstructionProjectStatus.running => (
          '进行中',
          const Color(0xFF2563EB),
          const Color(0xFFEAF2FF),
        ),
      BookDeconstructionProjectStatus.paused => (
          '排队中',
          const Color(0xFFD97706),
          const Color(0xFFFFF3DC),
        ),
      BookDeconstructionProjectStatus.completed => (
          '已完成',
          const Color(0xFF16A34A),
          const Color(0xFFE7F7ED),
        ),
      BookDeconstructionProjectStatus.failed => (
          '失败',
          Theme.of(context).colorScheme.error,
          Theme.of(context).colorScheme.errorContainer,
        ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.18) : background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BookProjectActionButton extends StatelessWidget {
  const _BookProjectActionButton({
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

    return SizedBox(
      height: 34,
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 16),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.text,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: const Size(0, 34),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          side: BorderSide(color: colors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TableHeaderText extends StatelessWidget {
  const _TableHeaderText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Text(
      text,
      style: TextStyle(
        color: colors.muted,
        fontSize: 13,
        fontWeight: FontWeight.w700,
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
              _StatusLabel(text: _statusText(context)),
              const SizedBox(height: 18),
              Text(
                _titleText(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                _metaText(context),
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
                      label: context.l10n.text('action.newNovel'),
                      onPressed: actions.createNovel,
                    ),
                    _SecondaryButton(
                      icon: Icons.upload_file,
                      label: context.l10n.text('action.importNovel'),
                      onPressed: actions.importNovel,
                    ),
                  ] else if (recentNovel != null)
                    _PrimaryButton(
                      icon: Icons.edit,
                      label: context.l10n.text('action.continueWriting'),
                      onPressed: () => actions.openProject(recentNovel),
                    )
                  else
                    _PrimaryButton(
                      icon: Icons.add,
                      label: context.l10n.text('action.newNovel'),
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
      minHeight: fillAvailableHeight ? 420 : 290,
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

  String _statusText(BuildContext context) {
    final l10n = context.l10n;
    switch (state.mode) {
      case DashboardMode.loading:
        return l10n.text('dashboard.loading.label');
      case DashboardMode.firstUse:
        return l10n.text('dashboard.firstUse.label');
      case DashboardMode.noRecentWriting:
        return l10n.text('dashboard.selectProject.label');
      case DashboardMode.searchEmpty:
      case DashboardMode.populated:
        return l10n.text('dashboard.populated.label');
    }
  }

  String _titleText(BuildContext context) {
    final l10n = context.l10n;
    switch (state.mode) {
      case DashboardMode.loading:
        return l10n.text('dashboard.loading.title');
      case DashboardMode.firstUse:
        return l10n.text('dashboard.firstUse.title');
      case DashboardMode.noRecentWriting:
        return l10n.text('dashboard.populated.titleFallback');
      case DashboardMode.searchEmpty:
      case DashboardMode.populated:
        return state.recentWriting?.novelTitle ??
            l10n.text('dashboard.populated.titleFallback');
    }
  }

  String _metaText(BuildContext context) {
    final l10n = context.l10n;
    switch (state.mode) {
      case DashboardMode.loading:
        return l10n.text('dashboard.loading.description');
      case DashboardMode.firstUse:
        return l10n.text('dashboard.firstUse.description');
      case DashboardMode.noRecentWriting:
        return l10n.projectStats(
          state.projectCount,
          _formatWords(context, state.totalWordCount),
        );
      case DashboardMode.searchEmpty:
      case DashboardMode.populated:
        final chapterTitle = state.recentWriting?.chapterTitle;
        return l10n.projectStats(
          state.projectCount,
          _formatWords(context, state.totalWordCount),
          suffix: chapterTitle,
        );
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
    final l10n = context.l10n;

    return Column(
      key: const ValueKey('dashboard-stats-column'),
      children: [
        _StatCard(
          title: l10n.text('dashboard.todayGoal'),
          value: goal == null
              ? l10n.text('dashboard.goalUnset')
              : l10n.goalProgress(goal.currentWords, goal.targetWords),
          icon: Icons.track_changes,
          child: goal == null
              ? Text(
                  l10n.text('dashboard.goalEmpty'),
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
        const SizedBox(height: 14),
        _StatCard(
          title: l10n.text('dashboard.projectCount'),
          value: state.projectCount.toString(),
          icon: Icons.menu_book,
          iconColor: colors.brand,
        ),
        const SizedBox(height: 14),
        _StatCard(
          title: l10n.text('dashboard.totalWords'),
          value: _formatWords(context, state.totalWordCount),
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
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final title = Text(
              l10n.text('dashboard.myNovels'),
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
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 18),
                        hintText: l10n.text('dashboard.searchHint'),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                _SecondaryButton(
                  icon: Icons.upload_file,
                  label: l10n.text('action.importNovel'),
                  onPressed: actions.importNovel,
                ),
                _PrimaryButton(
                  icon: Icons.add,
                  label: l10n.text('action.newNovel'),
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
    final l10n = context.l10n;

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
                    novel.summary.isEmpty
                        ? l10n.text('dashboard.noSummary')
                        : novel.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "${_formatWords(context, novel.wordCount)} · ${_novelTags(context, novel)}",
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
    final l10n = context.l10n;

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
                l10n.text('dashboard.emptyTitle'),
                style: TextStyle(
                  color: colors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.text('dashboard.emptyDescription'),
                style: TextStyle(color: colors.muted),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _PrimaryButton(
                    icon: Icons.add,
                    label: l10n.text('action.newNovel'),
                    onPressed: actions.createNovel,
                  ),
                  _SecondaryButton(
                    icon: Icons.upload_file,
                    label: l10n.text('action.importNovel'),
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
    final l10n = context.l10n;

    return _CardShell(
      minHeight: 150,
      child: Center(
        child: Text(
          l10n.searchEmpty(query.trim()),
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

String _formatWords(BuildContext context, int words) {
  if (words < 10000) {
    return words.toString();
  }
  final value = words / 10000;
  final text = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return context.l10n.tenThousands(text);
}

String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) {
    return '刚刚';
  }
  if (diff.inHours < 1) {
    return '${diff.inMinutes}分钟前';
  }
  if (diff.inDays < 1) {
    return '${diff.inHours}小时前';
  }
  if (diff.inDays == 1) {
    return '昨天';
  }
  return '${diff.inDays}天前';
}

String _novelTags(BuildContext context, NovelSummary novel) {
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
  return tags.isEmpty
      ? context.l10n.text('dashboard.unsetType')
      : tags.join(' · ');
}
