import 'package:flutter/foundation.dart';

@immutable
class AppAgentDefinition {
  const AppAgentDefinition({
    required this.id,
    required this.name,
    this.children = const [],
  });

  final String id;
  final String name;
  final List<AppAgentDefinition> children;
}

const defaultAgentDefinitions = [
  AppAgentDefinition(
    id: 'book_breakdown',
    name: '拆书 Agent',
    children: [
      AppAgentDefinition(id: 'book_master_control', name: '00 拆书总控 Agent'),
      AppAgentDefinition(id: 'book_text_cleaning', name: '01 文本清洗 Agent'),
      AppAgentDefinition(id: 'book_chapter_content', name: '02 章节内容 Agent'),
      AppAgentDefinition(id: 'book_overview', name: '03 全书总览 Agent'),
      AppAgentDefinition(id: 'book_plot_structure', name: '04 情节结构 Agent'),
      AppAgentDefinition(id: 'book_business_mechanism', name: '05 商业机制 Agent'),
      AppAgentDefinition(id: 'book_relationships', name: '06 人物关系 Agent'),
      AppAgentDefinition(
          id: 'book_foreshadowing_suspense', name: '07 伏笔悬念 Agent'),
      AppAgentDefinition(id: 'book_style_fingerprint', name: '08 文风指纹 Agent'),
      AppAgentDefinition(
          id: 'book_template_distillation', name: '09 模板蒸馏 Agent'),
      AppAgentDefinition(id: 'book_skill_compile', name: '10 Skill 编译 Agent'),
      AppAgentDefinition(id: 'book_quality_check', name: '11 拆书质检 Agent'),
      AppAgentDefinition(id: 'experimental_writing_agent', name: '实验性写作 Agent'),
    ],
  ),
  AppAgentDefinition(id: 'world_builder', name: '世界观构建师'),
  AppAgentDefinition(id: 'plot_architect', name: '剧情架构师'),
  AppAgentDefinition(id: 'character_designer', name: '角色设计师'),
  AppAgentDefinition(id: 'narrative_pacing', name: '叙事节奏师'),
  AppAgentDefinition(id: 'conflict_designer', name: '冲突设计师'),
  AppAgentDefinition(id: 'research_collector', name: '资料收集'),
  AppAgentDefinition(id: 'theme_guardian', name: '主题守护者'),
  AppAgentDefinition(id: 'prose_writer', name: '正文写手'),
  AppAgentDefinition(id: 'content_reviewer', name: '内容审核'),
  AppAgentDefinition(id: 'reader_simulator', name: '读者模拟'),
];

@immutable
class AppAgentSettings {
  const AppAgentSettings({
    this.modelByAgentId = const {},
  });

  final Map<String, String> modelByAgentId;

  String modelFor(String agentId) => modelByAgentId[agentId] ?? '';

  String effectiveModelFor(String agentId, {String? fallbackAgentId}) {
    final model = modelFor(agentId);
    if (model.isNotEmpty || fallbackAgentId == null) {
      return model;
    }
    return modelFor(fallbackAgentId);
  }

  AppAgentSettings setModel(String agentId, String model) {
    final next = {...modelByAgentId};
    if (model.isEmpty) {
      next.remove(agentId);
    } else {
      next[agentId] = model;
    }
    return AppAgentSettings(
      modelByAgentId: Map.unmodifiable(next),
    );
  }

  AppAgentSettings pruneUnavailableModels(List<String> availableModels) {
    final available = availableModels.toSet();
    final next = <String, String>{};
    for (final entry in modelByAgentId.entries) {
      if (available.contains(entry.value)) {
        next[entry.key] = entry.value;
      }
    }
    if (next.length == modelByAgentId.length) {
      return this;
    }
    return AppAgentSettings(modelByAgentId: Map.unmodifiable(next));
  }
}
