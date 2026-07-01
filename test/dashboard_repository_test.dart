import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:ai_novel_factory/src/book_lab/book_deconstruction_workflow.dart';
import 'package:ai_novel_factory/src/data/dashboard_repository.dart';
import 'package:ai_novel_factory/src/dashboard/dashboard_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('createNovel stores category and work type', () async {
    final dir = await Directory.systemTemp.createTemp('ainovel_test_');
    addTearDown(() => dir.delete(recursive: true));
    final repository = DashboardRepository.local(
      databasePath: '${dir.path}${Platform.pathSeparator}test.sqlite',
    );
    addTearDown(repository.close);

    await repository.createNovel(
      title: '新作品',
      summary: '简介',
      category: '科幻',
      workType: '原创',
      tags: const ['AI', '赛博'],
    );

    final data = await repository.loadDashboard();
    expect(data.novels.single.title, '新作品');
    expect(data.novels.single.summary, '简介');
    expect(data.novels.single.category, '科幻');
    expect(data.novels.single.workType, '原创');
    expect(data.novels.single.tags, ['AI', '赛博']);
  });

  test('importNovelFile supports text markdown html and epub', () async {
    final dir = await Directory.systemTemp.createTemp('ainovel_import_test_');
    addTearDown(() => dir.delete(recursive: true));
    final repository = DashboardRepository.local(
      databasePath: '${dir.path}${Platform.pathSeparator}test.sqlite',
    );
    addTearDown(repository.close);

    final txt = File('${dir.path}${Platform.pathSeparator}plain.txt')
      ..writeAsStringSync('TXT 正文');
    final md = File('${dir.path}${Platform.pathSeparator}markdown.md')
      ..writeAsStringSync('# 标题\n\nMarkdown 正文');
    final html = File('${dir.path}${Platform.pathSeparator}page.html')
      ..writeAsStringSync('<h1>标题</h1><p>HTML &amp; 正文</p>');
    final epub = File('${dir.path}${Platform.pathSeparator}book.epub')
      ..writeAsBytesSync(_epubBytes());

    await repository.importNovelFile(txt.path);
    await repository.importNovelFile(md.path);
    await repository.importNovelFile(html.path);
    await repository.importNovelFile(epub.path);

    final data = await repository.loadDashboard();
    final titles = data.novels.map((novel) => novel.title).toSet();
    expect(titles, containsAll(['plain', 'markdown', 'page', 'book']));
    expect(data.totalWordCount, greaterThan(0));
  });

  test('importNovelFile keeps Chinese file names as titles', () async {
    final dir = await Directory.systemTemp.createTemp('ainovel_cn_import_');
    addTearDown(() => dir.delete(recursive: true));
    final repository = DashboardRepository.local(
      databasePath: '${dir.path}${Platform.pathSeparator}test.sqlite',
    );
    addTearDown(repository.close);

    final file = File('${dir.path}${Platform.pathSeparator}龙族I-火之晨曦.txt')
      ..writeAsStringSync('龙族正文');

    await repository.importNovelFile(file.path);

    final data = await repository.loadDashboard();
    expect(data.novels.single.title, '龙族I-火之晨曦');
  });

  test('importNovelFile splits strong Chinese section headings', () async {
    final dir = await Directory.systemTemp.createTemp('ainovel_split_import_');
    addTearDown(() => dir.delete(recursive: true));
    final repository = DashboardRepository.local(
      databasePath: '${dir.path}${Platform.pathSeparator}test.sqlite',
    );
    addTearDown(repository.close);

    final file = File('${dir.path}${Platform.pathSeparator}龙族I-火之晨曦.txt')
      ..writeAsStringSync('简介\n第一幕 卡塞尔之门\n正文一\n第二幕 神秘学院\n正文二\n尾声\n正文三');

    final novelId = await repository.importNovelFile(file.path);
    final projectId =
        await repository.createBookDeconstructionProject(novelId: novelId);
    await repository.recordBookDeconstructionNodeOutput(
      projectId: projectId,
      node: bookDeconstructionWorkflowNodes.firstWhere(
        (node) => node.id == 'book_chapter_content',
      ),
      content: await repository.buildBookDeconstructionNodeOutput(
        projectId: projectId,
        node: bookDeconstructionWorkflowNodes.firstWhere(
          (node) => node.id == 'book_chapter_content',
        ),
      ),
    );

    final exportPath =
        await repository.exportBookDeconstructionProjectFiles(projectId);
    final index = File(
      '$exportPath${Platform.pathSeparator}source${Platform.pathSeparator}chapters${Platform.pathSeparator}index.json',
    ).readAsStringSync();

    expect(index, contains('第一幕 卡塞尔之门'));
    expect(index, contains('第二幕 神秘学院'));
    expect(index, contains('尾声'));
    expect(
      File('$exportPath${Platform.pathSeparator}report.md').existsSync(),
      isTrue,
    );
  });

  test('book deconstruction export writes one json file per character',
      () async {
    final dir = await Directory.systemTemp.createTemp('ainovel_char_export_');
    addTearDown(() => dir.delete(recursive: true));
    final repository = DashboardRepository.local(
      databasePath: '${dir.path}${Platform.pathSeparator}test.sqlite',
    );
    addTearDown(repository.close);

    final novelId = await repository.importNovelFile(
      (File('${dir.path}${Platform.pathSeparator}source.txt')
            ..writeAsStringSync('路明非遇见诺诺。诺诺提醒路明非。'))
          .path,
    );
    final projectId =
        await repository.createBookDeconstructionProject(novelId: novelId);
    await repository.recordBookDeconstructionNodeOutput(
      projectId: projectId,
      node: bookDeconstructionWorkflowNodes.firstWhere(
        (node) => node.id == 'book_relationships',
      ),
      content: '''
**分析范围**：第一幕
**与父母**：情感缺席

## 人物清单

| 序号 | 人物名称 | 别名/ID | 首次出现 | 类型 |
| :--- | :--- | :--- | :--- | :--- |
| 1 | **路明非** | 无 | 开篇 | 核心主角 |
| 2 | **诺诺** | 无 | 回忆 | 关键人物 |

## 关系网络

| 序号 | 关系 | 证据 |
| :--- | :--- | :--- |
| 1 | 与父母 | 情感缺席 |
''',
    );
    await repository.recordBookDeconstructionNodeOutput(
      projectId: projectId,
      node: bookDeconstructionWorkflowNodes.firstWhere(
        (node) => node.id == 'style_character_voice',
      ),
      content: '''
### 角色声纹
#### 1. 视角
#### 2. 句式节奏
''',
    );
    await repository.updateBookDeconstructionNodeStatus(
      projectId: projectId,
      nodeId: 'book_relationships',
      status: BookDeconstructionNodeStatus.passed,
    );

    final project = await repository.loadCurrentBookDeconstructionProject();
    final exportPath =
        await repository.exportBookDeconstructionProjectFiles(projectId);
    final characterDir = Directory(
      '$exportPath${Platform.pathSeparator}book_$projectId${Platform.pathSeparator}characters${Platform.pathSeparator}people',
    );
    final files = characterDir
        .listSync()
        .whereType<File>()
        .map((file) => file.path.split(Platform.pathSeparator).last)
        .toSet();
    final luMingfei = jsonDecode(File(
      '${characterDir.path}${Platform.pathSeparator}路明非.json',
    ).readAsStringSync()) as Map<String, Object?>;
    final characterIndex = jsonDecode(File(
      '$exportPath${Platform.pathSeparator}book_$projectId${Platform.pathSeparator}characters${Platform.pathSeparator}index.json',
    ).readAsStringSync()) as List<Object?>;

    expect(project?.characterCount, 2);
    expect(files, {'路明非.json', '诺诺.json'});
    expect(characterIndex, hasLength(2));
    expect(files, isNot(contains('分析范围.json')));
    expect(files, isNot(contains('与父母.json')));
    expect(files, isNot(contains('视角.json')));
    expect(files, isNot(contains('句式节奏.json')));
    expect(luMingfei['name'], '路明非');
    expect(luMingfei['mentions'], 2);
    expect(
      File(
        '$exportPath${Platform.pathSeparator}book_$projectId${Platform.pathSeparator}characters${Platform.pathSeparator}book_relationships.json',
      ).existsSync(),
      isTrue,
    );
  });

  test('book deconstruction export reads the explicit character list',
      () async {
    final dir = await Directory.systemTemp.createTemp('ainovel_char_headings_');
    addTearDown(() => dir.delete(recursive: true));
    final repository = DashboardRepository.local(
      databasePath: '${dir.path}${Platform.pathSeparator}test.sqlite',
    );
    addTearDown(repository.close);

    const luMingfei = '路明非';
    const nono = '诺诺';
    final novelId = await repository.importNovelFile(
      (File('${dir.path}${Platform.pathSeparator}source.txt')
            ..writeAsStringSync('$luMingfei遇见$nono。$nono提醒$luMingfei。'))
          .path,
    );
    final projectId =
        await repository.createBookDeconstructionProject(novelId: novelId);
    await repository.recordBookDeconstructionNodeOutput(
      projectId: projectId,
      node: bookDeconstructionWorkflowNodes.firstWhere(
        (node) => node.id == 'book_relationships',
      ),
      content: '''
**分析范围**：第一幕

### 人物清单
- **$luMingfei**: 关键行动者。
- **$nono**: 关键行动者。

### 核心人物档案

#### 1. $luMingfei**   **姓名**: $luMingfei
- 身份：主角

#### 2. $nono
- 身份：关键人物

### 关系网络

#### 3.1 与父母
- 关系类型：家庭
''',
    );

    final exportPath =
        await repository.exportBookDeconstructionProjectFiles(projectId);
    final characterDir = Directory(
      '$exportPath${Platform.pathSeparator}book_$projectId${Platform.pathSeparator}characters${Platform.pathSeparator}people',
    );
    final files = characterDir
        .listSync()
        .whereType<File>()
        .map((file) => file.path.split(Platform.pathSeparator).last)
        .toSet();

    expect(files, {'$luMingfei.json', '$nono.json'});
    expect(files, isNot(contains('分析范围.json')));
    expect(files, isNot(contains('与父母.json')));
  });

  test(
      'book deconstruction character count includes text candidates when '
      'relationship artifact is incomplete', () async {
    final dir = await Directory.systemTemp.createTemp('ainovel_char_union_');
    addTearDown(() => dir.delete(recursive: true));
    final repository = DashboardRepository.local(
      databasePath: '${dir.path}${Platform.pathSeparator}test.sqlite',
    );
    addTearDown(repository.close);

    final novelId = await repository.importNovelFile(
      (File('${dir.path}${Platform.pathSeparator}source.txt')
            ..writeAsStringSync('路明非遇见诺诺。楚子航看着路明非，诺诺提醒楚子航。'))
          .path,
    );
    final projectId =
        await repository.createBookDeconstructionProject(novelId: novelId);
    await repository.recordBookDeconstructionNodeOutput(
      projectId: projectId,
      node: bookDeconstructionWorkflowNodes.firstWhere(
        (node) => node.id == 'book_relationships',
      ),
      content: '''
## 人物清单

| 序号 | 人物名称 | 别名/ID | 首次出现 | 类型 |
| :--- | :--- | :--- | :--- | :--- |
| 1 | **路明非** | 无 | 开篇 | 核心主角 |
''',
    );
    await repository.updateBookDeconstructionNodeStatus(
      projectId: projectId,
      nodeId: 'book_relationships',
      status: BookDeconstructionNodeStatus.passed,
    );

    final project = await repository.loadCurrentBookDeconstructionProject();
    final exportPath =
        await repository.exportBookDeconstructionProjectFiles(projectId);
    final characterDir = Directory(
      '$exportPath${Platform.pathSeparator}book_$projectId${Platform.pathSeparator}characters${Platform.pathSeparator}people',
    );
    final files = characterDir
        .listSync()
        .whereType<File>()
        .map((file) => file.path.split(Platform.pathSeparator).last)
        .toSet();

    expect(project?.characterCount, 3);
    expect(files, containsAll({'路明非.json', '诺诺.json', '楚子航.json'}));
  });

  test('book deconstruction export uses explicit character index', () async {
    final dir = await Directory.systemTemp.createTemp('ainovel_char_index_');
    addTearDown(() => dir.delete(recursive: true));
    final repository = DashboardRepository.local(
      databasePath: '${dir.path}${Platform.pathSeparator}test.sqlite',
    );
    addTearDown(repository.close);

    final novelId = await repository.importNovelFile(
      (File('${dir.path}${Platform.pathSeparator}source.txt')
            ..writeAsStringSync('路明非遇见陈墨瞳。陈雯雯、芬格尔和楚子航也出现。'))
          .path,
    );
    final projectId =
        await repository.createBookDeconstructionProject(novelId: novelId);
    await repository.recordBookDeconstructionNodeOutput(
      projectId: projectId,
      node: bookDeconstructionWorkflowNodes.firstWhere(
        (node) => node.id == 'book_relationships',
      ),
      content: '''
#### 人物索引
*   **路明非**: 主角。
*   **陈墨瞳 (诺诺)**: 引路人。
*   **陈雯雯**: 暗恋对象。
*   **芬格尔·冯·弗林斯**: 室友。
*   **楚子航**: 学长。
*   **叔叔 & 婶婶**: 监护人。

#### 核心人物档案
### 1. 路明非
### 2. 陈墨瞳 (诺诺)
''',
    );

    final exportPath =
        await repository.exportBookDeconstructionProjectFiles(projectId);
    final characterDir = Directory(
      '$exportPath${Platform.pathSeparator}book_$projectId${Platform.pathSeparator}characters${Platform.pathSeparator}people',
    );
    final files = characterDir
        .listSync()
        .whereType<File>()
        .map((file) => file.path.split(Platform.pathSeparator).last)
        .toSet();

    expect(files, {
      '路明非.json',
      '陈墨瞳.json',
      '陈雯雯.json',
      '芬格尔·冯·弗林斯.json',
      '楚子航.json',
      '叔叔.json',
      '婶婶.json',
    });
  });

  test(
      'book deconstruction imports stay out of writing library and delete with project',
      () async {
    final dir = await Directory.systemTemp.createTemp('ainovel_book_source_');
    addTearDown(() => dir.delete(recursive: true));
    final repository = DashboardRepository.local(
      databasePath: '${dir.path}${Platform.pathSeparator}test.sqlite',
    );
    addTearDown(repository.close);

    final writingNovelId = await repository.importNovelFile(
      (File('${dir.path}${Platform.pathSeparator}writing.txt')
            ..writeAsStringSync('正式小说正文'))
          .path,
    );
    final sourceNovelId = await repository.importBookDeconstructionSourceFile(
      (File('${dir.path}${Platform.pathSeparator}book-source.txt')
            ..writeAsStringSync('拆书源正文'))
          .path,
    );
    final projectId = await repository.createBookDeconstructionProject(
        novelId: sourceNovelId);

    var dashboard = await repository.loadDashboard();
    expect(dashboard.novels.map((novel) => novel.id), [writingNovelId]);
    expect(dashboard.totalWordCount, countWritingUnits('正式小说正文'));
    expect(dashboard.recentWriting?.novelId, writingNovelId);

    await repository.deleteBookDeconstructionProject(projectId);
    dashboard = await repository.loadDashboard();

    expect(dashboard.novels.map((novel) => novel.id), [writingNovelId]);
    expect(await repository.loadBookDeconstructionProjects(), isEmpty);
  });

  test('deleting a book deconstruction project keeps assigned writing novel',
      () async {
    final dir = await Directory.systemTemp.createTemp('ainovel_keep_writing_');
    addTearDown(() => dir.delete(recursive: true));
    final repository = DashboardRepository.local(
      databasePath: '${dir.path}${Platform.pathSeparator}test.sqlite',
    );
    addTearDown(repository.close);

    final novelId = await repository.importNovelFile(
      (File('${dir.path}${Platform.pathSeparator}writing.txt')
            ..writeAsStringSync('正式小说正文'))
          .path,
    );
    final projectId =
        await repository.createBookDeconstructionProject(novelId: novelId);

    await repository.deleteBookDeconstructionProject(projectId);

    final dashboard = await repository.loadDashboard();
    expect(dashboard.novels.single.id, novelId);
  });

  test(
      'backupToDirectory copies and restoreFromBackup restores sqlite database',
      () async {
    final dir = await Directory.systemTemp.createTemp('ainovel_backup_test_');
    addTearDown(() => dir.delete(recursive: true));
    final backupDir = Directory('${dir.path}${Platform.pathSeparator}backups')
      ..createSync();
    final repository = DashboardRepository.local(
      databasePath: '${dir.path}${Platform.pathSeparator}test.sqlite',
    );
    addTearDown(repository.close);

    await repository.createNovel(title: 'Before backup');
    final backupPath = await repository.backupToDirectory(
      backupDir.path,
      now: DateTime(2026, 6, 30, 12, 30, 45),
    );

    expect(File(backupPath).existsSync(), isTrue);
    expect(backupPath, endsWith('ai_novel_factory_20260630_123045.sqlite'));

    await repository.createNovel(title: 'After backup');
    var data = await repository.loadDashboard();
    expect(data.novels.map((novel) => novel.title), contains('After backup'));

    await repository.restoreFromBackup(backupPath);
    data = await repository.loadDashboard();

    expect(data.novels.map((novel) => novel.title), ['Before backup']);
  });

  test('book deconstruction project persists run state and resumes', () async {
    final dir = await Directory.systemTemp.createTemp('ainovel_book_lab_test_');
    addTearDown(() => dir.delete(recursive: true));
    final repository = DashboardRepository.local(
      databasePath: '${dir.path}${Platform.pathSeparator}test.sqlite',
    );
    addTearDown(repository.close);

    final novelId = await repository.createNovel(title: 'Book Lab Source');
    final projectId =
        await repository.createBookDeconstructionProject(novelId: novelId);
    await repository.updateBookDeconstructionNodeStatus(
      projectId: projectId,
      nodeId: 'book_text_cleaning',
      status: BookDeconstructionNodeStatus.running,
    );
    await repository.recordBookDeconstructionNodeOutput(
      projectId: projectId,
      node: bookDeconstructionWorkflowNodes.firstWhere(
        (node) => node.id == 'book_text_cleaning',
      ),
      content: '{"ok":true}',
    );
    await repository.updateBookDeconstructionNodeStatus(
      projectId: projectId,
      nodeId: 'book_text_cleaning',
      status: BookDeconstructionNodeStatus.passed,
    );
    await repository.setBookDeconstructionProjectStatus(
      projectId: projectId,
      status: BookDeconstructionProjectStatus.running,
      currentNodeId: 'book_chapter_content',
    );

    final projects = await repository.loadBookDeconstructionProjects();

    expect(projects.single.status, BookDeconstructionProjectStatus.paused);
    expect(projects.single.nodeStatuses['book_text_cleaning'],
        BookDeconstructionNodeStatus.passed);
    expect(projects.single.progress, greaterThan(0));
  });

  test('book deconstruction project shows imported novel after assignment',
      () async {
    final dir = await Directory.systemTemp.createTemp('ainovel_book_import_');
    addTearDown(() => dir.delete(recursive: true));
    final repository = DashboardRepository.local(
      databasePath: '${dir.path}${Platform.pathSeparator}test.sqlite',
    );
    addTearDown(repository.close);

    final projectId = await repository.createBookDeconstructionProject();
    await repository.updateBookDeconstructionNodeStatus(
      projectId: projectId,
      nodeId: 'book_text_cleaning',
      status: BookDeconstructionNodeStatus.passed,
    );
    final file = File('${dir.path}${Platform.pathSeparator}source.txt')
      ..writeAsStringSync('chapter text');
    final novelId = await repository.importNovelFile(file.path);

    await repository.assignNovelToBookDeconstructionProject(
      projectId: projectId,
      novelId: novelId,
    );

    final project = await repository.loadCurrentBookDeconstructionProject();

    expect(project?.id, projectId);
    expect(project?.novelId, novelId);
    expect(project?.novelTitle, 'source');
    expect(project?.title, 'source 拆解');
    expect(project?.status, BookDeconstructionProjectStatus.draft);
    expect(project?.nodeStatuses, isEmpty);
    expect(project?.progress, 0);
  });

  test('book deconstruction project delete removes the project', () async {
    final dir = await Directory.systemTemp.createTemp('ainovel_book_delete_');
    addTearDown(() => dir.delete(recursive: true));
    final repository = DashboardRepository.local(
      databasePath: '${dir.path}${Platform.pathSeparator}test.sqlite',
    );
    addTearDown(repository.close);

    final projectId = await repository.createBookDeconstructionProject();
    await repository.updateBookDeconstructionNodeStatus(
      projectId: projectId,
      nodeId: 'book_text_cleaning',
      status: BookDeconstructionNodeStatus.passed,
    );
    await repository.recordBookDeconstructionNodeOutput(
      projectId: projectId,
      node: bookDeconstructionWorkflowNodes.first,
      content: '{"deleted":true}',
    );

    await repository.deleteBookDeconstructionProject(projectId);

    expect(await repository.loadBookDeconstructionProjects(), isEmpty);
  });

  test('book deconstruction prompt keeps chapter text beyond 900 characters',
      () async {
    final dir = await Directory.systemTemp.createTemp('ainovel_prompt_cap_');
    addTearDown(() => dir.delete(recursive: true));
    final repository = DashboardRepository.local(
      databasePath: '${dir.path}${Platform.pathSeparator}test.sqlite',
    );
    addTearDown(repository.close);

    final longChapter = 'A' * 1200;
    final novelId = await repository.importNovelFile(
      (File('${dir.path}${Platform.pathSeparator}source.txt')
            ..writeAsStringSync(longChapter))
          .path,
    );
    final projectId =
        await repository.createBookDeconstructionProject(novelId: novelId);
    final prompt = await repository.buildBookDeconstructionAgentPrompt(
      projectId: projectId,
      node: bookDeconstructionWorkflowNodes.firstWhere(
        (node) => node.id == 'book_chapter_content',
      ),
    );

    expect(prompt, contains('A' * 1200));
    expect(prompt, contains('# book_chapter_content.skill'));
    expect(prompt, contains('## 必须执行的 Agent Skill'));
    expect(prompt, contains('## 拆书 Agent 共享硬契约'));
    expect(prompt, contains('列表类结果不得只展开前几项'));
    expect(prompt, contains('不要声称生成了某个 JSON、文件或 Skill'));
  });

  test('every callable book deconstruction agent has a skill file', () {
    for (final agentId in bookDeconstructionAgentIds) {
      final file = File(
        '${Directory.current.path}${Platform.pathSeparator}book_deconstruction_skills${Platform.pathSeparator}$agentId.skill${Platform.pathSeparator}SKILL.md',
      );
      expect(file.existsSync(), isTrue, reason: agentId);
      expect(file.readAsStringSync().trim(), isNotEmpty, reason: agentId);
    }
  });

  test('relationship agent loads its dedicated skill file', () async {
    final dir = await Directory.systemTemp.createTemp('ainovel_rel_skill_');
    addTearDown(() => dir.delete(recursive: true));
    final repository = DashboardRepository.local(
      databasePath: '${dir.path}${Platform.pathSeparator}test.sqlite',
    );
    addTearDown(repository.close);

    final novelId = await repository.importNovelFile(
      (File('${dir.path}${Platform.pathSeparator}source.txt')
            ..writeAsStringSync('路明非遇见诺诺。'))
          .path,
    );
    final projectId =
        await repository.createBookDeconstructionProject(novelId: novelId);
    final prompt = await repository.buildBookDeconstructionAgentPrompt(
      projectId: projectId,
      node: bookDeconstructionWorkflowNodes.firstWhere(
        (node) => node.id == 'book_relationships',
      ),
    );

    expect(prompt, contains('# book_relationships.skill'));
    expect(prompt, contains('## 必须执行的 Agent Skill'));
    expect(prompt, contains('不得只输出主角或首个出现的人物'));
    expect(prompt, contains('每个人物一行'));
  });

  test('skill compile node exports a real writing skill package', () async {
    final dir = await Directory.systemTemp.createTemp('ainovel_skill_package_');
    addTearDown(() => dir.delete(recursive: true));
    final repository = DashboardRepository.local(
      databasePath: '${dir.path}${Platform.pathSeparator}test.sqlite',
    );
    addTearDown(repository.close);

    final novelId = await repository.importBookDeconstructionSourceFile(
      (File('${dir.path}${Platform.pathSeparator}source.txt')
            ..writeAsStringSync('第一章\\n主角遇到危机。'))
          .path,
    );
    final projectId =
        await repository.createBookDeconstructionProject(novelId: novelId);
    final node = bookDeconstructionWorkflowNodes.firstWhere(
      (node) => node.id == 'book_skill_compile',
    );
    await repository.recordBookDeconstructionNodeOutput(
      projectId: projectId,
      node: node,
      content: '''
# Skill 编译报告

### `### SKILL.md`
```markdown
你是本书提取出的实验写作 Skill。
```

### `### skill_manifest.json`
```json
{"entry":"SKILL.md","files":["README.md","writing_constraints.json"]}
```

### `### README.md`
```markdown
先压迫再反击。
```

### `### writing_constraints.json`
```json
{"rules":["不要复制原书专名"]}
```

---
''',
    );

    final exportPath =
        await repository.exportBookDeconstructionProjectFiles(projectId);
    final skillDir = Directory(
      '$exportPath${Platform.pathSeparator}compiled_skill${Platform.pathSeparator}book_001.skill',
    );
    final skill = File('${skillDir.path}${Platform.pathSeparator}SKILL.md');
    final manifest = File(
      '${skillDir.path}${Platform.pathSeparator}skill_manifest.json',
    );
    final constraints = File(
      '${skillDir.path}${Platform.pathSeparator}writing_constraints.json',
    );

    expect(skill.existsSync(), isTrue);
    expect(manifest.existsSync(), isTrue);
    expect(constraints.existsSync(), isTrue);
    expect(
      skill.readAsStringSync(),
      contains('实验写作 Skill'),
    );
    expect(
      File('${skillDir.path}${Platform.pathSeparator}README.md')
          .readAsStringSync(),
      contains('先压迫再反击'),
    );
    expect(
      jsonDecode(manifest.readAsStringSync())['entry'],
      'SKILL.md',
    );
    expect(
      (jsonDecode(constraints.readAsStringSync())
          as Map<String, Object?>)['rules'],
      ['不要复制原书专名'],
    );
  });

  test('skill compile export does not fabricate missing file sections',
      () async {
    final dir = await Directory.systemTemp.createTemp('ainovel_skill_missing_');
    addTearDown(() => dir.delete(recursive: true));
    final repository = DashboardRepository.local(
      databasePath: '${dir.path}${Platform.pathSeparator}test.sqlite',
    );
    addTearDown(repository.close);

    final novelId = await repository.importBookDeconstructionSourceFile(
      (File('${dir.path}${Platform.pathSeparator}source.txt')
            ..writeAsStringSync('第一章\n主角遇到危机。'))
          .path,
    );
    final projectId =
        await repository.createBookDeconstructionProject(novelId: novelId);
    final node = bookDeconstructionWorkflowNodes.firstWhere(
      (node) => node.id == 'book_skill_compile',
    );
    await repository.recordBookDeconstructionNodeOutput(
      projectId: projectId,
      node: node,
      content: '这里只是普通总结，不是文件内容。',
    );

    final exportPath =
        await repository.exportBookDeconstructionProjectFiles(projectId);
    final fakeFile = File(
      '$exportPath${Platform.pathSeparator}compiled_skill${Platform.pathSeparator}book_001.skill${Platform.pathSeparator}style_guide.md',
    );

    expect(fakeFile.existsSync(), isFalse);
  });

  test('ai usage records persist real token usage only', () async {
    final dir = await Directory.systemTemp.createTemp('ainovel_usage_');
    addTearDown(() => dir.delete(recursive: true));
    final repository = DashboardRepository.local(
      databasePath: '${dir.path}${Platform.pathSeparator}test.sqlite',
    );
    addTearDown(repository.close);

    await repository.recordAiUsage(
      providerId: 'provider-1',
      providerName: 'Provider',
      model: 'model-a',
      inputTokens: 0,
      outputTokens: 0,
      cacheReadTokens: 0,
      cacheWriteTokens: 0,
      totalTokens: 0,
    );
    await repository.recordAiUsage(
      providerId: 'provider-1',
      providerName: 'Provider',
      model: 'model-a',
      inputTokens: 100,
      outputTokens: 40,
      cacheReadTokens: 7,
      cacheWriteTokens: 3,
      totalTokens: 143,
    );

    final records = await repository.loadAiUsageRecords();

    expect(records, hasLength(1));
    expect(records.single.inputTokens, 100);
    expect(records.single.outputTokens, 40);
    expect(records.single.totalTokens, 143);
  });

  test('book deconstruction project reset clears old run outputs', () async {
    final dir = await Directory.systemTemp.createTemp('ainovel_book_reset_');
    addTearDown(() => dir.delete(recursive: true));
    final repository = DashboardRepository.local(
      databasePath: '${dir.path}${Platform.pathSeparator}test.sqlite',
    );
    addTearDown(repository.close);

    final novelId = await repository.importNovelFile(
      (File('${dir.path}${Platform.pathSeparator}source.txt')
            ..writeAsStringSync('第一章 开始\n正文'))
          .path,
    );
    final projectId =
        await repository.createBookDeconstructionProject(novelId: novelId);
    await repository.recordBookDeconstructionNodeOutput(
      projectId: projectId,
      node: bookDeconstructionWorkflowNodes.first,
      content: '{"old":true}',
    );
    await repository.updateBookDeconstructionNodeStatus(
      projectId: projectId,
      nodeId: bookDeconstructionWorkflowNodes.first.id,
      status: BookDeconstructionNodeStatus.passed,
    );
    await repository.appendBookExperimentalWritingMessage(
      projectId: projectId,
      role: 'assistant',
      content: '旧实验记录',
    );
    await repository.setBookDeconstructionProjectStatus(
      projectId: projectId,
      status: BookDeconstructionProjectStatus.completed,
    );

    await repository.resetBookDeconstructionProject(projectId);

    final project = (await repository.loadBookDeconstructionProjects()).single;
    expect(project.status, BookDeconstructionProjectStatus.draft);
    expect(project.nodeStatuses, isEmpty);
    expect(project.progress, 0);
    expect(project.characterCount, 0);
    expect(await repository.loadBookExperimentalWritingMessages(projectId),
        isEmpty);
  });

  test('experimental writing chat is project scoped and exports final draft',
      () async {
    final dir = await Directory.systemTemp.createTemp('ainovel_book_exp_');
    addTearDown(() => dir.delete(recursive: true));
    final repository = DashboardRepository.local(
      databasePath: '${dir.path}${Platform.pathSeparator}test.sqlite',
    );
    addTearDown(repository.close);

    final novelId = await repository.importBookDeconstructionSourceFile(
      (File('${dir.path}${Platform.pathSeparator}source.txt')
            ..writeAsStringSync('第一章 开始\n原书秘密正文不应出现'))
          .path,
    );
    final projectId =
        await repository.createBookDeconstructionProject(novelId: novelId);
    final skillNode = bookDeconstructionWorkflowNodes.firstWhere(
      (node) => node.id == 'book_skill_compile',
    );
    await repository.recordBookDeconstructionNodeOutput(
      projectId: projectId,
      node: skillNode,
      content: '''
### SKILL.md
实验写作入口：先执行文风指纹，再写草稿。

### style_guide.md
规则2：长句铺陈具体动作后，用短句自我消解。

### character_voice_patterns.json
```json
{"self_filter":"每段至少有一个主角视角的判断，不写上帝视角"}
```

### writing_constraints.json
```json
{"rules":["禁止复刻原书专名","草稿正文禁止破折号"]}
```
''',
    );

    await repository.appendBookExperimentalWritingMessage(
      projectId: projectId,
      role: 'user',
      content: '写一个 800 字都市奇幻开场',
    );
    await repository.appendBookExperimentalWritingMessage(
      projectId: projectId,
      role: 'assistant',
      content: '实验草稿',
    );

    final messages =
        await repository.loadBookExperimentalWritingMessages(projectId);
    expect(messages.map((message) => message.role), ['user', 'assistant']);

    final prompt = await repository.buildExperimentalWritingAgentPrompt(
      projectId: projectId,
      userMessage: '继续扩写',
    );
    expect(prompt, contains('Skill 命中表'));
    expect(prompt, contains('处理过程摘要'));
    expect(prompt, contains('实验性写作 Agent 纲领'));
    expect(prompt, contains('humanizer-zh'));
    expect(prompt, contains('全文禁止出现 `——`'));
    expect(prompt, contains('全文禁止出现 `—`'));
    expect(prompt, contains('禁止使用补充式解释的语句'));
    expect(prompt, contains('草稿正文禁止使用破折号'));
    expect(prompt, contains('规则2：长句铺陈具体动作后，用短句自我消解'));
    expect(prompt, contains('每段至少有一个主角视角的判断'));
    expect(prompt, isNot(contains('原书秘密正文不应出现')));

    await repository.saveBookExperimentalWritingFinalDraft(
      projectId: projectId,
      content: '最终实验文稿',
    );
    final exportPath =
        await repository.exportBookDeconstructionProjectFiles(projectId);
    final draft = File(
      '$exportPath${Platform.pathSeparator}experiments${Platform.pathSeparator}final_draft.md',
    );

    expect(draft.existsSync(), isTrue);
    expect(draft.readAsStringSync(), '最终实验文稿');
  });
}

List<int> _epubBytes() {
  final archive = Archive()
    ..addFile(ArchiveFile.string(
      'OPS/chapter1.xhtml',
      '<html><body><h1>第一章</h1><p>EPUB 正文</p></body></html>',
    ));
  return ZipEncoder().encode(archive);
}
