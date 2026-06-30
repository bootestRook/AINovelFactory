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
}

List<int> _epubBytes() {
  final archive = Archive()
    ..addFile(ArchiveFile.string(
      'OPS/chapter1.xhtml',
      '<html><body><h1>第一章</h1><p>EPUB 正文</p></body></html>',
    ));
  return ZipEncoder().encode(archive);
}
