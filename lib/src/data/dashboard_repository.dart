import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../book_lab/book_deconstruction_workflow.dart';
import '../dashboard/dashboard_models.dart';

const _bookChapterPromptMaxCharacters = 30000;

class DashboardRepository {
  DashboardRepository({
    required DatabaseFactory databaseFactory,
    required String databasePath,
  })  : _databaseFactory = databaseFactory,
        _databasePath = databasePath;

  factory DashboardRepository.local({String? databasePath}) {
    sqfliteFfiInit();
    return DashboardRepository(
      databaseFactory: databaseFactoryFfi,
      databasePath: databasePath ?? _defaultDatabasePath(),
    );
  }

  final DatabaseFactory _databaseFactory;
  final String _databasePath;
  Database? _database;

  Future<DashboardData> loadDashboard({
    DateTime? today,
    String searchQuery = '',
  }) async {
    final now = today ?? DateTime.now();
    final db = await _open();
    final novels = await _loadNovels(db);
    final totalWordCount = await _loadTotalWordCount(db);
    final writingGoal = await _loadWritingGoal(db, now);
    final recentWriting = await _loadRecentWriting(db);

    return DashboardData(
      novels: novels,
      totalWordCount: totalWordCount,
      today: now,
      writingGoal: writingGoal,
      recentWriting: recentWriting,
      searchQuery: searchQuery,
    );
  }

  Future<int> createNovel({
    required String title,
    String summary = '',
    String category = '',
    String workType = '',
    List<String> tags = const [],
    String? coverPath,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Title cannot be empty.');
    }

    final db = await _open();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return db.transaction((txn) async {
      final novelId = await txn.insert('novels', {
        'title': trimmedTitle,
        'summary': summary.trim(),
        'status': '',
        'category': category.trim(),
        'work_type': workType.trim(),
        'cover_path':
            coverPath?.trim().isEmpty ?? true ? null : coverPath!.trim(),
        'updated_at': timestamp,
      });

      await _insertTags(txn, novelId, tags);
      return novelId;
    });
  }

  Future<int> importTextNovel(String filePath) async {
    return importNovelFile(filePath);
  }

  Future<int> importNovelFile(String filePath) async {
    final file = File(filePath.trim());
    if (!await file.exists()) {
      throw ArgumentError.value(filePath, 'filePath', 'File does not exist.');
    }

    final content = await _readImportContent(file);
    final title = _titleFromFile(file);
    final db = await _open();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return db.transaction((txn) async {
      final novelId = await txn.insert('novels', {
        'title': title,
        'summary': '',
        'status': '',
        'category': '',
        'work_type': '',
        'cover_path': null,
        'updated_at': timestamp,
      });

      final chapters = _splitImportedChapters(content, title);
      int? firstChapterId;
      for (final chapter in chapters) {
        final chapterId = await txn.insert('chapters', {
          'novel_id': novelId,
          'title': chapter.title,
          'content': chapter.content,
          'word_count': countWritingUnits(chapter.content),
          'updated_at': timestamp,
        });
        firstChapterId ??= chapterId;
      }

      await txn.insert(
        'recent_writing',
        {
          'id': 1,
          'novel_id': novelId,
          'chapter_id': firstChapterId,
          'updated_at': timestamp,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return novelId;
    });
  }

  Future<List<BookDeconstructionProject>> loadBookDeconstructionProjects({
    bool recoverInterrupted = true,
  }) async {
    final db = await _open();
    if (recoverInterrupted) {
      await _recoverInterruptedBookDeconstructionRuns(db);
    }
    return _loadBookDeconstructionProjects(db);
  }

  Future<BookDeconstructionProject?>
      loadCurrentBookDeconstructionProject() async {
    final projects = await loadBookDeconstructionProjects();
    return projects.isEmpty ? null : projects.first;
  }

  Future<int> createBookDeconstructionProject({int? novelId}) async {
    final db = await _open();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    String? novelTitle;
    if (novelId != null) {
      novelTitle = await _loadNovelTitle(db, novelId);
    }

    return db.insert('book_deconstruction_projects', {
      'title': novelTitle == null ? '未命名拆书项目' : '$novelTitle 拆解',
      'novel_id': novelId,
      'status': BookDeconstructionProjectStatus.draft.name,
      'current_node_id': null,
      'progress': 0.0,
      'chapter_count': 0,
      'character_count': 0,
      'foreshadowing_count': 0,
      'style_asset_count': 0,
      'created_at': timestamp,
      'updated_at': timestamp,
    });
  }

  Future<void> assignNovelToBookDeconstructionProject({
    required int projectId,
    required int novelId,
  }) async {
    final db = await _open();
    final novelTitle = await _loadNovelTitle(db, novelId);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.delete(
        'book_deconstruction_nodes',
        where: 'project_id = ?',
        whereArgs: [projectId],
      );
      await txn.delete(
        'book_deconstruction_artifacts',
        where: 'project_id = ?',
        whereArgs: [projectId],
      );
      await txn.update(
        'book_deconstruction_projects',
        {
          'title': novelTitle == null ? '未命名拆书项目' : '$novelTitle 拆解',
          'novel_id': novelId,
          'status': BookDeconstructionProjectStatus.draft.name,
          'current_node_id': null,
          'progress': 0.0,
          'chapter_count': 0,
          'character_count': 0,
          'foreshadowing_count': 0,
          'style_asset_count': 0,
          'updated_at': timestamp,
        },
        where: 'id = ?',
        whereArgs: [projectId],
      );
    });
  }

