import 'dashboard_models.dart';

DashboardViewState mapDashboardData(DashboardData data) {
  if (data.isLoading) {
    return DashboardViewState.loading(today: data.today);
  }

  final query = data.searchQuery.trim().toLowerCase();
  final visibleNovels = query.isEmpty
      ? data.novels
      : data.novels.where((novel) {
          return novel.title.toLowerCase().contains(query) ||
              novel.summary.toLowerCase().contains(query) ||
              novel.category.toLowerCase().contains(query) ||
              novel.workType.toLowerCase().contains(query) ||
              novel.tags.any((tag) => tag.toLowerCase().contains(query));
        }).toList(growable: false);

  if (data.novels.isEmpty) {
    return DashboardViewState(
      mode: DashboardMode.firstUse,
      novels: data.novels,
      visibleNovels: const [],
      totalWordCount: data.totalWordCount,
      today: data.today,
      writingGoal: data.writingGoal,
      searchQuery: data.searchQuery,
    );
  }

  if (query.isNotEmpty && visibleNovels.isEmpty) {
    return DashboardViewState(
      mode: DashboardMode.searchEmpty,
      novels: data.novels,
      visibleNovels: const [],
      totalWordCount: data.totalWordCount,
      today: data.today,
      writingGoal: data.writingGoal,
      recentWriting: _validRecentWriting(data),
      searchQuery: data.searchQuery,
    );
  }

  final recentWriting = _validRecentWriting(data);

  return DashboardViewState(
    mode: recentWriting == null
        ? DashboardMode.noRecentWriting
        : DashboardMode.populated,
    novels: data.novels,
    visibleNovels: visibleNovels,
    totalWordCount: data.totalWordCount,
    today: data.today,
    writingGoal: data.writingGoal,
    recentWriting: recentWriting,
    searchQuery: data.searchQuery,
  );
}

RecentWriting? _validRecentWriting(DashboardData data) {
  final recentWriting = data.recentWriting;
  if (recentWriting == null) {
    return null;
  }

  for (final novel in data.novels) {
    if (novel.id == recentWriting.novelId) {
      return recentWriting;
    }
  }

  return null;
}
