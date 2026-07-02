import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../app/ai_models_client.dart';
import '../app/app_ai_settings.dart';
import '../app/app_appearance.dart';
import '../app/app_localizations.dart';
import '../app/app_theme.dart';
import '../book_lab/book_deconstruction_workflow.dart';
import 'dashboard_models.dart';

typedef BookExperimentalMessageLoader
    = Future<List<BookExperimentalWritingMessage>> Function(int projectId);
typedef BookExperimentalMessageSender = Future<BookExperimentalWritingMessage>
    Function(int projectId, String message);
typedef BookExperimentalFinalDraftSaver = Future<void> Function(
  int projectId,
  String content,
);
typedef NovelChapterLoader = Future<List<NovelChapter>> Function(int novelId);
typedef NovelChapterSaver = Future<NovelChapter> Function({
  required int novelId,
  required int? chapterId,
  required String title,
  required String outline,
  required String content,
});
typedef NovelChapterDeleter = Future<void> Function(int novelId, int chapterId);
typedef NovelVolumeLoader = Future<List<NovelVolume>> Function(int novelId);
typedef NovelVolumeCreator = Future<NovelVolume> Function({
  required int novelId,
  required String title,
});
typedef NovelOutlineLoader = Future<List<NovelOutline>> Function(int novelId);
typedef NovelOutlineSaver = Future<NovelOutline> Function({
  required int novelId,
  required int? outlineId,
  required String title,
  required String status,
  required String content,
  required String beatsJson,
});
typedef NovelOutlineDeleter = Future<void> Function(
  int novelId,
  int outlineId,
);
typedef NovelCharacterLoader = Future<List<NovelCharacter>> Function(
  int novelId,
);
typedef NovelCharacterSaver = Future<NovelCharacter> Function({
  required int novelId,
  required int? characterId,
  required String name,
  required String role,
  required String gender,
  required String identity,
  required String age,
  required String motivation,
  required String arc,
  required String? avatarPath,
  required List<String> galleryPaths,
  required int? firstChapterId,
  required String biography,
  required String currentState,
  required List<NovelCharacterSkill> skills,
});
typedef NovelCharacterDeleter = Future<void> Function(
  int novelId,
  int characterId,
);
typedef NovelForeshadowingLoader = Future<List<NovelForeshadowing>> Function(
  int novelId,
);
typedef NovelForeshadowingSaver = Future<NovelForeshadowing> Function({
  required int novelId,
  required int? foreshadowingId,
  required String title,
  required String status,
  required String setupContent,
  required String payoffContent,
});
typedef NovelForeshadowingDeleter = Future<void> Function(
  int novelId,
  int foreshadowingId,
);
typedef RecentChapterRecorder = Future<void> Function(
  int novelId,
  int chapterId,
);

class DashboardActions {
  const DashboardActions({
    required this.createNovel,
    required this.importNovel,
    required this.openProject,
    required this.toggleTheme,
    this.editProject,
    this.updateProjectStatus,
    this.deleteProject,
    this.openSettings,
    this.openBookBreakdown,
  });

