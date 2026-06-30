import 'package:ai_novel_factory/src/app/app_theme.dart';
import 'package:ai_novel_factory/src/book_lab/book_deconstruction_workflow.dart';
import 'package:ai_novel_factory/src/dashboard/dashboard_models.dart';
import 'package:ai_novel_factory/src/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
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
      ),
    ));

    expect(find.text('Source Novel'), findsOneWidget);
    expect(find.text('暂停拆书'), findsOneWidget);
    expect(find.text('Book Lab'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, '暂停拆书'));
    await tester.tap(find.widgetWithText(FilledButton, '新建拆书'));

    expect(toggled, isTrue);
    expect(created, isTrue);
  });
}

BookDeconstructionProject _bookProject({
  Map<String, BookDeconstructionNodeStatus> nodeStatuses = const {},
}) {
  return BookDeconstructionProject(
    id: 1,
    title: 'Book Lab',
    status: BookDeconstructionProjectStatus.running,
    progress: 0.1,
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
