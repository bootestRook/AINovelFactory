import '../book_lab/book_deconstruction_workflow.dart';

enum DashboardMode {
  loading,
  firstUse,
  populated,
  noRecentWriting,
  searchEmpty,
}

class NovelSummary {
  const NovelSummary({
    required this.id,
    required this.title,
    required this.summary,
    required this.status,
    required this.category,
    required this.workType,
    required this.tags,
    required this.coverPath,
    required this.updatedAt,
    required this.wordCount,
  });

  final int id;
  final String title;
  final String summary;
  final String status;
  final String category;
  final String workType;
  final List<String> tags;
  final String? coverPath;
  final DateTime updatedAt;
  final int wordCount;
}

class NovelChapter {
  const NovelChapter({
    required this.id,
    required this.novelId,
    required this.title,
    required this.outline,
    required this.content,
    required this.wordCount,
    required this.updatedAt,
  });

  final int id;
  final int novelId;
  final String title;
  final String outline;
  final String content;
  final int wordCount;
  final DateTime updatedAt;

  NovelChapter copyWith({
    String? title,
    String? outline,
    String? content,
    int? wordCount,
    DateTime? updatedAt,
  }) {
    return NovelChapter(
      id: id,
      novelId: novelId,
      title: title ?? this.title,
      outline: outline ?? this.outline,
      content: content ?? this.content,
      wordCount: wordCount ?? this.wordCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class NovelVolume {
  const NovelVolume({
    required this.id,
    required this.novelId,
    required this.title,
    required this.updatedAt,
  });

  final int id;
  final int novelId;
  final String title;
  final DateTime updatedAt;
}

class NovelOutline {
  const NovelOutline({
    required this.id,
    required this.novelId,
    required this.title,
    required this.status,
    required this.content,
    this.beatsJson = '[]',
    required this.updatedAt,
  });

  final int id;
  final int novelId;
  final String title;
  final String status;
  final String content;
  final String beatsJson;
  final DateTime updatedAt;

  NovelOutline copyWith({
    String? title,
    String? status,
    String? content,
    String? beatsJson,
    DateTime? updatedAt,
  }) {
    return NovelOutline(
      id: id,
      novelId: novelId,
      title: title ?? this.title,
      status: status ?? this.status,
      content: content ?? this.content,
      beatsJson: beatsJson ?? this.beatsJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class NovelCharacterSkill {
  const NovelCharacterSkill({
    required this.name,
    required this.relation,
    this.skillId,
  });

  final int? skillId;
  final String name;
  final String relation;

  Map<String, Object> toJson() => {
        if (skillId != null) 'skillId': skillId!,
        'name': name,
        'relation': relation,
      };

  static NovelCharacterSkill fromJson(Object? value) {
    if (value is! Map) {
      return const NovelCharacterSkill(name: '', relation: '已学会');
    }
    return NovelCharacterSkill(
      skillId: value['skillId'] as int?,
      name: (value['name'] as String? ?? '').trim(),
      relation: (value['relation'] as String? ?? '已学会').trim(),
    );
  }
}

class NovelCharacter {
  const NovelCharacter({
    required this.id,
    required this.novelId,
    required this.name,
    required this.role,
    required this.gender,
    required this.identity,
    required this.age,
    required this.motivation,
    required this.arc,
    required this.avatarPath,
    required this.galleryPaths,
    required this.firstChapterId,
    required this.biography,
    required this.currentState,
    required this.skills,
    required this.updatedAt,
  });

  final int id;
  final int novelId;
  final String name;
  final String role;
  final String gender;
  final String identity;
  final String age;
  final String motivation;
  final String arc;
  final String? avatarPath;
  final List<String> galleryPaths;
  final int? firstChapterId;
  final String biography;
  final String currentState;
  final List<NovelCharacterSkill> skills;
  final DateTime updatedAt;

  NovelCharacter copyWith({
    String? name,
    String? role,
    String? gender,
    String? identity,
    String? age,
    String? motivation,
    String? arc,
    String? avatarPath,
    List<String>? galleryPaths,
    int? firstChapterId,
    bool clearFirstChapter = false,
    String? biography,
    String? currentState,
    List<NovelCharacterSkill>? skills,
    DateTime? updatedAt,
  }) {
    return NovelCharacter(
      id: id,
      novelId: novelId,
      name: name ?? this.name,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      identity: identity ?? this.identity,
      age: age ?? this.age,
      motivation: motivation ?? this.motivation,
      arc: arc ?? this.arc,
      avatarPath: avatarPath ?? this.avatarPath,
      galleryPaths: galleryPaths ?? this.galleryPaths,
      firstChapterId:
          clearFirstChapter ? null : firstChapterId ?? this.firstChapterId,
      biography: biography ?? this.biography,
      currentState: currentState ?? this.currentState,
      skills: skills ?? this.skills,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class NovelForeshadowing {
  const NovelForeshadowing({
    required this.id,
    required this.novelId,
    required this.title,
    required this.status,
    required this.setupContent,
    required this.payoffContent,
    required this.updatedAt,
  });

  final int id;
  final int novelId;
  final String title;
  final String status;
  final String setupContent;
  final String payoffContent;
  final DateTime updatedAt;
}

class WritingGoalSummary {
  const WritingGoalSummary({
    required this.targetWords,
    required this.currentWords,
  });

  final int targetWords;
  final int currentWords;
}

class RecentWriting {
  const RecentWriting({
    required this.novelId,
    required this.novelTitle,
    required this.updatedAt,
    this.chapterId,
    this.chapterTitle,
  });

  final int novelId;
  final String novelTitle;
  final int? chapterId;
  final String? chapterTitle;
  final DateTime updatedAt;
}

class DashboardData {
  const DashboardData({
    required this.novels,
    required this.totalWordCount,
    required this.today,
    this.writingGoal,
    this.recentWriting,
    this.searchQuery = '',
    this.isLoading = false,
  });

  factory DashboardData.loading({DateTime? today}) {
    return DashboardData(
      novels: const [],
      totalWordCount: 0,
      today: today ?? DateTime.now(),
      isLoading: true,
    );
  }

  final List<NovelSummary> novels;
  final int totalWordCount;
  final DateTime today;
  final WritingGoalSummary? writingGoal;
  final RecentWriting? recentWriting;
  final String searchQuery;
  final bool isLoading;
}

class DashboardViewState {
  const DashboardViewState({
    required this.mode,
    required this.novels,
    required this.visibleNovels,
    required this.totalWordCount,
    required this.today,
    required this.searchQuery,
    this.writingGoal,
    this.recentWriting,
  });

  factory DashboardViewState.loading({DateTime? today}) {
    return DashboardViewState(
      mode: DashboardMode.loading,
      novels: const [],
      visibleNovels: const [],
      totalWordCount: 0,
      today: today ?? DateTime.now(),
      searchQuery: '',
    );
  }

  final DashboardMode mode;
  final List<NovelSummary> novels;
  final List<NovelSummary> visibleNovels;
  final int totalWordCount;
  final DateTime today;
  final WritingGoalSummary? writingGoal;
  final RecentWriting? recentWriting;
  final String searchQuery;

  bool get hasNovels => novels.isNotEmpty;
  bool get showProjectSearch => hasNovels;
  int get projectCount => novels.length;
}

enum BookDeconstructionProjectStatus {
  draft,
  running,
  paused,
  completed,
  failed,
}

class BookDeconstructionProject {
  const BookDeconstructionProject({
    required this.id,
    required this.title,
    required this.status,
    required this.progress,
    required this.chapterCount,
    required this.characterCount,
    required this.foreshadowingCount,
    required this.styleAssetCount,
    required this.updatedAt,
    required this.nodeStatuses,
    this.novelId,
    this.novelTitle,
    this.currentNodeId,
  });

  final int id;
  final String title;
  final int? novelId;
  final String? novelTitle;
  final BookDeconstructionProjectStatus status;
  final String? currentNodeId;
  final double progress;
  final int chapterCount;
  final int characterCount;
  final int foreshadowingCount;
  final int styleAssetCount;
  final DateTime updatedAt;
  final Map<String, BookDeconstructionNodeStatus> nodeStatuses;

  bool get hasNovel => novelId != null;
  bool get isRunning => status == BookDeconstructionProjectStatus.running;
}

class BookExperimentalWritingMessage {
  const BookExperimentalWritingMessage({
    required this.projectId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final int projectId;
  final String role;
  final String content;
  final DateTime createdAt;

  bool get isUser => role == 'user';
}