  Future<void> deleteBookDeconstructionProject(int projectId) async {
    final db = await _open();
    await db.transaction((txn) async {
      await txn.delete(
        'book_deconstruction_nodes',
        where: 'project_id = ?',
        whereArgs: [projectId],
      );
      await txn.delete(
        'book_deconstruction_artifacts',
        where: 'project_id = ?',
        whereArgs: [projectId],
      );
      await txn.delete(
        'book_deconstruction_projects',
        where: 'id = ?',
        whereArgs: [projectId],
      );
    });
  }

  Future<void> resetBookDeconstructionProject(int projectId) async {
    final db = await _open();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.delete(
        'book_deconstruction_nodes',
        where: 'project_id = ?',
        whereArgs: [projectId],
      );
      await txn.delete(
        'book_deconstruction_artifacts',
        where: 'project_id = ?',
        whereArgs: [projectId],
      );
      await txn.update(
        'book_deconstruction_projects',
        {
          'status': BookDeconstructionProjectStatus.draft.name,
          'current_node_id': null,
          'progress': 0.0,
          'character_count': 0,
          'foreshadowing_count': 0,
          'style_asset_count': 0,
          'updated_at': timestamp,
        },
        where: 'id = ?',
        whereArgs: [projectId],
      );
    });
    await _refreshBookDeconstructionStats(db, projectId);
  }

  Future<void> setBookDeconstructionProjectStatus({
    required int projectId,
    required BookDeconstructionProjectStatus status,
    String? currentNodeId,
  }) async {
    final db = await _open();
    await db.update(
      'book_deconstruction_projects',
      {
        'status': status.name,
        'current_node_id': currentNodeId,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [projectId],
    );
  }

  Future<void> updateBookDeconstructionNodeStatus({
    required int projectId,
    required String nodeId,
    required BookDeconstructionNodeStatus status,
    String message = '',
  }) async {
    final db = await _open();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'book_deconstruction_nodes',
      {
        'project_id': projectId,
        'node_id': nodeId,
        'status': status.name,
        'message': message,
        'updated_at': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.update(
      'book_deconstruction_projects',
      {
        'current_node_id': nodeId,
        'updated_at': timestamp,
      },
      where: 'id = ?',
      whereArgs: [projectId],
    );
    await _refreshBookDeconstructionStats(db, projectId);
  }

  Future<void> recordBookDeconstructionNodeOutput({
    required int projectId,
    required BookDeconstructionNode node,
    required String content,
  }) async {
    final db = await _open();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = _artifactPathForNode(projectId, node);
    await db.insert(
      'book_deconstruction_artifacts',
      {
        'project_id': projectId,
        'node_id': node.id,
        'artifact_path': path,
        'artifact_kind': _artifactKindForNode(node),
        'content': content,
        'updated_at': timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String> buildBookDeconstructionNodeOutput({
    required int projectId,
    required BookDeconstructionNode node,
  }) async {
    final db = await _open();
    final data = await _loadBookExportData(db, projectId);
    final payload = <String, Object?>{
      'project_id': projectId,
      'node_id': node.id,
      'node_name': node.name,
      'generated_at': DateTime.now().toIso8601String(),
      'book_title': data.novelTitle,
      'chapter_count': data.chapters.length,
      'total_words': data.totalWords,
    };

    switch (node.id) {
      case 'book_text_cleaning':
      case 'gate_1_text_cleaned':
        payload['chapters'] = [
          for (final chapter in data.chapters)
            {
              'title': chapter.title,
              'word_count': chapter.wordCount,
            },
        ];
      case 'book_chapter_content':
      case 'gate_2_chapter_content':
        payload['chapters'] = [
          for (final chapter in data.chapters)
            {
              'title': chapter.title,
              'word_count': chapter.wordCount,
              'excerpt': _excerpt(chapter.content),
            },
        ];
      case 'style_chapter_statistics':
        payload.addAll(_chapterStatistics(data.chapters));
      case 'book_relationships':
      case 'style_character_voice':
        payload['character_candidates'] = _characterCandidates(data.fullText);
      case 'foreshadowing_initial':
      case 'foreshadowing_review':
        payload['foreshadowing_markers'] = _markerLines(data.fullText, [
          '秘密',
          '神秘',
          '谜',
          '龙',
          '命运',
        ]);
      case 'style_global':
      case 'style_scene_voice':
        payload['style_notes'] = _styleNotes(data.fullText);
      default:
        payload['status'] = 'passed';
    }

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<String> buildBookDeconstructionAgentPrompt({
    required int projectId,
    required BookDeconstructionNode node,
  }) async {
    final db = await _open();
    final data = await _loadBookExportData(db, projectId);
    final artifacts = data.artifacts
        .where((artifact) =>
            artifact.path != _artifactPathForNode(projectId, node))
        .take(8)
        .toList();

    final buffer = StringBuffer()
      ..writeln('你是 AI 小说工坊的拆书 Agent。')
      ..writeln('当前节点：${node.name} (${node.id})')
      ..writeln('小说：${data.novelTitle}')
      ..writeln('总字数：${data.totalWords}')
      ..writeln('章节/分幕数量：${data.chapters.length}')
      ..writeln()
      ..writeln('请基于给定文本做真实分析，不要只复述节点名。')
      ..writeln('输出 Markdown，结构清晰，包含可复用结论；如果信息不足，请明确说明不足。')
      ..writeln()
      ..writeln('## 章节索引与片段');

    for (var i = 0; i < data.chapters.length; i++) {
      final chapter = data.chapters[i];
      buffer
        ..writeln()
        ..writeln('### ${i + 1}. ${chapter.title} (${chapter.wordCount} 字)')
        ..writeln(
          _excerpt(
            chapter.content,
            maxLength: _bookChapterPromptMaxCharacters,
          ),
        );
    }

    if (artifacts.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## 上游节点产物');
      for (final artifact in artifacts) {
        buffer
          ..writeln()
          ..writeln('### ${artifact.path}')
          ..writeln(_excerpt(artifact.content, maxLength: 1200));
      }
    }

    buffer
      ..writeln()
      ..writeln('## 本节点要求')
      ..writeln(_agentTaskInstruction(node));
    return buffer.toString();
  }

  Future<String> exportBookDeconstructionProjectFiles(int projectId) async {
    final db = await _open();
    final data = await _loadBookExportData(db, projectId);
    final directory = Directory(_bookProjectDirectory(projectId));
    await directory.create(recursive: true);

    await _writeTextFile(
      '${directory.path}${Platform.pathSeparator}source${Platform.pathSeparator}raw.txt',
      data.fullText,
    );
    await _writeTextFile(
      '${directory.path}${Platform.pathSeparator}source${Platform.pathSeparator}chapters${Platform.pathSeparator}index.json',
      const JsonEncoder.withIndent('  ').convert([
        for (var i = 0; i < data.chapters.length; i++)
          {
            'index': i + 1,
            'title': data.chapters[i].title,
            'word_count': data.chapters[i].wordCount,
            'file': 'ch${(i + 1).toString().padLeft(3, '0')}.txt',
          },
      ]),
    );
    for (var i = 0; i < data.chapters.length; i++) {
      await _writeTextFile(
        '${directory.path}${Platform.pathSeparator}source${Platform.pathSeparator}chapters${Platform.pathSeparator}ch${(i + 1).toString().padLeft(3, '0')}.txt',
        data.chapters[i].content,
      );
    }

    for (final artifact in data.artifacts) {
      await _writeTextFile(
        '${directory.path}${Platform.pathSeparator}${artifact.path.replaceAll('/', Platform.pathSeparator)}',
        artifact.content,
      );
    }

    await _writeTextFile(
      '${directory.path}${Platform.pathSeparator}report.md',
      _buildBookReport(data),
    );
    return directory.path;
  }

  Future<String> exportBookDeconstructionReport(int projectId) async {
    final directory = await exportBookDeconstructionProjectFiles(projectId);
    return '$directory${Platform.pathSeparator}report.md';
  }

  Future<bool> bookDeconstructionProjectHasNovel(int projectId) async {
    final db = await _open();
    final rows = await db.query(
      'book_deconstruction_projects',
      columns: ['novel_id'],
      where: 'id = ? AND novel_id IS NOT NULL',
      whereArgs: [projectId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> close() async {
    final database = _database;
    if (database == null) {
      return;
    }
    _database = null;
    await database.close();
  }

  Future<String> backupToDirectory(String directoryPath,
      {DateTime? now}) async {
    final directory = Directory(directoryPath.trim());
    if (!await directory.exists()) {
      throw ArgumentError.value(
        directoryPath,
        'directoryPath',
        'Backup directory does not exist.',
      );
    }

    await _ensureDatabaseFile();
    await close();

    final timestamp = _backupTimestamp(now ?? DateTime.now());
    final targetPath =
        '${directory.path}${Platform.pathSeparator}ai_novel_factory_$timestamp.sqlite';
    return File(_databasePath).copy(targetPath).then((file) => file.path);
  }

  Future<void> restoreFromBackup(String backupPath) async {
    final backupFile = File(backupPath.trim());
    if (!await backupFile.exists()) {
      throw ArgumentError.value(
        backupPath,
        'backupPath',
        'Backup file does not exist.',
      );
    }

    await close();
    await File(_databasePath).parent.create(recursive: true);
    await backupFile.copy(_databasePath);
  }

  Future<Database> _open() async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final database = await _databaseFactory.openDatabase(
      _databasePath,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (db, version) async {
          await db.execute('''
CREATE TABLE novels (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  summary TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL DEFAULT '',
  work_type TEXT NOT NULL DEFAULT '',
  cover_path TEXT,
  updated_at INTEGER NOT NULL
)
''');
          await db.execute('''
CREATE TABLE chapters (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  novel_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL DEFAULT '',
  word_count INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (novel_id) REFERENCES novels(id) ON DELETE CASCADE
)
''');
          await db.execute('''
CREATE TABLE writing_goals (
  day TEXT PRIMARY KEY,
  target_words INTEGER NOT NULL
)
''');
          await db.execute('''
CREATE TABLE daily_writing_progress (
  day TEXT PRIMARY KEY,
  words INTEGER NOT NULL DEFAULT 0
)
''');
          await db.execute('''
CREATE TABLE recent_writing (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  novel_id INTEGER NOT NULL,
  chapter_id INTEGER,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (novel_id) REFERENCES novels(id) ON DELETE CASCADE,
  FOREIGN KEY (chapter_id) REFERENCES chapters(id) ON DELETE SET NULL
)
''');
          await db.execute('''
CREATE TABLE novel_tags (
  novel_id INTEGER NOT NULL,
  tag TEXT NOT NULL,
  position INTEGER NOT NULL,
  PRIMARY KEY (novel_id, tag),
  FOREIGN KEY (novel_id) REFERENCES novels(id) ON DELETE CASCADE
)
''');
          await _createBookDeconstructionTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
              "ALTER TABLE novels ADD COLUMN category TEXT NOT NULL DEFAULT ''",
            );
            await db.execute(
              "ALTER TABLE novels ADD COLUMN work_type TEXT NOT NULL DEFAULT ''",
            );
          }
          if (oldVersion < 3) {
            await db.execute('''
CREATE TABLE novel_tags (
  novel_id INTEGER NOT NULL,
  tag TEXT NOT NULL,
  position INTEGER NOT NULL,
  PRIMARY KEY (novel_id, tag),
  FOREIGN KEY (novel_id) REFERENCES novels(id) ON DELETE CASCADE
)
''');
          }
          if (oldVersion < 4) {
            await _createBookDeconstructionTables(db);
          }
        },
      ),
    );

    _database = database;
    return database;
  }

  static Future<void> _createBookDeconstructionTables(
    DatabaseExecutor db,
  ) async {
    await db.execute('''
CREATE TABLE book_deconstruction_projects (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  novel_id INTEGER,
  status TEXT NOT NULL,
  current_node_id TEXT,
  progress REAL NOT NULL DEFAULT 0,
  chapter_count INTEGER NOT NULL DEFAULT 0,
  character_count INTEGER NOT NULL DEFAULT 0,
  foreshadowing_count INTEGER NOT NULL DEFAULT 0,
  style_asset_count INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (novel_id) REFERENCES novels(id) ON DELETE SET NULL
)
''');
    await db.execute('''
CREATE TABLE book_deconstruction_nodes (
  project_id INTEGER NOT NULL,
  node_id TEXT NOT NULL,
  status TEXT NOT NULL,
  message TEXT NOT NULL DEFAULT '',
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (project_id, node_id),
  FOREIGN KEY (project_id) REFERENCES book_deconstruction_projects(id)
    ON DELETE CASCADE
)
''');
    await db.execute('''
CREATE TABLE book_deconstruction_artifacts (
  project_id INTEGER NOT NULL,
  node_id TEXT NOT NULL,
  artifact_path TEXT NOT NULL,
  artifact_kind TEXT NOT NULL,
  content TEXT NOT NULL,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (project_id, artifact_path),
  FOREIGN KEY (project_id) REFERENCES book_deconstruction_projects(id)
    ON DELETE CASCADE
)
''');
  }

  Future<void> _recoverInterruptedBookDeconstructionRuns(Database db) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'book_deconstruction_projects',
      {
        'status': BookDeconstructionProjectStatus.paused.name,
        'updated_at': timestamp,
      },
      where: 'status = ?',
      whereArgs: [BookDeconstructionProjectStatus.running.name],
    );
    await db.update(
      'book_deconstruction_nodes',
      {
        'status': BookDeconstructionNodeStatus.pending.name,
        'message': 'Recovered after interruption.',
        'updated_at': timestamp,
      },
      where: 'status = ?',
      whereArgs: [BookDeconstructionNodeStatus.running.name],
    );
  }

  Future<List<BookDeconstructionProject>> _loadBookDeconstructionProjects(
    Database db,
  ) async {
    final projectRows = await db.rawQuery('''
SELECT
  p.id,
  p.title,
  p.novel_id,
  n.title AS novel_title,
  p.status,
  p.current_node_id,
  p.progress,
  p.chapter_count,
  p.character_count,
  p.foreshadowing_count,
  p.style_asset_count,
  p.updated_at
FROM book_deconstruction_projects p
LEFT JOIN novels n ON n.id = p.novel_id
ORDER BY p.updated_at DESC, p.id DESC
''');
    final nodeStatuses = await _loadBookDeconstructionNodeStatuses(db);

    return [
      for (final row in projectRows)
        BookDeconstructionProject(
          id: row['id'] as int,
          title: row['title'] as String,
          novelId: row['novel_id'] as int?,
          novelTitle: row['novel_title'] as String?,
          status: _parseBookProjectStatus(row['status'] as String),
          currentNodeId: row['current_node_id'] as String?,
          progress: (row['progress'] as num).toDouble(),
          chapterCount: row['chapter_count'] as int,
          characterCount: row['character_count'] as int,
          foreshadowingCount: row['foreshadowing_count'] as int,
          styleAssetCount: row['style_asset_count'] as int,
          updatedAt: _fromTimestamp(row['updated_at'] as int),
          nodeStatuses: nodeStatuses[row['id'] as int] ?? const {},
        ),
    ];
  }

  Future<Map<int, Map<String, BookDeconstructionNodeStatus>>>
      _loadBookDeconstructionNodeStatuses(Database db) async {
    final rows = await db.query(
      'book_deconstruction_nodes',
      columns: ['project_id', 'node_id', 'status'],
    );
    final statuses = <int, Map<String, BookDeconstructionNodeStatus>>{};
    for (final row in rows) {
      final projectId = row['project_id'] as int;
      (statuses[projectId] ??= <String, BookDeconstructionNodeStatus>{})[
              row['node_id'] as String] =
          _parseBookNodeStatus(row['status'] as String);
    }
    return statuses;
  }

  Future<String?> _loadNovelTitle(Database db, int novelId) async {
    final rows = await db.query(
      'novels',
      columns: ['title'],
      where: 'id = ?',
      whereArgs: [novelId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single['title'] as String;
  }

  Future<void> _refreshBookDeconstructionStats(
    Database db,
    int projectId,
  ) async {
    final nodeRows = await db.query(
      'book_deconstruction_nodes',
      columns: ['node_id', 'status'],
      where: 'project_id = ?',
      whereArgs: [projectId],
    );
    final passedNodeIds = {
      for (final row in nodeRows)
        if (row['status'] == BookDeconstructionNodeStatus.passed.name)
          row['node_id'] as String,
    };
    final projectRows = await db.query(
      'book_deconstruction_projects',
      columns: ['novel_id'],
      where: 'id = ?',
      whereArgs: [projectId],
      limit: 1,
    );
    final novelId = projectRows.isEmpty ? null : projectRows.single['novel_id'];
    final data =
        novelId == null ? null : await _loadBookExportData(db, projectId);
    final chapterCount = data?.chapters.length ?? 0;
    final progress =
        passedNodeIds.length / bookDeconstructionWorkflowNodes.length;

    await db.update(
      'book_deconstruction_projects',
      {
        'progress': progress.clamp(0.0, 1.0),
        'chapter_count':
            passedNodeIds.contains('gate_1_text_cleaned') ? chapterCount : 0,
        'character_count': data == null ? 0 : _characterCount(data),
        'foreshadowing_count': data == null ? 0 : _foreshadowingCount(data),
        'style_asset_count': await _countArtifacts(db, projectId, 'style'),
      },
      where: 'id = ?',
      whereArgs: [projectId],
    );
  }

  Future<int> _countArtifacts(
    Database db,
    int projectId,
    String kind,
  ) async {
    final rows = await db.rawQuery(
      '''
SELECT COUNT(*) AS total
FROM book_deconstruction_artifacts
WHERE project_id = ? AND artifact_kind = ?
''',
      [projectId, kind],
    );
    return rows.single['total'] as int;
  }

  int _characterCount(_BookExportData data) {
    final names = <String>{};
    for (final artifact in data.artifacts) {
      if (artifact.kind != 'characters') {
        continue;
      }
      for (final match in RegExp(r'\*\*([\u4e00-\u9fff]{2,6})\*\*')
          .allMatches(artifact.content)) {
        names.add(match.group(1)!);
      }
    }
    if (names.isNotEmpty) {
      return names.length;
    }
    return _characterCandidates(data.fullText).length;
  }

  int _foreshadowingCount(_BookExportData data) {
    final fromArtifacts = data.artifacts
        .where((artifact) => artifact.kind == 'foreshadowing')
        .map((artifact) => artifact.content
            .split('\n')
            .where(_looksLikeNumberedHeading)
            .length)
        .fold<int>(0, (total, count) => total + count);
    if (fromArtifacts > 0) {
      return fromArtifacts;
    }
    return _markerLines(data.fullText, [
      '秘密',
      '神秘',
      '谜',
      '龙',
      '命运',
    ]).length;
  }

  Future<_BookExportData> _loadBookExportData(
    Database db,
    int projectId,
  ) async {
    final projectRows = await db.rawQuery(
      '''
SELECT
  p.id,
  p.title,
  p.status,
  p.progress,
  n.id AS novel_id,
  n.title AS novel_title
FROM book_deconstruction_projects p
LEFT JOIN novels n ON n.id = p.novel_id
WHERE p.id = ?
LIMIT 1
''',
      [projectId],
    );
    if (projectRows.isEmpty) {
      throw ArgumentError.value(projectId, 'projectId', 'Project not found.');
    }
    final project = projectRows.single;
    final novelId = project['novel_id'] as int?;
    if (novelId == null) {
      throw StateError('Book deconstruction project has no novel assigned.');
    }

    final chapterRows = await db.query(
      'chapters',
      where: 'novel_id = ?',
      whereArgs: [novelId],
      orderBy: 'id ASC',
    );
    final artifactRows = await db.query(
      'book_deconstruction_artifacts',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'artifact_path ASC',
    );

    return _BookExportData(
      projectId: projectId,
      projectTitle: project['title'] as String,
      projectStatus: project['status'] as String,
      progress: project['progress'] as double,
      novelTitle: project['novel_title'] as String? ?? '未命名小说',
      chapters: [
        for (final row in chapterRows)
          _ExportChapter(
            title: row['title'] as String,
            content: row['content'] as String,
            wordCount: row['word_count'] as int,
          ),
      ],
      artifacts: [
        for (final row in artifactRows)
          _ExportArtifact(
            path: row['artifact_path'] as String,
            kind: row['artifact_kind'] as String,
            content: row['content'] as String,
          ),
      ],
    );
  }

  Future<void> _ensureDatabaseFile() async {
    if (await File(_databasePath).exists()) {
      return;
    }
    final database = await _open();
    await database.close();
    _database = null;
  }

  Future<List<NovelSummary>> _loadNovels(Database db) async {
    final rows = await db.rawQuery('''
SELECT
  n.id,
  n.title,
  n.summary,
  n.status,
  n.category,
  n.work_type,
  n.cover_path,
  n.updated_at,
  COALESCE(SUM(c.word_count), 0) AS word_count
FROM novels n
LEFT JOIN chapters c ON c.novel_id = n.id
GROUP BY n.id
ORDER BY n.updated_at DESC, n.id DESC
''');

    final tagsByNovel = await _loadNovelTags(db);

    return rows.map((row) {
      final novelId = row['id'] as int;
      return NovelSummary(
        id: novelId,
        title: row['title'] as String,
        summary: row['summary'] as String,
        status: row['status'] as String,
        category: row['category'] as String,
        workType: row['work_type'] as String,
        tags: tagsByNovel[novelId] ?? const [],
        coverPath: row['cover_path'] as String?,
        updatedAt: _fromTimestamp(row['updated_at'] as int),
        wordCount: row['word_count'] as int,
      );
    }).toList(growable: false);
  }

  Future<Map<int, List<String>>> _loadNovelTags(Database db) async {
    final rows = await db.query(
      'novel_tags',
      columns: ['novel_id', 'tag'],
      orderBy: 'novel_id ASC, position ASC',
    );
    final tags = <int, List<String>>{};
    for (final row in rows) {
      final novelId = row['novel_id'] as int;
      (tags[novelId] ??= <String>[]).add(row['tag'] as String);
    }
    return tags;
  }

  Future<void> _insertTags(
    DatabaseExecutor db,
    int novelId,
    List<String> tags,
  ) async {
    final seen = <String>{};
    var position = 0;
    for (final rawTag in tags) {
      final tag = rawTag.trim();
      if (tag.isEmpty || !seen.add(tag)) {
        continue;
      }
      await db.insert('novel_tags', {
        'novel_id': novelId,
        'tag': tag,
        'position': position++,
      });
    }
  }

  Future<int> _loadTotalWordCount(Database db) async {
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(word_count), 0) AS total FROM chapters',
    );
    return rows.single['total'] as int;
  }

  Future<WritingGoalSummary?> _loadWritingGoal(
    Database db,
    DateTime today,
  ) async {
    final key = _dayKey(today);
    final goalRows = await db.query(
      'writing_goals',
      columns: ['target_words'],
      where: 'day = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (goalRows.isEmpty) {
      return null;
    }

    final progressRows = await db.query(
      'daily_writing_progress',
      columns: ['words'],
      where: 'day = ?',
      whereArgs: [key],
      limit: 1,
    );

    return WritingGoalSummary(
      targetWords: goalRows.single['target_words'] as int,
      currentWords:
          progressRows.isEmpty ? 0 : progressRows.single['words'] as int,
    );
  }

  Future<RecentWriting?> _loadRecentWriting(Database db) async {
    final rows = await db.rawQuery('''
SELECT
  r.novel_id,
  r.chapter_id,
  r.updated_at,
  n.title AS novel_title,
  c.title AS chapter_title
FROM recent_writing r
JOIN novels n ON n.id = r.novel_id
LEFT JOIN chapters c ON c.id = r.chapter_id AND c.novel_id = n.id
WHERE r.id = 1
LIMIT 1
''');

    if (rows.isEmpty) {
      return null;
    }

    final row = rows.single;
    return RecentWriting(
      novelId: row['novel_id'] as int,
      novelTitle: row['novel_title'] as String,
      chapterId: row['chapter_id'] as int?,
      chapterTitle: row['chapter_title'] as String?,
      updatedAt: _fromTimestamp(row['updated_at'] as int),
    );
  }
}

class _ImportedChapter {
  const _ImportedChapter({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;
}

class _BookExportData {
  const _BookExportData({
    required this.projectId,
    required this.projectTitle,
    required this.projectStatus,
    required this.progress,
    required this.novelTitle,
    required this.chapters,
    required this.artifacts,
  });

  final int projectId;
  final String projectTitle;
  final String projectStatus;
  final double progress;
  final String novelTitle;
  final List<_ExportChapter> chapters;
  final List<_ExportArtifact> artifacts;

  int get totalWords => chapters.fold(
        0,
        (total, chapter) => total + chapter.wordCount,
      );

  String get fullText =>
      chapters.map((chapter) => chapter.content).join('\n\n');
}

class _ExportChapter {
  const _ExportChapter({
    required this.title,
    required this.content,
    required this.wordCount,
  });

  final String title;
  final String content;
  final int wordCount;
}

class _ExportArtifact {
  const _ExportArtifact({
    required this.path,
    required this.kind,
    required this.content,
  });

  final String path;
  final String kind;
  final String content;
}

List<_ImportedChapter> _splitImportedChapters(String content, String title) {
  final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final lines = normalized.split('\n');
  final chapters = <_ImportedChapter>[];
  var currentTitle = title;
  var buffer = <String>[];
  var sawHeading = false;

  void flush() {
    final text = buffer.join('\n').trim();
    if (text.isEmpty) {
      return;
    }
    chapters.add(_ImportedChapter(title: currentTitle, content: text));
    buffer = <String>[];
  }

  for (final line in lines) {
    final heading = _chapterHeadingTitle(line);
    if (heading != null) {
      if (sawHeading) {
        flush();
      }
      currentTitle = heading;
      sawHeading = true;
    }
    buffer.add(line);
  }
  flush();

  if (chapters.isEmpty) {
    return [_ImportedChapter(title: title, content: normalized.trim())];
  }
  return chapters;
}

String? _chapterHeadingTitle(String line) {
  final text = line.trim();
  if (text.isEmpty || text.length > 80) {
    return null;
  }
  final heading = RegExp(
    r'^(第[一二三四五六七八九十百千万零〇两\d]+[章节卷部集幕回][^\n]*)$',
  );
  if (heading.hasMatch(text) && !text.endsWith('完】')) {
    return text;
  }
  if (RegExp(r'^(序章|楔子|尾声)(\s+.*)?$').hasMatch(text)) {
    return text;
  }
  if (text.length <= 40 &&
      RegExp(r'^[0-9０-９一二三四五六七八九十百]+[.．、]\s*\S.{0,32}$').hasMatch(text) &&
      !RegExp(r'[。！？!?，,；;：:]').hasMatch(text)) {
    return text;
  }
  return null;
}

Future<String> _readImportContent(File file) async {
  final extension = _extensionOf(file.path);
  switch (extension) {
    case 'txt':
    case 'md':
    case 'markdown':
      return file.readAsString();
    case 'html':
    case 'htm':
      return _htmlToText(await file.readAsString());
    case 'epub':
      return _epubToText(await file.readAsBytes());
    default:
      throw ArgumentError.value(
          file.path, 'filePath', 'Unsupported file type.');
  }
}

String _epubToText(List<int> bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final parts = archive.files.where((file) {
    final name = file.name.toLowerCase();
    return file.isFile &&
        (name.endsWith('.html') ||
            name.endsWith('.htm') ||
            name.endsWith('.xhtml'));
  }).toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  final text = parts
      .map((file) {
        return _htmlToText(String.fromCharCodes(file.content));
      })
      .where((part) => part.trim().isNotEmpty)
      .join('\n\n');

  if (text.trim().isEmpty) {
    throw ArgumentError.value('epub', 'filePath', 'EPUB contains no text.');
  }
  return text;
}

String _htmlToText(String html) {
  final withBreaks = html
      .replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n')
      .replaceAll(
          RegExp(r'</\s*(p|div|h[1-6]|li|section|article)\s*>',
              caseSensitive: false),
          '\n');
  final stripped = withBreaks
      .replaceAll(
          RegExp(r'<\s*(script|style)[^>]*>.*?</\s*\1\s*>',
              caseSensitive: false, dotAll: true),
          '')
      .replaceAll(RegExp(r'<[^>]+>', dotAll: true), ' ');
  return _decodeHtmlEntities(stripped)
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((line) => line.isNotEmpty)
      .join('\n');
}

String _decodeHtmlEntities(String text) {
  return text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'");
}

Future<void> _writeTextFile(String path, String content) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
}

String _bookProjectDirectory(int projectId) {
  return [
    Directory.current.path,
    'book_deconstruction_projects',
    'book_$projectId',
  ].join(Platform.pathSeparator);
}

String _buildBookReport(_BookExportData data) {
  final buffer = StringBuffer()
    ..writeln('# ${data.projectTitle}')
    ..writeln()
    ..writeln('- 小说：${data.novelTitle}')
    ..writeln('- 状态：${data.projectStatus}')
    ..writeln('- 进度：${(data.progress * 100).round()}%')
    ..writeln('- 章节/分幕：${data.chapters.length}')
    ..writeln('- 总字数：${data.totalWords}')
    ..writeln()
    ..writeln('## 章节索引')
    ..writeln();
  for (var i = 0; i < data.chapters.length; i++) {
    final chapter = data.chapters[i];
    buffer.writeln(
      '${i + 1}. ${chapter.title}（${chapter.wordCount} 字）',
    );
  }
  buffer
    ..writeln()
    ..writeln('## 本地拆书产物')
    ..writeln();
  if (data.artifacts.isEmpty) {
    buffer.writeln('暂无节点产物。');
  } else {
    for (final artifact in data.artifacts) {
      buffer.writeln('- `${artifact.path}`（${artifact.kind}）');
    }
  }
  buffer
    ..writeln()
    ..writeln('## 说明')
    ..writeln()
    ..writeln('当前报告由本地导入文本和工作流节点产物生成。')
    ..writeln('真实人物关系、伏笔、文风等深度分析需要后续接入拆书 Agent/LLM 后生成。');
  return buffer.toString();
}

Map<String, Object> _chapterStatistics(List<_ExportChapter> chapters) {
  if (chapters.isEmpty) {
    return {
      'average_words': 0,
      'min_words': 0,
      'max_words': 0,
    };
  }
  final counts = chapters.map((chapter) => chapter.wordCount).toList()..sort();
  final total = counts.fold<int>(0, (sum, count) => sum + count);
  return {
    'average_words': (total / counts.length).round(),
    'min_words': counts.first,
    'max_words': counts.last,
  };
}

List<Map<String, Object>> _characterCandidates(String text) {
  final names = <String, int>{};
  final commonNames = [
    '路明非',
    '楚子航',
    '恺撒',
    '诺诺',
    '芬格尔',
    '昂热',
    '古德里安',
    '曼施坦因',
    '施耐德',
    '陈雯雯',
    '赵孟华',
    '路鸣泽',
    '叶胜',
    '亚纪',
  ];
  for (final name in commonNames) {
    final count = RegExp(RegExp.escape(name)).allMatches(text).length;
    if (count > 0) {
      names[name] = count;
    }
  }
  final entries = names.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return [
    for (final entry in entries.take(20))
      {
        'name': entry.key,
        'mentions': entry.value,
      },
  ];
}

List<Map<String, Object>> _markerLines(
  String text,
  List<String> markers,
) {
  final results = <Map<String, Object>>[];
  for (final line in text.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.length < 12) {
      continue;
    }
    String? marker;
    for (final candidate in markers) {
      if (trimmed.contains(candidate)) {
        marker = candidate;
        break;
      }
    }
    if (marker == null) {
      continue;
    }
    results.add({
      'marker': marker,
      'excerpt': _excerpt(trimmed, maxLength: 120),
    });
    if (results.length >= 20) {
      break;
    }
  }
  return results;
}

bool _looksLikeNumberedHeading(String line) {
  final text = line.trimLeft();
  final hashes = text.startsWith('#### ')
      ? 5
      : text.startsWith('### ')
          ? 4
          : 0;
  if (hashes == 0 || text.length <= hashes) {
    return false;
  }
  final first = text.codeUnitAt(hashes);
  return first >= 0x30 && first <= 0x39;
}

Map<String, Object> _styleNotes(String text) {
  final sentenceCount = RegExp(r'[。！？!?]').allMatches(text).length;
  final dialogueCount = RegExp(r'[“"]([^”"]+)[”"]').allMatches(text).length;
  return {
    'sentence_count': sentenceCount,
    'dialogue_count': dialogueCount,
    'dialogue_ratio': sentenceCount == 0
        ? 0
        : double.parse((dialogueCount / sentenceCount).toStringAsFixed(3)),
  };
}

String _excerpt(String text, {int maxLength = 180}) {
  final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (compact.length <= maxLength) {
    return compact;
  }
  return '${compact.substring(0, maxLength)}...';
}

String _agentTaskInstruction(BookDeconstructionNode node) {
  switch (node.agentId ?? node.id) {
    case 'book_master_control':
      return '识别作品基本信息、体裁、主要阅读目标，并给后续拆书节点制定分析重点。';
    case 'book_text_cleaning':
      return '检查文本结构、章节/分幕切分质量、目录噪声和正文异常，输出清洗建议与问题清单。';
    case 'book_chapter_content':
      return '逐章/逐幕概括剧情推进、关键冲突、登场人物、信息增量和读者钩子。';
    case 'book_overview':
      return '生成全书总览：核心卖点、主线剧情、世界观设定、人物弧光、主题与读者体验。';
    case 'book_plot_structure':
      return '分析情节结构：开端、转折、高潮、悬念递进、爽点节奏和章节功能分布。';
    case 'book_business_mechanism':
      return '分析商业机制：题材定位、受众预期、留存钩子、情绪奖励、可复用套路。';
    case 'book_relationships':
      return '抽取人物关系：核心人物、关系类型、阵营、冲突/亲密变化和关系网络。';
    case 'book_foreshadowing_suspense':
      return '抽取伏笔悬念：埋设位置、回收位置、悬念问题、读者预期和风险点。';
    case 'book_style_fingerprint':
      return '分析文风指纹：叙述视角、句式、对白比例、意象、节奏、幽默/热血/悬疑手法。';
    case 'book_template_distillation':
      return '蒸馏可迁移模板：章节结构模板、角色出场模板、冲突升级模板、钩子模板。';
    case 'book_skill_compile':
      return '把前序分析编译成写作 Skill：风格指南、结构模式、人物模式、禁用照抄规则。';
    case 'book_quality_check':
      return '质检所有拆书结论：指出证据不足、矛盾、遗漏和需要人工复核的位置。';
  }
  return '完成该节点要求的拆书分析，并输出可供后续节点复用的结构化结论。';
}

int countWritingUnits(String text) {
  var count = 0;
  for (final rune in text.runes) {
    if (String.fromCharCode(rune).trim().isNotEmpty) {
      count++;
    }
  }
  return count;
}

String _defaultDatabasePath() {
  return '${Directory.current.path}${Platform.pathSeparator}ai_novel_factory.sqlite';
}

String _backupTimestamp(DateTime date) {
  final local = date.toLocal();
  return '${local.year}'
      '${local.month.toString().padLeft(2, '0')}'
      '${local.day.toString().padLeft(2, '0')}_'
      '${local.hour.toString().padLeft(2, '0')}'
      '${local.minute.toString().padLeft(2, '0')}'
      '${local.second.toString().padLeft(2, '0')}';
}

String _dayKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _extensionOf(String path) {
  final name = path.split(RegExp(r'[\\/]')).last;
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) {
    return '';
  }
  return name.substring(dot + 1).toLowerCase();
}

DateTime _fromTimestamp(int timestamp) {
  return DateTime.fromMillisecondsSinceEpoch(timestamp);
}

BookDeconstructionProjectStatus _parseBookProjectStatus(String value) {
  for (final status in BookDeconstructionProjectStatus.values) {
    if (status.name == value) {
      return status;
    }
  }
  return BookDeconstructionProjectStatus.draft;
}

BookDeconstructionNodeStatus _parseBookNodeStatus(String value) {
  for (final status in BookDeconstructionNodeStatus.values) {
    if (status.name == value) {
      return status;
    }
  }
  return BookDeconstructionNodeStatus.pending;
}

String _artifactKindForNode(BookDeconstructionNode node) {
  if (node.id.contains('chapter')) {
    return 'chapters';
  }
  if (node.id.contains('relationship') || node.id.contains('character')) {
    return 'characters';
  }
  if (node.id.contains('foreshadowing')) {
    return 'foreshadowing';
  }
  if (node.id.contains('style')) {
    return 'style';
  }
  if (node.id.contains('skill')) {
    return 'skill';
  }
  return 'workflow';
}

String _artifactPathForNode(int projectId, BookDeconstructionNode node) {
  return 'book_$projectId/${_artifactKindForNode(node)}/${node.id}.json';
}

String _titleFromFile(File file) {
  final name = file.path.split(RegExp(r'[\\/]')).last;
  final dot = name.lastIndexOf('.');
  final title = dot <= 0 ? name : name.substring(0, dot);
  final trimmed = title.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(file.path, 'filePath', 'File name is empty.');
  }
  return trimmed;
}
