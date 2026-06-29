import 'dart:io';

import 'package:archive/archive.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../dashboard/dashboard_models.dart';

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

      final chapterId = await txn.insert('chapters', {
        'novel_id': novelId,
        'title': title,
        'content': content,
        'word_count': countWritingUnits(content),
        'updated_at': timestamp,
      });

      await txn.insert(
        'recent_writing',
        {
          'id': 1,
          'novel_id': novelId,
          'chapter_id': chapterId,
          'updated_at': timestamp,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return novelId;
    });
  }

  Future<void> close() async {
    final database = _database;
    if (database == null) {
      return;
    }
    _database = null;
    await database.close();
  }

  Future<Database> _open() async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final database = await _databaseFactory.openDatabase(
      _databasePath,
      options: OpenDatabaseOptions(
        version: 3,
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
        },
      ),
    );

    _database = database;
    return database;
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

String _titleFromFile(File file) {
  final name = file.uri.pathSegments.isEmpty
      ? file.path
      : Uri.decodeComponent(file.uri.pathSegments.last);
  final dot = name.lastIndexOf('.');
  final title = dot <= 0 ? name : name.substring(0, dot);
  final trimmed = title.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(file.path, 'filePath', 'File name is empty.');
  }
  return trimmed;
}
