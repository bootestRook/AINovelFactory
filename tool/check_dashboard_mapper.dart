import 'package:ai_novel_factory/src/dashboard/dashboard_mapper.dart';
import 'package:ai_novel_factory/src/dashboard/dashboard_models.dart';

void main() {
  final today = DateTime(2026, 6, 29);
  final novel = NovelSummary(
    id: 1,
    title: '真实项目',
    summary: '本地数据',
    status: '',
    category: '科幻',
    workType: '原创',
    tags: const [],
    coverPath: null,
    updatedAt: today,
    wordCount: 1200,
  );

  final empty = mapDashboardData(DashboardData(
    novels: const [],
    totalWordCount: 0,
    today: today,
  ));
  assert(empty.mode == DashboardMode.firstUse);
  assert(empty.projectCount == 0);
  assert(!empty.showProjectSearch);

  final withoutRecent = mapDashboardData(DashboardData(
    novels: [novel],
    totalWordCount: novel.wordCount,
    today: today,
  ));
  assert(withoutRecent.mode == DashboardMode.noRecentWriting);
  assert(withoutRecent.showProjectSearch);

  final withRecent = mapDashboardData(DashboardData(
    novels: [novel],
    totalWordCount: novel.wordCount,
    today: today,
    recentWriting: RecentWriting(
      novelId: novel.id,
      novelTitle: novel.title,
      updatedAt: today,
    ),
  ));
  assert(withRecent.mode == DashboardMode.populated);
  assert(withRecent.recentWriting?.novelId == novel.id);

  final searchEmpty = mapDashboardData(DashboardData(
    novels: [novel],
    totalWordCount: novel.wordCount,
    today: today,
    searchQuery: '不存在',
  ));
  assert(searchEmpty.mode == DashboardMode.searchEmpty);
  assert(searchEmpty.showProjectSearch);
  assert(searchEmpty.visibleNovels.isEmpty);

  final invalidRecent = mapDashboardData(DashboardData(
    novels: [novel],
    totalWordCount: novel.wordCount,
    today: today,
    recentWriting: RecentWriting(
      novelId: 999,
      novelTitle: '不存在',
      updatedAt: today,
    ),
  ));
  assert(invalidRecent.mode == DashboardMode.noRecentWriting);
}
