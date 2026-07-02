import 'dart:async';
import 'dart:ui';

import 'package:ai_novel_factory/src/app/app_theme.dart';
import 'package:ai_novel_factory/src/book_lab/book_deconstruction_workflow.dart';
import 'package:ai_novel_factory/src/dashboard/dashboard_models.dart';
import 'package:ai_novel_factory/src/dashboard/dashboard_screen.dart';
import 'package:flutter/gestures.dart';
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
    expect(find.text('创作中'), findsOneWidget);
    expect(find.text('全部作品'), findsOneWidget);
    expect(find.text('全部 1'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('primary card more action edits the last project',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final today = DateTime(2026, 6, 29);
    final novel = NovelSummary(
      id: 7,
      title: 'Last Book',
      summary: 'Summary',
      status: '',
      category: 'Sci-fi',
      workType: 'Original',
      tags: const [],
      coverPath: null,
      updatedAt: today,
      wordCount: 0,
    );
    NovelSummary? edited;

    await tester.pumpWidget(_wrap(
      DashboardScreen(
        state: DashboardViewState(
          mode: DashboardMode.noRecentWriting,
          novels: [novel],
          visibleNovels: [novel],
          totalWordCount: 0,
          today: today,
          searchQuery: '',
        ),
        actions: _actions(editProject: (novel) => edited = novel),
        searchController: controller,
        onSearchChanged: (_) {},
      ),
    ));

    await tester.tap(find.byIcon(Icons.more_horiz).first);
    await tester.pump();

    expect(edited?.id, 7);
  });

  testWidgets('project library filters statuses and updates from hover menu',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1417, 1200);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final today = DateTime(2026, 6, 29, 14, 49);
    final novels = [
      NovelSummary(
        id: 1,
        title: 'Writing',
        summary: '',
        status: '',
        category: '',
        workType: 'Original',
        tags: const [],
        coverPath: null,
        updatedAt: today,
        wordCount: 0,
      ),
      NovelSummary(
        id: 2,
        title: 'Completed',
        summary: '',
        status: '已完本',
        category: '',
        workType: 'Original',
        tags: const [],
        coverPath: null,
        updatedAt: today,
        wordCount: 0,
      ),
      NovelSummary(
        id: 3,
        title: 'Abandoned',
        summary: '',
        status: '已放弃',
        category: '',
        workType: 'Original',
        tags: const [],
        coverPath: null,
        updatedAt: today,
        wordCount: 0,
      ),
      NovelSummary(
        id: 4,
        title: 'Archived',
        summary: '',
        status: '已归档',
        category: '',
        workType: 'Original',
        tags: const [],
        coverPath: null,
        updatedAt: today,
        wordCount: 0,
      ),
    ];
    (NovelSummary, String)? statusChange;

    await tester.pumpWidget(_wrap(
      DashboardScreen(
        state: DashboardViewState(
          mode: DashboardMode.populated,
          novels: novels,
          visibleNovels: novels,
          totalWordCount: 0,
          today: today,
          searchQuery: '',
        ),
        actions: _actions(
          updateProjectStatus: (novel, status) {
            statusChange = (novel, status);
          },
        ),
        searchController: controller,
        onSearchChanged: (_) {},
      ),
    ));

    expect(find.text('全部 4'), findsOneWidget);
    expect(find.text('创作中 1'), findsOneWidget);
    expect(find.text('已完本 1'), findsOneWidget);
    expect(find.text('已放弃 1'), findsOneWidget);
    expect(find.text('已归档 1'), findsOneWidget);

    await tester.tap(find.text('已完本 1'));
    await tester.pump();
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Writing'), findsNothing);

    await tester.tap(find.text('全部 4'));
    await tester.pump();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(find.text('Writing')));
    await tester.pump();
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    await mouse.removePointer();

    await tester.tap(find.byIcon(Icons.format_list_bulleted));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('完结'));
    await tester.pump();

    expect(statusChange?.$1.id, 1);
    expect(statusChange?.$2, '已完本');
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
  testWidgets('project overview screen shows empty chapter state',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1417, 977);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    String? savedChapterTitle;
    String? savedVolumeTitle;
    final novel = NovelSummary(
      id: 1,
      title: '重生之我用 AI 写小说',
      summary: '',
      status: '',
      category: '穿越',
      workType: 'AI',
      tags: const [],
      coverPath: null,
      updatedAt: DateTime(2026, 6, 29),
      wordCount: 0,
    );

    await tester.pumpWidget(_wrap(
      ProjectOverviewScreen(
        novel: novel,
        assistantModels: const ['deepseek-v4-flash'],
        loadChapters: (_) async => const [],
        loadVolumes: (_) async => const [],
        createVolume: ({required novelId, required title}) async {
          savedVolumeTitle = title;
          return NovelVolume(
            id: 1,
            novelId: novelId,
            title: title,
            updatedAt: DateTime(2026, 6, 30),
          );
        },
        saveChapter: ({
          required novelId,
          required chapterId,
          required title,
          required outline,
          required content,
        }) async {
          savedChapterTitle = title;
          return NovelChapter(
            id: 1,
            novelId: novelId,
            title: title,
            outline: outline,
            content: content,
            wordCount: 0,
            updatedAt: DateTime(2026, 6, 30),
          );
        },
        onBack: () {},
        onToggleTheme: () {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('继续写作'), findsWidgets);
    expect(find.text('作品简介'), findsWidgets);

    await tester.tap(find.text('章节').first);
    await tester.pumpAndSettle();

    expect(find.text('还没有选中章节'), findsOneWidget);
    expect(find.text('先新建第一章。'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '新建章节'), findsOneWidget);

    await tester.tap(find.byTooltip('新建卷'));
    await tester.pumpAndSettle();
    expect(find.text('新建卷'), findsOneWidget);
    expect(find.text('输入卷名称'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '第一卷');
    await tester.tap(find.widgetWithText(FilledButton, '新建'));
    await tester.pumpAndSettle();
    expect(savedVolumeTitle, '第一卷');
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '新建章节'));
    await tester.pumpAndSettle();

    expect(savedChapterTitle, '第1章');
    expect(find.text('第1章'), findsWidgets);
  });

  testWidgets('project overview screen shows outline workspace',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1417, 977);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    var nextOutlineId = 1;
    String? savedOutlineTitle;
    String? savedBeatsJson;
    final novel = NovelSummary(
      id: 1,
      title: '重生之我用 AI 写小说',
      summary: '',
      status: '',
      category: '穿越',
      workType: 'AI',
      tags: const [],
      coverPath: null,
      updatedAt: DateTime(2026, 6, 29),
      wordCount: 0,
    );

    await tester.pumpWidget(_wrap(
      ProjectOverviewScreen(
        novel: novel,
        assistantModels: const ['deepseek-v4-flash'],
        loadChapters: (_) async => const [],
        loadOutlines: (_) async => const [],
        saveOutline: ({
          required novelId,
          required outlineId,
          required title,
          required status,
          required content,
          required beatsJson,
        }) async {
          savedOutlineTitle = title;
          savedBeatsJson = beatsJson;
          return NovelOutline(
            id: nextOutlineId++,
            novelId: novelId,
            title: title,
            status: status,
            content: content,
            beatsJson: beatsJson,
            updatedAt: DateTime(2026, 6, 30),
          );
        },
        onBack: () {},
        onToggleTheme: () {},
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('大纲').first);
    await tester.pumpAndSettle();

    expect(find.text('全局大纲时间轴'), findsOneWidget);
    expect(find.text('还没有时间线节拍'), findsOneWidget);

    await tester.tap(find.byTooltip('新增大纲'));
    await tester.pumpAndSettle();

    expect(savedOutlineTitle, '未命名');
    expect(find.text('时间线节拍'), findsOneWidget);
    expect(find.text('还没有时间线节拍'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '保存'), findsOneWidget);
    expect(find.text('记录这条大纲的主内容、目标、冲突、伏线和结局兑现。'), findsOneWidget);

    await tester.tap(find.byTooltip('展开节拍'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('收起节拍'), findsOneWidget);
    expect(find.text('记录这条大纲的主内容、目标、冲突、伏线和结局兑现。'), findsNothing);

    await tester.tap(find.byTooltip('收起节拍'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('状态'));
    await tester.pumpAndSettle();
    expect(find.text('进行中'), findsWidgets);
    await tester.tap(find.text('进行中').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '新增节拍'));
    await tester.pumpAndSettle();
    expect(find.text('新增节拍'), findsWidgets);
    expect(find.text('预计章节数'), findsOneWidget);

    await tester.tap(find.text('插入结构模板'));
    await tester.pumpAndSettle();
    expect(find.textContaining('核心主题'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, '保存').last);
    await tester.pumpAndSettle();
    expect(find.text('节拍 1'), findsOneWidget);
    expect(savedBeatsJson, contains('核心主题'));

    await tester.tap(find.text('核心主题'));
    await tester.pumpAndSettle();
    expect(find.text('编辑节拍'), findsOneWidget);
    await tester.tap(find.byTooltip('关闭').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('节拍操作'));
    await tester.pumpAndSettle();
    expect(find.text('生成章纲'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);

    await tester.tap(find.text('生成章纲'));
    await tester.pumpAndSettle();
    expect(find.text('未命名'), findsWidgets);
    expect(
      find.text('请根据当前选中的节拍和所属大纲，生成这个节拍覆盖的所有章节大纲。'),
      findsOneWidget,
    );
  });

  testWidgets('project overview screen saves world settings', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1417, 977);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    var nextOutlineId = 1;
    final saved = <NovelOutline>[];

    await tester.pumpWidget(_wrap(
      ProjectOverviewScreen(
        novel: _novelForOverview(),
        assistantModels: const ['deepseek-v4-flash'],
        loadChapters: (_) async => const [],
        loadOutlines: (_) async => const [],
        saveOutline: ({
          required novelId,
          required outlineId,
          required title,
          required status,
          required content,
          required beatsJson,
        }) async {
          final outline = NovelOutline(
            id: outlineId ?? nextOutlineId++,
            novelId: novelId,
            title: title,
            status: status,
            content: content,
            beatsJson: beatsJson,
            updatedAt: DateTime(2026, 6, 30),
          );
          saved.add(outline);
          return outline;
        },
        onBack: () {},
        onToggleTheme: () {},
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('设定').first);
    await tester.pumpAndSettle();
    expect(find.text('还没有选中设定'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '新建世界观'));
    await tester.pumpAndSettle();

    expect(saved.single.title, '未命名设定');
    expect(saved.single.beatsJson, contains('world_setting'));
    expect(find.text('设定'), findsWidgets);
    expect(find.text('已保存'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '输入标题'), '星门规则');
    await tester.enterText(
      find.widgetWithText(TextField, '如：关键物品、地理、势力'),
      '地理',
    );
    await tester.enterText(
        find.widgetWithText(TextField, '在这里整理内容。'), '只在满月开启。');
    await tester.pumpAndSettle();

    expect(find.text('未保存'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(saved.last.title, '星门规则');
    expect(saved.last.status, '地理');
    expect(saved.last.content, '只在满月开启。');
    expect(saved.last.beatsJson, contains('world_setting'));
  });

  testWidgets('project overview screen manages factions permissions and delete',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1417, 977);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    var nextOutlineId = 1;
    final outlines = <NovelOutline>[];
    final saved = <NovelOutline>[];
    final deleted = <int>[];

    await tester.pumpWidget(_wrap(
      ProjectOverviewScreen(
        novel: _novelForOverview(),
        assistantModels: const ['deepseek-v4-flash'],
        loadChapters: (_) async => const [],
        loadOutlines: (_) async => outlines,
        saveOutline: ({
          required novelId,
          required outlineId,
          required title,
          required status,
          required content,
          required beatsJson,
        }) async {
          final outline = NovelOutline(
            id: outlineId ?? nextOutlineId++,
            novelId: novelId,
            title: title,
            status: status,
            content: content,
            beatsJson: beatsJson,
            updatedAt: DateTime(2026, 7, 1),
          );
          outlines
            ..removeWhere((item) => item.id == outline.id)
            ..add(outline);
          saved.add(outline);
          return outline;
        },
        deleteOutline: (novelId, outlineId) async {
          deleted.add(outlineId);
          outlines.removeWhere((item) => item.id == outlineId);
        },
        onBack: () {},
        onToggleTheme: () {},
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('势力').first);
    await tester.pumpAndSettle();
    expect(find.text('还没有选中势力'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '新建势力'));
    await tester.pumpAndSettle();

    expect(saved.single.title, '未命名势力');
    expect(saved.single.beatsJson, contains('faction'));

    await tester.enterText(
      find.widgetWithText(TextField, '输入势力标题'),
      'Mirroric 开发团队',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '如：关键物品、地理、势力'),
      '技术团队',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '在这里整理内容。'),
      '以创作工具为核心的技术团队。',
    );
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(saved.last.title, 'Mirroric 开发团队');
    expect(saved.last.status, '技术团队');
    expect(saved.last.content, '以创作工具为核心的技术团队。');
    expect(saved.last.beatsJson, contains('faction'));
    expect(find.text('Mirroric 开发团队'), findsWidgets);

    final row = find.ancestor(
      of: find.text('Mirroric 开发团队').first,
      matching: find.byType(InkWell),
    );
    await tester.tapAt(tester.getCenter(row.first), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(find.text('权限设置'), findsOneWidget);

    await tester.tap(find.text('权限设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('对 AI 隐藏'));
    await tester.tap(find.text('AI 不可编辑'));
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pumpAndSettle();

    expect(saved.last.beatsJson, contains('ai_hidden'));
    expect(saved.last.beatsJson, contains('ai_readonly'));

    await tester.tapAt(tester.getCenter(row.first), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.text('确定要删除“Mirroric 开发团队”吗？'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '删除'));
    await tester.pumpAndSettle();

    expect(deleted, [1]);
    expect(find.text('还没有选中势力'), findsOneWidget);
  });

  testWidgets(
      'project overview screen manages creatures permissions and delete',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1417, 977);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    var nextOutlineId = 1;
    final outlines = <NovelOutline>[];
    final saved = <NovelOutline>[];
    final deleted = <int>[];

    await tester.pumpWidget(_wrap(
      ProjectOverviewScreen(
        novel: _novelForOverview(),
        assistantModels: const ['deepseek-v4-flash'],
        loadChapters: (_) async => const [],
        loadOutlines: (_) async => outlines,
        saveOutline: ({
          required novelId,
          required outlineId,
          required title,
          required status,
          required content,
          required beatsJson,
        }) async {
          final outline = NovelOutline(
            id: outlineId ?? nextOutlineId++,
            novelId: novelId,
            title: title,
            status: status,
            content: content,
            beatsJson: beatsJson,
            updatedAt: DateTime(2026, 7, 1),
          );
          outlines
            ..removeWhere((item) => item.id == outline.id)
            ..add(outline);
          saved.add(outline);
          return outline;
        },
        deleteOutline: (novelId, outlineId) async {
          deleted.add(outlineId);
          outlines.removeWhere((item) => item.id == outlineId);
        },
        onBack: () {},
        onToggleTheme: () {},
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('生物').first);
    await tester.pumpAndSettle();
    expect(find.text('还没有选中生物'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '新建生物'));
    await tester.pumpAndSettle();

    expect(saved.single.title, '未命名生物');
    expect(saved.single.beatsJson, contains('creature'));

    await tester.enterText(
      find.widgetWithText(TextField, '输入生物标题'),
      'AI 写作代理',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '如：关键物品、地理、势力'),
      '数字生命',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '在这里整理内容。'),
      'Mirroric 平台上的智能写作代理。',
    );
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(saved.last.title, 'AI 写作代理');
    expect(saved.last.status, '数字生命');
    expect(saved.last.content, 'Mirroric 平台上的智能写作代理。');
    expect(saved.last.beatsJson, contains('creature'));
    expect(find.text('AI 写作代理'), findsWidgets);

    final row = find.ancestor(
      of: find.text('AI 写作代理').first,
      matching: find.byType(InkWell),
    );
    await tester.tapAt(tester.getCenter(row.first), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('权限设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('对 AI 隐藏'));
    await tester.tap(find.text('锁住'));
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pumpAndSettle();

    expect(saved.last.beatsJson, contains('ai_hidden'));
    expect(saved.last.beatsJson, contains('locked'));

    await tester.tapAt(tester.getCenter(row.first), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.text('确定要删除“AI 写作代理”吗？'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '删除'));
    await tester.pumpAndSettle();

    expect(deleted, [1]);
    expect(find.text('还没有选中生物'), findsOneWidget);
  });

  testWidgets(
      'project overview screen manages items gallery permissions and delete',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1417, 977);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    var nextOutlineId = 1;
    final outlines = <NovelOutline>[];
    final saved = <NovelOutline>[];
    final deleted = <int>[];

    await tester.pumpWidget(_wrap(
      ProjectOverviewScreen(
        novel: _novelForOverview(),
        assistantModels: const ['deepseek-v4-flash'],
        loadChapters: (_) async => const [],
        loadOutlines: (_) async => outlines,
        saveOutline: ({
          required novelId,
          required outlineId,
          required title,
          required status,
          required content,
          required beatsJson,
        }) async {
          final outline = NovelOutline(
            id: outlineId ?? nextOutlineId++,
            novelId: novelId,
            title: title,
            status: status,
            content: content,
            beatsJson: beatsJson,
            updatedAt: DateTime(2026, 7, 1),
          );
          outlines
            ..removeWhere((item) => item.id == outline.id)
            ..add(outline);
          saved.add(outline);
          return outline;
        },
        deleteOutline: (novelId, outlineId) async {
          deleted.add(outlineId);
          outlines.removeWhere((item) => item.id == outlineId);
        },
        onBack: () {},
        onToggleTheme: () {},
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('物品').first);
    await tester.pumpAndSettle();
    expect(find.text('还没有选中物品'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '新建物品'));
    await tester.pumpAndSettle();

    expect(saved.single.title, '未命名物品');
    expect(saved.single.beatsJson, contains('item'));
    expect(find.text('照片集'), findsOneWidget);
    expect(find.text('添加照片'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, '输入物品标题'),
      '星门钥匙',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '如：关键物品、地理、势力'),
      '关键道具',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '在这里整理内容。'),
      '只能在满月时启动星门。',
    );
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(saved.last.title, '星门钥匙');
    expect(saved.last.status, '关键道具');
    expect(saved.last.content, '只能在满月时启动星门。');
    expect(saved.last.beatsJson, contains('item'));
    expect(saved.last.beatsJson, contains('photoPaths'));
    expect(find.text('星门钥匙'), findsWidgets);

    final row = find.ancestor(
      of: find.text('星门钥匙').first,
      matching: find.byType(InkWell),
    );
    await tester.tapAt(tester.getCenter(row.first), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('权限设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('对 AI 隐藏'));
    await tester.tap(find.text('AI 不可编辑'));
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pumpAndSettle();

    expect(saved.last.beatsJson, contains('ai_hidden'));
    expect(saved.last.beatsJson, contains('ai_readonly'));
    expect(saved.last.beatsJson, contains('photoPaths'));

    await tester.tapAt(tester.getCenter(row.first), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.text('确定要删除“星门钥匙”吗？'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '删除'));
    await tester.pumpAndSettle();

    expect(deleted, [1]);
    expect(find.text('还没有选中物品'), findsOneWidget);
  });

  testWidgets('project overview screen manages skills name helper and delete',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1417, 977);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    var nextOutlineId = 1;
    final outlines = <NovelOutline>[];
    final saved = <NovelOutline>[];
    final deleted = <int>[];

    await tester.pumpWidget(_wrap(
      ProjectOverviewScreen(
        novel: _novelForOverview(),
        assistantModels: const ['deepseek-v4-flash'],
        loadChapters: (_) async => const [],
        loadOutlines: (_) async => outlines,
        saveOutline: ({
          required novelId,
          required outlineId,
          required title,
          required status,
          required content,
          required beatsJson,
        }) async {
          final outline = NovelOutline(
            id: outlineId ?? nextOutlineId++,
            novelId: novelId,
            title: title,
            status: status,
            content: content,
            beatsJson: beatsJson,
            updatedAt: DateTime(2026, 7, 1),
          );
          outlines
            ..removeWhere((item) => item.id == outline.id)
            ..add(outline);
          saved.add(outline);
          return outline;
        },
        deleteOutline: (novelId, outlineId) async {
          deleted.add(outlineId);
          outlines.removeWhere((item) => item.id == outlineId);
        },
        onBack: () {},
        onToggleTheme: () {},
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('技能').first);
    await tester.pumpAndSettle();
    expect(find.text('还没有选中技能'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '新建技能'));
    await tester.pumpAndSettle();

    expect(saved.single.title, '未命名技能');
    expect(saved.single.beatsJson, contains('skill'));
    expect(find.byTooltip('起名助手'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, '输入技能标题'),
      'AI 核心算法',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '如：关键物品、地理、势力'),
      '核心技术',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '在这里整理内容。'),
      '基于 Transformer 架构的创意文本生成引擎。',
    );
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(saved.last.title, 'AI 核心算法');
    expect(saved.last.status, '核心技术');
    expect(saved.last.content, '基于 Transformer 架构的创意文本生成引擎。');
    expect(saved.last.beatsJson, contains('skill'));

    await tester.tap(find.byTooltip('起名助手'));
    await tester.pumpAndSettle();
    expect(find.text('技能起名'), findsOneWidget);
    expect(find.text('随机起名'), findsOneWidget);
    expect(find.text('AI 起名'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'AI 起名'));
    await tester.pumpAndSettle();
    expect(find.textContaining('请根据当前技能资料'), findsOneWidget);

    await tester.tap(find.byTooltip('起名助手'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '随机起名'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(saved.last.title.trim(), isNotEmpty);

    final currentTitle = saved.last.title;
    final row = find.ancestor(
      of: find.text(currentTitle).first,
      matching: find.byType(InkWell),
    );
    await tester.tapAt(tester.getCenter(row.first), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('权限设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('对 AI 隐藏'));
    await tester.tap(find.text('AI 不可编辑'));
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pumpAndSettle();

    expect(saved.last.beatsJson, contains('ai_hidden'));
    expect(saved.last.beatsJson, contains('ai_readonly'));

    await tester.tapAt(tester.getCenter(row.first), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.text('确定要删除“$currentTitle”吗？'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '删除'));
    await tester.pumpAndSettle();

    expect(deleted, [1]);
    expect(find.text('还没有选中技能'), findsOneWidget);
  });

  testWidgets('project overview screen manages map worlds and locations',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1417, 977);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    var nextOutlineId = 1;
    final outlines = <NovelOutline>[];
    final saved = <NovelOutline>[];
    final deleted = <int>[];

    await tester.pumpWidget(_wrap(
      ProjectOverviewScreen(
        novel: _novelForOverview(),
        assistantModels: const ['deepseek-v4-flash'],
        loadChapters: (_) async => const [],
        loadOutlines: (_) async => outlines,
        saveOutline: ({
          required novelId,
          required outlineId,
          required title,
          required status,
          required content,
          required beatsJson,
        }) async {
          final outline = NovelOutline(
            id: outlineId ?? nextOutlineId++,
            novelId: novelId,
            title: title,
            status: status,
            content: content,
            beatsJson: beatsJson,
            updatedAt: DateTime(2026, 7, 1),
          );
          outlines
            ..removeWhere((item) => item.id == outline.id)
            ..add(outline);
          saved.add(outline);
          return outline;
        },
        deleteOutline: (novelId, outlineId) async {
          deleted.add(outlineId);
          outlines.removeWhere((item) => item.id == outlineId);
        },
        onBack: () {},
        onToggleTheme: () {},
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('地图').first);
    await tester.pumpAndSettle();
    expect(find.text('暂无地图'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '新建世界'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '输入世界名称，如「艾泽拉斯」「中土世界」'),
      '艾泽拉斯',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '描述这个世界的基本设定、历史背景或独特之处'),
      '魔法与蒸汽并存。',
    );
    await tester.tap(find.widgetWithText(FilledButton, '新建'));
    await tester.pumpAndSettle();

    expect(saved.single.title, '艾泽拉斯');
    expect(saved.single.beatsJson, contains('map_world'));
    expect(find.text('地点库'), findsOneWidget);

    await tester.tap(find.byTooltip('新建地点'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '输入地点名称'), '暴风城');
    await tester.enterText(find.widgetWithText(TextField, '描述'), '联盟主城。');
    await tester.tap(find.widgetWithText(FilledButton, '新建'));
    await tester.pumpAndSettle();

    expect(saved.last.title, '暴风城');
    expect(saved.last.status, '区域');
    expect(saved.last.content, '联盟主城。');
    expect(saved.last.beatsJson, contains('map_location'));
    expect(saved.last.beatsJson, contains('"worldId":1'));
    expect(find.text('暴风城'), findsWidgets);
    expect(find.text('艾泽拉斯'), findsWidgets);

    await tester.tap(find.byTooltip('编辑').first);
    await tester.pumpAndSettle();
    expect(find.text('编辑'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, '输入地点名称'), '铁炉堡');
    await tester.tap(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.widgetWithText(FilledButton, '保存'),
      ),
    );
    await tester.pumpAndSettle();

    expect(saved.last.title, '铁炉堡');
    expect(saved.last.id, 2);

    await tester.tapAt(
      tester.getCenter(find.text('艾泽拉斯').first),
      buttons: kSecondaryButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(deleted, [2, 1]);
    expect(find.text('暂无地图'), findsOneWidget);
  });

  testWidgets('outline workspace opens global timeline with real beats',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1417, 977);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_wrap(
      ProjectOverviewScreen(
        novel: _novelForOverview(),
        assistantModels: const ['deepseek-v4-flash'],
        loadChapters: (_) async => const [],
        loadOutlines: (_) async => [
          NovelOutline(
            id: 1,
            novelId: 1,
            title: '真实大纲',
            status: '待开始',
            content: '',
            beatsJson:
                '[{"status":"待开始","chapterCount":3,"title":"111","content":""},{"status":"待开始","chapterCount":5,"title":"342413","content":""}]',
            updatedAt: DateTime(2026, 6, 30),
          ),
        ],
        onBack: () {},
        onToggleTheme: () {},
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('大纲').first);
    await tester.pumpAndSettle();

    expect(find.text('全局大纲时间轴'), findsOneWidget);
    expect(find.text('大纲 1'), findsOneWidget);
    expect(find.text('时间线节拍 2'), findsOneWidget);
    expect(find.text('章节 8'), findsOneWidget);
    expect(find.text('真实大纲'), findsWidgets);
    expect(find.text('111'), findsOneWidget);
    expect(find.text('342413'), findsOneWidget);
    expect(find.text('记录这条大纲的主内容、目标、冲突、伏线和结局兑现。'), findsNothing);
  });

  testWidgets('project overview screen shows desktop workspace shell',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1417, 977);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    var wentBack = false;
    var nextChapterId = 3;
    String? savedChapterTitle;
    int? deletedChapterId;
    final novel = NovelSummary(
      id: 1,
      title: '重生之我用 AI 写小说',
      summary: '一位现代网络作家意外穿越回 2015 年。',
      status: '',
      category: '穿越',
      workType: 'AI',
      tags: const ['写作', '科幻', 'demo'],
      coverPath: null,
      updatedAt: DateTime(2026, 6, 29),
      wordCount: 0,
    );

    await tester.pumpWidget(_wrap(
      ProjectOverviewScreen(
        novel: novel,
        assistantModels: const ['deepseek-v4-flash', 'kimi-k2.6'],
        loadChapters: (_) async => [
          NovelChapter(
            id: 1,
            novelId: novel.id,
            title: '第1章',
            outline: '开端',
            content: '旧正文',
            wordCount: 3,
            updatedAt: DateTime(2026, 6, 28),
          ),
          NovelChapter(
            id: 2,
            novelId: novel.id,
            title: '第2章',
            outline: '推进',
            content: '新正文',
            wordCount: 3,
            updatedAt: DateTime(2026, 6, 29),
          ),
        ],
        saveChapter: ({
          required novelId,
          required chapterId,
          required title,
          required outline,
          required content,
        }) async {
          savedChapterTitle = title;
          return NovelChapter(
            id: nextChapterId++,
            novelId: novelId,
            title: title,
            outline: outline,
            content: content,
            wordCount: 0,
            updatedAt: DateTime(2026, 6, 30),
          );
        },
        deleteChapter: (novelId, chapterId) async {
          deletedChapterId = chapterId;
        },
        onBack: () {
          wentBack = true;
        },
        onToggleTheme: () {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('重生之我用 AI 写小说'), findsWidgets);
    expect(find.text('继续写 第2章'), findsOneWidget);
    expect(find.text('作品简介'), findsWidgets);
    expect(find.text('写作入口'), findsWidgets);
    expect(find.text('章节大纲'), findsNothing);

    await tester.tap(find.text('章节').first);
    await tester.pumpAndSettle();

    expect(find.text('第2章'), findsWidgets);
    expect(find.text('章节大纲'), findsOneWidget);
    expect(find.text('新正文'), findsOneWidget);
    expect(find.text('已启用自动保存'), findsOneWidget);
    expect(find.text('写作助手'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '历史'));
    await tester.pumpAndSettle();
    expect(find.text('修改历史'), findsOneWidget);
    expect(find.text('自动保存章节'), findsWidgets);
    expect(find.text('章节基础信息'), findsOneWidget);
    expect(find.text('推进'), findsWidgets);
    await tester.tap(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byTooltip('关闭'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('新增章节'));
    await tester.pumpAndSettle();
    expect(savedChapterTitle, '第3章');
    expect(find.text('第3章'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, '1');
    await tester.pumpAndSettle();
    expect(find.text('第1章'), findsOneWidget);

    await tester.tap(find.text('第1章'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(find.text('删除章节'), findsOneWidget);
    await tester.tap(find.text('删除章节'));
    await tester.pumpAndSettle();
    expect(deletedChapterId, 1);

    await tester.tap(find.text('人物'));
    await tester.pump();
    expect(find.text('还没有人物'), findsOneWidget);
    expect(find.text('新建人物'), findsOneWidget);
    expect(find.text('章节大纲'), findsNothing);

    await tester.tap(find.text('章节').first);
    await tester.pump();
    expect(find.text('章节大纲'), findsOneWidget);

    await tester.tap(find.byTooltip('标题'));
    await tester.pumpAndSettle();
    expect(find.text('H1'), findsNWidgets(2));
    expect(find.text('H6'), findsNWidgets(2));
    await tester.tap(find.text('H1').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('返回'));
    expect(wentBack, isTrue);
  });

  testWidgets('foreshadowing workspace creates and saves real entries',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1417, 977);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final foreshadowings = <NovelForeshadowing>[];
    var nextForeshadowingId = 1;
    String? savedTitle;

    await tester.pumpWidget(_wrap(
      ProjectOverviewScreen(
        novel: _novelForOverview(),
        assistantModels: const ['deepseek-v4-flash'],
        loadChapters: (_) async => const [],
        loadForeshadowings: (_) async => foreshadowings,
        saveForeshadowing: ({
          required novelId,
          required foreshadowingId,
          required title,
          required status,
          required setupContent,
          required payoffContent,
        }) async {
          savedTitle = title;
          final saved = NovelForeshadowing(
            id: foreshadowingId ?? nextForeshadowingId++,
            novelId: novelId,
            title: title.trim().isEmpty ? '未命名伏笔' : title.trim(),
            status: status,
            setupContent: setupContent,
            payoffContent: payoffContent,
            updatedAt: DateTime(2026, 7, 1, 20, 33),
          );
          foreshadowings
            ..removeWhere((item) => item.id == saved.id)
            ..insert(0, saved);
          return saved;
        },
        onBack: () {},
        onToggleTheme: () {},
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('伏笔').first);
    await tester.pumpAndSettle();
    expect(find.text('还没有选中伏笔'), findsOneWidget);

    await tester.tap(find.text('新建伏笔'));
    await tester.pumpAndSettle();
    expect(savedTitle, '未命名伏笔');
    expect(find.text('记录伏笔埋设位置、关联章节与回收状态。'), findsOneWidget);
    expect(find.text('已保存'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), '旧相机');
    await tester.pump();
    expect(find.text('未保存'), findsOneWidget);

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(savedTitle, '旧相机');
    expect(find.text('旧相机'), findsWidgets);
  });

  testWidgets('character history dialog shows saved snapshot and rollback',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1417, 977);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_wrap(
      ProjectOverviewScreen(
        novel: _novelForOverview(),
        assistantModels: const ['deepseek-v4-flash'],
        loadChapters: (_) async => const [],
        loadCharacters: (_) async => [
          NovelCharacter(
            id: 1,
            novelId: 1,
            name: '林默',
            role: '主角',
            gender: '男',
            identity: '网文作者',
            age: '26',
            motivation: '写出爆款',
            arc: '逃避到直面',
            avatarPath: null,
            galleryPaths: const [],
            firstChapterId: null,
            biography: '穿越前是扑街作者。',
            currentState: '正在学习使用 AI 写作。',
            skills: const [],
            updatedAt: DateTime(2026, 7, 1, 20, 33),
          ),
        ],
        saveCharacter: ({
          required novelId,
          required characterId,
          required name,
          required role,
          required gender,
          required identity,
          required age,
          required motivation,
          required arc,
          required avatarPath,
          required galleryPaths,
          required firstChapterId,
          required biography,
          required currentState,
          required skills,
        }) async {
          return NovelCharacter(
            id: 1,
            novelId: 1,
            name: name,
            role: role,
            gender: gender,
            identity: identity,
            age: age,
            motivation: motivation,
            arc: arc,
            avatarPath: avatarPath,
            galleryPaths: galleryPaths,
            firstChapterId: firstChapterId,
            biography: biography,
            currentState: currentState,
            skills: skills,
            updatedAt: DateTime(2026, 7, 1, 20, 34),
          );
        },
        onBack: () {},
        onToggleTheme: () {},
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('人物').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '历史'));
    await tester.pumpAndSettle();

    expect(find.text('修改历史'), findsOneWidget);
    expect(find.text('自动保存人物'), findsWidgets);
    expect(find.textContaining('当前保存版本'), findsOneWidget);
    expect(find.text('人物基础信息'), findsOneWidget);
    expect(find.text('穿越前是扑街作者。'), findsWidgets);
    expect(find.text('正在学习使用 AI 写作。'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '回滚'));
    await tester.pumpAndSettle();
    expect(find.text('回滚本次变更？'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '回滚'));
    await tester.pumpAndSettle();
    expect(find.text('修改历史'), findsNothing);
  });

  testWidgets('character skill dialog creates and links world skill',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1417, 977);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    NovelCharacter? savedCharacter;
    String? savedSkillTitle;
    String? savedSkillContent;
    String? savedSkillMetadata;

    await tester.pumpWidget(_wrap(
      ProjectOverviewScreen(
        novel: _novelForOverview(),
        assistantModels: const ['deepseek-v4-flash'],
        loadChapters: (_) async => const [],
        loadOutlines: (_) async => const [],
        saveOutline: ({
          required novelId,
          required outlineId,
          required title,
          required status,
          required content,
          required beatsJson,
        }) async {
          savedSkillTitle = title;
          savedSkillContent = content;
          savedSkillMetadata = beatsJson;
          return NovelOutline(
            id: 9,
            novelId: novelId,
            title: title,
            status: status,
            content: content,
            beatsJson: beatsJson,
            updatedAt: DateTime(2026, 7, 1, 20, 40),
          );
        },
        loadCharacters: (_) async => [
          NovelCharacter(
            id: 1,
            novelId: 1,
            name: '林默',
            role: '主角',
            gender: '男',
            identity: '',
            age: '未知',
            motivation: '',
            arc: '',
            avatarPath: null,
            galleryPaths: const [],
            firstChapterId: null,
            biography: '',
            currentState: '',
            skills: const [],
            updatedAt: DateTime(2026, 7, 1, 20, 39),
          ),
        ],
        saveCharacter: ({
          required novelId,
          required characterId,
          required name,
          required role,
          required gender,
          required identity,
          required age,
          required motivation,
          required arc,
          required avatarPath,
          required galleryPaths,
          required firstChapterId,
          required biography,
          required currentState,
          required skills,
        }) async {
          savedCharacter = NovelCharacter(
            id: characterId ?? 1,
            novelId: novelId,
            name: name,
            role: role,
            gender: gender,
            identity: identity,
            age: age,
            motivation: motivation,
            arc: arc,
            avatarPath: avatarPath,
            galleryPaths: galleryPaths,
            firstChapterId: firstChapterId,
            biography: biography,
            currentState: currentState,
            skills: skills,
            updatedAt: DateTime(2026, 7, 1, 20, 41),
          );
          return savedCharacter!;
        },
        onBack: () {},
        onToggleTheme: () {},
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('人物').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '添加技能'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新建技能'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '请输入技能名称'),
      '影步',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '可选：描述技能的细节、效果或背景'),
      '短距离潜行移动。',
    );
    await tester.tap(find.widgetWithText(FilledButton, '添加'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(savedSkillTitle, '影步');
    expect(savedSkillContent, '短距离潜行移动。');
    expect(savedSkillMetadata, contains('"kind":"skill"'));
    expect(savedCharacter?.skills.single.skillId, 9);
    expect(savedCharacter?.skills.single.name, '影步');
  });

  testWidgets('assistant chat supports send model switch and panel states',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1417, 977);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_wrap(
      ProjectOverviewScreen(
        novel: _novelForOverview(),
        assistantModels: const ['deepseek-v4-flash', 'kimi-k2.6'],
        onBack: () {},
        onToggleTheme: () {},
      ),
    ));

    final modelMenu = tester.widget<PopupMenuButton<String>>(
      find.byWidgetPredicate((widget) => widget is PopupMenuButton<String>),
    );
    expect(modelMenu.color, AppPalette.light.card);
    expect(modelMenu.surfaceTintColor, Colors.transparent);

    await tester.enterText(find.byType(TextField).last, '帮我梳理伏笔');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(find.text('帮我梳理伏笔'), findsOneWidget);
    expect(find.text('执行过程'), findsOneWidget);
    expect(find.text('7 步'), findsNothing);
    expect(find.text('作品概览'), findsOneWidget);
    expect(find.text('AI 可读边界'), findsOneWidget);
    expect(find.text('模型配置'), findsOneWidget);
    expect(find.textContaining('AI 供应商配置'), findsOneWidget);

    await tester.tap(find.text('deepseek-v4-flash').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('kimi-k2.6').last);
    await tester.pumpAndSettle();
    expect(find.text('kimi-k2.6'), findsWidgets);

    await tester.tap(find.byTooltip('新建聊天'));
    await tester.pump();
    expect(find.text('帮我梳理伏笔'), findsNothing);
    expect(find.text('kimi-k2.6'), findsWidgets);

    await tester.tap(find.byTooltip('展开'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close_fullscreen), findsWidgets);

    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.chevron_left), findsWidgets);

    await tester.tap(find.byIcon(Icons.chevron_left).last);
    await tester.pumpAndSettle();
    expect(find.text('写作助手'), findsOneWidget);
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

NovelSummary _novelForOverview() {
  return NovelSummary(
    id: 1,
    title: '重生之我用 AI 写小说',
    summary: '一位现代网络作家意外穿越回 2015 年。',
    status: '',
    category: '穿越',
    workType: 'AI',
    tags: const ['写作', '科幻', 'demo'],
    coverPath: null,
    updatedAt: DateTime(2026, 6, 29),
    wordCount: 0,
  );
}

DashboardActions _actions({
  VoidCallback? openSettings,
  VoidCallback? openBookBreakdown,
  ValueChanged<NovelSummary>? editProject,
  void Function(NovelSummary novel, String status)? updateProjectStatus,
  ValueChanged<NovelSummary>? deleteProject,
}) {
  return DashboardActions(
    createNovel: () {},
    importNovel: () {},
    openProject: (_) {},
    toggleTheme: () {},
    editProject: editProject,
    updateProjectStatus: updateProjectStatus,
    deleteProject: deleteProject,
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
