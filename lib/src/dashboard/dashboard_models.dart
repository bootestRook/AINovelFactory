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
