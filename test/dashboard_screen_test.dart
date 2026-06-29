import 'package:ai_novel_factory/src/app/app_theme.dart';
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

DashboardActions _actions() {
  return DashboardActions(
    createNovel: () {},
    importNovel: () {},
    openProject: (_) {},
    toggleTheme: () {},
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
