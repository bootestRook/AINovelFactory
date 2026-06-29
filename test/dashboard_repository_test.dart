import 'dart:io';

import 'package:archive/archive.dart';
import 'package:ai_novel_factory/src/data/dashboard_repository.dart';
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
}

List<int> _epubBytes() {
  final archive = Archive()
    ..addFile(ArchiveFile.string(
      'OPS/chapter1.xhtml',
      '<html><body><h1>第一章</h1><p>EPUB 正文</p></body></html>',
    ));
  return ZipEncoder().encode(archive);
}