  final VoidCallback createNovel;
  final VoidCallback importNovel;
  final ValueChanged<NovelSummary> openProject;
  final VoidCallback toggleTheme;
  final ValueChanged<NovelSummary>? editProject;
  final void Function(NovelSummary novel, String status)? updateProjectStatus;
  final ValueChanged<NovelSummary>? deleteProject;
  final VoidCallback? openSettings;
  final VoidCallback? openBookBreakdown;
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.state,
    required this.actions,
    required this.searchController,
    required this.onSearchChanged,
  });

  final DashboardViewState state;
  final DashboardActions actions;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final appearance = AppAppearanceScope.of(context);

    return Scaffold(
      backgroundColor: appearance.backgroundKind == AppBackgroundKind.none
          ? colors.background
          : Colors.transparent,
      body: Column(
        children: [
          _TopBar(
            onToggleTheme: actions.toggleTheme,
            onOpenSettings: actions.openSettings,
            onOpenBookBreakdown: actions.openBookBreakdown,
          ),
          Expanded(
            child: SingleChildScrollView(
              key: const PageStorageKey<String>('book-deconstruction-scroll'),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1224),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 34, 24, 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.text('dashboard.welcome'),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: colors.text,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.l10n.date(state.today),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: colors.muted),
                        ),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 920;
                            final primary = _PrimaryWorkCard(
                              state: state,
                              actions: actions,
                              fillAvailableHeight: wide,
                            );
                            final stats = _StatsColumn(state: state);

                            if (!wide) {
                              return Column(
                                children: [
                                  primary,
                                  const SizedBox(height: 16),
                                  stats,
                                ],
                              );
                            }

                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(flex: 3, child: primary),
                                  const SizedBox(width: 24),
                                  Expanded(flex: 2, child: stats),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 44),
                        _ProjectsSection(
                          state: state,
                          actions: actions,
                          searchController: searchController,
                          onSearchChanged: onSearchChanged,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BookDeconstructionScreen extends StatelessWidget {
  const BookDeconstructionScreen({
    super.key,
    required this.today,
    this.currentProject,
    this.projects = const [],
    required this.onBack,
    required this.onToggleTheme,
    this.onOpenSettings,
    this.onImportNovel,
    this.onCreateProject,
    this.onStartOrPause,
    this.onSelectProject,
    this.onOpenProjectFolder,
    this.onOpenProjectReport,
    this.onDeleteProject,
    this.onOpenExperimentalWriting,
  });

  final DateTime today;
  final BookDeconstructionProject? currentProject;
  final List<BookDeconstructionProject> projects;
  final VoidCallback onBack;
  final VoidCallback onToggleTheme;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onImportNovel;
  final VoidCallback? onCreateProject;
  final VoidCallback? onStartOrPause;
  final ValueChanged<int>? onSelectProject;
  final ValueChanged<int>? onOpenProjectFolder;
  final ValueChanged<int>? onOpenProjectReport;
  final ValueChanged<int>? onDeleteProject;
  final ValueChanged<int>? onOpenExperimentalWriting;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final appearance = AppAppearanceScope.of(context);
    final nodeStatuses = currentProject?.nodeStatuses ?? const {};

    return Scaffold(
      backgroundColor: appearance.backgroundKind == AppBackgroundKind.none
          ? colors.background
          : Colors.transparent,
      body: Column(
        children: [
          _TopBar(
            onToggleTheme: onToggleTheme,
            onOpenSettings: onOpenSettings,
            onBack: onBack,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1224),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 34, 24, 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '拆书工作台',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: colors.text,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.l10n.date(today),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: colors.muted),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '导入一本小说，拆解结构、人物、伏笔与文风指纹',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: colors.muted),
                        ),
                        const SizedBox(height: 22),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 920;
                            final primary = _BookBreakdownStartCard(
                              onImportNovel: onImportNovel,
                              onStartOrPause: onStartOrPause,
                              onOpenExperimentalWriting:
                                  onOpenExperimentalWriting,
                              project: currentProject,
                              nodeStatuses: nodeStatuses,
                            );
                            final stats = _BookBreakdownStatsColumn(
                              project: currentProject,
                            );

                            if (!wide) {
                              return Column(
                                children: [
                                  primary,
                                  const SizedBox(height: 16),
                                  stats,
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 2, child: primary),
                                const SizedBox(width: 24),
                                Expanded(child: stats),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _BookBreakdownProjectsSection(
                          projects: projects,
                          currentProject: currentProject,
                          onImportNovel: onImportNovel,
                          onCreateProject: onCreateProject,
                          onStartOrPause: onStartOrPause,
                          onSelectProject: onSelectProject,
                          onOpenProjectFolder: onOpenProjectFolder,
                          onOpenProjectReport: onOpenProjectReport,
                          onDeleteProject: onDeleteProject,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProjectOverviewScreen extends StatelessWidget {
  const ProjectOverviewScreen({
    super.key,
    required this.novel,
    required this.assistantModels,
    required this.onBack,
    required this.onToggleTheme,
    this.aiSettings = const AppAiSettings(),
    this.loadChapters,
    this.saveChapter,
    this.deleteChapter,
    this.loadVolumes,
    this.createVolume,
    this.loadOutlines,
    this.saveOutline,
    this.deleteOutline,
    this.loadCharacters,
    this.saveCharacter,
    this.deleteCharacter,
    this.loadForeshadowings,
    this.saveForeshadowing,
    this.deleteForeshadowing,
    this.recordRecentChapter,
    this.onOpenSettings,
  });

  final NovelSummary novel;
  final List<String> assistantModels;
  final AppAiSettings aiSettings;
  final VoidCallback onBack;
  final VoidCallback onToggleTheme;
  final NovelChapterLoader? loadChapters;
  final NovelChapterSaver? saveChapter;
  final NovelChapterDeleter? deleteChapter;
  final NovelVolumeLoader? loadVolumes;
  final NovelVolumeCreator? createVolume;
  final NovelOutlineLoader? loadOutlines;
  final NovelOutlineSaver? saveOutline;
  final NovelOutlineDeleter? deleteOutline;
  final NovelCharacterLoader? loadCharacters;
  final NovelCharacterSaver? saveCharacter;
  final NovelCharacterDeleter? deleteCharacter;
  final NovelForeshadowingLoader? loadForeshadowings;
  final NovelForeshadowingSaver? saveForeshadowing;
  final NovelForeshadowingDeleter? deleteForeshadowing;
  final RecentChapterRecorder? recordRecentChapter;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return _ProjectOverviewShell(
      novel: novel,
      assistantModels: assistantModels,
      aiSettings: aiSettings,
      onBack: onBack,
      onToggleTheme: onToggleTheme,
      loadChapters: loadChapters,
      saveChapter: saveChapter,
      deleteChapter: deleteChapter,
      loadVolumes: loadVolumes,
      createVolume: createVolume,
      loadOutlines: loadOutlines,
      saveOutline: saveOutline,
      deleteOutline: deleteOutline,
      loadCharacters: loadCharacters,
      saveCharacter: saveCharacter,
      deleteCharacter: deleteCharacter,
      loadForeshadowings: loadForeshadowings,
      saveForeshadowing: saveForeshadowing,
      deleteForeshadowing: deleteForeshadowing,
      recordRecentChapter: recordRecentChapter,
      onOpenSettings: onOpenSettings,
    );
  }
}

enum _AssistantPanelMode { docked, expanded, collapsed }

enum _ProjectWorkspace {
  overview,
  relationships,
  chapters,
  outline,
  characters,
  foreshadowing,
  settings,
  map,
  factions,
  creatures,
  items,
  skills,
  assets,
  chat,
  roundtable,
  monologue,
  theatre,
  roleplay,
  agentRules,
  agentSkills,
}

extension on _ProjectWorkspace {
  String get label {
    switch (this) {
      case _ProjectWorkspace.overview:
        return '概览';
      case _ProjectWorkspace.relationships:
        return '实体关系图';
      case _ProjectWorkspace.chapters:
        return '章节';
      case _ProjectWorkspace.outline:
        return '大纲';
      case _ProjectWorkspace.characters:
        return '人物';
      case _ProjectWorkspace.foreshadowing:
        return '伏笔';
      case _ProjectWorkspace.settings:
        return '设定';
      case _ProjectWorkspace.map:
        return '地图';
      case _ProjectWorkspace.factions:
        return '势力';
      case _ProjectWorkspace.creatures:
        return '生物';
      case _ProjectWorkspace.items:
        return '物品';
      case _ProjectWorkspace.skills:
        return '技能';
      case _ProjectWorkspace.assets:
        return '素材';
      case _ProjectWorkspace.chat:
        return '聊天';
      case _ProjectWorkspace.roundtable:
        return '圆桌会议';
      case _ProjectWorkspace.monologue:
        return '独白';
      case _ProjectWorkspace.theatre:
        return '小剧场';
      case _ProjectWorkspace.roleplay:
        return '角色扮演';
      case _ProjectWorkspace.agentRules:
        return '智能体规则';
      case _ProjectWorkspace.agentSkills:
        return '智能体技能';
    }
  }
}

const _worldSettingKind = 'world_setting';
const _worldSettingDefaultCategory = '未分类';
const _mapWorldKind = 'map_world';
const _mapLocationKind = 'map_location';
const _factionKind = 'faction';
const _creatureKind = 'creature';
const _itemKind = 'item';
const _skillKind = 'skill';
const _accessOpen = 'open';
const _mapDefaultLocationType = '区域';
const _mapLocationTypes = [
  '通用',
  '世界',
  '大陆',
  '国家',
  '区域',
  '山脉',
  '平原',
  '森林',
  '城镇',
  '村镇',
  '建筑',
  '房间',
  '地标',
  '自定义',
  '自然景观',
];
const _projectDropdownMaxVisibleItems = 4.0;
const _projectDropdownItemHeight = kMinInteractiveDimension;
const _projectDropdownMenuMaxHeight =
    _projectDropdownMaxVisibleItems * _projectDropdownItemHeight;

bool _isWorldSetting(NovelOutline outline) {
  final value = _outlineMetadata(outline);
  return value['kind'] == _worldSettingKind;
}

bool _isMapWorld(NovelOutline outline) {
  final value = _outlineMetadata(outline);
  return value['kind'] == _mapWorldKind;
}

bool _isMapLocation(NovelOutline outline) {
  final value = _outlineMetadata(outline);
  return value['kind'] == _mapLocationKind;
}

bool _isFaction(NovelOutline outline) {
  final value = _outlineMetadata(outline);
  return value['kind'] == _factionKind;
}

bool _isCreature(NovelOutline outline) {
  final value = _outlineMetadata(outline);
  return value['kind'] == _creatureKind;
}

bool _isItem(NovelOutline outline) {
  final value = _outlineMetadata(outline);
  return value['kind'] == _itemKind;
}

bool _isSkill(NovelOutline outline) {
  final value = _outlineMetadata(outline);
  return value['kind'] == _skillKind;
}

Map<String, Object?> _outlineMetadata(NovelOutline outline) {
  try {
    final value = jsonDecode(outline.beatsJson);
    if (value is Map) {
      return {
        for (final entry in value.entries)
          if (entry.key is String) entry.key as String: entry.value,
      };
    }
  } catch (_) {
    return const {};
  }
  return const {};
}

String _cleanWorldSettingCategory(String value) {
  final category = value.trim();
  return category.isEmpty ? _worldSettingDefaultCategory : category;
}

String _worldSettingMetadata(String category) {
  return jsonEncode({
    'kind': _worldSettingKind,
    'category': _cleanWorldSettingCategory(category),
  });
}

String _mapWorldMetadata() {
  return jsonEncode({'kind': _mapWorldKind});
}

String _factionMetadata({
  String readAccess = _accessOpen,
  String writeAccess = _accessOpen,
}) {
  return jsonEncode({
    'kind': _factionKind,
    'readAccess': readAccess,
    'writeAccess': writeAccess,
  });
}

String _creatureMetadata({
  String readAccess = _accessOpen,
  String writeAccess = _accessOpen,
}) {
  return jsonEncode({
    'kind': _creatureKind,
    'readAccess': readAccess,
    'writeAccess': writeAccess,
  });
}

String _itemMetadata({
  String readAccess = _accessOpen,
  String writeAccess = _accessOpen,
  List<String> photoPaths = const [],
}) {
  return jsonEncode({
    'kind': _itemKind,
    'readAccess': readAccess,
    'writeAccess': writeAccess,
    'photoPaths': photoPaths,
  });
}

String _skillMetadata({
  String readAccess = _accessOpen,
  String writeAccess = _accessOpen,
}) {
  return jsonEncode({
    'kind': _skillKind,
    'readAccess': readAccess,
    'writeAccess': writeAccess,
  });
}

String _outlineAccess(NovelOutline outline, String key) {
  final value = _outlineMetadata(outline)[key];
  return value is String && value.trim().isNotEmpty
      ? value.trim()
      : _accessOpen;
}

List<String> _outlinePhotoPaths(NovelOutline outline) {
  final value = _outlineMetadata(outline)['photoPaths'];
  if (value is List) {
    return [
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item,
    ];
  }
  return const [];
}

String _mapLocationMetadata({
  required int worldId,
  required int parentId,
  required String type,
}) {
  return jsonEncode({
    'kind': _mapLocationKind,
    'worldId': worldId,
    'parentId': parentId,
    'type': _cleanMapLocationType(type),
  });
}

int? _mapLocationWorldId(NovelOutline outline) {
  final value = _outlineMetadata(outline)['worldId'];
  return value is int ? value : null;
}

int? _mapLocationParentId(NovelOutline outline) {
  final value = _outlineMetadata(outline)['parentId'];
  return value is int ? value : null;
}

String _mapLocationType(NovelOutline outline) {
  final value = _outlineMetadata(outline)['type'];
  return _cleanMapLocationType(value is String ? value : outline.status);
}

String _cleanMapLocationType(String value) {
  final type = value.trim();
  return type.isEmpty ? _mapDefaultLocationType : type;
}

List<NovelOutline> _upsertOutline(
  List<NovelOutline> outlines,
  NovelOutline outline,
) {
  final index = outlines.indexWhere((item) => item.id == outline.id);
  if (index < 0) {
    return [...outlines, outline];
  }
  return [
    for (final item in outlines)
      if (item.id == outline.id) outline else item,
  ];
}

NovelOutline? _selectedWorldSettingFrom(List<NovelOutline> outlines) {
  for (final outline in outlines) {
    if (_isWorldSetting(outline)) {
      return outline;
    }
  }
  return null;
}

NovelOutline? _firstMapWorld(List<NovelOutline> outlines) {
  for (final outline in outlines) {
    if (_isMapWorld(outline)) {
      return outline;
    }
  }
  return null;
}

NovelOutline? _selectedMapWorldFrom(List<NovelOutline> outlines) {
  return _firstMapWorld(outlines);
}

NovelOutline? _selectedFactionFrom(List<NovelOutline> outlines) {
  for (final outline in outlines) {
    if (_isFaction(outline)) {
      return outline;
    }
  }
  return null;
}

NovelOutline? _selectedCreatureFrom(List<NovelOutline> outlines) {
  for (final outline in outlines) {
    if (_isCreature(outline)) {
      return outline;
    }
  }
  return null;
}

NovelOutline? _selectedItemFrom(List<NovelOutline> outlines) {
  for (final outline in outlines) {
    if (_isItem(outline)) {
      return outline;
    }
  }
  return null;
}

NovelOutline? _selectedSkillFrom(List<NovelOutline> outlines) {
  for (final outline in outlines) {
    if (_isSkill(outline)) {
      return outline;
    }
  }
  return null;
}

NovelOutline? _firstMapLocation(
  List<NovelOutline> outlines,
  NovelOutline? world,
) {
  if (world == null) {
    return null;
  }
  for (final outline in outlines) {
    if (_isMapLocation(outline) && _mapLocationWorldId(outline) == world.id) {
      return outline;
    }
  }
  return null;
}

const _worldSettingFileTypes = [
  XTypeGroup(
    label: '文档',
    extensions: ['txt', 'md', 'markdown', 'json', 'yaml', 'yml'],
  ),
];

class _ProjectOverviewShell extends StatefulWidget {
  const _ProjectOverviewShell({
    required this.novel,
    required this.assistantModels,
    required this.aiSettings,
    required this.onBack,
    required this.onToggleTheme,
    this.loadChapters,
    this.saveChapter,
    this.deleteChapter,
    this.loadVolumes,
    this.createVolume,
    this.loadOutlines,
    this.saveOutline,
    this.deleteOutline,
    this.loadCharacters,
    this.saveCharacter,
    this.deleteCharacter,
    this.loadForeshadowings,
    this.saveForeshadowing,
    this.deleteForeshadowing,
    this.recordRecentChapter,
    this.onOpenSettings,
  });

  final NovelSummary novel;
  final List<String> assistantModels;
  final AppAiSettings aiSettings;
  final VoidCallback onBack;
  final VoidCallback onToggleTheme;
  final NovelChapterLoader? loadChapters;
  final NovelChapterSaver? saveChapter;
  final NovelChapterDeleter? deleteChapter;
  final NovelVolumeLoader? loadVolumes;
  final NovelVolumeCreator? createVolume;
  final NovelOutlineLoader? loadOutlines;
  final NovelOutlineSaver? saveOutline;
  final NovelOutlineDeleter? deleteOutline;
  final NovelCharacterLoader? loadCharacters;
  final NovelCharacterSaver? saveCharacter;
  final NovelCharacterDeleter? deleteCharacter;
  final NovelForeshadowingLoader? loadForeshadowings;
  final NovelForeshadowingSaver? saveForeshadowing;
  final NovelForeshadowingDeleter? deleteForeshadowing;
  final RecentChapterRecorder? recordRecentChapter;
  final VoidCallback? onOpenSettings;

  @override
  State<_ProjectOverviewShell> createState() => _ProjectOverviewShellState();
}

class _ProjectOverviewShellState extends State<_ProjectOverviewShell> {
  var _assistantMode = _AssistantPanelMode.docked;
  var _workspace = _ProjectWorkspace.overview;
  var _chapters = <NovelChapter>[];
  var _outlines = <NovelOutline>[];
  var _characters = <NovelCharacter>[];
  var _foreshadowings = <NovelForeshadowing>[];
  NovelChapter? _selectedChapter;
  NovelOutline? _selectedOutline;
  NovelOutline? _selectedWorldSetting;
  NovelOutline? _selectedMapWorld;
  NovelOutline? _selectedMapLocation;
  NovelOutline? _selectedFaction;
  NovelOutline? _selectedCreature;
  NovelOutline? _selectedItem;
  NovelOutline? _selectedSkill;
  NovelCharacter? _selectedCharacter;
  NovelForeshadowing? _selectedForeshadowing;
  String? _assistantContextLabel;
  String? _assistantDraftText;
  var _assistantDraftRevision = 0;
  bool _chaptersLoading = true;
  bool _outlinesLoading = true;
  bool _charactersLoading = true;
  bool _foreshadowingsLoading = true;
  String? _chapterError;
  String? _outlineError;
  String? _characterError;
  String? _foreshadowingError;

  int get _selectedChapterNumber {
    final selected = _selectedChapter;
    if (selected == null) {
      return _chapters.length + 1;
    }
    final index = _chapters.indexWhere((chapter) => chapter.id == selected.id);
    return index < 0 ? _chapters.length : index + 1;
  }

  List<NovelOutline> get _outlineItems => [
        for (final outline in _outlines)
          if (!_isWorldSetting(outline) &&
              !_isMapWorld(outline) &&
              !_isMapLocation(outline) &&
              !_isFaction(outline) &&
              !_isCreature(outline) &&
              !_isItem(outline) &&
              !_isSkill(outline))
            outline,
      ];

  List<NovelOutline> get _worldSettings => [
        for (final outline in _outlines)
          if (_isWorldSetting(outline)) outline,
      ];

  List<NovelOutline> get _mapWorlds => [
        for (final outline in _outlines)
          if (_isMapWorld(outline)) outline,
      ];

  List<NovelOutline> get _mapLocations => [
        for (final outline in _outlines)
          if (_isMapLocation(outline)) outline,
      ];

  List<NovelOutline> get _factions => [
        for (final outline in _outlines)
          if (_isFaction(outline)) outline,
      ];

  List<NovelOutline> get _creatures => [
        for (final outline in _outlines)
          if (_isCreature(outline)) outline,
      ];

  List<NovelOutline> get _items => [
        for (final outline in _outlines)
          if (_isItem(outline)) outline,
      ];

  List<NovelOutline> get _skills => [
        for (final outline in _outlines)
          if (_isSkill(outline)) outline,
      ];

  List<NovelOutline> get _selectedMapLocations {
    final world = _selectedMapWorld;
    if (world == null) {
      return const [];
    }
    return [
      for (final location in _mapLocations)
        if (_mapLocationWorldId(location) == world.id) location,
    ];
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadChapters());
    unawaited(_loadOutlines());
    unawaited(_loadCharacters());
    unawaited(_loadForeshadowings());
  }

  @override
  void didUpdateWidget(covariant _ProjectOverviewShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.novel.id != widget.novel.id) {
      unawaited(_loadChapters());
      unawaited(_loadOutlines());
      unawaited(_loadCharacters());
      unawaited(_loadForeshadowings());
    }
  }

  Future<void> _loadChapters() async {
    final loader = widget.loadChapters;
    if (loader == null) {
      setState(() {
        _chapters = const [];
        _selectedChapter = null;
        _chaptersLoading = false;
        _chapterError = null;
      });
      return;
    }

    setState(() {
      _chaptersLoading = true;
      _chapterError = null;
    });
    try {
      final chapters = await loader(widget.novel.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _chapters = chapters;
        _selectedChapter = chapters.isEmpty ? null : chapters.last;
        _chaptersLoading = false;
      });
      final selected = _selectedChapter;
      if (selected != null) {
        unawaited(
            widget.recordRecentChapter?.call(widget.novel.id, selected.id));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _chaptersLoading = false;
        _chapterError = error.toString();
      });
    }
  }

  Future<void> _loadOutlines() async {
    final loader = widget.loadOutlines;
    if (loader == null) {
      setState(() {
        _outlines = const [];
        _selectedOutline = null;
        _outlinesLoading = false;
        _outlineError = null;
      });
      return;
    }

    setState(() {
      _outlinesLoading = true;
      _outlineError = null;
    });
    try {
      final outlines = await loader(widget.novel.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _outlines = outlines;
        _selectedOutline = _outlineItems.isEmpty ? null : _selectedOutline;
        _selectedWorldSetting = _selectedWorldSettingFrom(outlines);
        _selectedMapWorld = _selectedMapWorldFrom(outlines);
        _selectedMapLocation = _firstMapLocation(outlines, _selectedMapWorld);
        _selectedFaction = _selectedFactionFrom(outlines);
        _selectedCreature = _selectedCreatureFrom(outlines);
        _selectedItem = _selectedItemFrom(outlines);
        _selectedSkill = _selectedSkillFrom(outlines);
        _outlinesLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _outlinesLoading = false;
        _outlineError = error.toString();
      });
    }
  }

  Future<void> _loadCharacters() async {
    final loader = widget.loadCharacters;
    if (loader == null) {
      setState(() {
        _characters = const [];
        _selectedCharacter = null;
        _charactersLoading = false;
        _characterError = null;
      });
      return;
    }

    setState(() {
      _charactersLoading = true;
      _characterError = null;
    });
    try {
      final characters = await loader(widget.novel.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _characters = characters;
        _selectedCharacter = characters.isEmpty ? null : characters.first;
        _charactersLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _charactersLoading = false;
        _characterError = error.toString();
      });
    }
  }

  Future<void> _loadForeshadowings() async {
    final loader = widget.loadForeshadowings;
    if (loader == null) {
      setState(() {
        _foreshadowings = const [];
        _selectedForeshadowing = null;
        _foreshadowingsLoading = false;
        _foreshadowingError = null;
      });
      return;
    }

    setState(() {
      _foreshadowingsLoading = true;
      _foreshadowingError = null;
    });
    try {
      final foreshadowings = await loader(widget.novel.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _foreshadowings = foreshadowings;
        _selectedForeshadowing =
            foreshadowings.isEmpty ? null : foreshadowings.first;
        _foreshadowingsLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _foreshadowingsLoading = false;
        _foreshadowingError = error.toString();
      });
    }
  }

  void _selectChapter(NovelChapter chapter) {
    setState(() => _selectedChapter = chapter);
    unawaited(widget.recordRecentChapter?.call(widget.novel.id, chapter.id));
  }

  void _selectOutline(NovelOutline outline) {
    setState(() => _selectedOutline = outline);
  }

  void _selectWorldSetting(NovelOutline setting) {
    setState(() => _selectedWorldSetting = setting);
  }

  void _selectMapWorld(NovelOutline world) {
    setState(() {
      _selectedMapWorld = world;
      _selectedMapLocation = _firstMapLocation(_outlines, world);
    });
  }

  void _selectMapLocation(NovelOutline location) {
    setState(() => _selectedMapLocation = location);
  }

  void _selectFaction(NovelOutline faction) {
    setState(() => _selectedFaction = faction);
  }

  void _selectCreature(NovelOutline creature) {
    setState(() => _selectedCreature = creature);
  }

  void _selectItem(NovelOutline item) {
    setState(() => _selectedItem = item);
  }

  void _selectSkill(NovelOutline skill) {
    setState(() => _selectedSkill = skill);
  }

  void _selectGlobalOutline() {
    setState(() => _selectedOutline = null);
  }

  void _selectCharacter(NovelCharacter character) {
    setState(() => _selectedCharacter = character);
  }

  void _selectForeshadowing(NovelForeshadowing foreshadowing) {
    setState(() => _selectedForeshadowing = foreshadowing);
  }

  Future<void> _startNewCharacter() async {
    setState(() => _selectedCharacter = null);
    await _saveCharacter(
      name: '未命名',
      role: '主角',
      gender: '未知',
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
    );
  }

  Future<void> _startNewOutline() async {
    setState(() => _selectedOutline = null);
    await _saveOutline(
      title: '未命名',
      status: '待开始',
      content: '',
      beatsJson: '[]',
    );
  }

  Future<void> _startNewWorldSetting({String? category}) async {
    setState(() => _selectedWorldSetting = null);
    await _saveWorldSetting(
      title: '未命名设定',
      category: category ?? _worldSettingDefaultCategory,
      content: '',
      photoPaths: const [],
    );
  }

  Future<void> _importWorldSettingFile() async {
    final file = await openFile(acceptedTypeGroups: _worldSettingFileTypes);
    if (file == null) {
      return;
    }
    final content = await File(file.path).readAsString();
    await _saveWorldSetting(
      title: file.name,
      category: '导入文件',
      content: content,
      photoPaths: const [],
    );
  }

  Future<void> _startNewMapWorld() async {
    final draft = await _showMapWorldDialog(context);
    if (draft == null) {
      return;
    }
    await _saveMapWorld(
      title: draft.title,
      description: draft.description,
    );
  }

  Future<void> _editMapWorld(NovelOutline world) async {
    final draft = await _showMapWorldDialog(context, world: world);
    if (draft == null) {
      return;
    }
    await _saveMapWorld(
      world: world,
      title: draft.title,
      description: draft.description,
    );
  }

  Future<void> _startNewMapLocation() async {
    final world = _selectedMapWorld;
    if (world == null) {
      return;
    }
    final draft = await _showMapLocationDialog(
      context,
      world: world,
      locations: _selectedMapLocations,
    );
    if (draft == null) {
      return;
    }
    await _saveMapLocation(world: world, draft: draft);
  }

  Future<void> _editMapLocation(NovelOutline location) async {
    final world = _selectedMapWorld;
    if (world == null) {
      return;
    }
    final draft = await _showMapLocationDialog(
      context,
      world: world,
      locations: _selectedMapLocations,
      location: location,
    );
    if (draft == null) {
      return;
    }
    await _saveMapLocation(world: world, location: location, draft: draft);
  }

  Future<void> _startNewFaction() async {
    setState(() => _selectedFaction = null);
    await _saveFaction(
      title: '未命名势力',
      category: '',
      content: '',
      photoPaths: const [],
    );
  }

  Future<void> _startNewCreature() async {
    setState(() => _selectedCreature = null);
    await _saveCreature(
      title: '未命名生物',
      category: '',
      content: '',
      photoPaths: const [],
    );
  }

  Future<void> _startNewItem() async {
    setState(() => _selectedItem = null);
    await _saveItem(
      title: '未命名物品',
      category: '',
      content: '',
      photoPaths: const [],
    );
  }

  Future<void> _startNewSkill() async {
    setState(() => _selectedSkill = null);
    await _saveSkill(
      title: '未命名技能',
      category: '',
      content: '',
      photoPaths: const [],
    );
  }

  Future<void> _startNewForeshadowing() async {
    setState(() => _selectedForeshadowing = null);
    await _saveForeshadowing(
      title: '未命名伏笔',
      status: _foreshadowingStatuses[1],
      setupContent: '',
      payoffContent: '',
    );
  }

  Future<void> _startNewChapter() async {
    final number = _chapters.length + 1;
    setState(() => _selectedChapter = null);
    await _saveChapter(
      title: '第$number章',
      outline: '',
      content: '',
    );
  }

  void _generateChapterOutlineFromBeat(String outlineTitle, _OutlineBeat beat) {
    final title = outlineTitle.trim().isEmpty ? '未命名' : outlineTitle.trim();
    setState(() {
      _assistantContextLabel = title;
      _assistantDraftText = '请根据当前选中的节拍和所属大纲，生成这个节拍覆盖的所有章节大纲。';
      _assistantDraftRevision += 1;
      _assistantMode = _AssistantPanelMode.docked;
    });
  }

  void _selectWorkspace(_ProjectWorkspace workspace) {
    if (_workspace == workspace) {
      return;
    }
    setState(() {
      _workspace = workspace;
      if (workspace == _ProjectWorkspace.outline) {
        _selectedOutline = null;
      }
    });
  }

  Future<NovelOutline> _saveOutline({
    required String title,
    required String status,
    required String content,
    required String beatsJson,
  }) async {
    final saver = widget.saveOutline;
    if (saver == null) {
      final outline = NovelOutline(
        id: _selectedOutline?.id ?? -1,
        novelId: widget.novel.id,
        title: title.trim().isEmpty ? '未命名' : title.trim(),
        status: status.trim().isEmpty ? '待开始' : status.trim(),
        content: content,
        beatsJson: beatsJson,
        updatedAt: DateTime.now(),
      );
      setState(() {
        final index = _outlines.indexWhere((item) => item.id == outline.id);
        if (index < 0) {
          _outlines = [..._outlines, outline];
        } else {
          _outlines = [
            for (final item in _outlines)
              if (item.id == outline.id) outline else item,
          ];
        }
        _selectedOutline = outline;
      });
      return outline;
    }

    final saved = await saver(
      novelId: widget.novel.id,
      outlineId: _selectedOutline?.id,
      title: title,
      status: status,
      content: content,
      beatsJson: beatsJson,
    );
    if (!mounted) {
      return saved;
    }
    setState(() {
      final index = _outlines.indexWhere((outline) => outline.id == saved.id);
      if (index < 0) {
        _outlines = [..._outlines, saved];
      } else {
        _outlines = [
          for (final outline in _outlines)
            if (outline.id == saved.id) saved else outline,
        ];
      }
      _selectedOutline = saved;
    });
    return saved;
  }

  Future<NovelOutline> _saveWorldSetting({
    required String title,
    required String category,
    required String content,
    required List<String> photoPaths,
  }) async {
    final cleanCategory = _cleanWorldSettingCategory(category);
    final saver = widget.saveOutline;
    if (saver == null) {
      final setting = NovelOutline(
        id: _selectedWorldSetting?.id ?? -(_worldSettings.length + 1),
        novelId: widget.novel.id,
        title: title.trim().isEmpty ? '未命名设定' : title.trim(),
        status: cleanCategory,
        content: content,
        beatsJson: _worldSettingMetadata(cleanCategory),
        updatedAt: DateTime.now(),
      );
      setState(() {
        _outlines = _upsertOutline(_outlines, setting);
        _selectedWorldSetting = setting;
      });
      return setting;
    }

    final saved = await saver(
      novelId: widget.novel.id,
      outlineId: _selectedWorldSetting?.id,
      title: title,
      status: cleanCategory,
      content: content,
      beatsJson: _worldSettingMetadata(cleanCategory),
    );
    if (!mounted) {
      return saved;
    }
    setState(() {
      _outlines = _upsertOutline(_outlines, saved);
      _selectedWorldSetting = saved;
    });
    return saved;
  }

  Future<NovelOutline> _saveMapWorld({
    NovelOutline? world,
    required String title,
    required String description,
  }) async {
    final saver = widget.saveOutline;
    if (saver == null) {
      final saved = NovelOutline(
        id: world?.id ?? -(_mapWorlds.length + 1),
        novelId: widget.novel.id,
        title: title.trim().isEmpty ? '未命名世界' : title.trim(),
        status: '世界',
        content: description,
        beatsJson: _mapWorldMetadata(),
        updatedAt: DateTime.now(),
      );
      setState(() {
        _outlines = _upsertOutline(_outlines, saved);
        _selectedMapWorld = saved;
        _selectedMapLocation = _firstMapLocation(_outlines, saved);
      });
      return saved;
    }

    final saved = await saver(
      novelId: widget.novel.id,
      outlineId: world?.id,
      title: title,
      status: '世界',
      content: description,
      beatsJson: _mapWorldMetadata(),
    );
    if (!mounted) {
      return saved;
    }
    setState(() {
      _outlines = _upsertOutline(_outlines, saved);
      _selectedMapWorld = saved;
      _selectedMapLocation = _firstMapLocation(_outlines, saved);
    });
    return saved;
  }

  Future<NovelOutline> _saveMapLocation({
    required NovelOutline world,
    NovelOutline? location,
    required _MapLocationDraft draft,
  }) async {
    final type = _cleanMapLocationType(draft.type);
    final parentId = draft.parentId ?? world.id;
    final saver = widget.saveOutline;
    if (saver == null) {
      final saved = NovelOutline(
        id: location?.id ?? -(_mapLocations.length + 1001),
        novelId: widget.novel.id,
        title: draft.title.trim().isEmpty ? '未命名地点' : draft.title.trim(),
        status: type,
        content: draft.description,
        beatsJson: _mapLocationMetadata(
          worldId: world.id,
          parentId: parentId,
          type: type,
        ),
        updatedAt: DateTime.now(),
      );
      setState(() {
        _outlines = _upsertOutline(_outlines, saved);
        _selectedMapLocation = saved;
      });
      return saved;
    }

    final saved = await saver(
      novelId: widget.novel.id,
      outlineId: location?.id,
      title: draft.title,
      status: type,
      content: draft.description,
      beatsJson: _mapLocationMetadata(
        worldId: world.id,
        parentId: parentId,
        type: type,
      ),
    );
    if (!mounted) {
      return saved;
    }
    setState(() {
      _outlines = _upsertOutline(_outlines, saved);
      _selectedMapLocation = saved;
    });
    return saved;
  }

  Future<NovelOutline> _saveFaction({
    NovelOutline? faction,
    required String title,
    required String category,
    required String content,
    required List<String> photoPaths,
    String? readAccess,
    String? writeAccess,
  }) async {
    final current = faction ?? _selectedFaction;
    final saver = widget.saveOutline;
    final savedReadAccess = readAccess ??
        (current == null ? _accessOpen : _outlineAccess(current, 'readAccess'));
    final savedWriteAccess = writeAccess ??
        (current == null
            ? _accessOpen
            : _outlineAccess(current, 'writeAccess'));
    if (saver == null) {
      final saved = NovelOutline(
        id: current?.id ?? -(_factions.length + 2001),
        novelId: widget.novel.id,
        title: title.trim().isEmpty ? '未命名势力' : title.trim(),
        status: category.trim(),
        content: content,
        beatsJson: _factionMetadata(
          readAccess: savedReadAccess,
          writeAccess: savedWriteAccess,
        ),
        updatedAt: DateTime.now(),
      );
      setState(() {
        _outlines = _upsertOutline(_outlines, saved);
        _selectedFaction = saved;
      });
      return saved;
    }

    final saved = await saver(
      novelId: widget.novel.id,
      outlineId: current?.id,
      title: title,
      status: category,
      content: content,
      beatsJson: _factionMetadata(
        readAccess: savedReadAccess,
        writeAccess: savedWriteAccess,
      ),
    );
    if (!mounted) {
      return saved;
    }
    setState(() {
      _outlines = _upsertOutline(_outlines, saved);
      _selectedFaction = saved;
    });
    return saved;
  }

  Future<NovelOutline> _saveCreature({
    NovelOutline? creature,
    required String title,
    required String category,
    required String content,
    required List<String> photoPaths,
    String? readAccess,
    String? writeAccess,
  }) async {
    final current = creature ?? _selectedCreature;
    final saver = widget.saveOutline;
    final savedReadAccess = readAccess ??
        (current == null ? _accessOpen : _outlineAccess(current, 'readAccess'));
    final savedWriteAccess = writeAccess ??
        (current == null
            ? _accessOpen
            : _outlineAccess(current, 'writeAccess'));
    if (saver == null) {
      final saved = NovelOutline(
        id: current?.id ?? -(_creatures.length + 3001),
        novelId: widget.novel.id,
        title: title.trim().isEmpty ? '未命名生物' : title.trim(),
        status: category.trim(),
        content: content,
        beatsJson: _creatureMetadata(
          readAccess: savedReadAccess,
          writeAccess: savedWriteAccess,
        ),
        updatedAt: DateTime.now(),
      );
      setState(() {
        _outlines = _upsertOutline(_outlines, saved);
        _selectedCreature = saved;
      });
      return saved;
    }

    final saved = await saver(
      novelId: widget.novel.id,
      outlineId: current?.id,
      title: title,
      status: category,
      content: content,
      beatsJson: _creatureMetadata(
        readAccess: savedReadAccess,
        writeAccess: savedWriteAccess,
      ),
    );
    if (!mounted) {
      return saved;
    }
    setState(() {
      _outlines = _upsertOutline(_outlines, saved);
      _selectedCreature = saved;
    });
    return saved;
  }

  Future<NovelOutline> _saveItem({
    NovelOutline? item,
    required String title,
    required String category,
    required String content,
    required List<String> photoPaths,
    String? readAccess,
    String? writeAccess,
  }) async {
    final current = item ?? _selectedItem;
    final saver = widget.saveOutline;
    final savedReadAccess = readAccess ??
        (current == null ? _accessOpen : _outlineAccess(current, 'readAccess'));
    final savedWriteAccess = writeAccess ??
        (current == null
            ? _accessOpen
            : _outlineAccess(current, 'writeAccess'));
    if (saver == null) {
      final saved = NovelOutline(
        id: current?.id ?? -(_items.length + 4001),
        novelId: widget.novel.id,
        title: title.trim().isEmpty ? '未命名物品' : title.trim(),
        status: category.trim(),
        content: content,
        beatsJson: _itemMetadata(
          readAccess: savedReadAccess,
          writeAccess: savedWriteAccess,
          photoPaths: photoPaths,
        ),
        updatedAt: DateTime.now(),
      );
      setState(() {
        _outlines = _upsertOutline(_outlines, saved);
        _selectedItem = saved;
      });
      return saved;
    }

    final saved = await saver(
      novelId: widget.novel.id,
      outlineId: current?.id,
      title: title,
      status: category,
      content: content,
      beatsJson: _itemMetadata(
        readAccess: savedReadAccess,
        writeAccess: savedWriteAccess,
        photoPaths: photoPaths,
      ),
    );
    if (!mounted) {
      return saved;
    }
    setState(() {
      _outlines = _upsertOutline(_outlines, saved);
      _selectedItem = saved;
    });
    return saved;
  }

  Future<NovelOutline> _saveSkill({
    NovelOutline? skill,
    required String title,
    required String category,
    required String content,
    required List<String> photoPaths,
    String? readAccess,
    String? writeAccess,
  }) async {
    final current = skill ?? _selectedSkill;
    final saver = widget.saveOutline;
    final savedReadAccess = readAccess ??
        (current == null ? _accessOpen : _outlineAccess(current, 'readAccess'));
    final savedWriteAccess = writeAccess ??
        (current == null
            ? _accessOpen
            : _outlineAccess(current, 'writeAccess'));
    if (saver == null) {
      final saved = NovelOutline(
        id: current?.id ?? -(_skills.length + 5001),
        novelId: widget.novel.id,
        title: title.trim().isEmpty ? '未命名技能' : title.trim(),
        status: category.trim(),
        content: content,
        beatsJson: _skillMetadata(
          readAccess: savedReadAccess,
          writeAccess: savedWriteAccess,
        ),
        updatedAt: DateTime.now(),
      );
      setState(() {
        _outlines = _upsertOutline(_outlines, saved);
        _selectedSkill = saved;
      });
      return saved;
    }

    final saved = await saver(
      novelId: widget.novel.id,
      outlineId: current?.id,
      title: title,
      status: category,
      content: content,
      beatsJson: _skillMetadata(
        readAccess: savedReadAccess,
        writeAccess: savedWriteAccess,
      ),
    );
    if (!mounted) {
      return saved;
    }
    setState(() {
      _outlines = _upsertOutline(_outlines, saved);
      _selectedSkill = saved;
    });
    return saved;
  }

  Future<void> _deleteOutlineRecord(NovelOutline outline) async {
    final deleter = widget.deleteOutline;
    if (deleter != null && outline.id > 0) {
      await deleter(widget.novel.id, outline.id);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _outlines = [
        for (final item in _outlines)
          if (item.id != outline.id) item,
      ];
    });
  }

  Future<void> _deleteMapWorld(NovelOutline world) async {
    final children = [
      for (final location in _mapLocations)
        if (_mapLocationWorldId(location) == world.id) location,
    ];
    for (final location in children) {
      await _deleteOutlineRecord(location);
    }
    await _deleteOutlineRecord(world);
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedMapWorld = _firstMapWorld(_outlines);
      _selectedMapLocation = _firstMapLocation(_outlines, _selectedMapWorld);
    });
  }

  Future<void> _deleteMapLocation(NovelOutline location) async {
    await _deleteOutlineRecord(location);
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedMapLocation = _firstMapLocation(_outlines, _selectedMapWorld);
    });
  }

  Future<void> _editFactionPermissions(NovelOutline faction) async {
    final draft = await _showFactionPermissionDialog(context, faction);
    if (draft == null) {
      return;
    }
    await _saveFaction(
      faction: faction,
      title: faction.title,
      category: faction.status,
      content: faction.content,
      photoPaths: const [],
      readAccess: draft.readAccess,
      writeAccess: draft.writeAccess,
    );
  }

  Future<void> _deleteFaction(NovelOutline faction) async {
    final confirmed = await _showDeleteFactionDialog(context, faction);
    if (confirmed != true) {
      return;
    }
    await _deleteOutlineRecord(faction);
    if (!mounted) {
      return;
    }
    setState(() => _selectedFaction = _selectedFactionFrom(_outlines));
  }

  Future<void> _editCreaturePermissions(NovelOutline creature) async {
    final draft = await _showFactionPermissionDialog(context, creature);
    if (draft == null) {
      return;
    }
    await _saveCreature(
      creature: creature,
      title: creature.title,
      category: creature.status,
      content: creature.content,
      photoPaths: const [],
      readAccess: draft.readAccess,
      writeAccess: draft.writeAccess,
    );
  }

  Future<void> _deleteCreature(NovelOutline creature) async {
    final confirmed = await _showDeleteFactionDialog(context, creature);
    if (confirmed != true) {
      return;
    }
    await _deleteOutlineRecord(creature);
    if (!mounted) {
      return;
    }
    setState(() => _selectedCreature = _selectedCreatureFrom(_outlines));
  }

  Future<void> _editItemPermissions(NovelOutline item) async {
    final draft = await _showFactionPermissionDialog(context, item);
    if (draft == null) {
      return;
    }
    await _saveItem(
      item: item,
      title: item.title,
      category: item.status,
      content: item.content,
      photoPaths: _outlinePhotoPaths(item),
      readAccess: draft.readAccess,
      writeAccess: draft.writeAccess,
    );
  }

  Future<void> _deleteItem(NovelOutline item) async {
    final confirmed = await _showDeleteFactionDialog(context, item);
    if (confirmed != true) {
      return;
    }
    await _deleteOutlineRecord(item);
    if (!mounted) {
      return;
    }
    setState(() => _selectedItem = _selectedItemFrom(_outlines));
  }

  Future<void> _editSkillPermissions(NovelOutline skill) async {
    final draft = await _showFactionPermissionDialog(context, skill);
    if (draft == null) {
      return;
    }
    await _saveSkill(
      skill: skill,
      title: skill.title,
      category: skill.status,
      content: skill.content,
      photoPaths: const [],
      readAccess: draft.readAccess,
      writeAccess: draft.writeAccess,
    );
  }

  Future<void> _deleteSkill(NovelOutline skill) async {
    final confirmed = await _showDeleteFactionDialog(context, skill);
    if (confirmed != true) {
      return;
    }
    await _deleteOutlineRecord(skill);
    if (!mounted) {
      return;
    }
    setState(() => _selectedSkill = _selectedSkillFrom(_outlines));
  }

  void _askAssistantForSkillName({
    required String title,
    required String category,
    required String content,
  }) {
    final cleanTitle = title.trim().isEmpty ? '未命名技能' : title.trim();
    setState(() {
      _assistantContextLabel = cleanTitle;
      _assistantDraftText = '请根据当前技能资料，为「$cleanTitle」生成 5 个简洁、可用于世界观设定的技能名称。';
      _assistantDraftRevision += 1;
      _assistantMode = _AssistantPanelMode.docked;
    });
  }

  Future<NovelChapter> _saveChapter({
    required String title,
    required String outline,
    required String content,
  }) async {
    final saver = widget.saveChapter;
    if (saver == null) {
      return NovelChapter(
        id: _selectedChapter?.id ?? -1,
        novelId: widget.novel.id,
        title: title.trim().isEmpty ? '章节标题' : title.trim(),
        outline: outline,
        content: content,
        wordCount: _countWritingUnits(content),
        updatedAt: DateTime.now(),
      );
    }

    final saved = await saver(
      novelId: widget.novel.id,
      chapterId: _selectedChapter?.id,
      title: title,
      outline: outline,
      content: content,
    );
    if (!mounted) {
      return saved;
    }
    setState(() {
      final index = _chapters.indexWhere((chapter) => chapter.id == saved.id);
      if (index < 0) {
        _chapters = [..._chapters, saved];
      } else {
        _chapters = [
          ..._chapters.take(index),
          saved,
          ..._chapters.skip(index + 1),
        ];
      }
      _selectedChapter = saved;
    });
    return saved;
  }

  Future<NovelCharacter> _saveCharacter({
    required String name,
    required String role,
    required String gender,
    required String identity,
    required String age,
    required String motivation,
    required String arc,
    required String? avatarPath,
    required List<String> galleryPaths,
    required int? firstChapterId,
    required String biography,
    required String currentState,
    required List<NovelCharacterSkill> skills,
  }) async {
    final saver = widget.saveCharacter;
    if (saver == null) {
      final character = NovelCharacter(
        id: _selectedCharacter?.id ?? -1,
        novelId: widget.novel.id,
        name: name.trim().isEmpty ? '未命名' : name.trim(),
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
        updatedAt: DateTime.now(),
      );
      setState(() {
        final index = _characters.indexWhere((item) => item.id == character.id);
        if (index < 0) {
          _characters = [..._characters, character];
        } else {
          _characters = [
            for (final item in _characters)
              if (item.id == character.id) character else item,
          ];
        }
        _selectedCharacter = character;
      });
      return character;
    }

    final saved = await saver(
      novelId: widget.novel.id,
      characterId: _selectedCharacter?.id,
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
    );
    if (!mounted) {
      return saved;
    }
    setState(() {
      final index =
          _characters.indexWhere((character) => character.id == saved.id);
      if (index < 0) {
        _characters = [..._characters, saved];
      } else {
        _characters = [
          for (final character in _characters)
            if (character.id == saved.id) saved else character,
        ];
      }
      _selectedCharacter = saved;
    });
    return saved;
  }

  Future<NovelForeshadowing> _saveForeshadowing({
    required String title,
    required String status,
    required String setupContent,
    required String payoffContent,
  }) async {
    final saver = widget.saveForeshadowing;
    if (saver == null) {
      final foreshadowing = NovelForeshadowing(
        id: _selectedForeshadowing?.id ?? -1,
        novelId: widget.novel.id,
        title: title.trim().isEmpty ? '未命名伏笔' : title.trim(),
        status: status.trim().isEmpty ? _foreshadowingStatuses[1] : status,
        setupContent: setupContent,
        payoffContent: payoffContent,
        updatedAt: DateTime.now(),
      );
      setState(() {
        final index =
            _foreshadowings.indexWhere((item) => item.id == foreshadowing.id);
        if (index < 0) {
          _foreshadowings = [foreshadowing, ..._foreshadowings];
        } else {
          _foreshadowings = [
            for (final item in _foreshadowings)
              if (item.id == foreshadowing.id) foreshadowing else item,
          ];
        }
        _selectedForeshadowing = foreshadowing;
      });
      return foreshadowing;
    }

    final saved = await saver(
      novelId: widget.novel.id,
      foreshadowingId: _selectedForeshadowing?.id,
      title: title,
      status: status,
      setupContent: setupContent,
      payoffContent: payoffContent,
    );
    if (!mounted) {
      return saved;
    }
    setState(() {
      final index = _foreshadowings.indexWhere((item) => item.id == saved.id);
      if (index < 0) {
        _foreshadowings = [saved, ..._foreshadowings];
      } else {
        _foreshadowings = [
          for (final item in _foreshadowings)
            if (item.id == saved.id) saved else item,
        ];
      }
      _selectedForeshadowing = saved;
    });
    return saved;
  }

  Future<void> _deleteCharacter(NovelCharacter character) async {
    final deleter = widget.deleteCharacter;
    if (deleter != null) {
      await deleter(widget.novel.id, character.id);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      final index = _characters.indexWhere((item) => item.id == character.id);
      _characters = [
        for (final item in _characters)
          if (item.id != character.id) item,
      ];
      if (_selectedCharacter?.id == character.id) {
        if (_characters.isEmpty) {
          _selectedCharacter = null;
        } else {
          final nextIndex = index.clamp(0, _characters.length - 1);
          _selectedCharacter = _characters[nextIndex];
        }
      }
    });
  }

  Future<void> _deleteForeshadowing(NovelForeshadowing foreshadowing) async {
    final deleter = widget.deleteForeshadowing;
    if (deleter != null) {
      await deleter(widget.novel.id, foreshadowing.id);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      final index =
          _foreshadowings.indexWhere((item) => item.id == foreshadowing.id);
      _foreshadowings = [
        for (final item in _foreshadowings)
          if (item.id != foreshadowing.id) item,
      ];
      if (_selectedForeshadowing?.id == foreshadowing.id) {
        if (_foreshadowings.isEmpty) {
          _selectedForeshadowing = null;
        } else {
          final nextIndex = index.clamp(0, _foreshadowings.length - 1);
          _selectedForeshadowing = _foreshadowings[nextIndex];
        }
      }
    });
  }

  Future<void> _deleteChapter(NovelChapter chapter) async {
    final deleter = widget.deleteChapter;
    if (deleter != null) {
      await deleter(widget.novel.id, chapter.id);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      final index = _chapters.indexWhere((item) => item.id == chapter.id);
      _chapters = [
        for (final item in _chapters)
          if (item.id != chapter.id) item,
      ];
      if (_selectedChapter?.id == chapter.id) {
        if (_chapters.isEmpty) {
          _selectedChapter = null;
        } else {
          final nextIndex = index.clamp(0, _chapters.length - 1);
          _selectedChapter = _chapters[nextIndex];
        }
      }
    });
    final selected = _selectedChapter;
    if (selected != null) {
      unawaited(widget.recordRecentChapter?.call(widget.novel.id, selected.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final appearance = AppAppearanceScope.of(context);

    return Scaffold(
      backgroundColor: appearance.backgroundKind == AppBackgroundKind.none
          ? colors.background
          : Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showProjectRail = constraints.maxWidth >= 920;
          final canDockAssistant = constraints.maxWidth >= 1180;
          final expanded = _assistantMode == _AssistantPanelMode.expanded &&
              constraints.maxWidth >= 920;
          final showAssistant = expanded ||
              (_assistantMode == _AssistantPanelMode.docked &&
                  canDockAssistant);
          final collapsed = _assistantMode == _AssistantPanelMode.collapsed ||
              (!canDockAssistant && !expanded);

          return Row(
            children: [
              _ProjectSystemRail(
                activeWorkspace: _workspace,
                onWorkspaceChanged: _selectWorkspace,
              ),
              if (showProjectRail)
                if (_workspace == _ProjectWorkspace.overview ||
                    _workspace == _ProjectWorkspace.chapters)
                  _ProjectChapterRail(
                    novel: widget.novel,
                    chapters: _chapters,
                    selectedChapterId: _selectedChapter?.id,
                    loading: _chaptersLoading,
                    loadVolumes: widget.loadVolumes,
                    createVolume: widget.createVolume,
                    onBack: widget.onBack,
                    onSelectChapter: (chapter) {
                      _selectChapter(chapter);
                      _selectWorkspace(_ProjectWorkspace.chapters);
                    },
                    onAddChapter: () {
                      _selectWorkspace(_ProjectWorkspace.chapters);
                      unawaited(_startNewChapter());
                    },
                    onDeleteChapter: _deleteChapter,
                  )
                else if (_workspace == _ProjectWorkspace.outline)
                  _ProjectOutlineRail(
                    novel: widget.novel,
                    outlines: _outlineItems,
                    selectedOutlineId: _selectedOutline?.id,
                    loading: _outlinesLoading,
                    onBack: widget.onBack,
                    onSelectOutline: _selectOutline,
                    onSelectGlobal: _selectGlobalOutline,
                    onAddOutline: () => unawaited(_startNewOutline()),
                  )
                else if (_workspace == _ProjectWorkspace.settings)
                  _ProjectWorldSettingRail(
                    novel: widget.novel,
                    settings: _worldSettings,
                    selectedSettingId: _selectedWorldSetting?.id,
                    loading: _outlinesLoading,
                    onBack: widget.onBack,
                    onSelectSetting: _selectWorldSetting,
                    onAddSetting: () => unawaited(_startNewWorldSetting()),
                    onAddFolder: (name) =>
                        unawaited(_startNewWorldSetting(category: name)),
                    onImportFile: () => unawaited(_importWorldSettingFile()),
                  )
                else if (_workspace == _ProjectWorkspace.map)
                  _ProjectMapWorldRail(
                    novel: widget.novel,
                    worlds: _mapWorlds,
                    selectedWorldId: _selectedMapWorld?.id,
                    loading: _outlinesLoading,
                    onBack: widget.onBack,
                    onSelectWorld: _selectMapWorld,
                    onAddWorld: () => unawaited(_startNewMapWorld()),
                    onEditWorld: (world) => unawaited(_editMapWorld(world)),
                    onDeleteWorld: (world) => unawaited(_deleteMapWorld(world)),
                  )
                else if (_workspace == _ProjectWorkspace.factions)
                  _ProjectWorldSettingRail(
                    novel: widget.novel,
                    settings: _factions,
                    selectedSettingId: _selectedFaction?.id,
                    loading: _outlinesLoading,
                    onBack: widget.onBack,
                    onSelectSetting: _selectFaction,
                    onAddSetting: () => unawaited(_startNewFaction()),
                    railTitle: '势力',
                    addTooltip: '新增势力',
                    itemIcon: Icons.description_outlined,
                    onOpenPermissions: (faction) =>
                        unawaited(_editFactionPermissions(faction)),
                    onDeleteSetting: (faction) =>
                        unawaited(_deleteFaction(faction)),
                  )
                else if (_workspace == _ProjectWorkspace.creatures)
                  _ProjectWorldSettingRail(
                    novel: widget.novel,
                    settings: _creatures,
                    selectedSettingId: _selectedCreature?.id,
                    loading: _outlinesLoading,
                    onBack: widget.onBack,
                    onSelectSetting: _selectCreature,
                    onAddSetting: () => unawaited(_startNewCreature()),
                    railTitle: '生物',
                    addTooltip: '新增生物',
                    itemIcon: Icons.description_outlined,
                    onOpenPermissions: (creature) =>
                        unawaited(_editCreaturePermissions(creature)),
                    onDeleteSetting: (creature) =>
                        unawaited(_deleteCreature(creature)),
                  )
                else if (_workspace == _ProjectWorkspace.items)
                  _ProjectWorldSettingRail(
                    novel: widget.novel,
                    settings: _items,
                    selectedSettingId: _selectedItem?.id,
                    loading: _outlinesLoading,
                    onBack: widget.onBack,
                    onSelectSetting: _selectItem,
                    onAddSetting: () => unawaited(_startNewItem()),
                    railTitle: '物品',
                    addTooltip: '新增物品',
                    itemIcon: Icons.description_outlined,
                    onOpenPermissions: (item) =>
                        unawaited(_editItemPermissions(item)),
                    onDeleteSetting: (item) => unawaited(_deleteItem(item)),
                  )
                else if (_workspace == _ProjectWorkspace.skills)
                  _ProjectWorldSettingRail(
                    novel: widget.novel,
                    settings: _skills,
                    selectedSettingId: _selectedSkill?.id,
                    loading: _outlinesLoading,
                    onBack: widget.onBack,
                    onSelectSetting: _selectSkill,
                    onAddSetting: () => unawaited(_startNewSkill()),
                    railTitle: '技能',
                    addTooltip: '新增技能',
                    itemIcon: Icons.description_outlined,
                    onOpenPermissions: (skill) =>
                        unawaited(_editSkillPermissions(skill)),
                    onDeleteSetting: (skill) => unawaited(_deleteSkill(skill)),
                  )
                else if (_workspace == _ProjectWorkspace.characters)
                  _ProjectCharacterRail(
                    novel: widget.novel,
                    characters: _characters,
                    selectedCharacterId: _selectedCharacter?.id,
                    loading: _charactersLoading,
                    onBack: widget.onBack,
                    onSelectCharacter: _selectCharacter,
                    onAddCharacter: () => unawaited(_startNewCharacter()),
                    onDeleteCharacter: (character) =>
                        unawaited(_deleteCharacter(character)),
                  )
                else if (_workspace == _ProjectWorkspace.foreshadowing)
                  _ProjectForeshadowingRail(
                    novel: widget.novel,
                    foreshadowings: _foreshadowings,
                    selectedForeshadowingId: _selectedForeshadowing?.id,
                    loading: _foreshadowingsLoading,
                    onBack: widget.onBack,
                    onSelectForeshadowing: _selectForeshadowing,
                    onAddForeshadowing: () =>
                        unawaited(_startNewForeshadowing()),
                    onDeleteForeshadowing: (foreshadowing) =>
                        unawaited(_deleteForeshadowing(foreshadowing)),
                  ),
              if (!expanded)
                Expanded(
                  child: switch (_workspace) {
                    _ProjectWorkspace.chapters =>
                      _chaptersLoading || _selectedChapter != null
                          ? _ChapterEditorMain(
                              novel: widget.novel,
                              chapter: _selectedChapter,
                              chapterNumber: _selectedChapterNumber,
                              loading: _chaptersLoading,
                              error: _chapterError,
                              onSave: _saveChapter,
                            )
                          : _ChapterEmptyMain(
                              novel: widget.novel,
                              onAddChapter: () => unawaited(_startNewChapter()),
                            ),
                    _ProjectWorkspace.outline =>
                      _outlinesLoading || _selectedOutline != null
                          ? _OutlineEditorMain(
                              novel: widget.novel,
                              outline: _selectedOutline,
                              loading: _outlinesLoading,
                              error: _outlineError,
                              onSave: _saveOutline,
                              onGenerateChapterOutline:
                                  _generateChapterOutlineFromBeat,
                            )
                          : _OutlineEmptyMain(
                              novel: widget.novel,
                              outlines: _outlineItems,
                              onAddOutline: () => unawaited(_startNewOutline()),
                            ),
                    _ProjectWorkspace.settings =>
                      _outlinesLoading || _selectedWorldSetting != null
                          ? _WorldSettingEditorMain(
                              novel: widget.novel,
                              setting: _selectedWorldSetting,
                              loading: _outlinesLoading,
                              error: _outlineError,
                              onSave: _saveWorldSetting,
                            )
                          : _WorldSettingEmptyMain(
                              novel: widget.novel,
                              onAddSetting: () =>
                                  unawaited(_startNewWorldSetting()),
                            ),
                    _ProjectWorkspace.map => _MapWorkspaceMain(
                        novel: widget.novel,
                        world: _selectedMapWorld,
                        locations: _selectedMapLocations,
                        selectedLocation: _selectedMapLocation,
                        loading: _outlinesLoading,
                        onAddWorld: () => unawaited(_startNewMapWorld()),
                        onAddLocation: () => unawaited(_startNewMapLocation()),
                        onSelectLocation: _selectMapLocation,
                        onEditWorld: _selectedMapWorld == null
                            ? null
                            : () =>
                                unawaited(_editMapWorld(_selectedMapWorld!)),
                        onEditLocation: _selectedMapLocation == null
                            ? null
                            : () => unawaited(
                                  _editMapLocation(_selectedMapLocation!),
                                ),
                        onDeleteLocation: (location) =>
                            unawaited(_deleteMapLocation(location)),
                      ),
                    _ProjectWorkspace.factions =>
                      _outlinesLoading || _selectedFaction != null
                          ? _WorldSettingEditorMain(
                              novel: widget.novel,
                              setting: _selectedFaction,
                              loading: _outlinesLoading,
                              error: _outlineError,
                              workspaceTitle: '势力',
                              description: '梳理组织、阵营、势力目标、关系和影响范围。',
                              titleHint: '输入势力标题',
                              includeItemInHeader: true,
                              onSave: _saveFaction,
                            )
                          : _WorldSettingEmptyMain(
                              novel: widget.novel,
                              workspaceTitle: '势力',
                              emptyTitle: '还没有选中势力',
                              emptyDescription: '先新建第一条势力内容。',
                              buttonLabel: '新建势力',
                              onAddSetting: () => unawaited(_startNewFaction()),
                            ),
                    _ProjectWorkspace.creatures => _outlinesLoading ||
                            _selectedCreature != null
                        ? _WorldSettingEditorMain(
                            novel: widget.novel,
                            setting: _selectedCreature,
                            loading: _outlinesLoading,
                            error: _outlineError,
                            workspaceTitle: '生物',
                            description: '记录故事中出现的具体动植物个体。',
                            titleHint: '输入生物标题',
                            includeItemInHeader: true,
                            onSave: _saveCreature,
                          )
                        : _WorldSettingEmptyMain(
                            novel: widget.novel,
                            workspaceTitle: '生物',
                            emptyTitle: '还没有选中生物',
                            emptyDescription: '先新建第一条生物内容。',
                            buttonLabel: '新建生物',
                            onAddSetting: () => unawaited(_startNewCreature()),
                          ),
                    _ProjectWorkspace.items =>
                      _outlinesLoading || _selectedItem != null
                          ? _WorldSettingEditorMain(
                              novel: widget.novel,
                              setting: _selectedItem,
                              loading: _outlinesLoading,
                              error: _outlineError,
                              workspaceTitle: '物品',
                              description: '管理关键道具、装备、遗物、资源和限制条件。',
                              titleHint: '输入物品标题',
                              includeItemInHeader: true,
                              showPhotoGallery: true,
                              onSave: ({
                                required title,
                                required category,
                                required content,
                                required photoPaths,
                              }) =>
                                  _saveItem(
                                title: title,
                                category: category,
                                content: content,
                                photoPaths: photoPaths,
                              ),
                            )
                          : _WorldSettingEmptyMain(
                              novel: widget.novel,
                              workspaceTitle: '物品',
                              emptyTitle: '还没有选中物品',
                              emptyDescription: '先新建第一条物品内容。',
                              buttonLabel: '新建物品',
                              onAddSetting: () => unawaited(_startNewItem()),
                            ),
                    _ProjectWorkspace.skills =>
                      _outlinesLoading || _selectedSkill != null
                          ? _WorldSettingEditorMain(
                              novel: widget.novel,
                              setting: _selectedSkill,
                              loading: _outlinesLoading,
                              error: _outlineError,
                              workspaceTitle: '技能',
                              description: '整理功法、能力、法术、招式和使用规则。',
                              titleHint: '输入技能标题',
                              includeItemInHeader: true,
                              showNameAssistant: true,
                              onRequestAiName: _askAssistantForSkillName,
                              onSave: _saveSkill,
                            )
                          : _WorldSettingEmptyMain(
                              novel: widget.novel,
                              workspaceTitle: '技能',
                              emptyTitle: '还没有选中技能',
                              emptyDescription: '先新建第一条技能内容。',
                              buttonLabel: '新建技能',
                              onAddSetting: () => unawaited(_startNewSkill()),
                            ),
                    _ProjectWorkspace.overview => _ProjectOverviewMain(
                        novel: widget.novel,
                        chapters: _chapters,
                        selectedChapter: _selectedChapter,
                        onOpenChapters: () =>
                            _selectWorkspace(_ProjectWorkspace.chapters),
                        onOpenOutline: () =>
                            _selectWorkspace(_ProjectWorkspace.outline),
                        onOpenSettings: () =>
                            _selectWorkspace(_ProjectWorkspace.settings),
                        onOpenCharacters: () =>
                            _selectWorkspace(_ProjectWorkspace.characters),
                      ),
                    _ProjectWorkspace.characters =>
                      _charactersLoading || _selectedCharacter != null
                          ? _CharacterEditorMain(
                              novel: widget.novel,
                              character: _selectedCharacter,
                              chapters: _chapters,
                              availableSkills: _skills,
                              loading: _charactersLoading,
                              error: _characterError,
                              onSave: _saveCharacter,
                              onCreateSkill: ({
                                required title,
                                required content,
                              }) =>
                                  _saveSkill(
                                skill: null,
                                title: title,
                                category: '通用',
                                content: content,
                                photoPaths: const [],
                              ),
                              onDelete: _selectedCharacter == null
                                  ? null
                                  : () => unawaited(
                                        _deleteCharacter(_selectedCharacter!),
                                      ),
                              onAskAssistant: (character, prompt) {
                                setState(() {
                                  _assistantContextLabel = character.name;
                                  _assistantDraftText = prompt;
                                  _assistantDraftRevision += 1;
                                  _assistantMode = _AssistantPanelMode.docked;
                                });
                              },
                            )
                          : _CharacterEmptyMain(
                              novel: widget.novel,
                              onAddCharacter: () =>
                                  unawaited(_startNewCharacter()),
                            ),
                    _ProjectWorkspace.foreshadowing =>
                      _foreshadowingsLoading || _selectedForeshadowing != null
                          ? _ForeshadowingEditorMain(
                              novel: widget.novel,
                              foreshadowing: _selectedForeshadowing,
                              loading: _foreshadowingsLoading,
                              error: _foreshadowingError,
                              onSave: _saveForeshadowing,
                            )
                          : _ForeshadowingEmptyMain(
                              novel: widget.novel,
                              onAddForeshadowing: () =>
                                  unawaited(_startNewForeshadowing()),
                            ),
                    _ => _ProjectWorkspacePlaceholder(
                        novel: widget.novel,
                        workspace: _workspace,
                      ),
                  },
                ),
              if (showAssistant)
                if (expanded)
                  Expanded(
                    child: _WritingAssistantPanel(
                      novel: widget.novel,
                      models: widget.assistantModels,
                      aiSettings: widget.aiSettings,
                      chapters: _chapters,
                      outlines: _outlines,
                      characters: _characters,
                      foreshadowings: _foreshadowings,
                      expanded: true,
                      onExpand: () {},
                      onCollapse: () {
                        setState(() =>
                            _assistantMode = _AssistantPanelMode.collapsed);
                      },
                      onDock: () {
                        setState(
                            () => _assistantMode = _AssistantPanelMode.docked);
                      },
                      onOpenSettings: widget.onOpenSettings,
                      contextLabel: _assistantContextLabel,
                      draftText: _assistantDraftText,
                      draftRevision: _assistantDraftRevision,
                    ),
                  )
                else
                  _WritingAssistantPanel(
                    novel: widget.novel,
                    models: widget.assistantModels,
                    aiSettings: widget.aiSettings,
                    chapters: _chapters,
                    outlines: _outlines,
                    characters: _characters,
                    foreshadowings: _foreshadowings,
                    expanded: false,
                    onExpand: () {
                      setState(
                          () => _assistantMode = _AssistantPanelMode.expanded);
                    },
                    onCollapse: () {
                      setState(
                          () => _assistantMode = _AssistantPanelMode.collapsed);
                    },
                    onDock: () {},
                    onOpenSettings: widget.onOpenSettings,
                    contextLabel: _assistantContextLabel,
                    draftText: _assistantDraftText,
                    draftRevision: _assistantDraftRevision,
                  ),
              if (expanded)
                Container(
                  width: 360,
                  decoration: BoxDecoration(
                    color: colors.card,
                    border: Border(left: BorderSide(color: colors.line)),
                  ),
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: '恢复侧栏',
                    onPressed: () {
                      setState(
                          () => _assistantMode = _AssistantPanelMode.docked);
                    },
                    icon: const Icon(Icons.close_fullscreen, size: 18),
                  ),
                ),
              if (collapsed)
                _AssistantCollapsedTab(
                  onTap: () {
                    setState(() => _assistantMode = _AssistantPanelMode.docked);
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProjectSystemRail extends StatelessWidget {
  const _ProjectSystemRail({
    required this.activeWorkspace,
    required this.onWorkspaceChanged,
  });

  final _ProjectWorkspace activeWorkspace;
  final ValueChanged<_ProjectWorkspace> onWorkspaceChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    _RailItem item(_ProjectWorkspace workspace, IconData icon) {
      return _RailItem(
        icon,
        workspace.label,
        selected: activeWorkspace == workspace,
        onTap: () => onWorkspaceChanged(workspace),
      );
    }

    return Container(
      width: 132,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(right: BorderSide(color: colors.line)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 50),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _RailGroup(title: '系统', items: [
                  item(_ProjectWorkspace.overview, Icons.dashboard_outlined),
                  item(
                    _ProjectWorkspace.relationships,
                    Icons.account_tree_outlined,
                  ),
                ]),
                _RailGroup(title: '创作', items: [
                  item(_ProjectWorkspace.chapters, Icons.menu_book_outlined),
                  item(
                    _ProjectWorkspace.outline,
                    Icons.format_list_numbered,
                  ),
                  item(_ProjectWorkspace.characters, Icons.people_outline),
                  item(_ProjectWorkspace.foreshadowing, Icons.flag_outlined),
                ]),
                _RailGroup(title: '世界观', items: [
                  item(_ProjectWorkspace.settings, Icons.settings_outlined),
                  item(_ProjectWorkspace.map, Icons.map_outlined),
                  item(_ProjectWorkspace.factions, Icons.hub_outlined),
                  item(_ProjectWorkspace.creatures, Icons.bug_report_outlined),
                  item(_ProjectWorkspace.items, Icons.inventory_2_outlined),
                  item(_ProjectWorkspace.skills, Icons.bolt_outlined),
                ]),
                _RailGroup(title: '资料', items: [
                  item(_ProjectWorkspace.assets, Icons.folder_copy_outlined),
                ]),
                _RailGroup(title: 'AI', items: [
                  item(_ProjectWorkspace.chat, Icons.chat_bubble_outline),
                  item(_ProjectWorkspace.roundtable, Icons.groups_outlined),
                  item(_ProjectWorkspace.monologue, Icons.person_outline),
                  item(_ProjectWorkspace.theatre, Icons.grid_on_outlined),
                  item(_ProjectWorkspace.roleplay, Icons.mode_comment_outlined),
                  item(_ProjectWorkspace.agentRules, Icons.shield_outlined),
                  item(_ProjectWorkspace.agentSkills, Icons.auto_awesome),
                ]),
              ],
            ),
          ),
          Divider(height: 1, color: colors.line),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.account_circle_outlined,
                    size: 22, color: colors.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "a'a'a",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.text, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RailGroup extends StatelessWidget {
  const _RailGroup({required this.title, required this.items});

  final String title;
  final List<_RailItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
            child: Text(
              title,
              style: TextStyle(
                color: colors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...items,
          Padding(
            padding: const EdgeInsets.only(left: 6, right: 12, top: 8),
            child: Divider(height: 1, color: colors.line),
          ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem(
    this.icon,
    this.label, {
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: SizedBox(
        height: 32,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              color: selected
                  ? colors.line.withValues(alpha: 0.55)
                  : Colors.transparent,
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: selected ? colors.text : colors.muted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? colors.text : colors.muted,
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectOverviewMain extends StatelessWidget {
  const _ProjectOverviewMain({
    required this.novel,
    required this.chapters,
    required this.selectedChapter,
    required this.onOpenChapters,
    required this.onOpenOutline,
    required this.onOpenSettings,
    required this.onOpenCharacters,
  });

  final NovelSummary novel;
  final List<NovelChapter> chapters;
  final NovelChapter? selectedChapter;
  final VoidCallback onOpenChapters;
  final VoidCallback onOpenOutline;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenCharacters;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final tags = _projectOverviewTags(novel);
    final snippets = _projectOverviewSnippets(novel, selectedChapter);
    final latest = selectedChapter ?? (chapters.isEmpty ? null : chapters.last);

    return Container(
      color: colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colors.card,
              border: Border(bottom: BorderSide(color: colors.line)),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              '${novel.title}  >  概览',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.muted, fontSize: 13),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 636),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 28, 0, 38),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                novel.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.text,
                                  fontSize: 28,
                                  height: 1.18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: '编辑',
                              onPressed: () {},
                              icon: const Icon(Icons.edit_outlined, size: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _ProjectOverviewStatusChip(
                            label: _statusOf(novel).label),
                        if (tags.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final tag in tags)
                                _ProjectOverviewTag(label: tag),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),
                        _ProjectOverviewContinueCard(
                          latest: latest,
                          nextChapterNumber: chapters.length + 1,
                          onOpenChapters: onOpenChapters,
                          onOpenOutline: onOpenOutline,
                          onOpenSettings: onOpenSettings,
                        ),
                        const SizedBox(height: 24),
                        _ProjectOverviewIntroCard(
                          novel: novel,
                          chapterCount: chapters.length,
                        ),
                        const SizedBox(height: 16),
                        _ProjectOverviewSnippetCard(snippets: snippets),
                        const SizedBox(height: 26),
                        Text(
                          '写作入口',
                          style: TextStyle(
                            color: colors.text,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.28,
                          children: [
                            _ProjectOverviewEntryCard(
                              icon: Icons.edit_square,
                              title: '正文创作',
                              description: '沉浸写作，流畅记录故事的每一步。',
                              onTap: onOpenChapters,
                            ),
                            _ProjectOverviewEntryCard(
                              icon: Icons.public,
                              title: '设定',
                              description: '先约束规则、历史与势力，避免后续冲突。',
                              onTap: onOpenSettings,
                            ),
                            _ProjectOverviewEntryCard(
                              icon: Icons.menu_book_outlined,
                              title: '大纲与剧情',
                              description: '梳理故事脉络，安排冲突与转折。',
                              onTap: onOpenOutline,
                            ),
                            _ProjectOverviewEntryCard(
                              icon: Icons.people_outline,
                              title: '人物管理',
                              description: '塑造立体角色，记录人物关系与成长。',
                              onTap: onOpenCharacters,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectOverviewStatusChip extends StatelessWidget {
  const _ProjectOverviewStatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.line.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.text.withValues(alpha: 0.18)),
      ),
      child: Text(
        '● $label',
        style: TextStyle(
          color: colors.text,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProjectOverviewTag extends StatelessWidget {
  const _ProjectOverviewTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.line),
      ),
      child: Text(label, style: TextStyle(color: colors.text, fontSize: 12)),
    );
  }
}

class _ProjectOverviewContinueCard extends StatelessWidget {
  const _ProjectOverviewContinueCard({
    required this.latest,
    required this.nextChapterNumber,
    required this.onOpenChapters,
    required this.onOpenOutline,
    required this.onOpenSettings,
  });

  final NovelChapter? latest;
  final int nextChapterNumber;
  final VoidCallback onOpenChapters;
  final VoidCallback onOpenOutline;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final title = latest == null ? '新章节空空如也，从一句话开始吧。' : '继续写 ${latest!.title}';
    final subtitle = latest == null ? '慢慢写，让故事自然生长吧。' : '你上次写到：';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.line.withValues(alpha: 0.62),
            colors.line.withValues(alpha: 0.32),
            colors.card,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.explore_outlined, color: colors.text, size: 18),
              const SizedBox(width: 8),
              Text(
                '继续写作',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(subtitle, style: TextStyle(color: colors.muted, fontSize: 13)),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.text,
              fontSize: 23,
              height: 1.25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            latest == null ? '第 $nextChapterNumber 章等待开笔。' : '打开章节编辑器接着写。',
            style: TextStyle(color: colors.muted, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ProjectOverviewPillButton(
                icon: Icons.edit_outlined,
                label: latest == null ? '开始写第 $nextChapterNumber 章' : '继续写作',
                primary: true,
                onTap: onOpenChapters,
              ),
              _ProjectOverviewPillButton(
                icon: Icons.format_list_bulleted,
                label: '查看大纲',
                onTap: onOpenOutline,
              ),
              _ProjectOverviewPillButton(
                icon: Icons.public,
                label: '翻看设定',
                onTap: onOpenSettings,
              ),
              _ProjectOverviewPillButton(
                icon: Icons.description_outlined,
                label: '打开草稿',
                onTap: onOpenChapters,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectOverviewPillButton extends StatelessWidget {
  const _ProjectOverviewPillButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Material(
      color: primary ? colors.text : colors.card.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: primary ? colors.card : colors.muted,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: primary ? colors.card : colors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectOverviewIntroCard extends StatelessWidget {
  const _ProjectOverviewIntroCard({
    required this.novel,
    required this.chapterCount,
  });

  final NovelSummary novel;
  final int chapterCount;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final summary =
        novel.summary.trim().isEmpty ? '暂无作品简介。' : novel.summary.trim();

    return _ProjectOverviewCard(
      title: '作品简介',
      icon: Icons.menu_book_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 72,
                  height: 112,
                  child: _NovelCover(novel: novel),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  summary,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ProjectOverviewMetric(label: '章节', value: chapterCount),
              _ProjectOverviewMetricText(
                label: '字数',
                value: _formatWords(context, novel.wordCount),
              ),
              _ProjectOverviewMetric(label: '标签', value: novel.tags.length),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectOverviewSnippetCard extends StatelessWidget {
  const _ProjectOverviewSnippetCard({required this.snippets});

  final List<String> snippets;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return _ProjectOverviewCard(
      title: '创作片段 / 灵感便签',
      icon: Icons.auto_awesome_outlined,
      trailing: Text(
        '查看更多 >',
        style: TextStyle(color: colors.text, fontSize: 12),
      ),
      child: snippets.isEmpty
          ? Container(
              height: 112,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.line.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '暂无灵感便签',
                style: TextStyle(color: colors.muted, fontSize: 13),
              ),
            )
          : Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  Expanded(
                    child: _ProjectOverviewSnippetNote(
                      text: i < snippets.length ? snippets[i] : '',
                    ),
                  ),
                  if (i != 2) const SizedBox(width: 12),
                ],
              ],
            ),
    );
  }
}

class _ProjectOverviewSnippetNote extends StatelessWidget {
  const _ProjectOverviewSnippetNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      height: 168,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.line.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text.isEmpty ? ' ' : text,
        maxLines: 6,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colors.text, fontSize: 13, height: 1.55),
      ),
    );
  }
}

class _ProjectOverviewEntryCard extends StatelessWidget {
  const _ProjectOverviewEntryCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.line.withValues(alpha: 0.45),
                colors.card,
              ],
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.card.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 20, color: colors.text),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: colors.card.withValues(alpha: 0.86),
                  child:
                      Icon(Icons.arrow_forward, color: colors.muted, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectOverviewCard extends StatelessWidget {
  const _ProjectOverviewCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: colors.text, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ProjectOverviewMetric extends StatelessWidget {
  const _ProjectOverviewMetric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return _ProjectOverviewMetricText(label: label, value: value.toString());
  }
}

class _ProjectOverviewMetricText extends StatelessWidget {
  const _ProjectOverviewMetricText({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.line),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(color: colors.text, fontSize: 12),
      ),
    );
  }
}

class _ProjectWorkspacePlaceholder extends StatelessWidget {
  const _ProjectWorkspacePlaceholder({
    required this.novel,
    required this.workspace,
  });

  final NovelSummary novel;
  final _ProjectWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      color: colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              color: colors.card,
              border: Border(bottom: BorderSide(color: colors.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${novel.title} / ${workspace.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '${workspace.label}待接入',
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectMapWorldRail extends StatefulWidget {
  const _ProjectMapWorldRail({
    required this.novel,
    required this.worlds,
    required this.selectedWorldId,
    required this.loading,
    required this.onBack,
    required this.onSelectWorld,
    required this.onAddWorld,
    required this.onEditWorld,
    required this.onDeleteWorld,
  });

  final NovelSummary novel;
  final List<NovelOutline> worlds;
  final int? selectedWorldId;
  final bool loading;
  final VoidCallback onBack;
  final ValueChanged<NovelOutline> onSelectWorld;
  final VoidCallback onAddWorld;
  final ValueChanged<NovelOutline> onEditWorld;
  final ValueChanged<NovelOutline> onDeleteWorld;

  @override
  State<_ProjectMapWorldRail> createState() => _ProjectMapWorldRailState();
}

class _ProjectMapWorldRailState extends State<_ProjectMapWorldRail> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NovelOutline> get _visibleWorlds {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return widget.worlds;
    }
    return [
      for (final world in widget.worlds)
        if (_fuzzyContains(world.title, query) ||
            _fuzzyContains(world.content, query))
          world,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final visibleWorlds = _visibleWorlds;
    return Container(
      width: 204,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(right: BorderSide(color: colors.line)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 46,
            child: Row(
              children: [
                IconButton(
                  tooltip: '返回',
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.chevron_left),
                ),
                const Spacer(),
                IconButton(
                  tooltip: '收起侧栏',
                  onPressed: () {},
                  icon: const Icon(Icons.view_sidebar_outlined, size: 18),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: _NovelCover(novel: widget.novel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.novel.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
            child: Row(
              children: [
                Text(
                  '世界',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  widget.worlds.length.toString(),
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: '新建世界',
                  onPressed: widget.onAddWorld,
                  icon: Icon(Icons.add, size: 18, color: colors.muted),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints.tightFor(width: 22, height: 22),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 34,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '搜索',
                  prefixIcon: const Icon(Icons.search, size: 16),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.line),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (widget.loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: LinearProgressIndicator(
                minHeight: 2,
                color: colors.text,
                backgroundColor: colors.line,
              ),
            )
          else
            Expanded(
              child: visibleWorlds.isEmpty
                  ? Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
                        child: Text(
                          '暂无内容',
                          style: TextStyle(color: colors.muted, fontSize: 13),
                        ),
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        for (final world in visibleWorlds)
                          _MapWorldRow(
                            world: world,
                            selected: world.id == widget.selectedWorldId,
                            onTap: () => widget.onSelectWorld(world),
                            onEdit: () => widget.onEditWorld(world),
                            onDelete: () => widget.onDeleteWorld(world),
                          ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}

class _MapWorldRow extends StatelessWidget {
  const _MapWorldRow({
    required this.world,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final NovelOutline world;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return GestureDetector(
      onSecondaryTapDown: (details) {
        _showMapRowMenu(
          context,
          details.globalPosition,
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          color: selected ? colors.line.withValues(alpha: 0.65) : null,
          child: Row(
            children: [
              Icon(Icons.public, size: 15, color: colors.text),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  world.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapWorkspaceMain extends StatelessWidget {
  const _MapWorkspaceMain({
    required this.novel,
    required this.world,
    required this.locations,
    required this.selectedLocation,
    required this.loading,
    required this.onAddWorld,
    required this.onAddLocation,
    required this.onSelectLocation,
    required this.onEditWorld,
    required this.onEditLocation,
    required this.onDeleteLocation,
  });

  final NovelSummary novel;
  final NovelOutline? world;
  final List<NovelOutline> locations;
  final NovelOutline? selectedLocation;
  final bool loading;
  final VoidCallback onAddWorld;
  final VoidCallback onAddLocation;
  final ValueChanged<NovelOutline> onSelectLocation;
  final VoidCallback? onEditWorld;
  final VoidCallback? onEditLocation;
  final ValueChanged<NovelOutline> onDeleteLocation;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Column(
      children: [
        _WorkspaceHeader(
          title: '${novel.title}  >  地图  >  地图',
          actions: [
            IconButton(
              tooltip: '历史',
              onPressed: () {},
              icon: const Icon(Icons.history, size: 16),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: colors.text,
                foregroundColor: colors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('保存'),
            ),
          ],
        ),
        Expanded(
          child: loading
              ? Center(child: CircularProgressIndicator(color: colors.text))
              : world == null
                  ? _MapEmptyState(onAddWorld: onAddWorld)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _MapLocationColumn(
                          world: world!,
                          locations: locations,
                          selectedLocation: selectedLocation,
                          onAddLocation: onAddLocation,
                          onSelectLocation: onSelectLocation,
                          onDeleteLocation: onDeleteLocation,
                        ),
                        Expanded(
                          child: selectedLocation == null
                              ? _MapWorldDetail(
                                  world: world!,
                                  locations: locations,
                                  onEdit: onEditWorld,
                                  onSelectLocation: onSelectLocation,
                                )
                              : _MapLocationDetail(
                                  world: world!,
                                  locations: locations,
                                  location: selectedLocation!,
                                  onEdit: onEditLocation,
                                ),
                        ),
                      ],
                    ),
        ),
        const _WorkspaceHistoryBar(),
      ],
    );
  }
}

class _MapEmptyState extends StatelessWidget {
  const _MapEmptyState({required this.onAddWorld});

  final VoidCallback onAddWorld;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.public, size: 34, color: colors.muted),
          const SizedBox(height: 14),
          Text(
            '暂无地图',
            style: TextStyle(
              color: colors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '新建你的第一张地图来可视化你的世界',
            style: TextStyle(color: colors.muted, fontSize: 13),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onAddWorld,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('新建世界'),
            style: FilledButton.styleFrom(
              backgroundColor: colors.text,
              foregroundColor: colors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLocationColumn extends StatelessWidget {
  const _MapLocationColumn({
    required this.world,
    required this.locations,
    required this.selectedLocation,
    required this.onAddLocation,
    required this.onSelectLocation,
    required this.onDeleteLocation,
  });

  final NovelOutline world;
  final List<NovelOutline> locations;
  final NovelOutline? selectedLocation;
  final VoidCallback onAddLocation;
  final ValueChanged<NovelOutline> onSelectLocation;
  final ValueChanged<NovelOutline> onDeleteLocation;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(right: BorderSide(color: colors.line)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(Icons.location_on_outlined, size: 18, color: colors.text),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    world.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '新建地点',
                  onPressed: onAddLocation,
                  icon: const Icon(Icons.add, size: 18),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          Divider(height: 1, color: colors.line),
          Expanded(
            child: locations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 28, color: colors.muted),
                        const SizedBox(height: 12),
                        Text(
                          '没有可添加的地点，请先新建地点',
                          style: TextStyle(color: colors.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(top: 8),
                    children: [
                      for (final location in locations)
                        _MapLocationRow(
                          location: location,
                          selected: selectedLocation?.id == location.id,
                          onTap: () => onSelectLocation(location),
                          onDelete: () => onDeleteLocation(location),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MapLocationRow extends StatelessWidget {
  const _MapLocationRow({
    required this.location,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  final NovelOutline location;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return GestureDetector(
      onSecondaryTapDown: (details) {
        _showMapRowMenu(
          context,
          details.globalPosition,
          onEdit: onTap,
          onDelete: onDelete,
        );
      },
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          color: selected ? colors.line.withValues(alpha: 0.65) : null,
          child: Row(
            children: [
              Icon(_mapLocationIcon(location), size: 16, color: colors.text),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  location.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapWorldDetail extends StatelessWidget {
  const _MapWorldDetail({
    required this.world,
    required this.locations,
    required this.onEdit,
    required this.onSelectLocation,
  });

  final NovelOutline world;
  final List<NovelOutline> locations;
  final VoidCallback? onEdit;
  final ValueChanged<NovelOutline> onSelectLocation;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.public, size: 24, color: colors.text),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    world.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '编辑',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _MapDetailLabel('描述'),
            const SizedBox(height: 10),
            _MapDescription(text: world.content),
            const SizedBox(height: 24),
            _MapDetailLabel('地点库'),
            const SizedBox(height: 8),
            if (locations.isEmpty)
              Text(
                '没有可添加的地点，请先新建地点',
                style: TextStyle(color: colors.muted, fontSize: 13),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final location in locations)
                    ActionChip(
                      avatar: Icon(_mapLocationIcon(location), size: 14),
                      label: Text(location.title),
                      onPressed: () => onSelectLocation(location),
                      side: BorderSide(color: colors.line),
                      backgroundColor: colors.card,
                      surfaceTintColor: Colors.transparent,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MapLocationDetail extends StatelessWidget {
  const _MapLocationDetail({
    required this.world,
    required this.locations,
    required this.location,
    required this.onEdit,
  });

  final NovelOutline world;
  final List<NovelOutline> locations;
  final NovelOutline location;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_mapLocationIcon(location), size: 24, color: colors.text),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    location.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '编辑',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _MapInlineField(label: '类型', value: _mapLocationType(location)),
                _MapInlineField(
                  label: '父级地点',
                  value: _mapParentName(world, locations, location),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _MapDetailLabel('描述'),
            const SizedBox(height: 10),
            _MapDescription(text: location.content),
          ],
        ),
      ),
    );
  }
}

class _MapInlineField extends StatelessWidget {
  const _MapInlineField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return RichText(
      text: TextSpan(
        style: TextStyle(color: colors.text, fontSize: 13),
        children: [
          TextSpan(text: '$label  '),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MapDetailLabel extends StatelessWidget {
  const _MapDetailLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Text(
      text,
      style: TextStyle(
        color: colors.text,
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _MapDescription extends StatelessWidget {
  const _MapDescription({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final content = text.trim();
    if (content.isEmpty) {
      return Text('暂无描述', style: TextStyle(color: colors.muted));
    }
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        content,
        style: TextStyle(color: colors.text, fontSize: 13, height: 1.55),
      ),
    );
  }
}

IconData _mapLocationIcon(NovelOutline location) {
  switch (_mapLocationType(location)) {
    case '世界':
      return Icons.public;
    case '大陆':
      return Icons.terrain_outlined;
    case '国家':
      return Icons.flag_outlined;
    case '山脉':
      return Icons.filter_hdr_outlined;
    case '森林':
    case '自然景观':
      return Icons.park_outlined;
    case '城镇':
    case '村镇':
      return Icons.location_city_outlined;
    case '建筑':
    case '房间':
      return Icons.business_outlined;
    case '地标':
      return Icons.place_outlined;
    default:
      return Icons.landscape_outlined;
  }
}

String _mapParentName(
  NovelOutline world,
  List<NovelOutline> locations,
  NovelOutline location,
) {
  final parentId = _mapLocationParentId(location);
  if (parentId == null || parentId == world.id) {
    return world.title;
  }
  for (final candidate in locations) {
    if (candidate.id == parentId) {
      return candidate.title;
    }
  }
  return world.title;
}

Future<void> _showMapRowMenu(
  BuildContext context,
  Offset position, {
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) async {
  final colors = AppPalette.of(context);
  final action = await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(position.dx, position.dy, 0, 0),
    color: colors.card,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: colors.line),
    ),
    items: const [
      PopupMenuItem(
        value: 'edit',
        child: _ProjectMenuItem(icon: Icons.edit_outlined, label: '编辑'),
      ),
      PopupMenuItem(
        value: 'delete',
        child: _ProjectMenuItem(
          icon: Icons.delete_outline,
          label: '删除',
          destructive: true,
        ),
      ),
    ],
  );
  if (action == 'edit') {
    onEdit();
  }
  if (action == 'delete') {
    onDelete();
  }
}

class _MapWorldDraft {
  const _MapWorldDraft({required this.title, required this.description});

  final String title;
  final String description;
}

class _MapLocationDraft {
  const _MapLocationDraft({
    required this.title,
    required this.description,
    required this.type,
    required this.parentId,
  });

  final String title;
  final String description;
  final String type;
  final int? parentId;
}

Future<_MapWorldDraft?> _showMapWorldDialog(
  BuildContext context, {
  NovelOutline? world,
}) {
  return showDialog<_MapWorldDraft>(
    context: context,
    builder: (context) => _MapWorldDialog(world: world),
  );
}

class _MapWorldDialog extends StatefulWidget {
  const _MapWorldDialog({this.world});

  final NovelOutline? world;

  @override
  State<_MapWorldDialog> createState() => _MapWorldDialogState();
}

class _MapWorldDialogState extends State<_MapWorldDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final world = widget.world;
    if (world != null) {
      _titleController.text = world.title;
      _descriptionController.text = world.content;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      return;
    }
    Navigator.of(context).pop(
      _MapWorldDraft(
        title: title,
        description: _descriptionController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 448),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.world == null ? '新建世界' : '编辑',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              const _FieldLabel('世界名称'),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                autofocus: true,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  hintText: '输入世界名称，如「艾泽拉斯」「中土世界」',
                ),
              ),
              const SizedBox(height: 14),
              const _FieldLabel('描述'),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: '描述这个世界的基本设定、历史背景或独特之处',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.text,
                      foregroundColor: colors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(widget.world == null ? '新建' : '保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<_MapLocationDraft?> _showMapLocationDialog(
  BuildContext context, {
  required NovelOutline world,
  required List<NovelOutline> locations,
  NovelOutline? location,
}) {
  return showDialog<_MapLocationDraft>(
    context: context,
    builder: (context) => _MapLocationDialog(
      world: world,
      locations: locations,
      location: location,
    ),
  );
}

class _MapLocationDialog extends StatefulWidget {
  const _MapLocationDialog({
    required this.world,
    required this.locations,
    this.location,
  });

  final NovelOutline world;
  final List<NovelOutline> locations;
  final NovelOutline? location;

  @override
  State<_MapLocationDialog> createState() => _MapLocationDialogState();
}

class _MapLocationDialogState extends State<_MapLocationDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late String _type;
  late int _parentId;

  @override
  void initState() {
    super.initState();
    final location = widget.location;
    _titleController.text = location?.title ?? '';
    _descriptionController.text = location?.content ?? '';
    _type =
        location == null ? _mapDefaultLocationType : _mapLocationType(location);
    _parentId = _initialParentId(location);
  }

  int _initialParentId(NovelOutline? location) {
    final parentId = location == null ? null : _mapLocationParentId(location);
    if (parentId == null) {
      return widget.world.id;
    }
    final validIds = {
      widget.world.id,
      for (final item in widget.locations)
        if (item.id != location?.id) item.id,
    };
    return validIds.contains(parentId) ? parentId : widget.world.id;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      return;
    }
    Navigator.of(context).pop(
      _MapLocationDraft(
        title: title,
        description: _descriptionController.text,
        type: _type,
        parentId: _parentId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final parentItems = [
      _ProjectDropdownItem<int>(
        value: widget.world.id,
        label: widget.world.title,
      ),
      for (final location in widget.locations)
        if (location.id != widget.location?.id)
          _ProjectDropdownItem<int>(
            value: location.id,
            label: location.title,
          ),
    ];
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 508),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.location == null ? '新建地点' : '编辑',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              const _FieldLabel('名称'),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                autofocus: true,
                decoration: const InputDecoration(hintText: '输入地点名称'),
              ),
              const SizedBox(height: 14),
              const _FieldLabel('描述'),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 4,
                decoration: const InputDecoration(hintText: '描述'),
              ),
              const SizedBox(height: 14),
              const _FieldLabel('类型'),
              const SizedBox(height: 8),
              _ProjectDropdownField<String>(
                value: _type,
                items: [
                  for (final type in _mapLocationTypes)
                    _ProjectDropdownItem(value: type, label: type),
                ],
                onChanged: (value) {
                  setState(() => _type = value);
                },
              ),
              const SizedBox(height: 14),
              const _FieldLabel('父级地点'),
              const SizedBox(height: 8),
              _ProjectDropdownField<int>(
                value: _parentId,
                items: parentItems,
                preferOpenAbove: true,
                onChanged: (value) {
                  setState(() => _parentId = value);
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.text,
                      foregroundColor: colors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(widget.location == null ? '新建' : '保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectDropdownItem<T> {
  const _ProjectDropdownItem({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

class _ProjectDropdownField<T> extends StatelessWidget {
  const _ProjectDropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
    this.preferOpenAbove = false,
  });

  final T value;
  final List<_ProjectDropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final bool preferOpenAbove;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final selected = items.firstWhere(
      (item) => item.value == value,
      orElse: () => items.first,
    );
    return Builder(
      builder: (fieldContext) {
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => unawaited(_showMenu(fieldContext)),
          child: InputDecorator(
            decoration: const InputDecoration(),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selected.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.text, fontSize: 14),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: colors.muted,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showMenu(BuildContext fieldContext) async {
    if (items.isEmpty) {
      return;
    }
    final colors = AppPalette.of(fieldContext);
    final fieldBox = fieldContext.findRenderObject() as RenderBox;
    final overlayBox = Navigator.of(fieldContext)
        .overlay!
        .context
        .findRenderObject()! as RenderBox;
    final fieldOffset =
        fieldBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final fieldRect = fieldOffset & fieldBox.size;
    final menuHeight = math.min(
      _projectDropdownMenuMaxHeight,
      items.length * _projectDropdownItemHeight,
    );
    final bottomSpace = overlayBox.size.height - fieldRect.bottom;
    final openAbove = preferOpenAbove ||
        (bottomSpace < menuHeight + 72 && fieldRect.top > menuHeight);
    final position = openAbove
        ? RelativeRect.fromLTRB(
            fieldRect.left,
            fieldRect.top - menuHeight,
            overlayBox.size.width - fieldRect.right,
            overlayBox.size.height - fieldRect.top,
          )
        : RelativeRect.fromLTRB(
            fieldRect.left,
            fieldRect.bottom,
            overlayBox.size.width - fieldRect.right,
            overlayBox.size.height - fieldRect.bottom,
          );

    final selected = await showMenu<T>(
      context: fieldContext,
      position: position,
      color: colors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shadowColor: colors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.line),
      ),
      constraints: BoxConstraints(
        minWidth: fieldRect.width,
        maxWidth: fieldRect.width,
        maxHeight: _projectDropdownMenuMaxHeight,
      ),
      items: [
        for (final item in items)
          PopupMenuItem<T>(
            value: item.value,
            height: _projectDropdownItemHeight,
            padding: EdgeInsets.zero,
            child: Container(
              height: _projectDropdownItemHeight,
              color:
                  item.value == value ? colors.background : Colors.transparent,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.text, fontSize: 14),
              ),
            ),
          ),
      ],
    );
    if (selected != null) {
      onChanged(selected);
    }
  }
}

class _ProjectWorldSettingRail extends StatefulWidget {
  const _ProjectWorldSettingRail({
    required this.novel,
    required this.settings,
    required this.selectedSettingId,
    required this.loading,
    required this.onBack,
    required this.onSelectSetting,
    required this.onAddSetting,
    this.onAddFolder,
    this.onImportFile,
    this.railTitle = '设定',
    this.addTooltip = '新增设定',
    this.itemIcon = Icons.description_outlined,
    this.onOpenPermissions,
    this.onDeleteSetting,
  });

  final NovelSummary novel;
  final List<NovelOutline> settings;
  final int? selectedSettingId;
  final bool loading;
  final VoidCallback onBack;
  final ValueChanged<NovelOutline> onSelectSetting;
  final VoidCallback onAddSetting;
  final ValueChanged<String>? onAddFolder;
  final VoidCallback? onImportFile;
  final String railTitle;
  final String addTooltip;
  final IconData itemIcon;
  final ValueChanged<NovelOutline>? onOpenPermissions;
  final ValueChanged<NovelOutline>? onDeleteSetting;

  @override
  State<_ProjectWorldSettingRail> createState() =>
      _ProjectWorldSettingRailState();
}

class _ProjectWorldSettingRailState extends State<_ProjectWorldSettingRail> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NovelOutline> get _visibleSettings {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return widget.settings;
    }
    return [
      for (final setting in widget.settings)
        if (_fuzzyContains(setting.title, query) ||
            _fuzzyContains(setting.status, query))
          setting,
    ];
  }

  Future<void> _addFolder() async {
    final name = await _showWorldSettingFolderDialog(context);
    if (name == null || name.trim().isEmpty) {
      return;
    }
    widget.onAddFolder?.call(name.trim());
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final visibleSettings = _visibleSettings;

    return Container(
      width: 204,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(right: BorderSide(color: colors.line)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 46,
            child: Row(
              children: [
                IconButton(
                  tooltip: '返回',
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.chevron_left),
                ),
                const Spacer(),
                IconButton(
                  tooltip: '收起侧栏',
                  onPressed: () {},
                  icon: const Icon(Icons.view_sidebar_outlined, size: 18),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: _NovelCover(novel: widget.novel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.novel.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
            child: Row(
              children: [
                Text(
                  widget.railTitle,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  widget.settings.length.toString(),
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
                const SizedBox(width: 6),
                if (widget.onAddFolder != null)
                  IconButton(
                    tooltip: '新建文件夹',
                    onPressed: _addFolder,
                    icon: Icon(Icons.create_new_folder_outlined,
                        size: 18, color: colors.muted),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints.tightFor(width: 22, height: 22),
                  ),
                IconButton(
                  tooltip: widget.addTooltip,
                  onPressed: widget.onAddSetting,
                  icon: Icon(Icons.add, size: 18, color: colors.muted),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints.tightFor(width: 22, height: 22),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 34,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '搜索',
                  prefixIcon: const Icon(Icons.search, size: 16),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.line),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (widget.loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: LinearProgressIndicator(
                minHeight: 2,
                color: colors.text,
                backgroundColor: colors.line,
              ),
            )
          else
            Expanded(
              child: visibleSettings.isEmpty
                  ? Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
                        child: Text(
                          '暂无内容',
                          style: TextStyle(color: colors.muted, fontSize: 13),
                        ),
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        for (final setting in visibleSettings)
                          _WorldSettingRow(
                            setting: setting,
                            selected: setting.id == widget.selectedSettingId,
                            icon: widget.itemIcon,
                            onTap: () => widget.onSelectSetting(setting),
                            onOpenPermissions: widget.onOpenPermissions == null
                                ? null
                                : () => widget.onOpenPermissions!(setting),
                            onDelete: widget.onDeleteSetting == null
                                ? null
                                : () => widget.onDeleteSetting!(setting),
                          ),
                      ],
                    ),
            ),
          if (widget.onImportFile != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: OutlinedButton.icon(
                onPressed: widget.onImportFile,
                icon: const Icon(Icons.description_outlined, size: 14),
                label: const Text('导入文件'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(34),
                  foregroundColor: colors.muted,
                  side: BorderSide(color: colors.line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WorldSettingRow extends StatelessWidget {
  const _WorldSettingRow({
    required this.setting,
    required this.selected,
    required this.onTap,
    this.icon = Icons.description_outlined,
    this.onOpenPermissions,
    this.onDelete,
  });

  final NovelOutline setting;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  final VoidCallback? onOpenPermissions;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return GestureDetector(
      onSecondaryTapDown: onOpenPermissions == null && onDelete == null
          ? null
          : (details) => unawaited(_showMenu(context, details)),
      onLongPress: onOpenPermissions == null && onDelete == null
          ? null
          : () => unawaited(_showMenu(context, null)),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: selected ? colors.line.withValues(alpha: 0.65) : null,
          child: Row(
            children: [
              Icon(icon, size: 15, color: colors.text),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      setting.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    if (setting.status.trim().isNotEmpty)
                      Text(
                        setting.status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.muted, fontSize: 11),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMenu(
    BuildContext context,
    TapDownDetails? details,
  ) async {
    final colors = AppPalette.of(context);
    final position = details?.globalPosition ?? Offset.zero;
    final selectedAction = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      color: colors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.line),
      ),
      items: [
        if (onOpenPermissions != null)
          const PopupMenuItem(
            value: 'permissions',
            child: _ProjectMenuItem(
              icon: Icons.edit_outlined,
              label: '权限设置',
            ),
          ),
        if (onOpenPermissions != null && onDelete != null)
          const PopupMenuDivider(height: 1),
        if (onDelete != null)
          const PopupMenuItem(
            value: 'delete',
            child: _ProjectMenuItem(
              icon: Icons.delete_outline,
              label: '删除',
              destructive: true,
            ),
          ),
      ],
    );
    if (selectedAction == 'permissions') {
      onOpenPermissions?.call();
    }
    if (selectedAction == 'delete') {
      onDelete?.call();
    }
  }
}

class _WorldSettingEmptyMain extends StatelessWidget {
  const _WorldSettingEmptyMain({
    required this.novel,
    required this.onAddSetting,
    this.workspaceTitle = '设定',
    this.emptyTitle = '还没有选中设定',
    this.emptyDescription = '先新建第一条设定内容。',
    this.buttonLabel = '新建世界观',
  });

  final NovelSummary novel;
  final VoidCallback onAddSetting;
  final String workspaceTitle;
  final String emptyTitle;
  final String emptyDescription;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      color: colors.background,
      child: Column(
        children: [
          _WorkspaceHeader(
            title: '${novel.title}  >  $workspaceTitle',
            actions: const [],
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined,
                      size: 30, color: colors.muted),
                  const SizedBox(height: 14),
                  Text(
                    emptyTitle,
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    emptyDescription,
                    style: TextStyle(color: colors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: onAddSetting,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.text,
                      foregroundColor: colors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(buttonLabel),
                  ),
                ],
              ),
            ),
          ),
          const _WorkspaceHistoryBar(),
        ],
      ),
    );
  }
}

class _WorldSettingEditorMain extends StatefulWidget {
  const _WorldSettingEditorMain({
    required this.novel,
    required this.setting,
    required this.loading,
    required this.error,
    required this.onSave,
    this.workspaceTitle = '设定',
    this.description = '先约束规则、历史与势力，避免后续冲突。',
    this.titleHint = '输入标题',
    this.includeItemInHeader = false,
    this.showPhotoGallery = false,
    this.showNameAssistant = false,
    this.onRequestAiName,
  });

  final NovelSummary novel;
  final NovelOutline? setting;
  final bool loading;
  final String? error;
  final String workspaceTitle;
  final String description;
  final String titleHint;
  final bool includeItemInHeader;
  final bool showPhotoGallery;
  final bool showNameAssistant;
  final void Function({
    required String title,
    required String category,
    required String content,
  })? onRequestAiName;
  final Future<NovelOutline> Function({
    required String title,
    required String category,
    required String content,
    required List<String> photoPaths,
  }) onSave;

  @override
  State<_WorldSettingEditorMain> createState() =>
      _WorldSettingEditorMainState();
}

class _WorldSettingEditorMainState extends State<_WorldSettingEditorMain> {
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _contentController = TextEditingController();
  var _photoPaths = <String>[];
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant _WorldSettingEditorMain oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.setting?.id != widget.setting?.id ||
        oldWidget.setting?.updatedAt != widget.setting?.updatedAt) {
      _syncControllers();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    final setting = widget.setting;
    _titleController.text = setting?.title ?? '';
    _categoryController.text =
        setting == null ? '' : _cleanWorldSettingCategory(setting.status);
    _contentController.text = setting?.content ?? '';
    _photoPaths = setting == null ? [] : _outlinePhotoPaths(setting);
    _dirty = false;
  }

  void _markDirty() {
    if (!_dirty) {
      setState(() => _dirty = true);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(
        title: _titleController.text,
        category: _categoryController.text,
        content: _contentController.text,
        photoPaths: _photoPaths,
      );
      if (mounted) {
        setState(() {
          _dirty = false;
          _saving = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
      }
      rethrow;
    }
  }

  void _discard() {
    setState(_syncControllers);
  }

  Future<void> _addPhoto() async {
    final files = await openFiles(acceptedTypeGroups: _characterImageTypes);
    if (files.isEmpty || !mounted) {
      return;
    }
    setState(() {
      _photoPaths = [
        ..._photoPaths,
        for (final file in files) file.path,
      ];
      _dirty = true;
    });
  }

  void _showPhotoNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('图片生成入口尚未接入，请先使用“添加照片”。')),
    );
  }

  Future<void> _openNameAssistant() async {
    final action = await _showSkillNameDialog(context);
    if (!mounted || action == null) {
      return;
    }
    if (action == _SkillNameAction.random) {
      _titleController.text = _randomSkillNameFromForm();
      _markDirty();
      return;
    }
    widget.onRequestAiName?.call(
      title: _titleController.text,
      category: _categoryController.text,
      content: _contentController.text,
    );
  }

  String _randomSkillNameFromForm() {
    final source = [
      _categoryController.text,
      _contentController.text,
      _titleController.text,
    ].join(' ');
    final phrases = source
        .replaceAll(RegExp(r'[，。、“”"：:；;,.!?！？（）()\[\]【】\n\r]+'), ' ')
        .split(RegExp(r'\s+'))
        .map((value) => value.trim())
        .where((value) => value.length >= 2 && !value.startsWith('未命名'))
        .toList();
    if (phrases.isEmpty) {
      final current = _titleController.text.trim();
      return current.isEmpty ? '未命名技能' : current;
    }
    final phrase =
        phrases[DateTime.now().microsecondsSinceEpoch % phrases.length];
    return phrase.length > 12 ? phrase.substring(0, 12) : phrase;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = widget.error;
    if (error != null) {
      return Center(child: Text(error));
    }
    final itemTitle = widget.setting?.title.trim();
    final headerTitle = widget.includeItemInHeader &&
            itemTitle != null &&
            itemTitle.isNotEmpty
        ? '${widget.novel.title}  >  ${widget.workspaceTitle}  >  $itemTitle'
        : '${widget.novel.title}  >  ${widget.workspaceTitle}';

    return Column(
      children: [
        _WorkspaceHeader(
          title: headerTitle,
          actions: [
            Text(
              _saving ? '保存中' : (_dirty ? '未保存' : '已保存'),
              style: TextStyle(color: colors.muted, fontSize: 12),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: _dirty ? _discard : null,
              child: const Text('丢弃'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _saving || !_dirty ? null : () => unawaited(_save()),
              style: FilledButton.styleFrom(
                backgroundColor: colors.text,
                foregroundColor: colors.card,
                disabledBackgroundColor: colors.line,
                disabledForegroundColor: colors.muted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('保存'),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 636),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 24, 0, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.workspaceTitle,
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.description,
                        style: TextStyle(color: colors.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      const _FieldLabel('标题'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _titleController,
                        onChanged: (_) => _markDirty(),
                        decoration: InputDecoration(
                          hintText: widget.titleHint,
                          suffixIcon: widget.showNameAssistant
                              ? IconButton(
                                  tooltip: '起名助手',
                                  icon:
                                      const Icon(Icons.auto_awesome, size: 16),
                                  onPressed: _openNameAssistant,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel('分类'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _categoryController,
                        onChanged: (_) => _markDirty(),
                        decoration:
                            const InputDecoration(hintText: '如：关键物品、地理、势力'),
                      ),
                      if (widget.showPhotoGallery) ...[
                        const SizedBox(height: 18),
                        _CharacterAssetCard(
                          title: '照片集',
                          trailing: TextButton.icon(
                            onPressed: _showPhotoNotice,
                            icon: const Icon(Icons.auto_awesome, size: 15),
                            label: const Text('生成照片'),
                            style: TextButton.styleFrom(
                              foregroundColor: colors.text,
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                          child: SizedBox(
                            height: 86,
                            child: _photoPaths.isEmpty
                                ? Center(
                                    child: _OutlineButton(
                                      icon: Icons.add,
                                      label: '添加照片',
                                      onPressed: _addPhoto,
                                    ),
                                  )
                                : ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _photoPaths.length + 1,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, index) {
                                      if (index == _photoPaths.length) {
                                        return _GalleryAddButton(
                                          onTap: _addPhoto,
                                        );
                                      }
                                      return _GalleryThumb(
                                        path: _photoPaths[index],
                                        onRemove: () {
                                          setState(() {
                                            _photoPaths = [
                                              ..._photoPaths.take(index),
                                              ..._photoPaths.skip(index + 1),
                                            ];
                                            _dirty = true;
                                          });
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      const _FieldLabel('内容'),
                      const SizedBox(height: 8),
                      const _WorldSettingToolbar(),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _contentController,
                        onChanged: (_) => _markDirty(),
                        minLines: 16,
                        maxLines: null,
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 15,
                          height: 1.75,
                        ),
                        decoration: const InputDecoration(hintText: '在这里整理内容。'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const _WorkspaceHistoryBar(),
      ],
    );
  }
}

enum _SkillNameAction { random, ai }

Future<_SkillNameAction?> _showSkillNameDialog(BuildContext context) {
  return showDialog<_SkillNameAction>(
    context: context,
    builder: (context) => const _SkillNameDialog(),
  );
}

class _SkillNameDialog extends StatelessWidget {
  const _SkillNameDialog();

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 408),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '技能起名',
                style: TextStyle(
                  color: colors.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(_SkillNameAction.random),
                  icon: const Icon(Icons.shuffle, size: 16),
                  label: const Text('随机起名'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(_SkillNameAction.ai),
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('AI 起名'),
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorldSettingToolbar extends StatelessWidget {
  const _WorldSettingToolbar();

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (final item in const [
            (Icons.format_bold, '加粗'),
            (Icons.format_italic, '斜体'),
            (Icons.strikethrough_s, '删除线'),
            (Icons.title, '标题'),
            (Icons.format_list_bulleted, '无序列表'),
            (Icons.format_list_numbered, '有序列表'),
            (Icons.format_quote, '引用'),
          ])
            IconButton(
              tooltip: item.$2,
              onPressed: () {},
              icon: Icon(item.$1, size: 16),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: 28,
                height: 28,
              ),
            ),
        ],
      ),
    );
  }
}

class _FactionPermissionDraft {
  const _FactionPermissionDraft({
    required this.readAccess,
    required this.writeAccess,
  });

  final String readAccess;
  final String writeAccess;
}

Future<_FactionPermissionDraft?> _showFactionPermissionDialog(
  BuildContext context,
  NovelOutline faction,
) {
  return showDialog<_FactionPermissionDraft>(
    context: context,
    builder: (context) => _FactionPermissionDialog(faction: faction),
  );
}

class _FactionPermissionDialog extends StatefulWidget {
  const _FactionPermissionDialog({required this.faction});

  final NovelOutline faction;

  @override
  State<_FactionPermissionDialog> createState() =>
      _FactionPermissionDialogState();
}

class _FactionPermissionDialogState extends State<_FactionPermissionDialog> {
  late String _readAccess;
  late String _writeAccess;

  @override
  void initState() {
    super.initState();
    _readAccess = _outlineAccess(widget.faction, 'readAccess');
    _writeAccess = _outlineAccess(widget.faction, 'writeAccess');
  }

  void _submit() {
    Navigator.of(context).pop(
      _FactionPermissionDraft(
        readAccess: _readAccess,
        writeAccess: _writeAccess,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 328),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '「${widget.faction.title}」访问权限',
                style: TextStyle(
                  color: colors.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              const _FieldLabel('读取权限'),
              _FactionPermissionOption(
                selected: _readAccess == _accessOpen,
                label: '开放',
                onTap: () => setState(() => _readAccess = _accessOpen),
              ),
              _FactionPermissionOption(
                selected: _readAccess == 'ai_hidden',
                label: '对 AI 隐藏',
                onTap: () => setState(() => _readAccess = 'ai_hidden'),
              ),
              const SizedBox(height: 8),
              const _FieldLabel('写入权限'),
              _FactionPermissionOption(
                selected: _writeAccess == _accessOpen,
                label: '开放',
                onTap: () => setState(() => _writeAccess = _accessOpen),
              ),
              _FactionPermissionOption(
                selected: _writeAccess == 'ai_readonly',
                label: 'AI 不可编辑',
                onTap: () => setState(() => _writeAccess = 'ai_readonly'),
              ),
              _FactionPermissionOption(
                selected: _writeAccess == 'locked',
                label: '锁住',
                onTap: () => setState(() => _writeAccess = 'locked'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.text,
                      foregroundColor: colors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('确定'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FactionPermissionOption extends StatelessWidget {
  const _FactionPermissionOption({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? colors.brand : colors.text,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(color: colors.text, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool?> _showDeleteFactionDialog(
  BuildContext context,
  NovelOutline faction,
) {
  final colors = AppPalette.of(context);
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('删除'),
      content: Text('确定要删除“${faction.title}”吗？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: colors.brand),
          child: const Text('删除'),
        ),
      ],
    ),
  );
}

class _WorkspaceHistoryBar extends StatelessWidget {
  const _WorkspaceHistoryBar();

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.history, size: 15),
        label: const Text('历史'),
        style: TextButton.styleFrom(
          foregroundColor: colors.text,
          textStyle: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

Future<String?> _showWorldSettingFolderDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => const _WorldSettingFolderDialog(),
  );
}

class _WorldSettingFolderDialog extends StatefulWidget {
  const _WorldSettingFolderDialog();

  @override
  State<_WorldSettingFolderDialog> createState() =>
      _WorldSettingFolderDialogState();
}

class _WorldSettingFolderDialogState extends State<_WorldSettingFolderDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '新建文件夹',
                style: TextStyle(
                  color: colors.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(hintText: '输入文件夹名称'),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.text,
                      foregroundColor: colors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('新建'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectForeshadowingRail extends StatefulWidget {
  const _ProjectForeshadowingRail({
    required this.novel,
    required this.foreshadowings,
    required this.selectedForeshadowingId,
    required this.loading,
    required this.onBack,
    required this.onSelectForeshadowing,
    required this.onAddForeshadowing,
    required this.onDeleteForeshadowing,
  });

  final NovelSummary novel;
  final List<NovelForeshadowing> foreshadowings;
  final int? selectedForeshadowingId;
  final bool loading;
  final VoidCallback onBack;
  final ValueChanged<NovelForeshadowing> onSelectForeshadowing;
  final VoidCallback onAddForeshadowing;
  final ValueChanged<NovelForeshadowing> onDeleteForeshadowing;

  @override
  State<_ProjectForeshadowingRail> createState() =>
      _ProjectForeshadowingRailState();
}

class _ProjectForeshadowingRailState extends State<_ProjectForeshadowingRail> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NovelForeshadowing> get _visibleForeshadowings {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return widget.foreshadowings;
    }
    return [
      for (final foreshadowing in widget.foreshadowings)
        if (_fuzzyContains(foreshadowing.title, query) ||
            _fuzzyContains(foreshadowing.status, query))
          foreshadowing,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final visibleForeshadowings = _visibleForeshadowings;

    return Container(
      width: 204,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(right: BorderSide(color: colors.line)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 46,
            child: Row(
              children: [
                IconButton(
                  tooltip: '返回',
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.chevron_left),
                ),
                const Spacer(),
                Icon(Icons.view_sidebar_outlined,
                    size: 18, color: colors.muted),
                const SizedBox(width: 14),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: _NovelCover(novel: widget.novel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.novel.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
            child: Row(
              children: [
                Text(
                  '伏笔',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  widget.foreshadowings.length.toString(),
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: '新增伏笔',
                  onPressed: widget.onAddForeshadowing,
                  icon: Icon(Icons.add, size: 18, color: colors.muted),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 22,
                    height: 22,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 34,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '搜索',
                  prefixIcon: const Icon(Icons.search, size: 16),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.line),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (widget.loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: LinearProgressIndicator(
                minHeight: 2,
                color: colors.text,
                backgroundColor: colors.line,
              ),
            )
          else
            Expanded(
              child: visibleForeshadowings.isEmpty
                  ? Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
                        child: Text(
                          '暂无内容',
                          style: TextStyle(color: colors.muted, fontSize: 13),
                        ),
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        for (final foreshadowing in visibleForeshadowings)
                          _ForeshadowingRow(
                            foreshadowing: foreshadowing,
                            selected: foreshadowing.id ==
                                widget.selectedForeshadowingId,
                            onTap: () =>
                                widget.onSelectForeshadowing(foreshadowing),
                            onDelete: () =>
                                widget.onDeleteForeshadowing(foreshadowing),
                          ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}

class _ForeshadowingRow extends StatelessWidget {
  const _ForeshadowingRow({
    required this.foreshadowing,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  final NovelForeshadowing foreshadowing;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return GestureDetector(
      onSecondaryTapDown: (details) => _showForeshadowingMenu(
        context,
        details,
      ),
      child: SizedBox(
        height: 32,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            color: selected ? colors.line.withValues(alpha: 0.65) : null,
            child: Row(
              children: [
                _ForeshadowingStatusDot(status: foreshadowing.status),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    foreshadowing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showForeshadowingMenu(
    BuildContext context,
    TapDownDetails details,
  ) async {
    final colors = AppPalette.of(context);
    final selectedAction = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      color: colors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.line),
      ),
      items: [
        PopupMenuItem(
          value: 'delete',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 16, color: colors.brand),
              const SizedBox(width: 10),
              Text(
                '删除伏笔',
                style: TextStyle(
                  color: colors.brand,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    if (selectedAction == 'delete') {
      onDelete();
    }
  }
}

class _ForeshadowingEmptyMain extends StatelessWidget {
  const _ForeshadowingEmptyMain({
    required this.novel,
    required this.onAddForeshadowing,
  });

  final NovelSummary novel;
  final VoidCallback onAddForeshadowing;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Column(
      children: [
        _WorkspaceHeader(
          title: '${novel.title} > 伏笔',
          actions: const [],
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.route_outlined, size: 32, color: colors.muted),
                const SizedBox(height: 18),
                Text(
                  '还没有选中伏笔',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '先新建第一条伏笔内容。',
                  style: TextStyle(color: colors.muted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onAddForeshadowing,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.text,
                    foregroundColor: colors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('新建伏笔'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ForeshadowingEditorMain extends StatefulWidget {
  const _ForeshadowingEditorMain({
    required this.novel,
    required this.foreshadowing,
    required this.loading,
    required this.error,
    required this.onSave,
  });

  final NovelSummary novel;
  final NovelForeshadowing? foreshadowing;
  final bool loading;
  final String? error;
  final Future<NovelForeshadowing> Function({
    required String title,
    required String status,
    required String setupContent,
    required String payoffContent,
  }) onSave;

  @override
  State<_ForeshadowingEditorMain> createState() =>
      _ForeshadowingEditorMainState();
}

class _ForeshadowingEditorMainState extends State<_ForeshadowingEditorMain> {
  final _titleController = TextEditingController();
  final _setupController = TextEditingController();
  final _payoffController = TextEditingController();
  var _status = _foreshadowingStatuses[1];
  var _tabIndex = 0;
  bool _saving = false;
  bool _dirty = false;
  bool _syncing = false;
  DateTime? _savedAt;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
    for (final controller in _controllers) {
      controller.addListener(_markDirty);
    }
  }

  @override
  void didUpdateWidget(covariant _ForeshadowingEditorMain oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.foreshadowing?.id != widget.foreshadowing?.id) {
      _syncFromWidget();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<TextEditingController> get _controllers => [
        _titleController,
        _setupController,
        _payoffController,
      ];

  void _syncFromWidget() {
    final foreshadowing = widget.foreshadowing;
    _syncing = true;
    _titleController.text = foreshadowing?.title ?? '';
    _status = _optionOrFallback(
      foreshadowing?.status,
      _foreshadowingStatuses,
    );
    _setupController.text = foreshadowing?.setupContent ?? '';
    _payoffController.text = foreshadowing?.payoffContent ?? '';
    _savedAt = foreshadowing?.updatedAt;
    _dirty = false;
    _syncing = false;
  }

  String _optionOrFallback(String? value, List<String> options) {
    final clean = value?.trim();
    if (clean != null && clean.isNotEmpty && options.contains(clean)) {
      return clean;
    }
    return options[1];
  }

  void _markDirty() {
    if (_syncing || _dirty) {
      return;
    }
    setState(() => _dirty = true);
  }

  void _changeStatus(String status) {
    setState(() {
      _status = status;
      _dirty = true;
    });
  }

  void _discard() {
    setState(_syncFromWidget);
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await widget.onSave(
        title: _titleController.text,
        status: _status,
        setupContent: _setupController.text,
        payoffContent: _payoffController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _savedAt = saved.updatedAt;
        _dirty = false;
        _saving = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showHistory() {
    final updated = _savedAt;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('历史'),
        content: Text(
          updated == null
              ? '当前伏笔还没有保存记录。'
              : '当前版本已保存。最近保存时间：${_formatClock(updated)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Column(
      children: [
        _WorkspaceHeader(
          title: '${widget.novel.title} > 伏笔',
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Text(
                  _dirty ? '未保存' : '已保存',
                  style: TextStyle(
                    color: _dirty ? colors.text : colors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: _dirty ? _discard : null,
              child: const Text('丢弃'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: colors.text,
                foregroundColor: colors.card,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(_saving ? '保存中' : '保存'),
            ),
          ],
        ),
        Expanded(
          child: Stack(
            children: [
              if (widget.loading)
                Center(child: CircularProgressIndicator(color: colors.text))
              else
                SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 636),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 26, 0, 82),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '伏笔',
                              style: TextStyle(
                                color: colors.text,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '记录伏笔埋设位置、关联章节与回收状态。',
                              style:
                                  TextStyle(color: colors.muted, fontSize: 13),
                            ),
                            const SizedBox(height: 24),
                            _CharacterCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FieldLabel('标题'),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _titleController,
                                    decoration: const InputDecoration(
                                      hintText: '输入标题',
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _ForeshadowingStatusField(
                                    value: _status,
                                    onChanged: _changeStatus,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            _ForeshadowingTabs(
                              index: _tabIndex,
                              onChanged: (index) =>
                                  setState(() => _tabIndex = index),
                            ),
                            const SizedBox(height: 10),
                            const _EditorToolbar(),
                            const SizedBox(height: 10),
                            _EditorBox(
                              controller: _tabIndex == 0
                                  ? _setupController
                                  : _payoffController,
                              hintText: _tabIndex == 0
                                  ? '记录伏笔埋设方式、出现位置和触发条件。'
                                  : '记录伏笔回收方式、揭示章节和读者感受。',
                              minLines: 17,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (widget.error != null)
                Positioned(
                  left: 24,
                  right: 24,
                  top: 18,
                  child: Material(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        widget.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        _CharacterStatusBar(
          saving: _saving,
          updatedAt: _savedAt,
          onHistory: _showHistory,
        ),
      ],
    );
  }
}

class _ForeshadowingStatusField extends StatelessWidget {
  const _ForeshadowingStatusField({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('状态'),
        const SizedBox(height: 8),
        PopupMenuButton<String>(
          tooltip: '状态',
          constraints: const BoxConstraints(maxHeight: 196, minWidth: 240),
          onSelected: onChanged,
          itemBuilder: (context) => [
            for (final status in _foreshadowingStatuses)
              PopupMenuItem(
                value: status,
                height: 36,
                child: Row(
                  children: [
                    _ForeshadowingStatusDot(status: status),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        status,
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 13,
                          fontWeight: status == value
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (status == value)
                      Icon(Icons.check_circle_outline,
                          size: 15, color: colors.text),
                  ],
                ),
              ),
          ],
          child: InputDecorator(
            decoration: InputDecoration(
              suffixIcon: const Icon(Icons.expand_more, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              children: [
                _ForeshadowingStatusDot(status: value),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.text, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ForeshadowingTabs extends StatelessWidget {
  const _ForeshadowingTabs({
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.line.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _ForeshadowingTab(
            label: '埋设',
            selected: index == 0,
            onTap: () => onChanged(0),
          ),
          const SizedBox(width: 4),
          _ForeshadowingTab(
            label: '回收',
            selected: index == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _ForeshadowingTab extends StatelessWidget {
  const _ForeshadowingTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: colors.text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ForeshadowingStatusDot extends StatelessWidget {
  const _ForeshadowingStatusDot({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      '已兑现' => const Color(0xFF111827),
      '已废弃' => const Color(0xFF6B7280),
      '已埋设' => const Color(0xFF707070),
      _ => const Color(0xFFB8B8B8),
    };
    return Icon(Icons.circle, size: 8, color: color);
  }
}

const _foreshadowingStatuses = ['未开始', '已埋设', '已兑现', '已废弃'];

class _ProjectCharacterRail extends StatefulWidget {
  const _ProjectCharacterRail({
    required this.novel,
    required this.characters,
    required this.selectedCharacterId,
    required this.loading,
    required this.onBack,
    required this.onSelectCharacter,
    required this.onAddCharacter,
    required this.onDeleteCharacter,
  });

  final NovelSummary novel;
  final List<NovelCharacter> characters;
  final int? selectedCharacterId;
  final bool loading;
  final VoidCallback onBack;
  final ValueChanged<NovelCharacter> onSelectCharacter;
  final VoidCallback onAddCharacter;
  final ValueChanged<NovelCharacter> onDeleteCharacter;

  @override
  State<_ProjectCharacterRail> createState() => _ProjectCharacterRailState();
}

class _ProjectCharacterRailState extends State<_ProjectCharacterRail> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NovelCharacter> get _visibleCharacters {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return widget.characters;
    }
    return [
      for (final character in widget.characters)
        if (_fuzzyContains(character.name, query)) character,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final visibleCharacters = _visibleCharacters;

    return Container(
      width: 204,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(right: BorderSide(color: colors.line)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 46,
            child: Row(
              children: [
                IconButton(
                  tooltip: '返回',
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.chevron_left),
                ),
                const Spacer(),
                IconButton(
                  tooltip: '收起侧栏',
                  onPressed: () {},
                  icon: const Icon(Icons.view_sidebar_outlined, size: 18),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: _NovelCover(novel: widget.novel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.novel.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
            child: Row(
              children: [
                Text(
                  '人物',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  widget.characters.length.toString(),
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: '新增人物',
                  onPressed: widget.onAddCharacter,
                  icon: Icon(Icons.add, color: colors.muted, size: 18),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 22,
                    height: 22,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 34,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '搜索',
                  prefixIcon: const Icon(Icons.search, size: 16),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.line),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (widget.loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: LinearProgressIndicator(
                minHeight: 2,
                color: colors.text,
                backgroundColor: colors.line,
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final character in visibleCharacters)
                    _CharacterRow(
                      character: character,
                      selected: character.id == widget.selectedCharacterId,
                      onTap: () => widget.onSelectCharacter(character),
                      onDelete: () => widget.onDeleteCharacter(character),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CharacterRow extends StatelessWidget {
  const _CharacterRow({
    required this.character,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  final NovelCharacter character;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return GestureDetector(
      onSecondaryTapDown: (details) => _showCharacterMenu(context, details),
      child: SizedBox(
        height: 31,
        child: InkWell(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: selected ? colors.line.withValues(alpha: 0.55) : null,
            child: Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 15,
                  color: selected ? colors.text : colors.muted,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    character.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCharacterMenu(
    BuildContext context,
    TapDownDetails details,
  ) async {
    final colors = AppPalette.of(context);
    final selectedAction = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      color: colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.line),
      ),
      items: [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 16, color: colors.text),
              const SizedBox(width: 8),
              const Text('删除人物'),
            ],
          ),
        ),
      ],
    );
    if (selectedAction == 'delete') {
      onDelete();
    }
  }
}

class _CharacterEmptyMain extends StatelessWidget {
  const _CharacterEmptyMain({
    required this.novel,
    required this.onAddCharacter,
  });

  final NovelSummary novel;
  final VoidCallback onAddCharacter;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Column(
      children: [
        _WorkspaceHeader(
          title: '${novel.title} > 人物',
          actions: const [],
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.line),
                  ),
                  child:
                      Icon(Icons.people_outline, size: 32, color: colors.muted),
                ),
                const SizedBox(height: 20),
                Text(
                  '还没有人物',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '先建立第一个角色档案。',
                  style: TextStyle(color: colors.muted, fontSize: 13),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onAddCharacter,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('新建人物'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.text,
                    foregroundColor: colors.card,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CharacterEditorMain extends StatefulWidget {
  const _CharacterEditorMain({
    required this.novel,
    required this.character,
    required this.chapters,
    required this.availableSkills,
    required this.loading,
    required this.error,
    required this.onSave,
    required this.onCreateSkill,
    required this.onDelete,
    required this.onAskAssistant,
  });

  final NovelSummary novel;
  final NovelCharacter? character;
  final List<NovelChapter> chapters;
  final List<NovelOutline> availableSkills;
  final bool loading;
  final String? error;
  final Future<NovelCharacter> Function({
    required String name,
    required String role,
    required String gender,
    required String identity,
    required String age,
    required String motivation,
    required String arc,
    required String? avatarPath,
    required List<String> galleryPaths,
    required int? firstChapterId,
    required String biography,
    required String currentState,
    required List<NovelCharacterSkill> skills,
  }) onSave;
  final Future<NovelOutline> Function({
    required String title,
    required String content,
  }) onCreateSkill;
  final VoidCallback? onDelete;
  final void Function(NovelCharacter character, String prompt) onAskAssistant;

  @override
  State<_CharacterEditorMain> createState() => _CharacterEditorMainState();
}

class _CharacterEditorMainState extends State<_CharacterEditorMain> {
  final _nameController = TextEditingController();
  final _identityController = TextEditingController();
  final _ageController = TextEditingController();
  final _motivationController = TextEditingController();
  final _arcController = TextEditingController();
  final _biographyController = TextEditingController();
  final _currentStateController = TextEditingController();
  Timer? _autosaveTimer;
  String _role = _characterRoles.first;
  String _gender = _characterGenders.last;
  String? _avatarPath;
  var _galleryPaths = <String>[];
  int? _firstChapterId;
  var _skills = <NovelCharacterSkill>[];
  var _tabIndex = 0;
  bool _saving = false;
  bool _syncing = false;
  DateTime? _savedAt;
  _CharacterHistorySnapshot? _historySnapshot;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
    for (final controller in _controllers) {
      controller.addListener(_scheduleAutosave);
    }
  }

  @override
  void didUpdateWidget(covariant _CharacterEditorMain oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character?.id != widget.character?.id) {
      _syncFromWidget();
    }
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<TextEditingController> get _controllers => [
        _nameController,
        _identityController,
        _ageController,
        _motivationController,
        _arcController,
        _biographyController,
        _currentStateController,
      ];

  void _syncFromWidget() {
    final character = widget.character;
    _syncing = true;
    _nameController.text = character?.name ?? '';
    _role = _optionOrFallback(character?.role, _characterRoles);
    _gender = _optionOrFallback(character?.gender, _characterGenders);
    _identityController.text = character?.identity ?? '';
    _ageController.text = character?.age ?? '未知';
    _motivationController.text = character?.motivation ?? '';
    _arcController.text = character?.arc ?? '';
    _avatarPath = character?.avatarPath;
    _galleryPaths = [...?character?.galleryPaths];
    _firstChapterId = character?.firstChapterId;
    _biographyController.text = character?.biography ?? '';
    _currentStateController.text = character?.currentState ?? '';
    _skills = [...?character?.skills];
    _savedAt = character?.updatedAt;
    _historySnapshot = character == null
        ? null
        : _CharacterHistorySnapshot.fromCharacter(character);
    _syncing = false;
  }

  String _optionOrFallback(String? value, List<String> options) {
    final clean = value?.trim();
    if (clean != null && clean.isNotEmpty && options.contains(clean)) {
      return clean;
    }
    return options.first;
  }

  void _scheduleAutosave() {
    if (_syncing) {
      return;
    }
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 700), _save);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _save() async {
    _autosaveTimer?.cancel();
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await widget.onSave(
        name: _nameController.text,
        role: _role,
        gender: _gender,
        identity: _identityController.text,
        age: _ageController.text,
        motivation: _motivationController.text,
        arc: _arcController.text,
        avatarPath: _avatarPath,
        galleryPaths: _galleryPaths,
        firstChapterId: _firstChapterId,
        biography: _biographyController.text,
        currentState: _currentStateController.text,
        skills: _skills,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _savedAt = saved.updatedAt;
        _historySnapshot = _CharacterHistorySnapshot.fromCharacter(saved);
        _saving = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickAvatar() async {
    final file = await openFile(acceptedTypeGroups: _characterImageTypes);
    if (file == null || !mounted) {
      return;
    }
    setState(() => _avatarPath = file.path);
    _scheduleAutosave();
  }

  Future<void> _addGalleryPhoto() async {
    final files = await openFiles(acceptedTypeGroups: _characterImageTypes);
    if (files.isEmpty || !mounted) {
      return;
    }
    setState(() {
      _galleryPaths = [
        ..._galleryPaths,
        for (final file in files) file.path,
      ];
    });
    _scheduleAutosave();
  }

  Future<void> _selectFirstChapter() async {
    final chapterId = await _showChapterPicker(
      context,
      chapters: widget.chapters,
      selectedChapterId: _firstChapterId,
    );
    if (!mounted) {
      return;
    }
    setState(() => _firstChapterId = chapterId);
    _scheduleAutosave();
  }

  Future<void> _addSkill() async {
    final skill = await _showCharacterSkillDialog(
      context,
      existingSkills: widget.availableSkills,
      onCreateSkill: widget.onCreateSkill,
    );
    if (skill == null || !mounted) {
      return;
    }
    final index = _skills.indexWhere((item) {
      final skillId = skill.skillId;
      if (skillId != null && item.skillId == skillId) {
        return true;
      }
      return item.skillId == null && item.name == skill.name;
    });
    setState(() {
      if (index < 0) {
        _skills = [..._skills, skill];
      } else {
        _skills = [
          ..._skills.take(index),
          skill,
          ..._skills.skip(index + 1),
        ];
      }
    });
    _scheduleAutosave();
  }

  String get _firstChapterLabel {
    final id = _firstChapterId;
    if (id == null) {
      return '无';
    }
    for (final chapter in widget.chapters) {
      if (chapter.id == id) {
        return chapter.title;
      }
    }
    return '无';
  }

  void _askAvatarPrompt() {
    final character = widget.character;
    if (character == null) {
      return;
    }
    widget.onAskAssistant(
      character,
      '请根据人物“${_nameController.text.trim()}”的身份、动机、弧光和小传，生成一份头像绘制提示词。',
    );
  }

  void _showPhotoNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('桌面拍照入口尚未接入摄像头，请先使用“添加照片”。')),
    );
  }

  void _showHistory() {
    showDialog<void>(
      context: context,
      builder: (context) => _CharacterHistoryDialog(
        snapshot: _historySnapshot,
        onRestore: _restoreHistorySnapshot,
      ),
    );
  }

  Future<void> _restoreHistorySnapshot(
      _CharacterHistorySnapshot snapshot) async {
    _syncing = true;
    setState(() {
      _nameController.text = snapshot.name;
      _role = snapshot.role;
      _gender = snapshot.gender;
      _identityController.text = snapshot.identity;
      _ageController.text = snapshot.age;
      _motivationController.text = snapshot.motivation;
      _arcController.text = snapshot.arc;
      _avatarPath = snapshot.avatarPath;
      _galleryPaths = [...snapshot.galleryPaths];
      _firstChapterId = snapshot.firstChapterId;
      _biographyController.text = snapshot.biography;
      _currentStateController.text = snapshot.currentState;
      _skills = [...snapshot.skills];
      _savedAt = snapshot.updatedAt;
    });
    _syncing = false;
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final characterName = _nameController.text.trim().isEmpty
        ? '未命名'
        : _nameController.text.trim();

    return Column(
      children: [
        _WorkspaceHeader(
          title: '${widget.novel.title} > 人物 > $characterName',
          actions: [
            IconButton(
              tooltip: '历史',
              onPressed: _showHistory,
              icon: const Icon(Icons.history, size: 18),
            ),
            IconButton(
              tooltip: '灵感',
              onPressed: _askAvatarPrompt,
              icon: const Icon(Icons.rocket_launch_outlined, size: 18),
            ),
            if (widget.onDelete != null)
              IconButton(
                tooltip: '删除人物',
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            const SizedBox(width: 6),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: colors.text,
                foregroundColor: colors.card,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('保存'),
            ),
          ],
        ),
        Expanded(
          child: Stack(
            children: [
              if (widget.loading)
                Center(child: CircularProgressIndicator(color: colors.text))
              else
                SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 668),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 26, 0, 72),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '人物',
                              style: TextStyle(
                                color: colors.text,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '管理角色小传、动机、关系、语气与成长弧线。',
                              style: TextStyle(
                                color: colors.muted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _CharacterCard(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final compact = constraints.maxWidth < 620;
                                  final nameField = _CharacterTextField(
                                    label: '名称',
                                    controller: _nameController,
                                  );
                                  final roleField = _CharacterSelectField(
                                    label: '定位',
                                    value: _role,
                                    values: _characterRoles,
                                    onChanged: (value) {
                                      setState(() => _role = value);
                                      _scheduleAutosave();
                                    },
                                  );
                                  final genderField = _CharacterSelectField(
                                    label: '性别',
                                    value: _gender,
                                    values: _characterGenders,
                                    onChanged: (value) {
                                      setState(() => _gender = value);
                                      _scheduleAutosave();
                                    },
                                  );
                                  return compact
                                      ? Column(
                                          children: [
                                            nameField,
                                            const SizedBox(height: 12),
                                            roleField,
                                            const SizedBox(height: 12),
                                            genderField,
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: nameField,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(child: roleField),
                                            const SizedBox(width: 12),
                                            Expanded(child: genderField),
                                          ],
                                        );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            _CharacterCard(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final compact = constraints.maxWidth < 560;
                                  final identity = _CharacterTextField(
                                    label: '身份',
                                    controller: _identityController,
                                    hintText: '如：松江府画师（隐名）、逃婚小姐',
                                  );
                                  final age = _CharacterTextField(
                                    label: '年龄',
                                    controller: _ageController,
                                  );
                                  return compact
                                      ? Column(
                                          children: [
                                            identity,
                                            const SizedBox(height: 12),
                                            age,
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Expanded(flex: 2, child: identity),
                                            const SizedBox(width: 12),
                                            Expanded(child: age),
                                          ],
                                        );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            _CharacterCard(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final compact = constraints.maxWidth < 560;
                                  final motivation = _CharacterTextField(
                                    label: '动机',
                                    controller: _motivationController,
                                    hintText: '驱动这个人物的核心动机是什么？',
                                  );
                                  final arc = _CharacterTextField(
                                    label: '弧光',
                                    controller: _arcController,
                                    hintText: '如：由回避 → 直面',
                                  );
                                  return compact
                                      ? Column(
                                          children: [
                                            motivation,
                                            const SizedBox(height: 12),
                                            arc,
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Expanded(child: motivation),
                                            const SizedBox(width: 12),
                                            Expanded(child: arc),
                                          ],
                                        );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth < 600;
                                final avatar = _CharacterAssetCard(
                                  title: '头像',
                                  child: Row(
                                    children: [
                                      _CharacterAvatar(path: _avatarPath),
                                      const SizedBox(width: 18),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            _OutlineButton(
                                              icon: Icons.image_outlined,
                                              label: '选择头像图片',
                                              onPressed: _pickAvatar,
                                            ),
                                            const SizedBox(height: 8),
                                            _OutlineButton(
                                              icon: Icons.auto_awesome,
                                              label: '生成头像',
                                              onPressed: _askAvatarPrompt,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                final gallery = _CharacterAssetCard(
                                  title: '照片集',
                                  trailing: TextButton.icon(
                                    onPressed: _showPhotoNotice,
                                    icon: const Icon(Icons.auto_awesome,
                                        size: 15),
                                    label: const Text('拍照'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: colors.muted,
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  child: SizedBox(
                                    height: 86,
                                    child: _galleryPaths.isEmpty
                                        ? Center(
                                            child: _OutlineButton(
                                              icon: Icons.add,
                                              label: '添加照片',
                                              onPressed: _addGalleryPhoto,
                                            ),
                                          )
                                        : ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: _galleryPaths.length + 1,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(width: 8),
                                            itemBuilder: (context, index) {
                                              if (index ==
                                                  _galleryPaths.length) {
                                                return _GalleryAddButton(
                                                  onTap: _addGalleryPhoto,
                                                );
                                              }
                                              return _GalleryThumb(
                                                path: _galleryPaths[index],
                                                onRemove: () {
                                                  setState(() {
                                                    _galleryPaths = [
                                                      ..._galleryPaths
                                                          .take(index),
                                                      ..._galleryPaths
                                                          .skip(index + 1),
                                                    ];
                                                  });
                                                  _scheduleAutosave();
                                                },
                                              );
                                            },
                                          ),
                                  ),
                                );
                                return compact
                                    ? Column(
                                        children: [
                                          avatar,
                                          const SizedBox(height: 16),
                                          gallery,
                                        ],
                                      )
                                    : Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(flex: 2, child: avatar),
                                          const SizedBox(width: 16),
                                          Expanded(flex: 3, child: gallery),
                                        ],
                                      );
                              },
                            ),
                            const SizedBox(height: 16),
                            _CharacterCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FieldLabel('首次出场章节'),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: _selectFirstChapter,
                                    borderRadius: BorderRadius.circular(8),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        suffixIcon:
                                            const Icon(Icons.search, size: 18),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        _firstChapterLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: colors.text,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _CharacterCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '技能',
                                        style: TextStyle(
                                          color: colors.text,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const Spacer(),
                                      OutlinedButton.icon(
                                        onPressed: _addSkill,
                                        icon: const Icon(Icons.add, size: 16),
                                        label: const Text('添加技能'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: colors.text,
                                          side: BorderSide(color: colors.line),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (_skills.isEmpty)
                                    Row(
                                      children: [
                                        Icon(Icons.info_outline,
                                            size: 15, color: colors.muted),
                                        const SizedBox(width: 6),
                                        Text(
                                          '该角色尚未关联任何技能。',
                                          style: TextStyle(
                                            color: colors.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (var i = 0; i < _skills.length; i++)
                                          _SkillChip(
                                            skill: _skills[i],
                                            onRemove: () {
                                              setState(() {
                                                _skills = [
                                                  ..._skills.take(i),
                                                  ..._skills.skip(i + 1),
                                                ];
                                              });
                                              _scheduleAutosave();
                                            },
                                          ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _CharacterTabs(
                              index: _tabIndex,
                              onChanged: (index) =>
                                  setState(() => _tabIndex = index),
                            ),
                            const SizedBox(height: 8),
                            const _EditorToolbar(),
                            const SizedBox(height: 8),
                            _EditorBox(
                              controller: _tabIndex == 0
                                  ? _biographyController
                                  : _currentStateController,
                              hintText: _tabIndex == 0
                                  ? '记录人物小传、背景、关键经历与性格。'
                                  : '记录人物当前状态、目标、秘密和下一步行动。',
                              minLines: 9,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (widget.error != null)
                Positioned(
                  left: 24,
                  right: 24,
                  top: 18,
                  child: Material(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        widget.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        _CharacterStatusBar(
          saving: _saving,
          updatedAt: _savedAt,
          onHistory: _showHistory,
        ),
      ],
    );
  }
}

const _characterRoles = ['主角', '反派', '配角', '龙套'];
const _characterGenders = ['男', '女', '非二元', '其他', '未知'];
const _characterSkillRelations = ['已学会', '精通中', '已精通', '创造者'];
const _characterImageTypes = [
  XTypeGroup(
    label: '图片',
    extensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
  ),
];

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({
    required this.title,
    required this.actions,
  });

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.text, fontSize: 13),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.line),
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Text(
      text,
      style: TextStyle(
        color: colors.text,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _CharacterTextField extends StatelessWidget {
  const _CharacterTextField({
    required this.label,
    required this.controller,
    this.hintText,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hintText),
        ),
      ],
    );
  }
}

class _CharacterSelectField extends StatelessWidget {
  const _CharacterSelectField({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 8),
        PopupMenuButton<String>(
          tooltip: label,
          constraints: const BoxConstraints(maxHeight: 196, minWidth: 150),
          onSelected: onChanged,
          itemBuilder: (context) => [
            for (final item in values)
              PopupMenuItem(
                value: item,
                height: 36,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 13,
                          fontWeight:
                              item == value ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (item == value)
                      Icon(Icons.check_circle_outline,
                          size: 15, color: colors.text),
                  ],
                ),
              ),
          ],
          child: InputDecorator(
            decoration: InputDecoration(
              suffixIcon: const Icon(Icons.expand_more, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.text, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

class _CharacterAssetCard extends StatelessWidget {
  const _CharacterAssetCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      height: 136,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _CharacterAvatar extends StatelessWidget {
  const _CharacterAvatar({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final imagePath = path;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: colors.line.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: imagePath != null && File(imagePath).existsSync()
          ? Image.file(File(imagePath), fit: BoxFit.cover)
          : Center(
              child: Text(
                '?',
                style: TextStyle(
                  color: colors.card,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return SizedBox(
      height: 26,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.text,
          side: BorderSide(color: colors.text),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _GalleryAddButton extends StatelessWidget {
  const _GalleryAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.line),
        ),
        child: Icon(Icons.add, size: 18, color: colors.text),
      ),
    );
  }
}

class _GalleryThumb extends StatelessWidget {
  const _GalleryThumb({
    required this.path,
    required this.onRemove,
  });

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Stack(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: File(path).existsSync()
              ? Image.file(File(path), fit: BoxFit.cover)
              : Icon(Icons.broken_image_outlined, color: colors.muted),
        ),
        Positioned(
          right: 2,
          top: 2,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: colors.card.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                border: Border.all(color: colors.line),
              ),
              child: Icon(Icons.close, size: 13, color: colors.text),
            ),
          ),
        ),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({
    required this.skill,
    required this.onRemove,
  });

  final NovelCharacterSkill skill;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      height: 36,
      padding: const EdgeInsets.only(left: 10, right: 4),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 14, color: colors.text),
          const SizedBox(width: 6),
          Text(
            skill.name,
            style: TextStyle(
              color: colors.text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.line.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              skill.relation,
              style: TextStyle(color: colors.text, fontSize: 11),
            ),
          ),
          IconButton(
            tooltip: '移除技能',
            onPressed: onRemove,
            icon: Icon(Icons.close, size: 14, color: colors.brand),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 26, height: 26),
          ),
        ],
      ),
    );
  }
}

class _CharacterTabs extends StatelessWidget {
  const _CharacterTabs({
    required this.index,
    required this.onChanged,
    this.firstLabel = '人物小传',
    this.secondLabel = '人物当前状态',
  });

  final int index;
  final ValueChanged<int> onChanged;
  final String firstLabel;
  final String secondLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      height: 39,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _CharacterTab(
            label: firstLabel,
            selected: index == 0,
            onTap: () => onChanged(0),
          ),
          _CharacterTab(
            label: secondLabel,
            selected: index == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _CharacterTab extends StatelessWidget {
  const _CharacterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.line.withValues(alpha: 0.65) : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: colors.text,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterStatusBar extends StatelessWidget {
  const _CharacterStatusBar({
    required this.saving,
    required this.updatedAt,
    required this.onHistory,
  });

  final bool saving;
  final DateTime? updatedAt;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Icon(Icons.save_outlined, size: 14, color: colors.muted),
          const SizedBox(width: 6),
          Text(
            saving ? '正在自动保存' : '已启用自动保存',
            style: TextStyle(color: colors.muted, fontSize: 12),
          ),
          const SizedBox(width: 22),
          Icon(Icons.schedule, size: 14, color: colors.muted),
          const SizedBox(width: 6),
          Text(
            updatedAt == null ? '尚未保存' : '最近保存 ${_formatClock(updatedAt!)}',
            style: TextStyle(color: colors.muted, fontSize: 12),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onHistory,
            icon: const Icon(Icons.history, size: 15),
            label: const Text('历史'),
            style: TextButton.styleFrom(
              foregroundColor: colors.text,
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterHistorySnapshot {
  const _CharacterHistorySnapshot({
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

  factory _CharacterHistorySnapshot.fromCharacter(NovelCharacter character) {
    return _CharacterHistorySnapshot(
      name: character.name,
      role: character.role,
      gender: character.gender,
      identity: character.identity,
      age: character.age,
      motivation: character.motivation,
      arc: character.arc,
      avatarPath: character.avatarPath,
      galleryPaths: character.galleryPaths,
      firstChapterId: character.firstChapterId,
      biography: character.biography,
      currentState: character.currentState,
      skills: character.skills,
      updatedAt: character.updatedAt,
    );
  }

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
}

class _CharacterHistoryDialog extends StatelessWidget {
  const _CharacterHistoryDialog({
    required this.snapshot,
    required this.onRestore,
  });

  final _CharacterHistorySnapshot? snapshot;
  final Future<void> Function(_CharacterHistorySnapshot snapshot) onRestore;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final record = snapshot;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 168, vertical: 130),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: 1080,
        height: 720,
        child: Column(
          children: [
            SizedBox(
              height: 54,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(Icons.history, size: 18, color: colors.text),
                  const SizedBox(width: 8),
                  Text(
                    '修改历史',
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 22),
                  _HistoryFilterChip(label: '全部', selected: true),
                  const SizedBox(width: 8),
                  _HistoryFilterChip(label: 'AI', selected: false),
                  const SizedBox(width: 8),
                  _HistoryFilterChip(label: '手动', selected: false),
                  const Spacer(),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
            Divider(height: 1, color: colors.line),
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 322,
                    child: record == null
                        ? _HistoryEmptyList(message: '当前人物还没有保存记录。')
                        : _HistoryRecordTile(
                            title: '自动保存人物',
                            updatedAt: record.updatedAt,
                          ),
                  ),
                  VerticalDivider(width: 1, color: colors.line),
                  Expanded(
                    child: record == null
                        ? _HistoryEmptyDetail()
                        : _CharacterHistoryDetail(
                            snapshot: record,
                            onRestore: onRestore,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryFilterChip extends StatelessWidget {
  const _HistoryFilterChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? colors.card : Colors.transparent,
        border: Border.all(color: selected ? colors.line : Colors.transparent),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? colors.text : colors.muted,
          fontSize: 13,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _HistoryRecordTile extends StatelessWidget {
  const _HistoryRecordTile({
    required this.title,
    required this.updatedAt,
  });

  final String title;
  final DateTime updatedAt;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      color: colors.line.withValues(alpha: 0.35),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.edit_outlined, size: 16, color: colors.text),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_formatShortDate(updatedAt)} · 当前保存版本',
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEmptyList extends StatelessWidget {
  const _HistoryEmptyList({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(message, style: TextStyle(color: colors.muted)),
      ),
    );
  }
}

class _HistoryEmptyDetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Center(
      child: Text('选择一条记录查看详情', style: TextStyle(color: colors.muted)),
    );
  }
}

class _ChapterHistorySnapshot {
  const _ChapterHistorySnapshot({
    required this.title,
    required this.outline,
    required this.content,
    required this.updatedAt,
  });

  factory _ChapterHistorySnapshot.fromChapter(NovelChapter chapter) {
    return _ChapterHistorySnapshot(
      title: chapter.title,
      outline: chapter.outline,
      content: chapter.content,
      updatedAt: chapter.updatedAt,
    );
  }

  final String title;
  final String outline;
  final String content;
  final DateTime updatedAt;
}

class _ChapterHistoryDialog extends StatelessWidget {
  const _ChapterHistoryDialog({
    required this.snapshot,
    required this.onRestore,
  });

  final _ChapterHistorySnapshot? snapshot;
  final Future<void> Function(_ChapterHistorySnapshot snapshot) onRestore;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final record = snapshot;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 168, vertical: 130),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: 1080,
        height: 720,
        child: Column(
          children: [
            SizedBox(
              height: 54,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(Icons.history, size: 18, color: colors.text),
                  const SizedBox(width: 8),
                  Text(
                    '修改历史',
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 22),
                  _HistoryFilterChip(label: '全部', selected: true),
                  const SizedBox(width: 8),
                  _HistoryFilterChip(label: 'AI', selected: false),
                  const SizedBox(width: 8),
                  _HistoryFilterChip(label: '手动', selected: false),
                  const Spacer(),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
            Divider(height: 1, color: colors.line),
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 322,
                    child: record == null
                        ? _HistoryEmptyList(message: '当前章节还没有保存记录。')
                        : _HistoryRecordTile(
                            title: '自动保存章节',
                            updatedAt: record.updatedAt,
                          ),
                  ),
                  VerticalDivider(width: 1, color: colors.line),
                  Expanded(
                    child: record == null
                        ? _HistoryEmptyDetail()
                        : _ChapterHistoryDetail(
                            snapshot: record,
                            onRestore: onRestore,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterHistoryDetail extends StatelessWidget {
  const _ChapterHistoryDetail({
    required this.snapshot,
    required this.onRestore,
  });

  final _ChapterHistorySnapshot snapshot;
  final Future<void> Function(_ChapterHistorySnapshot snapshot) onRestore;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final title = snapshot.title.trim().isEmpty ? '未命名' : snapshot.title;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '自动保存章节',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  final confirmed = await _confirmHistoryRestore(context);
                  if (!confirmed || !context.mounted) {
                    return;
                  }
                  await onRestore(snapshot);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.history, size: 15),
                label: const Text('回滚'),
                style: TextButton.styleFrom(foregroundColor: colors.text),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '自动 · ${_formatShortDate(snapshot.updatedAt)}',
            style: TextStyle(color: colors.muted, fontSize: 12),
          ),
          const SizedBox(height: 22),
          _HistorySection(
            label: '章节基础信息',
            rows: [
              ('标题', title),
              ('字数', '${_countWritingUnits(snapshot.content)}'),
            ],
          ),
          const SizedBox(height: 14),
          _HistoryTextBlock(
            path: '/chapters/$title/outline',
            label: 'outline',
            content: snapshot.outline,
          ),
          const SizedBox(height: 14),
          _HistoryTextBlock(
            path: '/chapters/$title/content',
            label: 'content',
            content: snapshot.content,
          ),
        ],
      ),
    );
  }
}

class _CharacterHistoryDetail extends StatelessWidget {
  const _CharacterHistoryDetail({
    required this.snapshot,
    required this.onRestore,
  });

  final _CharacterHistorySnapshot snapshot;
  final Future<void> Function(_CharacterHistorySnapshot snapshot) onRestore;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '自动保存人物',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  final confirmed = await _confirmHistoryRestore(context);
                  if (!confirmed || !context.mounted) {
                    return;
                  }
                  await onRestore(snapshot);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.history, size: 15),
                label: const Text('回滚'),
                style: TextButton.styleFrom(foregroundColor: colors.text),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '自动 · ${_formatShortDate(snapshot.updatedAt)}',
            style: TextStyle(color: colors.muted, fontSize: 12),
          ),
          const SizedBox(height: 22),
          _HistorySection(
            label: '人物基础信息',
            rows: [
              ('名称', snapshot.name.trim().isEmpty ? '未命名' : snapshot.name),
              ('定位', snapshot.role),
              ('性别', snapshot.gender),
              (
                '身份',
                snapshot.identity.trim().isEmpty ? '未填写' : snapshot.identity
              ),
              ('年龄', snapshot.age.trim().isEmpty ? '未知' : snapshot.age),
            ],
          ),
          const SizedBox(height: 14),
          _HistoryTextBlock(
            path:
                '/characters/${snapshot.name.trim().isEmpty ? '未命名' : snapshot.name}/biography',
            label: '人物小传',
            content: snapshot.biography,
          ),
          const SizedBox(height: 14),
          _HistoryTextBlock(
            path:
                '/characters/${snapshot.name.trim().isEmpty ? '未命名' : snapshot.name}/current_state',
            label: '人物当前状态',
            content: snapshot.currentState,
          ),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.label, required this.rows});

  final String label;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              label,
              style: TextStyle(
                color: colors.text,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Divider(height: 1, color: colors.line),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final row in rows)
                  _HistoryValueChip(name: row.$1, value: row.$2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryValueChip extends StatelessWidget {
  const _HistoryValueChip({required this.name, required this.value});

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: colors.line),
      ),
      child: Text(
        '$name：$value',
        style: TextStyle(color: colors.text, fontSize: 12),
      ),
    );
  }
}

class _HistoryTextBlock extends StatelessWidget {
  const _HistoryTextBlock({
    required this.path,
    required this.label,
    required this.content,
  });

  final String path;
  final String label;
  final String content;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final lines = content.trim().isEmpty ? ['暂无内容'] : content.split('\n');
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: colors.line.withValues(alpha: 0.45),
            child: Row(
              children: [
                Icon(Icons.description_outlined, size: 15, color: colors.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.text, fontSize: 12),
                  ),
                ),
                Text(label,
                    style: TextStyle(color: colors.muted, fontSize: 12)),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: const Color(0xFFD2F7E1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < lines.length; i++)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 54, vertical: 2),
                    child: Text(
                      lines[i].trim().isEmpty ? ' ' : lines[i],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.text, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> _confirmHistoryRestore(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final colors = AppPalette.of(context);
      return AlertDialog(
        title: const Text('回滚本次变更？'),
        content: Text(
          '这条记录中的字段会写回到当前表单，并保存为最新版本。',
          style: TextStyle(color: colors.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('回滚'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

Future<int?> _showChapterPicker(
  BuildContext context, {
  required List<NovelChapter> chapters,
  required int? selectedChapterId,
}) {
  return showDialog<int?>(
    context: context,
    builder: (context) => _ChapterPickerDialog(
      chapters: chapters,
      selectedChapterId: selectedChapterId,
    ),
  );
}

class _ChapterPickerDialog extends StatefulWidget {
  const _ChapterPickerDialog({
    required this.chapters,
    required this.selectedChapterId,
  });

  final List<NovelChapter> chapters;
  final int? selectedChapterId;

  @override
  State<_ChapterPickerDialog> createState() => _ChapterPickerDialogState();
}

class _ChapterPickerDialogState extends State<_ChapterPickerDialog> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NovelChapter> get _visibleChapters {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return widget.chapters;
    }
    return [
      for (final chapter in widget.chapters)
        if (_fuzzyContains(chapter.title, query)) chapter,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final visibleChapters = _visibleChapters;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 468, minHeight: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '选择章节',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: '搜索章节',
                  prefixIcon: Icon(Icons.search, size: 26),
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () => Navigator.of(context).pop(null),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 9,
                  ),
                  child: Text(
                    '无',
                    style: TextStyle(color: colors.muted, fontSize: 13),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final chapter in visibleChapters)
                      ListTile(
                        dense: true,
                        title: Text(
                          chapter.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: chapter.id == widget.selectedChapterId
                            ? Icon(Icons.check_circle_outline,
                                size: 16, color: colors.text)
                            : null,
                        onTap: () => Navigator.of(context).pop(chapter.id),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<NovelCharacterSkill?> _showCharacterSkillDialog(
  BuildContext context, {
  required List<NovelOutline> existingSkills,
  required Future<NovelOutline> Function({
    required String title,
    required String content,
  }) onCreateSkill,
}) {
  return showDialog<NovelCharacterSkill>(
    context: context,
    builder: (context) => _CharacterSkillDialog(
      existingSkills: existingSkills,
      onCreateSkill: onCreateSkill,
    ),
  );
}

class _CharacterSkillDialog extends StatefulWidget {
  const _CharacterSkillDialog({
    required this.existingSkills,
    required this.onCreateSkill,
  });

  final List<NovelOutline> existingSkills;
  final Future<NovelOutline> Function({
    required String title,
    required String content,
  }) onCreateSkill;

  @override
  State<_CharacterSkillDialog> createState() => _CharacterSkillDialogState();
}

class _CharacterSkillDialogState extends State<_CharacterSkillDialog> {
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  var _creating = false;
  var _saving = false;
  var _relation = _characterSkillRelations.first;
  int? _selectedSkillId;

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<NovelOutline> get _visibleSkills {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return widget.existingSkills;
    }
    return [
      for (final skill in widget.existingSkills)
        if (_fuzzyContains(skill.title, query)) skill,
    ];
  }

  Future<void> _submit() async {
    if (_saving) {
      return;
    }
    final name = _creating
        ? _nameController.text.trim()
        : _selectedSkill?.title.trim() ?? '';
    if (name.isEmpty) {
      return;
    }
    if (_creating) {
      setState(() => _saving = true);
      try {
        final saved = await widget.onCreateSkill(
          title: name,
          content: _descriptionController.text,
        );
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop(
          NovelCharacterSkill(
            skillId: saved.id,
            name: saved.title,
            relation: _relation,
          ),
        );
      } catch (_) {
        if (mounted) {
          setState(() => _saving = false);
        }
      }
      return;
    }
    final selected = _selectedSkill;
    if (selected == null) {
      return;
    }
    Navigator.of(context).pop(
      NovelCharacterSkill(
        skillId: selected.id,
        name: selected.title,
        relation: _relation,
      ),
    );
  }

  NovelOutline? get _selectedSkill {
    final id = _selectedSkillId;
    if (id == null) {
      return null;
    }
    for (final skill in widget.existingSkills) {
      if (skill.id == id) {
        return skill;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 528),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.line.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add, color: colors.text),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '添加技能',
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _CharacterTabs(
                index: _creating ? 1 : 0,
                onChanged: (index) => setState(() => _creating = index == 1),
                firstLabel: '关联已有',
                secondLabel: '新建技能',
              ),
              const SizedBox(height: 14),
              if (_creating) ...[
                _FieldLabel('技能名称'),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: '请输入技能名称'),
                ),
                const SizedBox(height: 12),
                _FieldLabel('技能说明'),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: '可选：描述技能的细节、效果或背景',
                  ),
                ),
              ] else ...[
                _FieldLabel('技能'),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: '技能',
                    suffixIcon: Icon(Icons.search, size: 22),
                  ),
                ),
                if (_visibleSkills.isNotEmpty)
                  Container(
                    height: 156,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.line),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView(
                      children: [
                        for (final skill in _visibleSkills)
                          ListTile(
                            dense: true,
                            title: Text(skill.title),
                            subtitle: skill.status.trim().isEmpty
                                ? null
                                : Text(skill.status),
                            selected: skill.id == _selectedSkillId,
                            selectedTileColor:
                                colors.line.withValues(alpha: 0.5),
                            onTap: () =>
                                setState(() => _selectedSkillId = skill.id),
                          ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 14),
              Text(
                '关联方式',
                style: TextStyle(color: colors.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final relation in _characterSkillRelations)
                    ChoiceChip(
                      label: Text(relation),
                      selected: relation == _relation,
                      onSelected: (_) => setState(() => _relation = relation),
                      selectedColor: colors.text,
                      labelStyle: TextStyle(
                        color:
                            relation == _relation ? colors.card : colors.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: StadiumBorder(
                        side: BorderSide(color: colors.line),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.text,
                      foregroundColor: colors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(_saving ? '添加中' : '添加'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectChapterRail extends StatefulWidget {
  const _ProjectChapterRail({
    required this.novel,
    required this.chapters,
    required this.selectedChapterId,
    required this.loading,
    required this.loadVolumes,
    required this.createVolume,
    required this.onBack,
    required this.onSelectChapter,
    required this.onAddChapter,
    required this.onDeleteChapter,
  });

  final NovelSummary novel;
  final List<NovelChapter> chapters;
  final int? selectedChapterId;
  final bool loading;
  final NovelVolumeLoader? loadVolumes;
  final NovelVolumeCreator? createVolume;
  final VoidCallback onBack;
  final ValueChanged<NovelChapter> onSelectChapter;
  final VoidCallback onAddChapter;
  final ValueChanged<NovelChapter> onDeleteChapter;

  @override
  State<_ProjectChapterRail> createState() => _ProjectChapterRailState();
}

class _ProjectChapterRailState extends State<_ProjectChapterRail> {
  final _searchController = TextEditingController();
  int _volumeCount = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadVolumeCount());
  }

  @override
  void didUpdateWidget(covariant _ProjectChapterRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.novel.id != widget.novel.id ||
        oldWidget.loadVolumes != widget.loadVolumes) {
      unawaited(_loadVolumeCount());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NovelChapter> get _visibleChapters {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return widget.chapters;
    }
    return [
      for (final chapter in widget.chapters)
        if (_fuzzyContains(chapter.title, query)) chapter,
    ];
  }

  Future<void> _createVolume() async {
    final name = await _showCreateVolumeDialog(context);
    if (name == null || name.trim().isEmpty || !mounted) {
      return;
    }
    final createVolume = widget.createVolume;
    if (createVolume != null) {
      await createVolume(novelId: widget.novel.id, title: name.trim());
      if (!mounted) {
        return;
      }
    }
    setState(() => _volumeCount += 1);
  }

  Future<void> _loadVolumeCount() async {
    final loadVolumes = widget.loadVolumes;
    if (loadVolumes == null) {
      if (mounted && _volumeCount != 0) {
        setState(() => _volumeCount = 0);
      }
      return;
    }
    final volumes = await loadVolumes(widget.novel.id);
    if (mounted) {
      setState(() => _volumeCount = volumes.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final visibleChapters = _visibleChapters;

    return Container(
      width: 204,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(right: BorderSide(color: colors.line)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 46,
            child: Row(
              children: [
                IconButton(
                  tooltip: '返回',
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.chevron_left),
                ),
                const Spacer(),
                IconButton(
                  tooltip: '收起侧栏',
                  onPressed: () {},
                  icon: const Icon(Icons.view_sidebar_outlined, size: 18),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: _NovelCover(novel: widget.novel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.novel.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
            child: Row(
              children: [
                Text(
                  '章节',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: '卷数',
                  child: Text(
                    _volumeCount.toString(),
                    style: TextStyle(color: colors.muted, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: '新建卷',
                  onPressed: _createVolume,
                  icon: Icon(
                    Icons.create_new_folder_outlined,
                    size: 16,
                    color: colors.muted,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 22,
                    height: 22,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 34,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '搜索',
                  prefixIcon: const Icon(Icons.search, size: 16),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.line),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (widget.loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: LinearProgressIndicator(
                minHeight: 2,
                color: colors.text,
                backgroundColor: colors.line,
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final chapter in visibleChapters)
                    _ChapterRow(
                      title: chapter.title,
                      selected: chapter.id == widget.selectedChapterId,
                      onTap: () => widget.onSelectChapter(chapter),
                      onDelete: () => widget.onDeleteChapter(chapter),
                    ),
                  InkWell(
                    onTap: widget.onAddChapter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(13, 6, 12, 0),
                      child: Row(
                        children: [
                          Icon(Icons.add, color: colors.muted, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '新增章节',
                            style: TextStyle(color: colors.muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({
    required this.title,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return GestureDetector(
      onSecondaryTapDown: (details) => _showChapterMenu(context, details),
      child: SizedBox(
        height: 31,
        child: InkWell(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: selected ? colors.line.withValues(alpha: 0.55) : null,
            child: Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 15,
                  color: selected ? colors.text : colors.muted,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.note_add_outlined, size: 14, color: colors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showChapterMenu(
    BuildContext context,
    TapDownDetails details,
  ) async {
    final colors = AppPalette.of(context);
    final selectedAction = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      color: colors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.line),
      ),
      items: [
        PopupMenuItem(
          value: 'delete',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 16, color: colors.brand),
              const SizedBox(width: 10),
              Text(
                '删除章节',
                style: TextStyle(
                  color: colors.brand,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    if (selectedAction == 'delete') {
      onDelete();
    }
  }
}

Future<String?> _showCreateVolumeDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => const _CreateVolumeDialog(),
  );
}

class _CreateVolumeDialog extends StatefulWidget {
  const _CreateVolumeDialog();

  @override
  State<_CreateVolumeDialog> createState() => _CreateVolumeDialogState();
}

class _CreateVolumeDialogState extends State<_CreateVolumeDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints.tightFor(width: 280),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '新建卷',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 48,
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '输入卷名称',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(3),
                      borderSide: BorderSide(color: colors.text),
                    ),
                  ),
                  onSubmitted: (value) =>
                      Navigator.of(context).pop(value.trim()),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_controller.text.trim()),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.text,
                      foregroundColor: colors.card,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('新建'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectOutlineRail extends StatefulWidget {
  const _ProjectOutlineRail({
    required this.novel,
    required this.outlines,
    required this.selectedOutlineId,
    required this.loading,
    required this.onBack,
    required this.onSelectOutline,
    required this.onSelectGlobal,
    required this.onAddOutline,
  });

  final NovelSummary novel;
  final List<NovelOutline> outlines;
  final int? selectedOutlineId;
  final bool loading;
  final VoidCallback onBack;
  final ValueChanged<NovelOutline> onSelectOutline;
  final VoidCallback onSelectGlobal;
  final VoidCallback onAddOutline;

  @override
  State<_ProjectOutlineRail> createState() => _ProjectOutlineRailState();
}

class _ProjectOutlineRailState extends State<_ProjectOutlineRail> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NovelOutline> get _visibleOutlines {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return widget.outlines;
    }
    return [
      for (final outline in widget.outlines)
        if (_fuzzyContains(outline.title, query)) outline,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final visibleOutlines = _visibleOutlines;

    return Container(
      width: 204,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(right: BorderSide(color: colors.line)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 46,
            child: Row(
              children: [
                IconButton(
                  tooltip: '返回',
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.chevron_left),
                ),
                const Spacer(),
                Icon(Icons.view_sidebar_outlined,
                    size: 18, color: colors.muted),
                const SizedBox(width: 14),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: _NovelCover(novel: widget.novel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.novel.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
            child: Row(
              children: [
                Text(
                  '大纲',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  widget.outlines.length.toString(),
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: '新增大纲',
                  onPressed: widget.onAddOutline,
                  icon: Icon(Icons.add, size: 18, color: colors.muted),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 22,
                    height: 22,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 34,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '搜索',
                  prefixIcon: const Icon(Icons.search, size: 16),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.line),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (widget.loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: LinearProgressIndicator(
                minHeight: 2,
                color: colors.text,
                backgroundColor: colors.line,
              ),
            )
          else
            Expanded(
              child: visibleOutlines.isEmpty
                  ? Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
                        child: Text(
                          '暂无内容',
                          style: TextStyle(color: colors.muted, fontSize: 13),
                        ),
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        for (final outline in visibleOutlines)
                          _OutlineRow(
                            title: outline.title,
                            selected: outline.id == widget.selectedOutlineId,
                            onTap: () => widget.onSelectOutline(outline),
                          ),
                      ],
                    ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: OutlinedButton.icon(
              onPressed: widget.onSelectGlobal,
              icon: const Icon(Icons.account_tree_outlined, size: 14),
              label: const Text('全局'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(34),
                foregroundColor: colors.text,
                side: BorderSide(
                  color: widget.selectedOutlineId == null
                      ? colors.text
                      : colors.line,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineRow extends StatelessWidget {
  const _OutlineRow({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        color: selected ? colors.line.withValues(alpha: 0.65) : null,
        child: Row(
          children: [
            Icon(Icons.description_outlined, size: 15, color: colors.text),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineEmptyMain extends StatelessWidget {
  const _OutlineEmptyMain({
    required this.novel,
    required this.outlines,
    required this.onAddOutline,
  });

  final NovelSummary novel;
  final List<NovelOutline> outlines;
  final VoidCallback onAddOutline;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final totalBeats = outlines.fold<int>(
      0,
      (sum, outline) => sum + _OutlineBeat.decodeList(outline.beatsJson).length,
    );
    final totalChapters = outlines.fold<int>(
      0,
      (sum, outline) =>
          sum +
          _OutlineBeat.decodeList(outline.beatsJson)
              .fold<int>(0, (beatSum, beat) => beatSum + beat.chapterCount),
    );
    return Column(
      children: [
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(bottom: BorderSide(color: colors.line)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.centerLeft,
          child: Text(
            '${novel.title} > 大纲',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.text, fontSize: 13),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 684),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 24, 0, 84),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: colors.card,
                          border: Border.all(color: colors.line),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _OutlineGlobalStat('大纲 ${outlines.length}',
                                color: colors.text),
                            _OutlineGlobalStat('时间线节拍 $totalBeats',
                                color: colors.text),
                            _OutlineGlobalStat('章节 $totalChapters',
                                color: colors.muted),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        '全局大纲时间轴',
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '按章节跨度对比所有大纲。此视图仅支持查看。',
                        style: TextStyle(color: colors.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 28),
                      if (outlines.isEmpty || totalBeats == 0)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 54),
                          decoration: BoxDecoration(
                            color: colors.card,
                            border: Border.all(color: colors.line),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.timeline_outlined,
                                  size: 26, color: colors.muted),
                              const SizedBox(height: 14),
                              Text(
                                '还没有时间线节拍',
                                style: TextStyle(
                                  color: colors.text,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: onAddOutline,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('新增大纲'),
                              ),
                            ],
                          ),
                        )
                      else
                        _OutlineGlobalTimeline(outlines: outlines),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(top: BorderSide(color: colors.line)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.history, size: 15),
            label: const Text('历史'),
            style: TextButton.styleFrom(
              foregroundColor: colors.text,
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _OutlineGlobalStat extends StatelessWidget {
  const _OutlineGlobalStat(this.label, {required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 7),
        Text(label, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }
}

class _OutlineGlobalTimeline extends StatelessWidget {
  const _OutlineGlobalTimeline({required this.outlines});

  final List<NovelOutline> outlines;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final rows = [
      for (final outline in outlines)
        (outline: outline, beats: _OutlineBeat.decodeList(outline.beatsJson)),
    ].where((row) => row.beats.isNotEmpty).toList(growable: false);
    final totalChapters = rows.fold<int>(
      0,
      (maxTotal, row) => math.max(
        maxTotal,
        row.beats.fold<int>(0, (sum, beat) => sum + beat.chapterCount),
      ),
    );
    final chapterCount = math.max(1, totalChapters);
    final rowHeight = 72.0;
    final labelWidth = 168.0;
    final height = 58.0 + rows.length * rowHeight;

    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final timelineLeft = math.min(labelWidth, width * 0.28);
          final timelineWidth = math.max(1.0, width - timelineLeft - 8);
          final tickStep =
              chapterCount <= 3 ? 1 : math.max(1, chapterCount ~/ 3);
          final ticks = <int>{
            1,
            for (var chapter = tickStep + 1;
                chapter < chapterCount;
                chapter += tickStep)
              chapter,
            chapterCount,
          }.toList()
            ..sort();

          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 38,
                child: Divider(height: 1, color: colors.line),
              ),
              Positioned(
                left: 10,
                top: 10,
                child: Text(
                  '全局',
                  style: TextStyle(color: colors.text, fontSize: 12),
                ),
              ),
              for (final tick in ticks)
                Positioned(
                  left: timelineLeft +
                      ((tick - 1) / chapterCount) * timelineWidth,
                  top: 10,
                  child: Column(
                    children: [
                      Container(width: 1, height: 18, color: colors.line),
                      const SizedBox(height: 5),
                      Text(
                        '第$tick章',
                        style: TextStyle(color: colors.text, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
                Positioned(
                  left: 0,
                  right: 0,
                  top: 46 + rowIndex * rowHeight,
                  child: Divider(height: 1, color: colors.line),
                ),
                Positioned(
                  left: 10,
                  top: 58 + rowIndex * rowHeight,
                  width: timelineLeft - 16,
                  child: Text(
                    rows[rowIndex].outline.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ..._buildBeatBlocks(
                  colors: colors,
                  beats: rows[rowIndex].beats,
                  left: timelineLeft,
                  top: 52 + rowIndex * rowHeight,
                  width: timelineWidth,
                  chapterCount: chapterCount,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildBeatBlocks({
    required AppPalette colors,
    required List<_OutlineBeat> beats,
    required double left,
    required double top,
    required double width,
    required int chapterCount,
  }) {
    final widgets = <Widget>[];
    var cursor = 0;
    for (final beat in beats) {
      final blockLeft = left + cursor / chapterCount * width;
      final blockWidth =
          math.max(44.0, beat.chapterCount / chapterCount * width);
      widgets.add(
        Positioned(
          left: blockLeft,
          top: top,
          width: blockWidth,
          height: 46,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.line.withValues(alpha: 0.9),
              border: Border.all(color: colors.muted.withValues(alpha: 0.8)),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              beat.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
      cursor += beat.chapterCount;
    }
    return widgets;
  }
}

class _OutlineEditorMain extends StatefulWidget {
  const _OutlineEditorMain({
    required this.novel,
    required this.outline,
    required this.loading,
    required this.error,
    required this.onSave,
    required this.onGenerateChapterOutline,
  });

  final NovelSummary novel;
  final NovelOutline? outline;
  final bool loading;
  final String? error;
  final Future<NovelOutline> Function({
    required String title,
    required String status,
    required String content,
    required String beatsJson,
  }) onSave;
  final void Function(String outlineTitle, _OutlineBeat beat)
      onGenerateChapterOutline;

  @override
  State<_OutlineEditorMain> createState() => _OutlineEditorMainState();
}

class _OutlineEditorMainState extends State<_OutlineEditorMain> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _beats = <_OutlineBeat>[];
  var _status = '待开始';
  bool _beatsExpanded = false;
  int? _selectedBeatIndex;
  bool _saving = false;
  DateTime? _savedAt;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant _OutlineEditorMain oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.outline?.id != widget.outline?.id) {
      _syncFromWidget();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _syncFromWidget() {
    final outline = widget.outline;
    _titleController.text = outline?.title ?? '未命名';
    _contentController.text = outline?.content ?? '';
    _beats
      ..clear()
      ..addAll(_OutlineBeat.decodeList(outline?.beatsJson ?? '[]'));
    _status = outline?.status ?? '待开始';
    _beatsExpanded = false;
    _selectedBeatIndex = _beats.isEmpty ? null : 0;
    _savedAt = outline?.updatedAt;
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await widget.onSave(
        title: _titleController.text,
        status: _status,
        content: _contentController.text,
        beatsJson: _OutlineBeat.encodeList(_beats),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _savedAt = saved.updatedAt;
        _saving = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _addBeat() async {
    final beat = await showDialog<_OutlineBeat>(
      context: context,
      builder: (context) => const _OutlineBeatDialog(),
    );
    if (beat == null || !mounted) {
      return;
    }
    setState(() {
      _beats.add(beat);
      _selectedBeatIndex = _beats.length - 1;
    });
    unawaited(_save());
  }

  void _toggleBeatsExpanded() {
    setState(() => _beatsExpanded = !_beatsExpanded);
  }

  Future<void> _editBeat(int index) async {
    final beat = await showDialog<_OutlineBeat>(
      context: context,
      builder: (context) => _OutlineBeatDialog(beat: _beats[index]),
    );
    if (beat == null || !mounted) {
      return;
    }
    setState(() {
      _beats[index] = beat;
      _selectedBeatIndex = index;
    });
    unawaited(_save());
  }

  void _deleteBeat(int index) {
    setState(() {
      _beats.removeAt(index);
      if (_beats.isEmpty) {
        _selectedBeatIndex = null;
      } else if (_selectedBeatIndex == null) {
        _selectedBeatIndex = 0;
      } else if (_selectedBeatIndex! >= _beats.length) {
        _selectedBeatIndex = _beats.length - 1;
      }
    });
    unawaited(_save());
  }

  void _generateChapterOutline(int index) {
    setState(() => _selectedBeatIndex = index);
    widget.onGenerateChapterOutline(_titleController.text, _beats[index]);
  }

  void _showHistory() {
    final updated = _savedAt;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('历史'),
        content: Text(
          updated == null
              ? '当前大纲还没有保存记录。'
              : '当前版本已保存。最近保存时间：${_formatClock(updated)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final title = _titleController.text.trim().isEmpty
        ? '未命名'
        : _titleController.text.trim();

    return Column(
      children: [
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(bottom: BorderSide(color: colors.line)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.novel.title} > 大纲 > $title',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.text, fontSize: 13),
                ),
              ),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.text,
                  foregroundColor: colors.card,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(_saving ? '保存中' : '保存'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              if (widget.loading)
                Center(child: CircularProgressIndicator(color: colors.text))
              else
                SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 666),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 26, 0, 86),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _titleController,
                                    style: TextStyle(
                                      color: colors.text,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: '未命名',
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      focusedErrorBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                _OutlineStatusMenu(
                                  value: _status,
                                  onChanged: (value) =>
                                      setState(() => _status = value),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (!_beatsExpanded) ...[
                              const _EditorToolbar(),
                              _EditorBox(
                                controller: _contentController,
                                hintText: '记录这条大纲的主内容、目标、冲突、伏线和结局兑现。',
                                minLines: 16,
                              ),
                              const SizedBox(height: 22),
                            ],
                            _OutlineTimelineSection(
                              beats: _beats,
                              onAddBeat: _addBeat,
                              expanded: _beatsExpanded,
                              onToggleExpanded: _toggleBeatsExpanded,
                              selectedIndex: _selectedBeatIndex,
                              onSelectBeat: (index) =>
                                  setState(() => _selectedBeatIndex = index),
                              onEditBeat: _editBeat,
                              onGenerateChapterOutline: _generateChapterOutline,
                              onDeleteBeat: _deleteBeat,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (widget.error != null)
                Positioned(
                  left: 24,
                  right: 24,
                  top: 18,
                  child: Material(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        widget.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(top: BorderSide(color: colors.line)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _showHistory,
            icon: const Icon(Icons.history, size: 15),
            label: const Text('历史'),
            style: TextButton.styleFrom(
              foregroundColor: colors.text,
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _OutlineStatusMenu extends StatelessWidget {
  const _OutlineStatusMenu({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return PopupMenuButton<String>(
      tooltip: '状态',
      onSelected: onChanged,
      itemBuilder: (context) => const [
        PopupMenuItem(value: '待开始', child: _OutlineStatusLabel('待开始')),
        PopupMenuItem(value: '进行中', child: _OutlineStatusLabel('进行中')),
        PopupMenuItem(value: '已完成', child: _OutlineStatusLabel('已完成')),
      ],
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: colors.card,
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusDot(status: value),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                color: colors.text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, color: colors.muted, size: 16),
          ],
        ),
      ),
    );
  }
}

class _OutlineStatusLabel extends StatelessWidget {
  const _OutlineStatusLabel(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusDot(status: status),
        const SizedBox(width: 8),
        Text(status),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      '已完成' => const Color(0xFF2F3437),
      '进行中' => const Color(0xFF111827),
      _ => const Color(0xFFB5740B),
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _OutlineTimelineSection extends StatelessWidget {
  const _OutlineTimelineSection({
    required this.beats,
    required this.onAddBeat,
    required this.expanded,
    required this.onToggleExpanded,
    required this.selectedIndex,
    required this.onSelectBeat,
    required this.onEditBeat,
    required this.onGenerateChapterOutline,
    required this.onDeleteBeat,
  });

  final List<_OutlineBeat> beats;
  final VoidCallback onAddBeat;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final int? selectedIndex;
  final ValueChanged<int> onSelectBeat;
  final ValueChanged<int> onEditBeat;
  final ValueChanged<int> onGenerateChapterOutline;
  final ValueChanged<int> onDeleteBeat;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '时间线节拍',
              style: TextStyle(
                color: colors.text,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: expanded ? '收起节拍' : '展开节拍',
              onPressed: onToggleExpanded,
              icon: Icon(
                expanded ? Icons.close_fullscreen : Icons.open_in_full,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onAddBeat,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('新增节拍'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.text,
                foregroundColor: colors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (beats.isEmpty)
          Container(
            height: 314,
            decoration: BoxDecoration(
              color: colors.card,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timeline_outlined, size: 26, color: colors.muted),
                  const SizedBox(height: 14),
                  Text(
                    '还没有时间线节拍',
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '先把引发事件放进去，再按因果顺序往后排。',
                    style: TextStyle(color: colors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: onAddBeat,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('新增节拍'),
                  ),
                ],
              ),
            ),
          )
        else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colors.card,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const _StatusDot(status: '已完成'),
                const SizedBox(width: 6),
                Text('已完成 0', style: TextStyle(color: colors.text)),
                const SizedBox(width: 12),
                const _StatusDot(status: '进行中'),
                const SizedBox(width: 6),
                Text('进行中 0', style: TextStyle(color: colors.text)),
                const SizedBox(width: 12),
                const _StatusDot(status: '待开始'),
                const SizedBox(width: 6),
                Text('待开始 ${beats.length}',
                    style: TextStyle(color: colors.text)),
                const SizedBox(width: 12),
                Icon(Icons.circle, size: 8, color: colors.muted),
                const SizedBox(width: 6),
                Text('共 ${beats.length} 个节点',
                    style: TextStyle(color: colors.text)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          for (var i = 0; i < beats.length; i++) ...[
            _OutlineBeatCard(
              beat: beats[i],
              index: i,
              selected: selectedIndex == i,
              onTap: () {
                onSelectBeat(i);
                onEditBeat(i);
              },
              onGenerateChapterOutline: () => onGenerateChapterOutline(i),
              onDelete: () => onDeleteBeat(i),
            ),
            if (i != beats.length - 1) const SizedBox(height: 28),
          ],
        ],
      ],
    );
  }
}

class _OutlineBeatCard extends StatelessWidget {
  const _OutlineBeatCard({
    required this.beat,
    required this.index,
    required this.selected,
    required this.onTap,
    required this.onGenerateChapterOutline,
    required this.onDelete,
  });

  final _OutlineBeat beat;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onGenerateChapterOutline;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: colors.card,
                shape: BoxShape.circle,
                border: Border.all(color: colors.text, width: 2),
              ),
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: colors.text,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Container(width: 1, height: 118, color: colors.line),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Material(
            color: colors.card,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: selected ? colors.text : colors.line),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              hoverColor: colors.line.withValues(alpha: 0.35),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _OutlineChip('节拍 ${index + 1}'),
                        const SizedBox(width: 6),
                        _OutlineChip(beat.status, accent: true),
                        const SizedBox(width: 6),
                        _OutlineChip('${beat.chapterCount} 章'),
                        const Spacer(),
                        Text(
                          '第 ${index * beat.chapterCount + 1}-${(index + 1) * beat.chapterCount} 章',
                          style: TextStyle(color: colors.muted, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<_OutlineBeatAction>(
                          tooltip: '节拍操作',
                          color: colors.card,
                          surfaceTintColor: Colors.transparent,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: colors.line),
                          ),
                          onSelected: (action) {
                            switch (action) {
                              case _OutlineBeatAction.generateChapterOutline:
                                onGenerateChapterOutline();
                              case _OutlineBeatAction.delete:
                                onDelete();
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: _OutlineBeatAction.generateChapterOutline,
                              child: Row(
                                children: [
                                  Icon(Icons.rocket_launch_outlined, size: 16),
                                  SizedBox(width: 10),
                                  Text('生成章纲'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: _OutlineBeatAction.delete,
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 16),
                                  SizedBox(width: 10),
                                  Text('删除'),
                                ],
                              ),
                            ),
                          ],
                          child: Icon(
                            Icons.more_vert,
                            color: colors.muted,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      beat.title,
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (beat.content.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Divider(color: colors.line),
                      const SizedBox(height: 8),
                      Text(
                        beat.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.muted, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _OutlineBeatAction { generateChapterOutline, delete }

class _OutlineChip extends StatelessWidget {
  const _OutlineChip(this.label, {this.accent = false});

  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent
            ? const Color(0xFFFFF7E8)
            : colors.line.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent ? const Color(0xFFB5740B) : colors.text,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OutlineBeat {
  const _OutlineBeat({
    required this.status,
    required this.chapterCount,
    required this.title,
    required this.content,
  });

  final String status;
  final int chapterCount;
  final String title;
  final String content;

  Map<String, Object?> toJson() => {
        'status': status,
        'chapterCount': chapterCount,
        'title': title,
        'content': content,
      };

  static String encodeList(List<_OutlineBeat> beats) {
    return jsonEncode([for (final beat in beats) beat.toJson()]);
  }

  static List<_OutlineBeat> decodeList(String source) {
    try {
      final value = jsonDecode(source);
      if (value is! List) {
        return const [];
      }
      return [
        for (final item in value)
          if (item is Map)
            _OutlineBeat(
              status: item['status'] as String? ?? '待开始',
              chapterCount: item['chapterCount'] as int? ?? 5,
              title: item['title'] as String? ?? '核心主题',
              content: item['content'] as String? ?? '',
            ),
      ];
    } catch (_) {
      return const [];
    }
  }
}

class _OutlineBeatDialog extends StatefulWidget {
  const _OutlineBeatDialog({this.beat});

  final _OutlineBeat? beat;

  @override
  State<_OutlineBeatDialog> createState() => _OutlineBeatDialogState();
}

class _OutlineBeatDialogState extends State<_OutlineBeatDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  var _status = '待开始';
  var _chapterCount = 5;

  @override
  void initState() {
    super.initState();
    final beat = widget.beat;
    if (beat == null) {
      return;
    }
    _titleController.text = beat.title;
    _contentController.text = beat.content;
    _status = beat.status;
    _chapterCount = beat.chapterCount;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _insertTemplate() {
    _contentController.text = '核心主题\n\n阶段目标\n\n阶段兑现\n\n伏笔设置\n\n详细节拍';
  }

  void _save() {
    Navigator.of(context).pop(
      _OutlineBeat(
        status: _status,
        chapterCount: _chapterCount,
        title: _titleController.text.trim().isEmpty
            ? '核心主题'
            : _titleController.text.trim(),
        content: _contentController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 140, vertical: 72),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 18, 16),
              child: Row(
                children: [
                  Text(
                    widget.beat == null ? '新增节拍' : '编辑节拍',
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.line),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _DialogFieldFrame(
                          label: '状态',
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _status,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                  value: '待开始',
                                  child: _OutlineStatusLabel('待开始'),
                                ),
                                DropdownMenuItem(
                                  value: '进行中',
                                  child: _OutlineStatusLabel('进行中'),
                                ),
                                DropdownMenuItem(
                                  value: '已完成',
                                  child: _OutlineStatusLabel('已完成'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _status = value);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DialogFieldFrame(
                          label: '预计章节数',
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => setState(
                                  () => _chapterCount =
                                      math.max(1, _chapterCount - 1),
                                ),
                                icon: const Icon(Icons.remove, size: 18),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    _chapterCount.toString(),
                                    style: TextStyle(
                                      color: colors.text,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    setState(() => _chapterCount += 1),
                                icon: const Icon(Icons.add, size: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: '标题',
                      hintText: '建议简短标题，章数范围由下方「预计章节数」体现',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Text(
                        '内容',
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _insertTemplate,
                        icon: const Icon(Icons.format_list_bulleted, size: 16),
                        label: const Text('插入结构模板'),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const _EditorToolbar(),
                  _EditorBox(
                    controller: _contentController,
                    hintText: '写下这一段剧情节拍要发生什么、推动什么、留下什么结果。',
                    minLines: 12,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.line),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.text,
                      foregroundColor: colors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('保存'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogFieldFrame extends StatelessWidget {
  const _DialogFieldFrame({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: colors.text, fontSize: 13),
        child: child,
      ),
    );
  }
}

class _ChapterEmptyMain extends StatelessWidget {
  const _ChapterEmptyMain({
    required this.novel,
    required this.onAddChapter,
  });

  final NovelSummary novel;
  final VoidCallback onAddChapter;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Column(
      children: [
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(bottom: BorderSide(color: colors.line)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.centerLeft,
          child: Text(
            '${novel.title} > 章节',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.text, fontSize: 13),
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.line),
                  ),
                  child: Icon(
                    Icons.menu_book_outlined,
                    size: 32,
                    color: colors.muted,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '还没有选中章节',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '先新建第一章。',
                  style: TextStyle(color: colors.muted, fontSize: 13),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onAddChapter,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('新建章节'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.text,
                    foregroundColor: colors.card,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(top: BorderSide(color: colors.line)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.history, size: 15),
            label: const Text('历史'),
            style: TextButton.styleFrom(
              foregroundColor: colors.text,
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChapterEditorMain extends StatefulWidget {
  const _ChapterEditorMain({
    required this.novel,
    required this.chapter,
    required this.chapterNumber,
    required this.loading,
    required this.error,
    required this.onSave,
  });

  final NovelSummary novel;
  final NovelChapter? chapter;
  final int chapterNumber;
  final bool loading;
  final String? error;
  final Future<NovelChapter> Function({
    required String title,
    required String outline,
    required String content,
  }) onSave;

  @override
  State<_ChapterEditorMain> createState() => _ChapterEditorMainState();
}

class _ChapterEditorMainState extends State<_ChapterEditorMain> {
  final _titleController = TextEditingController();
  final _outlineController = TextEditingController();
  final _contentController = TextEditingController();
  Timer? _autosaveTimer;
  bool _outlineCollapsed = false;
  bool _saving = false;
  bool _syncing = false;
  _ChapterHistorySnapshot? _historySnapshot;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
    _titleController.addListener(_scheduleAutosave);
    _outlineController.addListener(_scheduleAutosave);
    _contentController.addListener(_scheduleAutosave);
  }

  @override
  void didUpdateWidget(covariant _ChapterEditorMain oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapter?.id != widget.chapter?.id) {
      _syncFromWidget();
    }
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _titleController.dispose();
    _outlineController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _syncFromWidget() {
    final chapter = widget.chapter;
    _syncing = true;
    _titleController.text = chapter?.title ?? '';
    _outlineController.text = chapter?.outline ?? '';
    _contentController.text = chapter?.content ?? '';
    _historySnapshot =
        chapter == null ? null : _ChapterHistorySnapshot.fromChapter(chapter);
    _syncing = false;
  }

  void _scheduleAutosave() {
    if (_syncing) {
      return;
    }
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 700), _save);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _save() async {
    _autosaveTimer?.cancel();
    final hasDraft = _titleController.text.trim().isNotEmpty ||
        _outlineController.text.trim().isNotEmpty ||
        _contentController.text.trim().isNotEmpty;
    if (!hasDraft || _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await widget.onSave(
        title: _titleController.text,
        outline: _outlineController.text,
        content: _contentController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _historySnapshot = _ChapterHistorySnapshot.fromChapter(saved);
        _saving = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _formatContent() {
    final formatted = _contentController.text
        .split('\n')
        .map((line) => line.trimRight())
        .join('\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    _contentController.text = formatted;
    _contentController.selection =
        TextSelection.collapsed(offset: formatted.length);
    _scheduleAutosave();
  }

  Future<void> _openOutlineDialog() async {
    final controller = TextEditingController(text: _outlineController.text);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final colors = AppPalette.of(context);
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 148, vertical: 88),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120, minHeight: 720),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, size: 18, color: colors.text),
                      const SizedBox(width: 8),
                      Text(
                        '章节大纲',
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: '关闭',
                        onPressed: () =>
                            Navigator.of(context).pop(controller.text),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _EditorBox(
                      controller: controller,
                      hintText: '记录这条大纲的主内容、目标、冲突、伏线和结局兑现。',
                      minLines: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    controller.dispose();
    if (result == null) {
      return;
    }
    _outlineController.text = result;
    _scheduleAutosave();
  }

  void _showHistory() {
    showDialog<void>(
      context: context,
      builder: (context) => _ChapterHistoryDialog(
        snapshot: _historySnapshot,
        onRestore: _restoreHistorySnapshot,
      ),
    );
  }

  Future<void> _restoreHistorySnapshot(_ChapterHistorySnapshot snapshot) async {
    _syncing = true;
    setState(() {
      _titleController.text = snapshot.title;
      _outlineController.text = snapshot.outline;
      _contentController.text = snapshot.content;
    });
    _syncing = false;
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final wordCount = _countWritingUnits(_contentController.text);
    final minutes = math.max(0, (wordCount / 500).ceil());
    final chapterTitle = _titleController.text.trim().isEmpty
        ? '章节标题'
        : _titleController.text.trim();

    return Column(
      children: [
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(bottom: BorderSide(color: colors.line)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.novel.title} > 章节 > $chapterTitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.text, fontSize: 13),
                ),
              ),
              IconButton(
                tooltip: '历史',
                onPressed: _showHistory,
                icon: const Icon(Icons.history, size: 18),
              ),
              IconButton(
                tooltip: '设置',
                onPressed: () {},
                icon: const Icon(Icons.settings_outlined, size: 18),
              ),
              IconButton(
                tooltip: '预览',
                onPressed: () {},
                icon: const Icon(Icons.visibility_outlined, size: 18),
              ),
              IconButton(
                tooltip: '灵感',
                onPressed: () {},
                icon: const Icon(Icons.rocket_launch_outlined, size: 18),
              ),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.text,
                  foregroundColor: colors.card,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('保存'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              if (widget.loading)
                Center(
                  child: CircularProgressIndicator(color: colors.text),
                )
              else
                SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 636),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 28, 0, 86),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '第${widget.chapterNumber}章',
                              style: TextStyle(
                                color: colors.muted,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _titleController,
                              style: TextStyle(
                                color: colors.text,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                              decoration: InputDecoration(
                                hintText: '章节标题',
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: colors.text),
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _OutlineEditorCard(
                              controller: _outlineController,
                              collapsed: _outlineCollapsed,
                              onToggle: () => setState(
                                () => _outlineCollapsed = !_outlineCollapsed,
                              ),
                              onExpand: _openOutlineDialog,
                            ),
                            const SizedBox(height: 24),
                            _EditorBox(
                              controller: _contentController,
                              hintText: '在这里开始写正文。',
                              minLines: 18,
                              borderless: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (widget.error != null)
                Positioned(
                  left: 24,
                  right: 24,
                  top: 18,
                  child: Material(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        widget.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        _ChapterStatusBar(
          saving: _saving,
          wordCount: wordCount,
          readingMinutes: minutes,
          onFormat: _formatContent,
          onHistory: _showHistory,
        ),
      ],
    );
  }
}

class _OutlineEditorCard extends StatefulWidget {
  const _OutlineEditorCard({
    required this.controller,
    required this.collapsed,
    required this.onToggle,
    required this.onExpand,
  });

  final TextEditingController controller;
  final bool collapsed;
  final VoidCallback onToggle;
  final VoidCallback onExpand;

  @override
  State<_OutlineEditorCard> createState() => _OutlineEditorCardState();
}

class _OutlineEditorCardState extends State<_OutlineEditorCard> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: InkWell(
              onTap: widget.onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                color:
                    _hovered ? colors.line.withValues(alpha: 0.8) : colors.card,
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(
                  children: [
                    Icon(Icons.trending_up, size: 16, color: colors.text),
                    const SizedBox(width: 8),
                    Text(
                      '章节大纲',
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: '展开大纲',
                      onPressed: widget.onExpand,
                      icon: const Icon(Icons.open_in_full, size: 16),
                    ),
                    Icon(
                      widget.collapsed ? Icons.expand_more : Icons.expand_less,
                      size: 18,
                      color: colors.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!widget.collapsed) ...[
            Divider(height: 1, color: colors.line),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const _EditorToolbar(),
                  const SizedBox(height: 8),
                  _EditorBox(
                    controller: widget.controller,
                    hintText: '记录这条大纲的主内容、目标、冲突、伏线和结局兑现。',
                    minLines: 5,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar();

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          _ToolbarButton(
            tooltip: '加粗',
            icon: Icons.format_bold,
            color: colors.text,
          ),
          _ToolbarButton(
            tooltip: '倾斜',
            icon: Icons.format_italic,
            color: colors.text,
          ),
          _ToolbarButton(
            tooltip: '删除线',
            icon: Icons.strikethrough_s,
            color: colors.text,
          ),
          _HeadingMenuButton(color: colors.text),
          _ToolbarButton(
            tooltip: '符号',
            icon: Icons.format_list_bulleted,
            color: colors.text,
          ),
          _ToolbarButton(
            tooltip: '编号',
            icon: Icons.format_list_numbered,
            color: colors.text,
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.tooltip,
    required this.icon,
    required this.color,
  });

  final String tooltip;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: () {},
      icon: Icon(icon, size: 17, color: color),
    );
  }
}

class _HeadingMenuButton extends StatelessWidget {
  const _HeadingMenuButton({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return PopupMenuButton<int>(
      tooltip: '标题',
      color: colors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      constraints: const BoxConstraints(minWidth: 64),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: colors.line),
      ),
      itemBuilder: (context) => [
        for (var level = 1; level <= 6; level++)
          PopupMenuItem(
            value: level,
            height: 28,
            child: Row(
              children: [
                Text(
                  'H$level',
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  'H$level',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: SizedBox(
        width: 40,
        height: 38,
        child: Center(
          child: Text(
            'H',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorBox extends StatelessWidget {
  const _EditorBox({
    required this.controller,
    required this.hintText,
    required this.minLines,
    this.borderless = false,
  });

  final TextEditingController controller;
  final String hintText;
  final int minLines;
  final bool borderless;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: null,
      style: TextStyle(color: colors.text, fontSize: 16, height: 1.8),
      decoration: InputDecoration(
        hintText: hintText,
        filled: !borderless,
        fillColor: colors.card,
        border: borderless
            ? InputBorder.none
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.line),
              ),
        enabledBorder: borderless
            ? InputBorder.none
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.line),
              ),
        focusedBorder: borderless
            ? InputBorder.none
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.brand),
              ),
      ),
    );
  }
}

class _ChapterStatusBar extends StatelessWidget {
  const _ChapterStatusBar({
    required this.saving,
    required this.wordCount,
    required this.readingMinutes,
    required this.onFormat,
    required this.onHistory,
  });

  final bool saving;
  final int wordCount;
  final int readingMinutes;
  final VoidCallback onFormat;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Icon(Icons.save_outlined, size: 14, color: colors.muted),
          const SizedBox(width: 6),
          Text(
            saving ? '正在自动保存' : '已启用自动保存',
            style: TextStyle(color: colors.muted, fontSize: 12),
          ),
          const SizedBox(width: 22),
          Icon(Icons.text_fields, size: 14, color: colors.muted),
          const SizedBox(width: 6),
          Text('字数 $wordCount',
              style: TextStyle(color: colors.muted, fontSize: 12)),
          const SizedBox(width: 18),
          Icon(Icons.schedule, size: 14, color: colors.muted),
          const SizedBox(width: 6),
          Text(
            '预计阅读 $readingMinutes 分钟',
            style: TextStyle(color: colors.muted, fontSize: 12),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onFormat,
            icon: const Icon(Icons.auto_fix_high, size: 15),
            label: const Text('格式化'),
            style: TextButton.styleFrom(
              foregroundColor: colors.muted,
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
          TextButton.icon(
            onPressed: onHistory,
            icon: const Icon(Icons.history, size: 15),
            label: const Text('历史'),
            style: TextButton.styleFrom(
              foregroundColor: colors.text,
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _WritingAssistantPanel extends StatefulWidget {
  const _WritingAssistantPanel({
    required this.novel,
    required this.models,
    required this.aiSettings,
    required this.chapters,
    required this.outlines,
    required this.characters,
    required this.foreshadowings,
    required this.expanded,
    required this.onExpand,
    required this.onCollapse,
    required this.onDock,
    this.contextLabel,
    this.draftText,
    this.draftRevision = 0,
    this.onOpenSettings,
  });

  final NovelSummary novel;
  final List<String> models;
  final AppAiSettings aiSettings;
  final List<NovelChapter> chapters;
  final List<NovelOutline> outlines;
  final List<NovelCharacter> characters;
  final List<NovelForeshadowing> foreshadowings;
  final bool expanded;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;
  final VoidCallback onDock;
  final String? contextLabel;
  final String? draftText;
  final int draftRevision;
  final VoidCallback? onOpenSettings;

  @override
  State<_WritingAssistantPanel> createState() => _WritingAssistantPanelState();
}

class _WritingAssistantPanelState extends State<_WritingAssistantPanel> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_AssistantChatMessage>[];
  final _pendingFiles = <_AssistantAttachment>[];
  String? _contextLabel;
  late String _selectedModel;
  var _running = false;
  var _runId = 0;

  List<String> get _models => widget.models.isEmpty
      ? const ['deepseek-v4-flash', 'kimi-k2.6']
      : widget.models;

  @override
  void initState() {
    super.initState();
    _selectedModel = _models.first;
    _contextLabel = widget.contextLabel;
    if (widget.draftText != null) {
      _controller.text = widget.draftText!;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void didUpdateWidget(covariant _WritingAssistantPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_models.contains(_selectedModel)) {
      _selectedModel = _models.first;
    }
    if (oldWidget.draftRevision != widget.draftRevision &&
        widget.draftText != null) {
      _contextLabel = widget.contextLabel;
      _controller.text = widget.draftText!;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      width: widget.expanded ? double.infinity : 360,
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(left: BorderSide(color: colors.line)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 90,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 14, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: colors.text,
                    child:
                        Icon(Icons.auto_awesome, size: 13, color: colors.card),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '写作助手',
                          style: TextStyle(
                            color: colors.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _running
                              ? 'Mirroric · $_selectedModel · 执行中'
                              : 'Mirroric · $_selectedModel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '展开',
                    onPressed:
                        widget.expanded ? widget.onDock : widget.onExpand,
                    icon: Icon(
                      widget.expanded
                          ? Icons.close_fullscreen
                          : Icons.open_in_full,
                      size: 17,
                    ),
                  ),
                  IconButton(
                    tooltip: '新建聊天',
                    onPressed: _newChat,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: widget.onCollapse,
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: colors.line),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                children: [
                  if (_messages.isEmpty) ...[
                    const SizedBox(height: 12),
                    const _AssistantIllustration(),
                    const SizedBox(height: 24),
                    Text(
                      '慢慢写，我会陪你一起\n整理灵感与情节。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 17,
                        height: 1.55,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 34),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '你可以这样开始',
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _AssistantSuggestion(
                      onTap: () => _sendSuggestion(
                        '规划今天的工作',
                        '围绕接下来三章安排今日写作。',
                      ),
                      icon: Icons.format_list_bulleted,
                      title: '规划今天的工作',
                      body: '围绕接下来三章安排今日写作。',
                    ),
                    const SizedBox(height: 12),
                    _AssistantSuggestion(
                      onTap: () => _sendSuggestion(
                        '梳理设定一致性',
                        '核对事实、时间线、角色和伏笔。',
                      ),
                      icon: Icons.flag_outlined,
                      title: '梳理设定一致性',
                      body: '核对事实、时间线、角色和伏笔。',
                    ),
                    const SizedBox(height: 12),
                    _AssistantSuggestion(
                      onTap: () => _sendSuggestion(
                        '开始写下一章',
                        '先读上下文，简要规划后起草正文。',
                      ),
                      icon: Icons.flag_outlined,
                      title: '开始写下一章',
                      body: '先读上下文，简要规划后起草正文。',
                    ),
                    const Spacer(),
                  ] else
                    Expanded(
                      child: _AssistantMessageList(
                        messages: _messages,
                        controller: _scrollController,
                        onAskUserAnswered: _send,
                      ),
                    ),
                  _AssistantInput(
                    controller: _controller,
                    files: _pendingFiles,
                    contextLabel: _contextLabel,
                    models: _models,
                    selectedModel: _selectedModel,
                    onModelSelected: (model) {
                      setState(() => _selectedModel = model);
                    },
                    onOpenSettings: widget.onOpenSettings,
                    onPickFiles: _pickFiles,
                    onPasteFiles: _pasteFilesFromClipboard,
                    onRemoveFile: (file) {
                      setState(() => _pendingFiles.remove(file));
                    },
                    onClearContext: () => setState(() => _contextLabel = null),
                    onSend: _running ? () {} : _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _newChat() {
    setState(() {
      _messages.clear();
      _pendingFiles.clear();
      _contextLabel = null;
      _controller.clear();
      _running = false;
      _runId++;
    });
  }

  void _sendSuggestion(String title, String body) {
    _send('请帮我$title：$body');
  }

  void _send([String? overrideText]) {
    if (_running) {
      return;
    }
    final text = (overrideText ?? _controller.text).trim();
    if (text.isEmpty && _pendingFiles.isEmpty) {
      return;
    }
    final files = List<_AssistantAttachment>.unmodifiable(_pendingFiles);
    final runId = ++_runId;
    setState(() {
      _messages.add(_AssistantChatMessage.user(text: text, files: files));
      _pendingFiles.clear();
      _contextLabel = null;
      _controller.clear();
      _running = true;
    });
    _scrollToLatest();
    unawaited(_runAssistant(runId, text, files));
  }

  Future<void> _runAssistant(
    int runId,
    String text,
    List<_AssistantAttachment> files,
  ) async {
    final sectionIndex = _appendRunMessage(
        runId,
        _AssistantChatMessage.section(
          title: '执行过程',
          text: '运行中',
        ));
    var modelStepIndex = -1;

    try {
      await _runStep<String>(
        runId: runId,
        title: '读取',
        text: '作品概览',
        runningDetail: '正在读取当前作品基础信息。',
        action: _novelOverviewSummary,
        doneDetail: (summary) => summary,
      );
      await _runStep<int>(
        runId: runId,
        title: '读取',
        text: '章节',
        runningDetail: '正在读取当前章节列表。',
        action: () => widget.chapters.length,
        doneDetail: (count) => '$count 章',
      );
      await _runStep<int>(
        runId: runId,
        title: '读取',
        text: '大纲',
        runningDetail: '正在过滤 AI 可读大纲。',
        action: () => widget.outlines
            .where((outline) => !_isHiddenFromAi(outline))
            .length,
        doneDetail: (count) => '$count 条可读',
      );
      await _runStep<int>(
        runId: runId,
        title: '读取',
        text: '人物',
        runningDetail: '正在读取人物卡。',
        action: () => widget.characters.length,
        doneDetail: (count) => '$count 个角色',
      );
      await _runStep<int>(
        runId: runId,
        title: '读取',
        text: '伏笔',
        runningDetail: '正在读取伏笔记录。',
        action: () => widget.foreshadowings.length,
        doneDetail: (count) => '$count 条',
      );
      await _runStep<String>(
        runId: runId,
        title: '检查',
        text: 'AI 可读边界',
        runningDetail: '正在应用本地权限规则。',
        action: _aiAccessSummary,
        doneDetail: (summary) => summary,
      );

      if (!_isCurrentRun(runId)) {
        return;
      }

      if (_shouldAskSetup(text)) {
        _replaceRunMessage(
          runId,
          sectionIndex,
          _AssistantChatMessage.section(title: '执行过程', text: '等待补充信息'),
        );
        _appendRunMessage(
            runId,
            _AssistantChatMessage.askUser(
              title: 'AI 询问',
              text: '在规划或开写前，我需要先补齐会反复影响质量的基础规则。',
              questions: const [
                _AssistantQuestion(
                  label: '核心设定',
                  question: '这个故事的核心设定是什么？题材、世界观、主角是谁，开篇从哪里切入？',
                ),
                _AssistantQuestion(
                  label: '已有资料',
                  question: '你这本书目前有没有其他地方的设定、灵感、讨论记录或已经写好的片段？',
                ),
                _AssistantQuestion(
                  label: '写作风格',
                  question: '每章大概多少字？文风偏爽文快节奏、慢热正剧、技术流，还是其他方向？有哪些禁忌？',
                ),
              ],
            ));
        _finishRun(runId);
        return;
      }

      final prompt = await _runStep<String>(
        runId: runId,
        title: '构建',
        text: '模型上下文',
        runningDetail: '正在拼接用户任务、附件与可读小说资料。',
        action: () => _buildAssistantPrompt(text, files),
        doneDetail: (prompt) => '${prompt.length} 字符',
      );
      final provider = await _runStep<AppAiProviderSettings?>(
        runId: runId,
        title: '检查',
        text: '模型配置',
        runningDetail: '正在匹配 $_selectedModel 的可用供应商。',
        action: _providerForSelectedModel,
        doneDetail: (provider) => provider == null ? '未找到可用供应商' : '已匹配可用供应商',
      );

      if (!_isCurrentRun(runId)) {
        return;
      }

      if (provider == null) {
        _replaceRunMessage(
          runId,
          sectionIndex,
          _AssistantChatMessage.section(title: '执行过程', text: '等待模型配置'),
        );
        _appendRunMessage(
            runId,
            _AssistantChatMessage.assistant(
              text:
                  '我已经读完当前项目上下文，但还没有可用的 AI 供应商配置。请先在设置里启用供应商、填写 API Key/Base URL，并选择模型。',
            ));
        _finishRun(runId);
        return;
      }

      modelStepIndex = _appendRunMessage(
          runId,
          _AssistantChatMessage.reasoning(
            title: '深度思考',
            text: '正在请求 $_selectedModel 生成回复。',
            status: _AssistantStepStatus.running,
          ));
      final completion = await createOpenAiCompatibleChatCompletion(
        apiKey: provider.apiKey.trim(),
        baseUrl: provider.baseUrl.trim(),
        model: _selectedModel,
        messages: [
          {
            'role': 'system',
            'content': _assistantSystemPrompt,
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
      ).timeout(
        const Duration(seconds: 120),
        onTimeout: () => throw TimeoutException('AI 回复超时，请稍后重试。'),
      );
      _replaceRunMessage(
        runId,
        modelStepIndex,
        _AssistantChatMessage.reasoning(
          title: '深度思考',
          text: '$_selectedModel 已返回 ${completion.content.length} 字。',
          status: _AssistantStepStatus.done,
        ),
      );
      _replaceRunMessage(
        runId,
        sectionIndex,
        _AssistantChatMessage.section(title: '执行过程', text: '完成'),
      );
      _appendRunMessage(
          runId, _AssistantChatMessage.assistant(text: completion.content));
    } catch (error) {
      if (modelStepIndex >= 0) {
        _replaceRunMessage(
          runId,
          modelStepIndex,
          _AssistantChatMessage.reasoning(
            title: '深度思考',
            text: '$_selectedModel 调用失败：$error',
            status: _AssistantStepStatus.failed,
          ),
        );
      }
      _replaceRunMessage(
        runId,
        sectionIndex,
        _AssistantChatMessage.section(title: '执行过程', text: '失败'),
      );
      _appendRunMessage(
          runId,
          _AssistantChatMessage.assistant(
            text: '这次 AI 调用失败：$error',
          ));
    } finally {
      _finishRun(runId);
    }
  }

  Future<T> _runStep<T>({
    required int runId,
    required String title,
    required String text,
    required String runningDetail,
    required FutureOr<T> Function() action,
    required String Function(T result) doneDetail,
  }) async {
    final index = _appendRunMessage(
        runId,
        _AssistantChatMessage.tool(
          title: title,
          text: text,
          detail: runningDetail,
          status: _AssistantStepStatus.running,
        ));
    try {
      final result = await Future<T>.sync(action);
      _replaceRunMessage(
          runId,
          index,
          _AssistantChatMessage.tool(
            title: title,
            text: text,
            detail: doneDetail(result),
            status: _AssistantStepStatus.done,
          ));
      return result;
    } catch (error) {
      _replaceRunMessage(
          runId,
          index,
          _AssistantChatMessage.tool(
            title: title,
            text: text,
            detail: '$error',
            status: _AssistantStepStatus.failed,
          ));
      rethrow;
    }
  }

  int _appendRunMessage(int runId, _AssistantChatMessage message) {
    if (!_isCurrentRun(runId)) {
      return -1;
    }
    late final int index;
    setState(() {
      index = _messages.length;
      _messages.add(message);
    });
    _scrollToLatest();
    return index;
  }

  void _replaceRunMessage(
    int runId,
    int index,
    _AssistantChatMessage message,
  ) {
    if (!_isCurrentRun(runId) || index < 0 || index >= _messages.length) {
      return;
    }
    setState(() => _messages[index] = message);
    _scrollToLatest();
  }

  bool _isCurrentRun(int runId) {
    return mounted && runId == _runId;
  }

  void _finishRun(int runId) {
    if (_isCurrentRun(runId)) {
      setState(() => _running = false);
    }
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  AppAiProviderSettings? _providerForSelectedModel() {
    for (final provider in widget.aiSettings.providers) {
      if (!provider.isReady) {
        continue;
      }
      if (provider.selectedModel == _selectedModel ||
          provider.availableModels.contains(_selectedModel)) {
        return provider;
      }
    }
    return null;
  }

  bool _shouldAskSetup(String text) {
    if (text.startsWith('开书规则回答：')) {
      return false;
    }
    final lower = text.toLowerCase();
    final creativeIntent = text.contains('写') ||
        text.contains('规划') ||
        text.contains('下一章') ||
        text.contains('大纲') ||
        lower.contains('chapter');
    if (!creativeIntent) {
      return false;
    }
    final hasReusableContext = widget.chapters.isNotEmpty ||
        widget.characters.isNotEmpty ||
        widget.foreshadowings.isNotEmpty ||
        widget.outlines.any((outline) =>
            !_isHiddenFromAi(outline) && outline.content.trim().isNotEmpty);
    final hasNovelBrief = widget.novel.summary.trim().isNotEmpty ||
        widget.novel.category.trim().isNotEmpty ||
        widget.novel.workType.trim().isNotEmpty ||
        widget.novel.tags.isNotEmpty;
    return !hasReusableContext && !hasNovelBrief;
  }

  bool _isHiddenFromAi(NovelOutline outline) {
    return _outlineAccess(outline, 'readAccess') == 'ai_hidden';
  }

  String _novelOverviewSummary() {
    final bits = [
      if (widget.novel.summary.trim().isNotEmpty) widget.novel.summary.trim(),
      if (widget.novel.category.trim().isNotEmpty) widget.novel.category.trim(),
      if (widget.novel.workType.trim().isNotEmpty) widget.novel.workType.trim(),
      if (widget.novel.tags.isNotEmpty) widget.novel.tags.join(' / '),
    ];
    return bits.isEmpty ? '暂无简介' : bits.join(' · ');
  }

  String _aiAccessSummary() {
    final hiddenCount =
        widget.outlines.where((outline) => _isHiddenFromAi(outline)).length;
    final readableCount = widget.outlines.length - hiddenCount;
    return '可读资料 $readableCount 条，隐藏资料 $hiddenCount 条，本轮只读不写。';
  }

  String _buildAssistantPrompt(
    String text,
    List<_AssistantAttachment> files,
  ) {
    final buffer = StringBuffer()
      ..writeln('## 用户任务')
      ..writeln(text)
      ..writeln()
      ..writeln('## 当前小说')
      ..writeln('标题：${widget.novel.title}')
      ..writeln(
          '状态：${widget.novel.status.isEmpty ? '未设置' : widget.novel.status}')
      ..writeln(
          '简介：${widget.novel.summary.isEmpty ? '暂无' : widget.novel.summary}')
      ..writeln(
          '分类：${widget.novel.category.isEmpty ? '未设置' : widget.novel.category}')
      ..writeln(
          '类型：${widget.novel.workType.isEmpty ? '未设置' : widget.novel.workType}')
      ..writeln(
          '标签：${widget.novel.tags.isEmpty ? '暂无' : widget.novel.tags.join('、')}')
      ..writeln();

    if (files.isNotEmpty) {
      buffer
        ..writeln('## 用户附加文件')
        ..writeln(
            files.map((file) => '- ${file.name}: ${file.path}').join('\n'))
        ..writeln();
    }

    buffer
      ..writeln('## 章节')
      ..writeln(widget.chapters.isEmpty ? '暂无章节。' : '');
    for (final entry in widget.chapters.indexed.take(6)) {
      final chapter = entry.$2;
      buffer
        ..writeln('### ${entry.$1 + 1}. ${chapter.title}')
        ..writeln('大纲：${_clipText(chapter.outline, 500)}')
        ..writeln('正文摘录：${_clipText(chapter.content, 900)}');
    }

    buffer
      ..writeln()
      ..writeln('## 大纲 / 设定 / 资料');
    final readableOutlines = [
      for (final outline in widget.outlines)
        if (!_isHiddenFromAi(outline)) outline,
    ];
    if (readableOutlines.isEmpty) {
      buffer.writeln('暂无可读资料。');
    }
    for (final outline in readableOutlines.take(12)) {
      buffer
        ..writeln('### ${outline.title} (${outline.status})')
        ..writeln(_clipText(outline.content, 700));
    }

    buffer
      ..writeln()
      ..writeln('## 人物');
    if (widget.characters.isEmpty) {
      buffer.writeln('暂无人物卡。');
    }
    for (final character in widget.characters.take(12)) {
      buffer
        ..writeln('- ${character.name}｜${character.role}｜${character.identity}')
        ..writeln('  状态：${_clipText(character.currentState, 240)}')
        ..writeln('  动机：${_clipText(character.motivation, 240)}');
    }

    buffer
      ..writeln()
      ..writeln('## 伏笔');
    if (widget.foreshadowings.isEmpty) {
      buffer.writeln('暂无伏笔记录。');
    }
    for (final item in widget.foreshadowings.take(12)) {
      buffer
        ..writeln('- ${item.title}｜${item.status}')
        ..writeln('  埋设：${_clipText(item.setupContent, 240)}')
        ..writeln('  回收：${_clipText(item.payoffContent, 240)}');
    }

    return buffer.toString();
  }

  String _clipText(String text, int maxLength) {
    final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) {
      return '暂无';
    }
    if (compact.length <= maxLength) {
      return compact;
    }
    return '${compact.substring(0, maxLength)}...';
  }

  Future<void> _pickFiles() async {
    final files = await openFiles(acceptedTypeGroups: _assistantFileTypes);
    if (files.isEmpty || !mounted) {
      return;
    }
    setState(() {
      _pendingFiles.addAll([
        for (final file in files)
          _AssistantAttachment(name: file.name, path: file.path),
      ]);
    });
  }

  Future<void> _pasteFilesFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    final files = <_AssistantAttachment>[];
    for (final rawLine in text.split(RegExp(r'[\r\n]+'))) {
      final path = _clipboardPath(rawLine);
      if (path == null || !File(path).existsSync()) {
        continue;
      }
      files.add(_AssistantAttachment(name: _fileName(path), path: path));
    }
    if (files.isEmpty || !mounted) {
      return;
    }
    setState(() => _pendingFiles.addAll(files));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已添加 ${files.length} 个剪贴板文件')),
    );
  }

  String? _clipboardPath(String value) {
    var path = value.trim();
    if (path.isEmpty) {
      return null;
    }
    if ((path.startsWith('"') && path.endsWith('"')) ||
        (path.startsWith("'") && path.endsWith("'"))) {
      path = path.substring(1, path.length - 1);
    }
    final uri = Uri.tryParse(path);
    if (uri != null && uri.scheme == 'file') {
      return uri.toFilePath(windows: Platform.isWindows);
    }
    return path;
  }
}

const _assistantSystemPrompt = '''
你是 AI 小说工坊的写作智能体。你需要先依据提供的小说上下文工作，不编造不存在的事实。

工作规则：
1. 当前版本只读上下文，不直接写入数据库；需要写入时输出可执行建议或草稿。
2. 如果项目信息不足，先指出缺口并给用户最少必要问题。
3. 回答要服务作者继续创作，避免泛泛鼓励。
4. 涉及多种互斥创作方向时，先给推荐和理由，再请用户选择。
5. 尊重“对 AI 隐藏 / AI 不可编辑”边界，未提供的资料不要假装已读取。
''';

const _assistantFileTypes = [
  XTypeGroup(
    label: '文档',
    extensions: ['txt', 'md', 'markdown', 'pdf', 'docx', 'json', 'yaml', 'yml'],
  ),
  XTypeGroup(
    label: '表格',
    extensions: ['csv', 'tsv', 'xlsx', 'xls'],
  ),
  XTypeGroup(
    label: '图片',
    extensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
  ),
];

enum _AssistantMessageKind {
  user,
  assistant,
  section,
  tool,
  reasoning,
  askUser,
}

enum _AssistantStepStatus { running, done, failed }

class _AssistantQuestion {
  const _AssistantQuestion({
    required this.label,
    required this.question,
  });

  final String label;
  final String question;
}

class _AssistantChatMessage {
  const _AssistantChatMessage({
    required this.kind,
    required this.text,
    this.title = '',
    this.detail = '',
    this.files = const [],
    this.questions = const [],
    this.status = _AssistantStepStatus.done,
  });

  factory _AssistantChatMessage.user({
    required String text,
    required List<_AssistantAttachment> files,
  }) {
    return _AssistantChatMessage(
      kind: _AssistantMessageKind.user,
      text: text,
      files: files,
    );
  }

  factory _AssistantChatMessage.assistant({required String text}) {
    return _AssistantChatMessage(
      kind: _AssistantMessageKind.assistant,
      text: text,
    );
  }

  factory _AssistantChatMessage.section({
    required String title,
    required String text,
  }) {
    return _AssistantChatMessage(
      kind: _AssistantMessageKind.section,
      title: title,
      text: text,
    );
  }

  factory _AssistantChatMessage.tool({
    required String title,
    required String text,
    required String detail,
    _AssistantStepStatus status = _AssistantStepStatus.done,
  }) {
    return _AssistantChatMessage(
      kind: _AssistantMessageKind.tool,
      title: title,
      text: text,
      detail: detail,
      status: status,
    );
  }

  factory _AssistantChatMessage.reasoning({
    required String title,
    required String text,
    _AssistantStepStatus status = _AssistantStepStatus.done,
  }) {
    return _AssistantChatMessage(
      kind: _AssistantMessageKind.reasoning,
      title: title,
      text: text,
      status: status,
    );
  }

  factory _AssistantChatMessage.askUser({
    required String title,
    required String text,
    required List<_AssistantQuestion> questions,
  }) {
    return _AssistantChatMessage(
      kind: _AssistantMessageKind.askUser,
      title: title,
      text: text,
      questions: questions,
    );
  }

  final _AssistantMessageKind kind;
  final String title;
  final String text;
  final String detail;
  final List<_AssistantAttachment> files;
  final List<_AssistantQuestion> questions;
  final _AssistantStepStatus status;

  bool get isUser => kind == _AssistantMessageKind.user;
}

class _AssistantAttachment {
  const _AssistantAttachment({required this.name, required this.path});

  final String name;
  final String path;
}

String _fileName(String path) {
  final parts = path.split(RegExp(r'[\\/]'));
  return parts.isEmpty ? path : parts.last;
}

class _AssistantIllustration extends StatelessWidget {
  const _AssistantIllustration();

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return SizedBox(
      width: 210,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 4,
            child: Container(
              width: 170,
              height: 12,
              decoration: BoxDecoration(
                color: colors.line.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            top: 10,
            child: Container(
              width: 72,
              height: 92,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3D5),
                borderRadius: BorderRadius.circular(36),
              ),
            ),
          ),
          Positioned(
            top: 22,
            child: Container(
              width: 54,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7FA),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFF4DDAA), width: 4),
              ),
              child: Icon(Icons.auto_awesome,
                  color: const Color(0xFFF1CF89), size: 18),
            ),
          ),
          Positioned(
            left: 40,
            bottom: 38,
            child: Icon(Icons.eco, color: const Color(0xFFA9C38A), size: 42),
          ),
          Positioned(
            right: 36,
            bottom: 34,
            child: Icon(Icons.auto_awesome,
                color: const Color(0xFFE8C982), size: 26),
          ),
          Positioned(
            bottom: 24,
            child: Icon(Icons.menu_book_outlined,
                color: const Color(0xFFE6C990), size: 74),
          ),
        ],
      ),
    );
  }
}

class _AssistantSuggestion extends StatelessWidget {
  const _AssistantSuggestion({
    required this.icon,
    required this.title,
    required this.body,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 74,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.line),
                  ),
                  child: Icon(icon, size: 18, color: colors.text),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward, size: 16, color: colors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantInput extends StatelessWidget {
  const _AssistantInput({
    required this.controller,
    required this.files,
    required this.contextLabel,
    required this.models,
    required this.selectedModel,
    required this.onModelSelected,
    required this.onPickFiles,
    required this.onPasteFiles,
    required this.onRemoveFile,
    required this.onClearContext,
    required this.onSend,
    this.onOpenSettings,
  });

  final TextEditingController controller;
  final List<_AssistantAttachment> files;
  final String? contextLabel;
  final List<String> models;
  final String selectedModel;
  final ValueChanged<String> onModelSelected;
  final VoidCallback onPickFiles;
  final VoidCallback onPasteFiles;
  final ValueChanged<_AssistantAttachment> onRemoveFile;
  final VoidCallback onClearContext;
  final VoidCallback onSend;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Focus(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }
        final pressed = HardwareKeyboard.instance.logicalKeysPressed;
        final ctrl = pressed.contains(LogicalKeyboardKey.controlLeft) ||
            pressed.contains(LogicalKeyboardKey.controlRight) ||
            pressed.contains(LogicalKeyboardKey.metaLeft) ||
            pressed.contains(LogicalKeyboardKey.metaRight);
        if (ctrl && event.logicalKey == LogicalKeyboardKey.keyV) {
          onPasteFiles();
          return KeyEventResult.ignored;
        }
        final shift = pressed.contains(LogicalKeyboardKey.shiftLeft) ||
            pressed.contains(LogicalKeyboardKey.shiftRight);
        if (!shift && event.logicalKey == LogicalKeyboardKey.enter) {
          onSend();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 88, maxHeight: 172),
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (files.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final file in files)
                      InputChip(
                        label: Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onDeleted: () => onRemoveFile(file),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
            if (contextLabel != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  avatar: const Icon(Icons.description_outlined, size: 14),
                  label: Text(
                    contextLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onDeleted: onClearContext,
                  deleteIcon: const Icon(Icons.close, size: 14),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Flexible(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: '输入消息，Enter 发送',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  tooltip: '添加文件',
                  onPressed: onPickFiles,
                  icon: const Icon(Icons.add, size: 18),
                ),
                const Spacer(),
                _AssistantModelMenu(
                  models: models,
                  selectedModel: selectedModel,
                  onSelected: onModelSelected,
                  onOpenSettings: onOpenSettings,
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton.filledTonal(
                    tooltip: '发送',
                    onPressed: onSend,
                    icon: const Icon(Icons.arrow_upward, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AssistantModelMenu extends StatelessWidget {
  const _AssistantModelMenu({
    required this.models,
    required this.selectedModel,
    required this.onSelected,
    this.onOpenSettings,
  });

  final List<String> models;
  final String selectedModel;
  final ValueChanged<String> onSelected;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return PopupMenuButton<String>(
      tooltip: '切换模型',
      constraints: const BoxConstraints(minWidth: 260),
      color: colors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.line),
      ),
      onSelected: (value) {
        if (value == '__add_model__') {
          onOpenSettings?.call();
          return;
        }
        onSelected(value);
      },
      itemBuilder: (context) => [
        for (final model in models)
          PopupMenuItem(
            value: model,
            child: Row(
              children: [
                Icon(Icons.smart_toy_outlined, size: 16, color: colors.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(model, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        'Mirroric',
                        style: TextStyle(color: colors.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (model == selectedModel)
                  Icon(Icons.check, size: 18, color: colors.text),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: '__add_model__',
          child: Center(child: Text('添加模型')),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(selectedModel,
              style: TextStyle(color: colors.muted, fontSize: 11)),
          Icon(Icons.expand_more, color: colors.muted, size: 16),
        ],
      ),
    );
  }
}

class _AssistantMessageList extends StatelessWidget {
  const _AssistantMessageList({
    required this.messages,
    required this.controller,
    required this.onAskUserAnswered,
  });

  final List<_AssistantChatMessage> messages;
  final ScrollController controller;
  final ValueChanged<String> onAskUserAnswered;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final message = messages[index];
        return switch (message.kind) {
          _AssistantMessageKind.user => _AssistantBubble(message: message),
          _AssistantMessageKind.assistant => _AssistantBubble(message: message),
          _AssistantMessageKind.section => _AssistantSection(message: message),
          _AssistantMessageKind.tool => _AssistantToolRow(message: message),
          _AssistantMessageKind.reasoning =>
            _AssistantReasoningCard(message: message),
          _AssistantMessageKind.askUser => _AssistantAskUserCard(
              message: message,
              onSubmit: onAskUserAnswered,
            ),
        };
      },
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.message});

  final _AssistantChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUser ? colors.text : colors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isUser ? colors.text : colors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.text.isNotEmpty)
                Text(
                  message.text,
                  style: TextStyle(
                    color: isUser ? colors.card : colors.text,
                    height: 1.45,
                  ),
                ),
              for (final file in message.files) ...[
                if (message.text.isNotEmpty) const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 15,
                      color: isUser ? colors.card : colors.muted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        file.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isUser ? colors.card : colors.text,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistantSection extends StatelessWidget {
  const _AssistantSection({required this.message});

  final _AssistantChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Row(
      children: [
        Icon(Icons.auto_awesome, size: 17, color: colors.text),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message.title,
            style: TextStyle(
              color: colors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.line),
          ),
          child: Text(
            message.text,
            style: TextStyle(color: colors.muted, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _AssistantToolRow extends StatelessWidget {
  const _AssistantToolRow({required this.message});

  final _AssistantChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final status = message.status;
    final statusColor = switch (status) {
      _AssistantStepStatus.running => colors.brand,
      _AssistantStepStatus.done => const Color(0xFF14804A),
      _AssistantStepStatus.failed => const Color(0xFFB42318),
    };
    final statusBackground = switch (status) {
      _AssistantStepStatus.running => colors.background,
      _AssistantStepStatus.done => const Color(0xFFBDF4D8),
      _AssistantStepStatus.failed => const Color(0xFFFEE4E2),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: statusBackground,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: switch (status) {
              _AssistantStepStatus.running => SizedBox(
                  width: 11,
                  height: 11,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              _AssistantStepStatus.done =>
                Icon(Icons.check, size: 13, color: statusColor),
              _AssistantStepStatus.failed =>
                Icon(Icons.close, size: 13, color: statusColor),
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.title,
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        message.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.muted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message.detail,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AssistantReasoningCard extends StatelessWidget {
  const _AssistantReasoningCard({required this.message});

  final _AssistantChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final statusColor = switch (message.status) {
      _AssistantStepStatus.running => colors.brand,
      _AssistantStepStatus.done => const Color(0xFF14804A),
      _AssistantStepStatus.failed => const Color(0xFFB42318),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.status == _AssistantStepStatus.running)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            )
          else
            Icon(
              message.status == _AssistantStepStatus.failed
                  ? Icons.error_outline
                  : Icons.psychology_outlined,
              size: 18,
              color: statusColor,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.title,
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message.text,
                  style: TextStyle(color: colors.muted, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantAskUserCard extends StatefulWidget {
  const _AssistantAskUserCard({
    required this.message,
    required this.onSubmit,
  });

  final _AssistantChatMessage message;
  final ValueChanged<String> onSubmit;

  @override
  State<_AssistantAskUserCard> createState() => _AssistantAskUserCardState();
}

class _AssistantAskUserCardState extends State<_AssistantAskUserCard> {
  late final List<TextEditingController> _controllers;
  var _submitted = false;

  @override
  void initState() {
    super.initState();
    _controllers = [
      for (final _ in widget.message.questions) TextEditingController(),
    ];
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final answers = <String>[];
    for (var i = 0; i < widget.message.questions.length; i++) {
      final answer = _controllers[i].text.trim();
      if (answer.isNotEmpty) {
        answers.add('${widget.message.questions[i].label}：$answer');
      }
    }
    if (answers.isEmpty) {
      return;
    }
    setState(() => _submitted = true);
    widget.onSubmit('开书规则回答：\n${answers.join('\n')}');
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, size: 17, color: colors.text),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.message.title,
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _submitted ? '已回复' : '等待回复',
                  style: TextStyle(color: colors.muted, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.message.text,
            style: TextStyle(color: colors.muted, height: 1.45),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < widget.message.questions.length; i++) ...[
            Text(
              '${i + 1}. ${widget.message.questions[i].question}',
              style: TextStyle(
                color: colors.text,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controllers[i],
              enabled: !_submitted,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '输入你的回答...',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _submitted ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: colors.text),
              child: const Text('确认'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantCollapsedTab extends StatelessWidget {
  const _AssistantCollapsedTab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      width: 44,
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(left: BorderSide(color: colors.line)),
      ),
      child: Center(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: colors.text, size: 18),
                const SizedBox(height: 10),
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'AI',
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Icon(Icons.chevron_left, color: colors.muted, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showBookExperimentalWritingDialog(
  BuildContext context, {
  required BookDeconstructionProject project,
  required BookExperimentalMessageLoader loadMessages,
  required BookExperimentalMessageSender onSendMessage,
  required BookExperimentalFinalDraftSaver onSaveFinalDraft,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => Center(
      child: _BookExperimentalWritingDialog(
        project: project,
        loadMessages: loadMessages,
        onSendMessage: onSendMessage,
        onSaveFinalDraft: onSaveFinalDraft,
        onClose: entry.remove,
      ),
    ),
  );
  overlay.insert(entry);
  return Future.value();
}

class _BookExperimentalWritingDialog extends StatefulWidget {
  const _BookExperimentalWritingDialog({
    required this.project,
    required this.loadMessages,
    required this.onSendMessage,
    required this.onSaveFinalDraft,
    required this.onClose,
  });

  final BookDeconstructionProject project;
  final BookExperimentalMessageLoader loadMessages;
  final BookExperimentalMessageSender onSendMessage;
  final BookExperimentalFinalDraftSaver onSaveFinalDraft;
  final VoidCallback onClose;

  @override
  State<_BookExperimentalWritingDialog> createState() =>
      _BookExperimentalWritingDialogState();
}

class _BookExperimentalWritingDialogState
    extends State<_BookExperimentalWritingDialog> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<BookExperimentalWritingMessage> _messages = const [];
  var _loading = true;
  var _sending = false;
  var _saving = false;
  String? _error;
  String? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _load() async {
    try {
      final messages = await widget.loadMessages(widget.project.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _messages = messages;
        _loading = false;
        _error = null;
      });
      _scrollToLatest();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
      _status = '已发送，正在构建 Skill 上下文并等待 Agent 回复。';
      _messages = [
        ..._messages,
        BookExperimentalWritingMessage(
          projectId: widget.project.id,
          role: 'user',
          content: text,
          createdAt: DateTime.now(),
        ),
      ];
    });
    _controller.clear();
    _scrollToLatest();
    try {
      await widget.onSendMessage(widget.project.id, text);
      final messages = await widget.loadMessages(widget.project.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _messages = messages;
        _status = '回复已保存。';
      });
      _scrollToLatest();
    } catch (error) {
      if (!mounted) {
        return;
      }
      List<BookExperimentalWritingMessage>? messages;
      try {
        messages = await widget.loadMessages(widget.project.id);
      } catch (_) {
        messages = null;
      }
      setState(() {
        if (messages != null) {
          _messages = messages;
        }
        _error = error.toString();
        _status = '生成失败，用户消息已保留，可重试。';
      });
      _scrollToLatest();
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _saveFinalDraft() async {
    final draft = _lastAgentDraft;
    if (draft == null || _saving) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSaveFinalDraft(widget.project.id, draft.content);
      if (mounted) {
        widget.onClose();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  BookExperimentalWritingMessage? get _lastAgentDraft {
    for (final message in _messages.reversed) {
      if (!message.isUser) {
        return message;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final canSave = _lastAgentDraft != null && !_saving && !_sending;

    return Dialog(
      insetPadding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 680),
        child: SizedBox(
          width: 900,
          height: 680,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 14, 14),
                child: Row(
                  children: [
                    Icon(Icons.science_outlined, color: colors.brand, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '实验性写作 Agent',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: colors.text,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '锁定项目：${widget.project.title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: colors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭',
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.line),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _BookExperimentalMessageList(
                        messages: _messages,
                        controller: _scrollController,
                      ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                  child: Text(
                    _error!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (_status != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                  child: Text(
                    _status!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.muted, fontSize: 12),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.enter): _send,
                      },
                      child: TextField(
                        controller: _controller,
                        minLines: 2,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: '例如：自由发挥一个 1500 字都市奇幻开场，重点测试文风和节奏。',
                          filled: true,
                          fillColor: colors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: colors.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: colors.line),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '敲定后会保存到本拆书项目的 experiments/final_draft.md。',
                            style: TextStyle(color: colors.muted, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: canSave ? _saveFinalDraft : null,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.task_alt, size: 18),
                          label: const Text('敲定为最终稿'),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: _sending ? null : _send,
                          icon: _sending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send, size: 18),
                          label: Text(_sending ? '生成中' : '发送'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookExperimentalMessageList extends StatelessWidget {
  const _BookExperimentalMessageList({
    required this.messages,
    required this.controller,
  });

  final List<BookExperimentalWritingMessage> messages;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    if (messages.isEmpty) {
      return Center(
        child: Text(
          '还没有对话。先描述题材、字数、限制，或让 Agent 自由发挥。',
          style: TextStyle(color: colors.muted),
        ),
      );
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.all(18),
      itemCount: messages.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final message = messages[index];
        return Align(
          alignment:
              message.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? colors.text
                    : colors.background.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: message.isUser ? colors.text : colors.line,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.isUser ? '你' : '实验性写作 Agent',
                    style: TextStyle(
                      color: message.isUser ? colors.card : colors.brand,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    message.content,
                    style: TextStyle(
                      color: message.isUser ? colors.card : colors.text,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onToggleTheme,
    this.onOpenSettings,
    this.onOpenBookBreakdown,
    this.onBack,
  });

  final VoidCallback onToggleTheme;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenBookBreakdown;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          bottom: BorderSide(color: colors.line),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1224),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.brand,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    context.l10n.text('brand.mark'),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.text('app.title'),
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.text('app.subtitle'),
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  tooltip: isDarkMode
                      ? context.l10n.text('theme.light')
                      : context.l10n.text('theme.dark'),
                  onPressed: onToggleTheme,
                  icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                ),
                if (onOpenSettings != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onOpenSettings,
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: Text(context.l10n.text('settings')),
                  ),
                ],
                if (onOpenBookBreakdown != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onOpenBookBreakdown,
                    icon: const Icon(Icons.auto_stories_outlined, size: 18),
                    label: Text(context.l10n.text('action.bookBreakdown')),
                  ),
                ],
                if (onBack != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: context.l10n.isEnglish ? 'Back' : '返回',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookBreakdownStartCard extends StatelessWidget {
  const _BookBreakdownStartCard({
    this.onImportNovel,
    this.onStartOrPause,
    this.onOpenExperimentalWriting,
    this.project,
    required this.nodeStatuses,
  });

  final VoidCallback? onImportNovel;
  final VoidCallback? onStartOrPause;
  final ValueChanged<int>? onOpenExperimentalWriting;
  final BookDeconstructionProject? project;
  final Map<String, BookDeconstructionNodeStatus> nodeStatuses;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final title = project?.novelTitle ?? '未选择小说';
    final subtitle = project?.hasNovel ?? false
        ? '拆书项目：${project!.title}'
        : '导入 TXT / EPUB 后开始生成拆书资产。';
    final running = project?.isRunning ?? false;

    return _CardShell(
      minHeight: 390,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '开始拆书',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 128,
                  height: 188,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.line),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.text,
                        colors.brand.withValues(alpha: 0.36),
                        colors.card,
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.auto_stories_outlined,
                    color: colors.card,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 28),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: colors.text,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subtitle,
                        style: TextStyle(color: colors.muted),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '分析目标',
                        style: TextStyle(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final target in _bookBreakdownTargets)
                            _BookBreakdownTargetChip(
                              icon: target.icon,
                              label: target.label,
                              status: _bookBreakdownStatusForNodes(
                                nodeStatuses,
                                target.nodeIds,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 14,
              children: [
                _PrimaryButton(
                  icon: running ? Icons.pause : Icons.play_arrow,
                  label: running ? '暂停拆书' : '开始拆书',
                  onPressed: onStartOrPause ?? () {},
                ),
                _SecondaryButton(
                  icon: Icons.upload_file,
                  label: context.l10n.text('action.importNovel'),
                  onPressed: onImportNovel ?? () {},
                ),
                _SecondaryButton(
                  icon: Icons.science_outlined,
                  label: '实验写作',
                  onPressed: project == null
                      ? () {}
                      : () => onOpenExperimentalWriting?.call(project!.id),
                ),
                const SizedBox(width: 32),
                _BookBreakdownPipeline(nodeStatuses: nodeStatuses),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BookBreakdownTargetData {
  const _BookBreakdownTargetData({
    required this.icon,
    required this.label,
    required this.nodeIds,
  });

  final IconData icon;
  final String label;
  final List<String> nodeIds;
}

class _BookBreakdownPipelineStepData {
  const _BookBreakdownPipelineStepData({
    required this.icon,
    required this.label,
    required this.nodeIds,
  });

  final IconData icon;
  final String label;
  final List<String> nodeIds;
}

const _bookBreakdownTargets = [
  _BookBreakdownTargetData(
    icon: Icons.article_outlined,
    label: '章节拆解',
    nodeIds: ['book_chapter_content'],
  ),
  _BookBreakdownTargetData(
    icon: Icons.travel_explore,
    label: '全书总览',
    nodeIds: ['book_overview'],
  ),
  _BookBreakdownTargetData(
    icon: Icons.account_tree_outlined,
    label: '情节结构',
    nodeIds: ['book_plot_structure'],
  ),
  _BookBreakdownTargetData(
    icon: Icons.groups_outlined,
    label: '人物关系',
    nodeIds: ['book_relationships'],
  ),
  _BookBreakdownTargetData(
    icon: Icons.psychology_alt_outlined,
    label: '伏笔悬念',
    nodeIds: ['foreshadowing_initial', 'foreshadowing_review'],
  ),
  _BookBreakdownTargetData(
    icon: Icons.fingerprint,
    label: '文风指纹',
    nodeIds: [
      'style_chapter_statistics',
      'style_global',
      'style_character_voice',
      'style_scene_voice',
    ],
  ),
  _BookBreakdownTargetData(
    icon: Icons.integration_instructions_outlined,
    label: 'Skill 编译',
    nodeIds: ['book_skill_compile'],
  ),
];

const _bookBreakdownPipelineSteps = [
  _BookBreakdownPipelineStepData(
    icon: Icons.cleaning_services_outlined,
    label: '文本清洗',
    nodeIds: ['book_text_cleaning'],
  ),
  _BookBreakdownPipelineStepData(
    icon: Icons.segment_outlined,
    label: '分章',
    nodeIds: ['gate_1_text_cleaned'],
  ),
  _BookBreakdownPipelineStepData(
    icon: Icons.description_outlined,
    label: '拆解',
    nodeIds: [
      'book_chapter_content',
      'style_chapter_statistics',
      'base_index_normalization',
      'book_plot_structure',
      'book_relationships',
      'foreshadowing_initial',
      'style_global',
      'book_business_mechanism',
      'style_character_voice',
      'style_scene_voice',
      'foreshadowing_review',
      'gate_4_multidimensional_analysis',
    ],
  ),
  _BookBreakdownPipelineStepData(
    icon: Icons.summarize_outlined,
    label: '汇总',
    nodeIds: ['book_overview', 'book_template_distillation'],
  ),
  _BookBreakdownPipelineStepData(
    icon: Icons.ios_share_outlined,
    label: 'Skill 编译',
    nodeIds: ['book_skill_compile', 'book_quality_check'],
  ),
];

BookDeconstructionNodeStatus _bookBreakdownStatusForNodes(
  Map<String, BookDeconstructionNodeStatus> statuses,
  List<String> nodeIds,
) {
  final values = [
    for (final id in nodeIds)
      if (statuses[id] != null) statuses[id]!,
  ];

  if (values.isEmpty) {
    return BookDeconstructionNodeStatus.pending;
  }
  if (values.any((status) => status == BookDeconstructionNodeStatus.running)) {
    return BookDeconstructionNodeStatus.running;
  }
  if (values.any((status) => status == BookDeconstructionNodeStatus.failed)) {
    return BookDeconstructionNodeStatus.failed;
  }
  if (values.length == nodeIds.length &&
      values.every((status) => status == BookDeconstructionNodeStatus.passed)) {
    return BookDeconstructionNodeStatus.passed;
  }
  if (values.length == nodeIds.length &&
      values.every(
        (status) => status == BookDeconstructionNodeStatus.skipped,
      )) {
    return BookDeconstructionNodeStatus.skipped;
  }
  return BookDeconstructionNodeStatus.pending;
}

class _BookBreakdownTargetChip extends StatelessWidget {
  const _BookBreakdownTargetChip({
    required this.icon,
    required this.label,
    required this.status,
  });

  final IconData icon;
  final String label;
  final BookDeconstructionNodeStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Container(
      width: 142,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.line),
        color: colors.card,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.muted, fontSize: 13),
            ),
          ),
          _BookBreakdownStatusIcon(
            key: ValueKey('book-target-status-$label-${status.name}'),
            status: status,
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _BookBreakdownStatusIcon extends StatelessWidget {
  const _BookBreakdownStatusIcon({
    super.key,
    required this.status,
    required this.size,
  });

  final BookDeconstructionNodeStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    return switch (status) {
      BookDeconstructionNodeStatus.running => _RunningStatusIcon(
          color: colors.text,
          size: size,
        ),
      BookDeconstructionNodeStatus.passed => Icon(
          Icons.check_circle,
          size: size,
          color: colors.text,
        ),
      BookDeconstructionNodeStatus.failed => Icon(
          Icons.error,
          size: size,
          color: errorColor,
        ),
      BookDeconstructionNodeStatus.skipped => Icon(
          Icons.remove_circle_outline,
          size: size,
          color: colors.muted,
        ),
      BookDeconstructionNodeStatus.pending => Icon(
          Icons.radio_button_unchecked,
          size: size,
          color: colors.muted,
        ),
    };
  }
}

class _RunningStatusIcon extends StatelessWidget {
  const _RunningStatusIcon({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class _BookBreakdownPipeline extends StatelessWidget {
  const _BookBreakdownPipeline({
    required this.nodeStatuses,
  });

  final Map<String, BookDeconstructionNodeStatus> nodeStatuses;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        for (var i = 0; i < _bookBreakdownPipelineSteps.length; i++) ...[
          _PipelineStep(
            icon: _bookBreakdownPipelineSteps[i].icon,
            label: _bookBreakdownPipelineSteps[i].label,
            status: _bookBreakdownStatusForNodes(
              nodeStatuses,
              _bookBreakdownPipelineSteps[i].nodeIds,
            ),
          ),
          if (i != _bookBreakdownPipelineSteps.length - 1)
            Icon(Icons.arrow_forward, size: 16, color: colors.muted),
        ],
      ],
    );
  }
}

class _PipelineStep extends StatelessWidget {
  const _PipelineStep({
    required this.icon,
    required this.label,
    required this.status,
  });

  final IconData icon;
  final String label;
  final BookDeconstructionNodeStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final running = status == BookDeconstructionNodeStatus.running;
    final failed = status == BookDeconstructionNodeStatus.failed;
    final circleColor = running ? colors.text : colors.card;
    final statusColor = failed ? errorColor : colors.muted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: ValueKey('book-pipeline-status-$label-${status.name}'),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: circleColor,
            border: Border.all(
              color: running
                  ? colors.text
                  : failed
                      ? errorColor
                      : colors.line,
            ),
          ),
          child: Center(
            child: running
                ? _RunningStatusIcon(color: colors.card, size: 18)
                : Icon(icon, size: 18, color: statusColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: running ? colors.text : statusColor,
            fontSize: 12,
            fontWeight: running ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _BookBreakdownStatsColumn extends StatelessWidget {
  const _BookBreakdownStatsColumn({this.project});

  final BookDeconstructionProject? project;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final progress = project?.progress ?? 0;

    return Column(
      children: [
        _BookBreakdownStatCard(
          title: project?.isRunning ?? false ? '当前任务' : '当前进度',
          value: '${(progress * 100).round()}%',
          icon: Icons.track_changes,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: colors.line,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 12),
        _BookBreakdownStatCard(
          title: '已拆章节',
          value: (project?.chapterCount ?? 0).toString(),
          icon: Icons.snippet_folder_outlined,
          iconColor: colors.brand,
        ),
        const SizedBox(height: 12),
        _BookBreakdownStatCard(
          title: '提取角色',
          value: (project?.characterCount ?? 0).toString(),
          icon: Icons.group_outlined,
          iconColor: colors.success,
        ),
        const SizedBox(height: 12),
        _BookBreakdownStatCard(
          title: '风格资产',
          value: (project?.styleAssetCount ?? 0).toString(),
          icon: Icons.fingerprint,
          iconColor: colors.brand,
        ),
      ],
    );
  }
}

class _BookBreakdownStatCard extends StatelessWidget {
  const _BookBreakdownStatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.child,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return _CardShell(
      minHeight: 92,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(icon, color: iconColor ?? colors.muted, size: 20),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: colors.text,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (child != null) ...[
              const SizedBox(height: 10),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

class _BookBreakdownMetricsStrip extends StatelessWidget {
  const _BookBreakdownMetricsStrip({this.project});

  final BookDeconstructionProject? project;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            final metrics = const [
              _CompactMetricData(
                icon: Icons.article_outlined,
                label: '章节文件',
              ),
              _CompactMetricData(
                icon: Icons.groups_outlined,
                label: '人物档案',
              ),
              _CompactMetricData(
                icon: Icons.checklist_rtl,
                label: '伏笔条目',
              ),
              _CompactMetricData(
                icon: Icons.fingerprint,
                label: '风格指纹',
              ),
            ];
            final widgets = [
              _CompactMetric(
                icon: metrics[0].icon,
                label: metrics[0].label,
                value: (project?.chapterCount ?? 0).toString(),
              ),
              _CompactMetric(
                icon: metrics[1].icon,
                label: metrics[1].label,
                value: (project?.characterCount ?? 0).toString(),
              ),
              _CompactMetric(
                icon: metrics[2].icon,
                label: metrics[2].label,
                value: (project?.foreshadowingCount ?? 0).toString(),
              ),
              _CompactMetric(
                icon: metrics[3].icon,
                label: metrics[3].label,
                value: (project?.styleAssetCount ?? 0).toString(),
              ),
            ];

            if (compact) {
              return Wrap(spacing: 24, runSpacing: 12, children: widgets);
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: widgets,
            );
          },
        ),
      ),
    );
  }
}

class _CompactMetricData {
  const _CompactMetricData({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: colors.muted),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: colors.muted, fontSize: 12)),
            Text(
              value,
              style: TextStyle(
                color: colors.text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

const _bookProjectTableHorizontalPadding = 28.0;
const _bookProjectTableMinWidth = 1108.0;
const _bookProjectNameMinWidth = 260.0;
const _bookProjectProgressWidth = 230.0;
const _bookProjectStatusWidth = 170.0;
const _bookProjectUpdatedWidth = 180.0;
const _bookProjectActionWidth = 150.0;
const _bookProjectMenuWidth = 44.0;

double _bookProjectNameWidth(double tableWidth) {
  const fixedWidth = _bookProjectProgressWidth +
      _bookProjectStatusWidth +
      _bookProjectUpdatedWidth +
      _bookProjectActionWidth +
      _bookProjectMenuWidth +
      (_bookProjectTableHorizontalPadding * 2);

  return math.max(_bookProjectNameMinWidth, tableWidth - fixedWidth);
}

class _BookBreakdownProjectsSection extends StatelessWidget {
  const _BookBreakdownProjectsSection({
    required this.projects,
    this.currentProject,
    this.onImportNovel,
    this.onCreateProject,
    this.onStartOrPause,
    this.onSelectProject,
    this.onOpenProjectFolder,
    this.onOpenProjectReport,
    this.onDeleteProject,
  });

  final List<BookDeconstructionProject> projects;
  final BookDeconstructionProject? currentProject;
  final VoidCallback? onImportNovel;
  final VoidCallback? onCreateProject;
  final VoidCallback? onStartOrPause;
  final ValueChanged<int>? onSelectProject;
  final ValueChanged<int>? onOpenProjectFolder;
  final ValueChanged<int>? onOpenProjectReport;
  final ValueChanged<int>? onDeleteProject;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final title = Text(
              '拆书项目',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
            );
            final actions = Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SecondaryButton(
                  icon: Icons.upload_file,
                  label: context.l10n.text('action.importNovel'),
                  onPressed: onImportNovel ?? () {},
                ),
                _PrimaryButton(
                  icon: Icons.add,
                  label: '新建拆书',
                  onPressed: onCreateProject ?? () {},
                ),
              ],
            );

            if (constraints.maxWidth < 920) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      title,
                      const Spacer(),
                      actions,
                    ],
                  ),
                  const SizedBox(height: 12),
                  _BookBreakdownMetricsStrip(project: currentProject),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 126, child: title),
                Expanded(
                  child: _BookBreakdownMetricsStrip(project: currentProject),
                ),
                const SizedBox(width: 18),
                actions,
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _CardShell(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth =
                  math.max(constraints.maxWidth, _bookProjectTableMinWidth);

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      _BookBreakdownProjectTableHeader(tableWidth: tableWidth),
                      Divider(height: 1, color: colors.line),
                      if (projects.isEmpty)
                        SizedBox(
                          height: 126,
                          child: Center(
                            child: Text(
                              '暂无拆书项目',
                              style: TextStyle(color: colors.muted),
                            ),
                          ),
                        )
                      else
                        for (final project in projects) ...[
                          _BookBreakdownProjectRow(
                            project: project,
                            isCurrent: project.id == currentProject?.id,
                            tableWidth: tableWidth,
                            onStartOrPause: onStartOrPause,
                            onSelectProject: onSelectProject,
                            onOpenProjectFolder: onOpenProjectFolder,
                            onOpenProjectReport: onOpenProjectReport,
                            onDeleteProject: onDeleteProject,
                          ),
                          if (project != projects.last)
                            Divider(height: 1, color: colors.line),
                        ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BookBreakdownProjectTableHeader extends StatelessWidget {
  const _BookBreakdownProjectTableHeader({required this.tableWidth});

  final double tableWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _bookProjectTableHorizontalPadding,
        ),
        child: Row(
          children: [
            SizedBox(
              width: _bookProjectNameWidth(tableWidth),
              child: const _TableHeaderText('项目名称'),
            ),
            const SizedBox(
              width: _bookProjectProgressWidth,
              child: _TableHeaderText('进度'),
            ),
            const SizedBox(
              width: _bookProjectStatusWidth,
              child: _TableHeaderText('状态'),
            ),
            const SizedBox(
              width: _bookProjectUpdatedWidth,
              child: _TableHeaderText('更新时间'),
            ),
            const SizedBox(
              width: _bookProjectActionWidth,
              child: _TableHeaderText('操作'),
            ),
            const SizedBox(width: _bookProjectMenuWidth),
          ],
        ),
      ),
    );
  }
}

class _BookBreakdownProjectRow extends StatelessWidget {
  const _BookBreakdownProjectRow({
    required this.project,
    required this.isCurrent,
    required this.tableWidth,
    this.onStartOrPause,
    this.onSelectProject,
    this.onOpenProjectFolder,
    this.onOpenProjectReport,
    this.onDeleteProject,
  });

  final BookDeconstructionProject project;
  final bool isCurrent;
  final double tableWidth;
  final VoidCallback? onStartOrPause;
  final ValueChanged<int>? onSelectProject;
  final ValueChanged<int>? onOpenProjectFolder;
  final ValueChanged<int>? onOpenProjectReport;
  final ValueChanged<int>? onDeleteProject;

  @override
  Widget build(BuildContext context) {
    final progress = (project.progress * 100).round();
    final action = _projectAction(project.status, isCurrent);

    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _bookProjectTableHorizontalPadding,
        ),
        child: Row(
          children: [
            SizedBox(
              width: _bookProjectNameWidth(tableWidth),
              child: Text(
                project.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppPalette.of(context).text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              width: _bookProjectProgressWidth,
              child: _BookProjectProgress(
                progress: project.progress,
                label: '$progress%',
              ),
            ),
            SizedBox(
              width: _bookProjectStatusWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _BookProjectStatusPill(status: project.status),
              ),
            ),
            SizedBox(
              width: _bookProjectUpdatedWidth,
              child: Text(
                _relativeTime(project.updatedAt),
                style: TextStyle(color: AppPalette.of(context).muted),
              ),
            ),
            SizedBox(
              width: _bookProjectActionWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _BookProjectActionButton(
                  icon: action.$2,
                  label: action.$1,
                  onPressed: () {
                    if (project.status ==
                        BookDeconstructionProjectStatus.completed) {
                      onOpenProjectReport?.call(project.id);
                    } else if (isCurrent &&
                        project.status ==
                            BookDeconstructionProjectStatus.paused) {
                      onStartOrPause?.call();
                    } else {
                      onSelectProject?.call(project.id);
                    }
                  },
                ),
              ),
            ),
            SizedBox(
              width: _bookProjectMenuWidth,
              child: _BookProjectMoreMenu(
                isCurrent: isCurrent,
                isCompleted:
                    project.status == BookDeconstructionProjectStatus.completed,
                onSelect: () => onSelectProject?.call(project.id),
                onOpenFolder: () => onOpenProjectFolder?.call(project.id),
                onOpenReport: () => onOpenProjectReport?.call(project.id),
                onDelete: () => onDeleteProject?.call(project.id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookProjectProgress extends StatelessWidget {
  const _BookProjectProgress({
    required this.progress,
    required this.label,
  });

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final value = progress.clamp(0.0, 1.0).toDouble();

    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: TextStyle(
              color: colors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          width: 148,
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: colors.line,
            color: colors.text,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

class _BookProjectMoreMenu extends StatelessWidget {
  const _BookProjectMoreMenu({
    required this.isCurrent,
    required this.isCompleted,
    required this.onSelect,
    required this.onOpenFolder,
    required this.onOpenReport,
    required this.onDelete,
  });

  final bool isCurrent;
  final bool isCompleted;
  final VoidCallback onSelect;
  final VoidCallback onOpenFolder;
  final VoidCallback onOpenReport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return PopupMenuButton<_BookProjectMenuAction>(
      tooltip: '更多',
      icon: Icon(Icons.more_horiz, color: colors.muted),
      onSelected: (action) {
        switch (action) {
          case _BookProjectMenuAction.select:
            onSelect();
          case _BookProjectMenuAction.openFolder:
            onOpenFolder();
          case _BookProjectMenuAction.openReport:
            onOpenReport();
          case _BookProjectMenuAction.delete:
            onDelete();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _BookProjectMenuAction.select,
          enabled: !isCurrent,
          child: const Text('设为当前项目'),
        ),
        const PopupMenuItem(
          value: _BookProjectMenuAction.openFolder,
          child: Text('打开项目文件夹'),
        ),
        PopupMenuItem(
          value: _BookProjectMenuAction.openReport,
          enabled: isCompleted,
          child: const Text('查看报告'),
        ),
        const PopupMenuItem(
          value: _BookProjectMenuAction.delete,
          child: Text('删除项目'),
        ),
      ],
    );
  }
}

enum _BookProjectMenuAction { select, openFolder, openReport, delete }

(String, IconData) _projectAction(
  BookDeconstructionProjectStatus status,
  bool isCurrent,
) {
  if (isCurrent) {
    return switch (status) {
      BookDeconstructionProjectStatus.completed => ('查看报告', Icons.article),
      BookDeconstructionProjectStatus.paused => ('继续拆书', Icons.play_arrow),
      BookDeconstructionProjectStatus.failed => ('查看详情', Icons.error_outline),
      _ => ('进入项目', Icons.open_in_new),
    };
  }

  return switch (status) {
    BookDeconstructionProjectStatus.completed => ('查看报告', Icons.article),
    BookDeconstructionProjectStatus.running => ('进入项目', Icons.open_in_new),
    BookDeconstructionProjectStatus.paused => ('继续拆书', Icons.play_arrow),
    BookDeconstructionProjectStatus.failed => ('查看详情', Icons.error_outline),
    BookDeconstructionProjectStatus.draft => ('进入项目', Icons.open_in_new),
  };
}

class _BookProjectStatusPill extends StatelessWidget {
  const _BookProjectStatusPill({required this.status});

  final BookDeconstructionProjectStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (label, color, background) = switch (status) {
      BookDeconstructionProjectStatus.draft => (
          '待开始',
          const Color(0xFF6B7280),
          const Color(0xFFF3F4F6),
        ),
      BookDeconstructionProjectStatus.running => (
          '进行中',
          const Color(0xFF2563EB),
          const Color(0xFFEAF2FF),
        ),
      BookDeconstructionProjectStatus.paused => (
          '排队中',
          const Color(0xFFD97706),
          const Color(0xFFFFF3DC),
        ),
      BookDeconstructionProjectStatus.completed => (
          '已完成',
          const Color(0xFF16A34A),
          const Color(0xFFE7F7ED),
        ),
      BookDeconstructionProjectStatus.failed => (
          '失败',
          Theme.of(context).colorScheme.error,
          Theme.of(context).colorScheme.errorContainer,
        ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.18) : background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BookProjectActionButton extends StatelessWidget {
  const _BookProjectActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return SizedBox(
      height: 34,
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 16),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.text,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: const Size(0, 34),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          side: BorderSide(color: colors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TableHeaderText extends StatelessWidget {
  const _TableHeaderText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Text(
      text,
      style: TextStyle(
        color: colors.muted,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PrimaryWorkCard extends StatelessWidget {
  const _PrimaryWorkCard({
    required this.state,
    required this.actions,
    required this.fillAvailableHeight,
  });

  final DashboardViewState state;
  final DashboardActions actions;
  final bool fillAvailableHeight;

  @override
  Widget build(BuildContext context) {
    final recentNovel =
        _recentNovel() ?? (state.novels.isEmpty ? null : state.novels.first);
    final colors = AppPalette.of(context);

    final content = Stack(
      fit: StackFit.expand,
      children: [
        _HeroBackground(novel: recentNovel),
        Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _StatusLabel(text: _statusText(context)),
              const SizedBox(height: 18),
              Text(
                _titleText(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                _metaText(context),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.muted,
                    ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (state.mode == DashboardMode.firstUse) ...[
                    _PrimaryButton(
                      icon: Icons.add,
                      label: context.l10n.text('action.newNovel'),
                      onPressed: actions.createNovel,
                    ),
                    _SecondaryButton(
                      icon: Icons.upload_file,
                      label: context.l10n.text('action.importNovel'),
                      onPressed: actions.importNovel,
                    ),
                  ] else if (recentNovel != null) ...[
                    _PrimaryButton(
                      icon: Icons.edit,
                      label: context.l10n.text('action.continueWriting'),
                      onPressed: () => actions.openProject(recentNovel),
                    ),
                    if (actions.editProject != null)
                      _SecondaryButton(
                        icon: Icons.more_horiz,
                        label: context.l10n.text('action.more'),
                        onPressed: () => actions.editProject!(recentNovel),
                      ),
                  ] else
                    _PrimaryButton(
                      icon: Icons.add,
                      label: context.l10n.text('action.newNovel'),
                      onPressed: actions.createNovel,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    return _CardShell(
      key: const ValueKey('dashboard-primary-work-card'),
      minHeight: fillAvailableHeight ? 420 : 290,
      child: fillAvailableHeight
          ? content
          : SizedBox(
              height: 290,
              child: content,
            ),
    );
  }

  NovelSummary? _recentNovel() {
    final recent = state.recentWriting;
    if (recent == null) {
      return null;
    }

    for (final novel in state.novels) {
      if (novel.id == recent.novelId) {
        return novel;
      }
    }
    return null;
  }

  String _statusText(BuildContext context) {
    final l10n = context.l10n;
    switch (state.mode) {
      case DashboardMode.loading:
        return l10n.text('dashboard.loading.label');
      case DashboardMode.firstUse:
        return l10n.text('dashboard.firstUse.label');
      case DashboardMode.noRecentWriting:
        return l10n.text('dashboard.selectProject.label');
      case DashboardMode.searchEmpty:
      case DashboardMode.populated:
        return l10n.text('dashboard.populated.label');
    }
  }

  String _titleText(BuildContext context) {
    final l10n = context.l10n;
    switch (state.mode) {
      case DashboardMode.loading:
        return l10n.text('dashboard.loading.title');
      case DashboardMode.firstUse:
        return l10n.text('dashboard.firstUse.title');
      case DashboardMode.noRecentWriting:
        return l10n.text('dashboard.populated.titleFallback');
      case DashboardMode.searchEmpty:
      case DashboardMode.populated:
        return state.recentWriting?.novelTitle ??
            l10n.text('dashboard.populated.titleFallback');
    }
  }

  String _metaText(BuildContext context) {
    final l10n = context.l10n;
    switch (state.mode) {
      case DashboardMode.loading:
        return l10n.text('dashboard.loading.description');
      case DashboardMode.firstUse:
        return l10n.text('dashboard.firstUse.description');
      case DashboardMode.noRecentWriting:
        return l10n.projectStats(
          state.projectCount,
          _formatWords(context, state.totalWordCount),
        );
      case DashboardMode.searchEmpty:
      case DashboardMode.populated:
        final chapterTitle = state.recentWriting?.chapterTitle;
        return l10n.projectStats(
          state.projectCount,
          _formatWords(context, state.totalWordCount),
          suffix: chapterTitle,
        );
    }
  }
}

class _StatsColumn extends StatelessWidget {
  const _StatsColumn({required this.state});

  final DashboardViewState state;

  @override
  Widget build(BuildContext context) {
    final goal = state.writingGoal;
    final colors = AppPalette.of(context);
    final l10n = context.l10n;

    return Column(
      key: const ValueKey('dashboard-stats-column'),
      children: [
        _StatCard(
          title: l10n.text('dashboard.todayGoal'),
          value: goal == null
              ? l10n.text('dashboard.goalUnset')
              : l10n.goalProgress(goal.currentWords, goal.targetWords),
          icon: Icons.track_changes,
          child: goal == null
              ? Text(
                  l10n.text('dashboard.goalEmpty'),
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 12,
                  ),
                )
              : LinearProgressIndicator(
                  value: goal.targetWords <= 0
                      ? 0.0
                      : (goal.currentWords / goal.targetWords)
                          .clamp(0.0, 1.0)
                          .toDouble(),
                  backgroundColor: colors.line,
                  color: colors.brand,
                ),
        ),
        const SizedBox(height: 14),
        _StatCard(
          title: l10n.text('dashboard.projectCount'),
          value: state.projectCount.toString(),
          icon: Icons.menu_book,
          iconColor: colors.brand,
        ),
        const SizedBox(height: 14),
        _StatCard(
          title: l10n.text('dashboard.totalWords'),
          value: _formatWords(context, state.totalWordCount),
          icon: Icons.trending_up,
          iconColor: colors.success,
        ),
      ],
    );
  }
}

class _ProjectsSection extends StatelessWidget {
  const _ProjectsSection({
    required this.state,
    required this.actions,
    required this.searchController,
    required this.onSearchChanged,
  });

  final DashboardViewState state;
  final DashboardActions actions;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final l10n = context.l10n;

    if (state.mode != DashboardMode.firstUse &&
        state.mode != DashboardMode.searchEmpty) {
      return _ProjectLibraryView(state: state, actions: actions);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final title = Text(
              l10n.text('dashboard.myNovels'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
            );

            final actionsRow = Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (state.showProjectSearch)
                  SizedBox(
                    width: compact ? constraints.maxWidth : 260,
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 18),
                        hintText: l10n.text('dashboard.searchHint'),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                _SecondaryButton(
                  icon: Icons.upload_file,
                  label: l10n.text('action.importNovel'),
                  onPressed: actions.importNovel,
                ),
                _PrimaryButton(
                  icon: Icons.add,
                  label: l10n.text('action.newNovel'),
                  onPressed: actions.createNovel,
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: 16),
                  actionsRow,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                title,
                const Spacer(),
                actionsRow,
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        if (state.mode == DashboardMode.firstUse)
          _EmptyProjects(actions: actions)
        else if (state.mode == DashboardMode.searchEmpty)
          _SearchEmpty(query: state.searchQuery)
        else
          _ProjectLibraryView(state: state, actions: actions),
      ],
    );
  }
}

// ignore: unused_element
class _ProjectGrid extends StatelessWidget {
  const _ProjectGrid({
    required this.state,
    required this.actions,
  });

  final DashboardViewState state;
  final DashboardActions actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 980
            ? 3
            : width >= 640
                ? 2
                : 1;
        final gap = 18.0;
        final tileWidth = (width - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final novel in state.visibleNovels)
              SizedBox(
                width: tileWidth,
                child: _ProjectCard(
                  novel: novel,
                  onTap: () => actions.openProject(novel),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.novel,
    required this.onTap,
  });

  final NovelSummary novel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final l10n = context.l10n;

    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 122,
              width: double.infinity,
              child: _NovelCover(novel: novel),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    novel.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    novel.summary.isEmpty
                        ? l10n.text('dashboard.noSummary')
                        : novel.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "${_formatWords(context, novel.wordCount)} · ${_novelTags(context, novel)}",
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  const _EmptyProjects({required this.actions});

  final DashboardActions actions;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final l10n = context.l10n;

    return _CardShell(
      minHeight: 190,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.library_books_outlined,
                color: colors.muted,
                size: 34,
              ),
              const SizedBox(height: 14),
              Text(
                l10n.text('dashboard.emptyTitle'),
                style: TextStyle(
                  color: colors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.text('dashboard.emptyDescription'),
                style: TextStyle(color: colors.muted),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _PrimaryButton(
                    icon: Icons.add,
                    label: l10n.text('action.newNovel'),
                    onPressed: actions.createNovel,
                  ),
                  _SecondaryButton(
                    icon: Icons.upload_file,
                    label: l10n.text('action.importNovel'),
                    onPressed: actions.importNovel,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchEmpty extends StatelessWidget {
  const _SearchEmpty({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final l10n = context.l10n;

    return _CardShell(
      minHeight: 150,
      child: Center(
        child: Text(
          l10n.searchEmpty(query.trim()),
          style: TextStyle(color: colors.muted),
        ),
      ),
    );
  }
}

enum _ProjectStatus {
  inProgress('创作中', Icons.edit_outlined),
  completed('已完本', Icons.check_circle_outline),
  abandoned('已放弃', Icons.block_outlined),
  archived('已归档', Icons.archive_outlined);

  const _ProjectStatus(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum _ProjectViewMode { grid, list }

enum _ProjectMenuAction { edit, complete, archive, abandon, restore, delete }

class _ProjectLibraryView extends StatefulWidget {
  const _ProjectLibraryView({
    required this.state,
    required this.actions,
  });

  final DashboardViewState state;
  final DashboardActions actions;

  @override
  State<_ProjectLibraryView> createState() => _ProjectLibraryViewState();
}

class _ProjectLibraryViewState extends State<_ProjectLibraryView> {
  _ProjectStatus? _selectedStatus;
  var _viewMode = _ProjectViewMode.grid;

  @override
  Widget build(BuildContext context) {
    final all = widget.state.visibleNovels;
    final novels = _selectedStatus == null
        ? all
        : all
            .where((novel) => _statusOf(novel) == _selectedStatus)
            .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProjectLibraryToolbar(
          novels: all,
          selectedStatus: _selectedStatus,
          viewMode: _viewMode,
          onStatusChanged: (status) => setState(() => _selectedStatus = status),
          onViewModeChanged: (mode) => setState(() => _viewMode = mode),
        ),
        const SizedBox(height: 18),
        if (_viewMode == _ProjectViewMode.grid)
          _ProjectLibraryGrid(novels: novels, actions: widget.actions)
        else
          _ProjectLibraryList(novels: novels, actions: widget.actions),
      ],
    );
  }
}

class _ProjectLibraryToolbar extends StatelessWidget {
  const _ProjectLibraryToolbar({
    required this.novels,
    required this.selectedStatus,
    required this.viewMode,
    required this.onStatusChanged,
    required this.onViewModeChanged,
  });

  final List<NovelSummary> novels;
  final _ProjectStatus? selectedStatus;
  final _ProjectViewMode viewMode;
  final ValueChanged<_ProjectStatus?> onStatusChanged;
  final ValueChanged<_ProjectViewMode> onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final counts = {
      for (final status in _ProjectStatus.values)
        status: novels.where((novel) => _statusOf(novel) == status).length,
    };

    return Row(
      children: [
        Text(
          '全部作品',
          style: TextStyle(color: colors.text, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatusFilterChip(
                  label: '全部 ${novels.length}',
                  selected: selectedStatus == null,
                  onTap: () => onStatusChanged(null),
                ),
                for (final status in _ProjectStatus.values) ...[
                  const SizedBox(width: 12),
                  _StatusFilterChip(
                    label: '${status.label} ${counts[status]}',
                    selected: selectedStatus == status,
                    onTap: () => onStatusChanged(status),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        _ProjectSortButton(),
        const SizedBox(width: 8),
        _ProjectViewToggle(mode: viewMode, onChanged: onViewModeChanged),
      ],
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? colors.line.withValues(alpha: 0.8)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colors.text : colors.muted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ProjectSortButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('最近编辑', style: TextStyle(color: colors.text, fontSize: 13)),
          const SizedBox(width: 6),
          Icon(Icons.expand_more, color: colors.muted, size: 16),
        ],
      ),
    );
  }
}

class _ProjectViewToggle extends StatelessWidget {
  const _ProjectViewToggle({required this.mode, required this.onChanged});

  final _ProjectViewMode mode;
  final ValueChanged<_ProjectViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    Widget item(_ProjectViewMode value, IconData icon) {
      final selected = value == mode;
      return InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: () => onChanged(value),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? colors.line.withValues(alpha: 0.9) : colors.card,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon,
              color: selected ? colors.text : colors.muted, size: 18),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          item(_ProjectViewMode.grid, Icons.grid_view_outlined),
          item(_ProjectViewMode.list, Icons.format_list_bulleted),
        ],
      ),
    );
  }
}

class _ProjectLibraryGrid extends StatelessWidget {
  const _ProjectLibraryGrid({required this.novels, required this.actions});

  final List<NovelSummary> novels;
  final DashboardActions actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1120
            ? 4
            : width >= 820
                ? 3
                : width >= 560
                    ? 2
                    : 1;
        final gap = 16.0;
        final tileWidth = (width - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final novel in novels)
              SizedBox(
                width: tileWidth,
                child: _ProjectLibraryCard(novel: novel, actions: actions),
              ),
            SizedBox(
                width: tileWidth, child: _NewProjectTile(actions: actions)),
          ],
        );
      },
    );
  }
}

class _ProjectLibraryCard extends StatefulWidget {
  const _ProjectLibraryCard({required this.novel, required this.actions});

  final NovelSummary novel;
  final DashboardActions actions;

  @override
  State<_ProjectLibraryCard> createState() => _ProjectLibraryCardState();
}

class _ProjectLibraryCardState extends State<_ProjectLibraryCard> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final novel = widget.novel;
    final status = _statusOf(novel);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => widget.actions.openProject(novel),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 218,
                    width: double.infinity,
                    child: _ProjectCover(novel: novel),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: _ProjectStatusBadge(status: status),
                  ),
                  if (_hovered)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: _ProjectMoreButton(
                        novel: novel,
                        actions: widget.actions,
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: _ProjectLibraryCardBody(novel: novel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectLibraryCardBody extends StatelessWidget {
  const _ProjectLibraryCardBody({required this.novel});

  final NovelSummary novel;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          novel.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.text,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          novel.workType.isEmpty ? '原创' : novel.workType,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: colors.muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Text(
          _relativeUpdatedAt(novel.updatedAt),
          style: TextStyle(color: colors.muted, fontSize: 12),
        ),
        if (novel.summary.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            novel.summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.muted, fontSize: 12),
          ),
        ],
        if (novel.tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in novel.tags.take(3)) _LibraryTagChip(label: tag),
            ],
          ),
        ],
      ],
    );
  }
}

class _ProjectLibraryList extends StatelessWidget {
  const _ProjectLibraryList({required this.novels, required this.actions});

  final List<NovelSummary> novels;
  final DashboardActions actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final novel in novels) ...[
          _ProjectLibraryRow(novel: novel, actions: actions),
          const SizedBox(height: 10),
        ],
        _NewProjectTile(actions: actions, list: true),
      ],
    );
  }
}

class _ProjectLibraryRow extends StatelessWidget {
  const _ProjectLibraryRow({required this.novel, required this.actions});

  final NovelSummary novel;
  final DashboardActions actions;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final status = _statusOf(novel);

    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => actions.openProject(novel),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: _ProjectCover(novel: novel),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _ProjectLibraryCardBody(novel: novel)),
              const SizedBox(width: 12),
              _ProjectStatusBadge(status: status),
              const SizedBox(width: 12),
              IconButton(
                tooltip: '编辑标签',
                onPressed: () {},
                icon: const Icon(Icons.sell_outlined, size: 18),
              ),
              _ProjectMoreButton(novel: novel, actions: actions),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectCover extends StatelessWidget {
  const _ProjectCover({required this.novel});

  final NovelSummary novel;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final coverPath = novel.coverPath;
    if (coverPath != null && coverPath.isNotEmpty) {
      final file = File(coverPath);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    return Container(
      color: colors.line.withValues(alpha: 0.45),
      alignment: Alignment.center,
      child: Icon(
        Icons.menu_book_outlined,
        color: colors.muted.withValues(alpha: 0.35),
        size: 42,
      ),
    );
  }
}

class _ProjectStatusBadge extends StatelessWidget {
  const _ProjectStatusBadge({required this.status});

  final _ProjectStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, color: colors.muted, size: 13),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: colors.text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryTagChip extends StatelessWidget {
  const _LibraryTagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.line.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: colors.text, fontSize: 12)),
    );
  }
}

class _ProjectMoreButton extends StatelessWidget {
  const _ProjectMoreButton({required this.novel, required this.actions});

  final NovelSummary novel;
  final DashboardActions actions;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final active = _statusOf(novel) == _ProjectStatus.inProgress;
    return PopupMenuButton<_ProjectMenuAction>(
      tooltip: '更多',
      color: colors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.line),
      ),
      onSelected: (action) {
        switch (action) {
          case _ProjectMenuAction.edit:
            actions.editProject?.call(novel);
          case _ProjectMenuAction.complete:
            actions.updateProjectStatus?.call(
              novel,
              _ProjectStatus.completed.label,
            );
          case _ProjectMenuAction.archive:
            actions.updateProjectStatus?.call(
              novel,
              _ProjectStatus.archived.label,
            );
          case _ProjectMenuAction.abandon:
            actions.updateProjectStatus?.call(
              novel,
              _ProjectStatus.abandoned.label,
            );
          case _ProjectMenuAction.restore:
            actions.updateProjectStatus?.call(
              novel,
              _ProjectStatus.inProgress.label,
            );
          case _ProjectMenuAction.delete:
            actions.deleteProject?.call(novel);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _ProjectMenuAction.edit,
          child: _ProjectMenuItem(icon: Icons.edit_outlined, label: '编辑'),
        ),
        if (active) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: _ProjectMenuAction.complete,
            child: _ProjectMenuItem(
              icon: Icons.check_circle_outline,
              label: '完结',
            ),
          ),
          const PopupMenuItem(
            value: _ProjectMenuAction.archive,
            child: _ProjectMenuItem(icon: Icons.archive_outlined, label: '归档'),
          ),
          const PopupMenuItem(
            value: _ProjectMenuAction.abandon,
            child: _ProjectMenuItem(icon: Icons.block_outlined, label: '废弃'),
          ),
        ] else ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: _ProjectMenuAction.restore,
            child: _ProjectMenuItem(
              icon: Icons.play_circle_outline,
              label: '恢复',
            ),
          ),
        ],
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _ProjectMenuAction.delete,
          child: _ProjectMenuItem(
            icon: Icons.delete_outline,
            label: '删除',
            destructive: true,
          ),
        ),
      ],
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(Icons.more_vert, color: colors.text, size: 18),
      ),
    );
  }
}

class _ProjectMenuItem extends StatelessWidget {
  const _ProjectMenuItem({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final color = destructive ? Colors.redAccent : colors.text;
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

class _NewProjectTile extends StatelessWidget {
  const _NewProjectTile({required this.actions, this.list = false});

  final DashboardActions actions;
  final bool list;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    return InkWell(
      onTap: actions.createNovel,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: list ? 84 : 188,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.line),
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          mainAxisAlignment:
              list ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: colors.line.withValues(alpha: 0.7),
              child: Icon(Icons.add, color: colors.text),
            ),
            const SizedBox(width: 12),
            Text(
              '新建作品',
              style: TextStyle(color: colors.text, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

_ProjectStatus _statusOf(NovelSummary novel) {
  switch (novel.status.trim()) {
    case '已完本':
    case 'completed':
      return _ProjectStatus.completed;
    case '已放弃':
    case 'abandoned':
      return _ProjectStatus.abandoned;
    case '已归档':
    case 'archived':
      return _ProjectStatus.archived;
    case '创作中':
    case 'inProgress':
    default:
      return _ProjectStatus.inProgress;
  }
}

String _relativeUpdatedAt(DateTime updatedAt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(updatedAt.year, updatedAt.month, updatedAt.day);
  final days = today.difference(day).inDays;
  if (days == 0) {
    final minute = updatedAt.minute.toString().padLeft(2, '0');
    return '今天 ${updatedAt.hour}:$minute';
  }
  if (days == 1) {
    return '昨天';
  }
  return '$days 天前';
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.child,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return _CardShell(
      minHeight: 112,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  icon,
                  color: iconColor ?? colors.muted,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              value,
              style: TextStyle(
                color: colors.text,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (child != null) ...[
              const SizedBox(height: 16),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    super.key,
    required this.child,
    this.minHeight = 0,
  });

  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _HeroBackground extends StatelessWidget {
  const _HeroBackground({required this.novel});

  final NovelSummary? novel;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        _NovelCover(novel: novel),
        Container(color: colors.heroOverlay),
      ],
    );
  }
}

class _NovelCover extends StatelessWidget {
  const _NovelCover({required this.novel});

  final NovelSummary? novel;

  @override
  Widget build(BuildContext context) {
    final coverPath = novel?.coverPath;
    if (coverPath != null && coverPath.isNotEmpty) {
      final file = File(coverPath);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF172033),
            Color(0xFFE8E9EC),
            Color(0xFFFFF1EE),
          ],
        ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return Text(
      text,
      style: TextStyle(
        color: colors.brand,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: colors.text,
        foregroundColor: colors.card,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.text,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        side: BorderSide(color: colors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

String _formatWords(BuildContext context, int words) {
  if (words < 10000) {
    return words.toString();
  }
  final value = words / 10000;
  final text = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return context.l10n.tenThousands(text);
}

List<String> _projectOverviewTags(NovelSummary novel) {
  return [
    if (novel.category.trim().isNotEmpty) novel.category.trim(),
    if (novel.workType.trim().isNotEmpty) novel.workType.trim(),
    ...novel.tags
        .where((tag) => tag.trim().isNotEmpty)
        .map((tag) => tag.trim()),
  ];
}

List<String> _projectOverviewSnippets(
  NovelSummary novel,
  NovelChapter? selectedChapter,
) {
  return [
    novel.summary.trim(),
    selectedChapter?.outline.trim() ?? '',
    selectedChapter?.content.trim() ?? '',
  ].where((text) => text.isNotEmpty).toList();
}

int _countWritingUnits(String text) {
  var count = 0;
  for (final rune in text.runes) {
    if (String.fromCharCode(rune).trim().isNotEmpty) {
      count++;
    }
  }
  return count;
}

bool _fuzzyContains(String source, String query) {
  final text = source.toLowerCase();
  final needle = query.toLowerCase();
  if (text.contains(needle)) {
    return true;
  }
  var index = 0;
  for (final rune in needle.runes) {
    final char = String.fromCharCode(rune);
    index = text.indexOf(char, index);
    if (index < 0) {
      return false;
    }
    index++;
  }
  return true;
}

String _formatClock(DateTime date) {
  final local = date.toLocal();
  return '${local.year}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String _formatShortDate(DateTime date) {
  final local = date.toLocal();
  return '${local.year}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) {
    return '刚刚';
  }
  if (diff.inHours < 1) {
    return '${diff.inMinutes}分钟前';
  }
  if (diff.inDays < 1) {
    return '${diff.inHours}小时前';
  }
  if (diff.inDays == 1) {
    return '昨天';
  }
  return '${diff.inDays}天前';
}

String _novelTags(BuildContext context, NovelSummary novel) {
  final tags = [
    if (novel.category.isNotEmpty) novel.category,
    if (novel.workType.isNotEmpty) novel.workType,
    ...novel.tags,
    if (novel.category.isEmpty &&
        novel.workType.isEmpty &&
        novel.tags.isEmpty &&
        novel.status.isNotEmpty)
      novel.status,
  ];
  return tags.isEmpty
      ? context.l10n.text('dashboard.unsetType')
      : tags.join(' · ');
}
