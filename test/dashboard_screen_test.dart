import 'dart:async';

import 'package:ai_novel_factory/src/app/app_theme.dart';
import 'package:ai_novel_factory/src/book_lab/book_deconstruction_workflow.dart';
import 'package:ai_novel_factory/src/dashboard/dashboard_models.dart';
import 'package:ai_novel_factory/src/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('first-use state shows empty dashboard without search',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrap(
      DashboardScreen(
        state: DashboardViewState(
          mode: DashboardMode.firstUse,
          novels: const [],
          visibleNovels: const [],
          totalWordCount: 0,
          today: DateTime(2026, 6, 29),
          searchQuery: '',
        ),
        actions: _actions(),
        searchController: controller,
        onSearchChanged: (_) {},
      ),
    ));

    expect(find.text('还没有小说项目'), findsOneWidget);
    expect(find.text('暂无小说项目'), findsOneWidget);
    expect(find.text('未设置'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('populated state shows real project data', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final today = DateTime(2026, 6, 29);
    final novel = NovelSummary(
      id: 1,
      title: '真实小说',
      summary: '真实简介',
      status: '规划中',
      category: '科幻',
      workType: '原创',
      tags: const ['AI'],
      coverPath: null,
      updatedAt: today,
      wordCount: 1200,
    );

    await tester.pumpWidget(_wrap(
      DashboardScreen(
        state: DashboardViewState(
          mode: DashboardMode.populated,
          novels: [novel],
          visibleNovels: [novel],
          totalWordCount: 1200,
          today: today,
          writingGoal: const WritingGoalSummary(
            targetWords: 2000,
            currentWords: 1200,
          ),
          recentWriting: RecentWriting(
            novelId: 1,
            novelTitle: novel.title,
            updatedAt: today,
          ),
          searchQuery: '',
        ),
        actions: _actions(),
        searchController: controller,
        onSearchChanged: (_) {},
      ),
    ));

    expect(find.text('真实小说'), findsWidgets);
    expect(find.text('真实简介'), findsOneWidget);
    expect(find.text('1200 / 2000'), findsOneWidget);
    expect(find.text('1200 · 科幻 · 原创 · AI'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('search-empty state is not first-use state', (tester) async {
    final controller = TextEditingController(text: '不存在');
    addTearDown(controller.dispose);
    final today = DateTime(2026, 6, 29);
    final novel = NovelSummary(
      id: 1,
      title: '真实小说',
      summary: '',
      status: '',
      category: '',
      workType: '',
      tags: const [],
      coverPath: null,
      updatedAt: today,
      wordCount: 0,
    );

    await tester.pumpWidget(_wrap(
      DashboardScreen(
        state: DashboardViewState(
          mode: DashboardMode.searchEmpty,
          novels: [novel],
          visibleNovels: const [],
          totalWordCount: 0,
          today: today,
          searchQuery: '不存在',
        ),
        actions: _actions(),
        searchController: controller,
        onSearchChanged: (_) {},
      ),
    ));

    expect(find.text('没有匹配“不存在”的小说项目'), findsOneWidget);
    expect(find.text('暂无小说项目'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('wide hero card aligns with stats column height', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_wrap(
      DashboardScreen(
        state: DashboardViewState(
          mode: DashboardMode.firstUse,
          novels: const [],
          visibleNovels: const [],
          totalWordCount: 0,
          today: DateTime(2026, 6, 29),
          searchQuery: '',
        ),
        actions: _actions(),
        searchController: controller,
        onSearchChanged: (_) {},
      ),
    ));

    final primaryHeight = tester
        .getSize(find.byKey(const ValueKey('dashboard-primary-work-card')))
        .height;
    final statsHeight = tester
        .getSize(find.byKey(const ValueKey('dashboard-stats-column')))
        .height;

    expect(primaryHeight, statsHeight);
  });

  testWidgets('theme toggle changes the app palette globally', (tester) async {
    await tester.pumpWidget(const _ThemeHarness());

    expect(_scaffoldBackground(tester), AppPalette.light.background);
    expect(find.byIcon(Icons.dark_mode), findsOneWidget);

    await tester.tap(find.byTooltip('切换深色模式'));
    await tester.pumpAndSettle();

    expect(_scaffoldBackground(tester), AppPalette.dark.background);
    expect(find.byIcon(Icons.light_mode), findsOneWidget);
  });

  testWidgets('settings button appears when action is available',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var opened = false;

    await tester.pumpWidget(_wrap(
      DashboardScreen(
        state: DashboardViewState(
          mode: DashboardMode.firstUse,
          novels: const [],
          visibleNovels: const [],
          totalWordCount: 0,
          today: DateTime(2026, 6, 29),
          searchQuery: '',
        ),
        actions: _actions(
          openSettings: () {
            opened = true;
          },
        ),
        searchController: controller,
        onSearchChanged: (_) {},
      ),
    ));

    expect(find.widgetWithText(OutlinedButton, '设置'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, '设置'));
    expect(opened, isTrue);
  });

  testWidgets('book breakdown button appears when action is available',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var opened = false;

    await tester.pumpWidget(_wrap(
      DashboardScreen(
        state: DashboardViewState(
          mode: DashboardMode.firstUse,
          novels: const [],
          visibleNovels: const [],
          totalWordCount: 0,
          today: DateTime(2026, 6, 29),
          searchQuery: '',
        ),
        actions: _actions(
          openBookBreakdown: () {
            opened = true;
          },
        ),
        searchController: controller,
        onSearchChanged: (_) {},
      ),
    ));

    expect(find.widgetWithText(OutlinedButton, '拆书'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, '拆书'));
    expect(opened, isTrue);
  });
  testWidgets('book deconstruction screen shows workspace and back action',
      (tester) async {
    var wentBack = false;

    await tester.pumpWidget(_wrap(
      BookDeconstructionScreen(
        today: DateTime(2026, 6, 30),
        onBack: () {
          wentBack = true;
        },
        onToggleTheme: () {},
      ),
    ));

    expect(find.text('拆书工作台'), findsOneWidget);
    expect(find.text('开始拆书'), findsWidgets);
    expect(find.text('暂无拆书项目'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('book-target-status-章节拆解-pending'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('book-pipeline-status-文本清洗-pending'),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_circle), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back));
    expect(wentBack, isTrue);
  });

  testWidgets('book deconstruction running nodes animate current statuses',
      (tester) async {
    await tester.pumpWidget(_wrap(
      BookDeconstructionScreen(
        today: DateTime(2026, 6, 30),
        onBack: () {},
        onToggleTheme: () {},
        currentProject: _bookProject(
          nodeStatuses: const {
            'book_text_cleaning': BookDeconstructionNodeStatus.running,
            'book_chapter_content': BookDeconstructionNodeStatus.running,
          },
        ),
      ),
    ));

    expect(
      find.byKey(
        const ValueKey('book-target-status-章节拆解-running'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('book-pipeline-status-文本清洗-running'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('book-pipeline-status-拆解-running'),
      ),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNWidgets(3));
  });

  testWidgets('book deconstruction project state drives actions and metrics',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    var created = false;
    var toggled = false;
    int? experimentalProjectId;
    final project = _bookProject(
      nodeStatuses: const {
        'book_text_cleaning': BookDeconstructionNodeStatus.passed,
      },
    );

    await tester.pumpWidget(_wrap(
      BookDeconstructionScreen(
        today: DateTime(2026, 6, 30),
        currentProject: project,
        projects: [project],
        onBack: () {},
        onToggleTheme: () {},
        onCreateProject: () {
          created = true;
        },
        onStartOrPause: () {
          toggled = true;
        },
        onOpenExperimentalWriting: (projectId) {
          experimentalProjectId = projectId;
        },
      ),
    ));

    expect(find.text('Source Novel'), findsOneWidget);
    expect(find.text('暂停拆书'), findsOneWidget);
    expect(find.text('Book Lab'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, '暂停拆书'));
    await tester.tap(find.widgetWithText(OutlinedButton, '实验写作'));
    await tester.tap(find.widgetWithText(FilledButton, '新建拆书'));

    expect(toggled, isTrue);
    expect(created, isTrue);
    expect(experimentalProjectId, project.id);
  });

  testWidgets('book project continue action does not open project folder',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    var resumed = 0;
    var openedFolder = 0;
    var selectedProjectId = 0;
    final project = _bookProject(
      status: BookDeconstructionProjectStatus.paused,
      progress: 0.85,
    );

    await tester.pumpWidget(_wrap(
      BookDeconstructionScreen(
        today: DateTime(2026, 7, 1),
        currentProject: project,
        projects: [project],
        onBack: () {},
        onToggleTheme: () {},
        onStartOrPause: () {
          resumed++;
        },
        onSelectProject: (projectId) {
          selectedProjectId = projectId;
        },
        onOpenProjectFolder: (_) {
          openedFolder++;
        },
      ),
    ));

    final continueButton = find.widgetWithText(OutlinedButton, '继续拆书');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();

    expect(resumed, 1);
    expect(openedFolder, 0);
    expect(selectedProjectId, 0);
  });

  testWidgets('book project row action selects unfinished non-current project',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    var openedFolder = 0;
    var selectedProjectId = 0;
    final current = _bookProject(id: 1, title: 'Current');
    final queued = _bookProject(
      id: 2,
      title: 'Queued',
      status: BookDeconstructionProjectStatus.paused,
      progress: 0.85,
    );

    await tester.pumpWidget(_wrap(
      BookDeconstructionScreen(
        today: DateTime(2026, 7, 1),
        currentProject: current,
        projects: [queued],
        onBack: () {},
        onToggleTheme: () {},
        onSelectProject: (projectId) {
          selectedProjectId = projectId;
        },
        onOpenProjectFolder: (_) {
          openedFolder++;
        },
      ),
    ));

    final continueButton = find.widgetWithText(OutlinedButton, '继续拆书');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();

    expect(selectedProjectId, queued.id);
    expect(openedFolder, 0);
  });

  testWidgets('experimental writing dialog sends with Enter', (tester) async {
    final messages = <BookExperimentalWritingMessage>[];
    var sends = 0;

    await tester.pumpWidget(_wrap(
      Builder(
        builder: (context) => TextButton(
          onPressed: () {
            showBookExperimentalWritingDialog(
              context,
              project: _bookProject(),
              loadMessages: (_) async => messages,
              onSendMessage: (projectId, message) async {
                sends++;
                final reply = BookExperimentalWritingMessage(
                  projectId: projectId,
                  role: 'assistant',
                  content: '收到：$message',
                  createdAt: DateTime(2026, 6, 30),
                );
                messages.add(reply);
                return reply;
              },
              onSaveFinalDraft: (_, __) async {},
            );
          },
          child: const Text('open'),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '重新一版');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(sends, 1);
    expect(find.text('收到：重新一版'), findsOneWidget);
  });

  testWidgets('experimental writing dialog does not block background actions',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    var backgroundTapped = false;

    await tester.pumpWidget(_wrap(
      Stack(
        children: [
          Positioned(
            left: 20,
            top: 20,
            child: TextButton(
              onPressed: () => backgroundTapped = true,
              child: const Text('background back'),
            ),
          ),
          Center(
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  showBookExperimentalWritingDialog(
                    context,
                    project: _bookProject(),
                    loadMessages: (_) async => const [],
                    onSendMessage: (_, __) async =>
                        BookExperimentalWritingMessage(
                      projectId: 1,
                      role: 'assistant',
                      content: 'ok',
                      createdAt: DateTime(2026, 6, 30),
                    ),
                    onSaveFinalDraft: (_, __) async {},
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ],
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('实验性写作 Agent'), findsOneWidget);

    await tester.tap(find.text('background back'));
    await tester.pump();

    expect(backgroundTapped, isTrue);
  });

  testWidgets('experimental writing dialog shows outgoing message immediately',
      (tester) async {
    final pending = Completer<BookExperimentalWritingMessage>();

    await tester.pumpWidget(_wrap(
      Builder(
        builder: (context) => TextButton(
          onPressed: () {
            showBookExperimentalWritingDialog(
              context,
              project: _bookProject(),
              loadMessages: (_) async => const [],
              onSendMessage: (_, __) => pending.future,
              onSaveFinalDraft: (_, __) async {},
            );
          },
          child: const Text('open'),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '重新一版');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(find.text('重新一版'), findsOneWidget);
    expect(find.text('生成中'), findsOneWidget);

    pending.complete(BookExperimentalWritingMessage(
      projectId: 1,
      role: 'assistant',
      content: '完成',
      createdAt: DateTime(2026, 6, 30),
    ));
    await tester.pumpAndSettle();
  });

  testWidgets('experimental writing dialog opens at latest message',
      (tester) async {
    final messages = [
      for (var i = 0; i < 28; i++)
        BookExperimentalWritingMessage(
          projectId: 1,
          role: i.isEven ? 'user' : 'assistant',
          content: '历史消息 $i',
          createdAt: DateTime(2026, 6, 30),
        ),
      BookExperimentalWritingMessage(
        projectId: 1,
        role: 'assistant',
        content: '最新回复',
        createdAt: DateTime(2026, 6, 30),
      ),
    ];

    await tester.pumpWidget(_wrap(
      Builder(
        builder: (context) => TextButton(
          onPressed: () {
            showBookExperimentalWritingDialog(
              context,
              project: _bookProject(),
              loadMessages: (_) async => messages,
              onSendMessage: (_, __) async => messages.last,
              onSaveFinalDraft: (_, __) async {},
            );
          },
          child: const Text('open'),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('最新回复'), findsOneWidget);
    expect(
        find.byWidgetPredicate(
          (widget) => widget is SelectableText && widget.data == '最新回复',
        ),
        findsOneWidget);
  });
}

BookDeconstructionProject _bookProject({
  int id = 1,
  String title = 'Book Lab',
  BookDeconstructionProjectStatus status =
      BookDeconstructionProjectStatus.running,
  double progress = 0.1,
  Map<String, BookDeconstructionNodeStatus> nodeStatuses = const {},
}) {
  return BookDeconstructionProject(
    id: id,
    title: title,
    status: status,
    progress: progress,
    chapterCount: 1,
    characterCount: 0,
    foreshadowingCount: 0,
    styleAssetCount: 0,
    updatedAt: DateTime(2026, 6, 30),
    nodeStatuses: nodeStatuses,
    novelId: 1,
    novelTitle: 'Source Novel',
  );
}

Color? _scaffoldBackground(WidgetTester tester) {
  return tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor;
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    home: child,
  );
}

DashboardActions _actions({
  VoidCallback? openSettings,
  VoidCallback? openBookBreakdown,
}) {
  return DashboardActions(
    createNovel: () {},
    importNovel: () {},
    openProject: (_) {},
    toggleTheme: () {},
    openSettings: openSettings,
    openBookBreakdown: openBookBreakdown,
  );
}

class _ThemeHarness extends StatefulWidget {
  const _ThemeHarness();

  @override
  State<_ThemeHarness> createState() => _ThemeHarnessState();
}

class _ThemeHarnessState extends State<_ThemeHarness> {
  final _controller = TextEditingController();
  var _themeMode = ThemeMode.light;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: DashboardScreen(
        state: DashboardViewState(
          mode: DashboardMode.firstUse,
          novels: const [],
          visibleNovels: const [],
          totalWordCount: 0,
          today: DateTime(2026, 6, 29),
          searchQuery: '',
        ),
        actions: DashboardActions(
          createNovel: () {},
          importNovel: () {},
          openProject: (_) {},
          toggleTheme: () {
            setState(() {
              _themeMode = _themeMode == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
            });
          },
        ),
        searchController: _controller,
        onSearchChanged: (_) {},
      ),
    );
  }
}
