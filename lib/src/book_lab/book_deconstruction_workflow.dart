import 'dart:async';

enum BookDeconstructionNodeKind {
  gate,
  agent,
  internal,
}

enum BookDeconstructionNodeStatus {
  pending,
  running,
  passed,
  failed,
  skipped,
}

class BookDeconstructionNode {
  const BookDeconstructionNode({
    required this.id,
    required this.name,
    required this.kind,
    this.agentId,
    this.dependsOn = const [],
    this.requiredArtifacts = const [],
  });

  final String id;
  final String name;
  final BookDeconstructionNodeKind kind;
  final String? agentId;
  final List<String> dependsOn;
  final List<String> requiredArtifacts;

  bool get isGate => kind == BookDeconstructionNodeKind.gate;
  bool get isInternal => kind == BookDeconstructionNodeKind.internal;
  bool get isUserCallableAgent => kind == BookDeconstructionNodeKind.agent;
}

class BookDeconstructionNodeResult {
  const BookDeconstructionNodeResult.pass([this.message = '']) : passed = true;
  const BookDeconstructionNodeResult.fail(this.message) : passed = false;

  final String message;
  final bool passed;
}

BookDeconstructionNodeResult bookDeconstructionPass([String message = '']) =>
    BookDeconstructionNodeResult.pass(message);

BookDeconstructionNodeResult bookDeconstructionFail(String message) =>
    BookDeconstructionNodeResult.fail(message);

typedef BookDeconstructionNodeRunner = FutureOr<BookDeconstructionNodeResult>
    Function(BookDeconstructionNode node);

class BookDeconstructionRunRecord {
  const BookDeconstructionRunRecord({
    required this.node,
    required this.status,
    this.message = '',
  });

  final BookDeconstructionNode node;
  final BookDeconstructionNodeStatus status;
  final String message;
}

class BookDeconstructionRunReport {
  const BookDeconstructionRunReport(this.records);

  final List<BookDeconstructionRunRecord> records;

  bool get passed => records
      .every((record) => record.status != BookDeconstructionNodeStatus.failed);

  BookDeconstructionRunRecord? get failedRecord {
    for (final record in records) {
      if (record.status == BookDeconstructionNodeStatus.failed) {
        return record;
      }
    }
    return null;
  }

  List<String> get completedNodeIds => [
        for (final record in records)
          if (record.status == BookDeconstructionNodeStatus.passed)
            record.node.id,
      ];
}

class BookDeconstructionWorkflowRunner {
  const BookDeconstructionWorkflowRunner({
    this.nodes = bookDeconstructionWorkflowNodes,
  });

  final List<BookDeconstructionNode> nodes;

  Future<BookDeconstructionRunReport> run({
    required BookDeconstructionNodeRunner runAgent,
    required BookDeconstructionNodeRunner runInternalStep,
    required BookDeconstructionNodeRunner checkGate,
    Set<String> alreadyPassedNodeIds = const {},
  }) async {
    final byId = {for (final node in nodes) node.id: node};
    final pending = <String>{for (final node in nodes) node.id}
      ..removeAll(alreadyPassedNodeIds);
    final passed = {...alreadyPassedNodeIds};
    final records = <BookDeconstructionRunRecord>[
      for (final id in alreadyPassedNodeIds)
        if (byId[id] != null)
          BookDeconstructionRunRecord(
            node: byId[id]!,
            status: BookDeconstructionNodeStatus.passed,
          ),
    ];

    while (pending.isNotEmpty) {
      final ready = pending
          .map((id) => byId[id]!)
          .where((node) => node.dependsOn.every(passed.contains))
          .toList();
      if (ready.isEmpty) {
        records.add(
          BookDeconstructionRunRecord(
            node: pending.map((id) => byId[id]!).first,
            status: BookDeconstructionNodeStatus.failed,
            message: 'Workflow dependency cycle or missing prerequisite.',
          ),
        );
        break;
      }

      final results = await Future.wait([
        for (final node in ready)
          _runNode(node, runAgent, runInternalStep, checkGate),
      ]);

      for (final record in results) {
        records.add(record);
        pending.remove(record.node.id);
        if (record.status == BookDeconstructionNodeStatus.passed) {
          passed.add(record.node.id);
        }
      }

      if (results.any(
        (record) => record.status == BookDeconstructionNodeStatus.failed,
      )) {
        for (final id in pending) {
          records.add(
            BookDeconstructionRunRecord(
              node: byId[id]!,
              status: BookDeconstructionNodeStatus.skipped,
              message: 'Skipped because an upstream node failed.',
            ),
          );
        }
        break;
      }
    }

    return BookDeconstructionRunReport(records);
  }

  Future<BookDeconstructionRunRecord> _runNode(
    BookDeconstructionNode node,
    BookDeconstructionNodeRunner runAgent,
    BookDeconstructionNodeRunner runInternalStep,
    BookDeconstructionNodeRunner checkGate,
  ) async {
    final result = await switch (node.kind) {
      BookDeconstructionNodeKind.agent => runAgent(node),
      BookDeconstructionNodeKind.internal => runInternalStep(node),
      BookDeconstructionNodeKind.gate => checkGate(node),
    };

    return BookDeconstructionRunRecord(
      node: node,
      status: result.passed
          ? BookDeconstructionNodeStatus.passed
          : BookDeconstructionNodeStatus.failed,
      message: result.message,
    );
  }
}

const bookDeconstructionAgentIds = [
  'book_master_control',
  'book_text_cleaning',
  'book_chapter_content',
  'book_overview',
  'book_plot_structure',
  'book_business_mechanism',
  'book_relationships',
  'book_foreshadowing_suspense',
  'book_style_fingerprint',
  'book_template_distillation',
  'book_skill_compile',
  'book_quality_check',
];

const bookDeconstructionWorkflowNodes = [
  BookDeconstructionNode(
    id: 'gate_0_task_initialized',
    name: 'Gate 0: task initialized',
    kind: BookDeconstructionNodeKind.gate,
    requiredArtifacts: [
      'meta/book_info.json',
      'source/raw.txt',
    ],
  ),
  BookDeconstructionNode(
    id: 'book_master_control',
    name: '00 拆书总控 Agent',
    kind: BookDeconstructionNodeKind.agent,
    agentId: 'book_master_control',
    dependsOn: ['gate_0_task_initialized'],
  ),
  BookDeconstructionNode(
    id: 'book_text_cleaning',
    name: '01 文本清洗 Agent',
    kind: BookDeconstructionNodeKind.agent,
    agentId: 'book_text_cleaning',
    dependsOn: ['book_master_control'],
  ),
  BookDeconstructionNode(
    id: 'gate_1_text_cleaned',
    name: 'Gate 1: text cleaning passed',
    kind: BookDeconstructionNodeKind.gate,
    dependsOn: ['book_text_cleaning'],
    requiredArtifacts: [
      'source/cleaned.txt',
      'source/chapters/index.json',
      'source/chapters/ch001.txt',
      'meta/source_manifest.json',
    ],
  ),
  BookDeconstructionNode(
    id: 'book_chapter_content',
    name: '02 章节内容 Agent',
    kind: BookDeconstructionNodeKind.agent,
    agentId: 'book_chapter_content',
    dependsOn: ['gate_1_text_cleaned'],
  ),
  BookDeconstructionNode(
    id: 'style_chapter_statistics',
    name: '08 文风指纹 Agent: 章节统计',
    kind: BookDeconstructionNodeKind.internal,
    agentId: 'book_style_fingerprint',
    dependsOn: ['gate_1_text_cleaned'],
  ),
  BookDeconstructionNode(
    id: 'gate_2_chapter_content',
    name: 'Gate 2: chapter content passed',
    kind: BookDeconstructionNodeKind.gate,
    dependsOn: ['book_chapter_content'],
    requiredArtifacts: [
      'analysis/chapters/index.md',
      'analysis/chapters/index.json',
      'analysis/chapters/ch001.md',
      'analysis/chapters/ch001.json',
    ],
  ),
  BookDeconstructionNode(
    id: 'base_index_normalization',
    name: '基础索引归一化 / 实体对齐',
    kind: BookDeconstructionNodeKind.internal,
    dependsOn: ['gate_2_chapter_content', 'style_chapter_statistics'],
  ),
  BookDeconstructionNode(
    id: 'gate_3_base_indexes',
    name: 'Gate 3: base indexes passed',
    kind: BookDeconstructionNodeKind.gate,
    dependsOn: ['base_index_normalization'],
    requiredArtifacts: [
      'analysis/indexes/entity_index.json',
      'analysis/indexes/event_index.json',
      'analysis/indexes/location_index.json',
      'analysis/indexes/organization_index.json',
      'analysis/indexes/item_index.json',
      'analysis/indexes/term_alias_map.json',
    ],
  ),
  BookDeconstructionNode(
    id: 'book_plot_structure',
    name: '04 情节结构 Agent',
    kind: BookDeconstructionNodeKind.agent,
    agentId: 'book_plot_structure',
    dependsOn: ['gate_3_base_indexes'],
  ),
  BookDeconstructionNode(
    id: 'book_relationships',
    name: '06 人物关系 Agent',
    kind: BookDeconstructionNodeKind.agent,
    agentId: 'book_relationships',
    dependsOn: ['gate_3_base_indexes'],
  ),
  BookDeconstructionNode(
    id: 'foreshadowing_initial',
    name: '07 伏笔悬念 Agent: 初拆',
    kind: BookDeconstructionNodeKind.internal,
    agentId: 'book_foreshadowing_suspense',
    dependsOn: ['gate_3_base_indexes'],
  ),
  BookDeconstructionNode(
    id: 'style_global',
    name: '08 文风指纹 Agent: 全局文风',
    kind: BookDeconstructionNodeKind.internal,
    agentId: 'book_style_fingerprint',
    dependsOn: ['gate_3_base_indexes'],
  ),
  BookDeconstructionNode(
    id: 'book_business_mechanism',
    name: '05 商业机制 Agent',
    kind: BookDeconstructionNodeKind.agent,
    agentId: 'book_business_mechanism',
    dependsOn: ['book_plot_structure'],
  ),
  BookDeconstructionNode(
    id: 'style_character_voice',
    name: '08 文风指纹 Agent: 角色声纹',
    kind: BookDeconstructionNodeKind.internal,
    agentId: 'book_style_fingerprint',
    dependsOn: ['book_relationships'],
  ),
  BookDeconstructionNode(
    id: 'style_scene_voice',
    name: '08 文风指纹 Agent: 场景声纹',
    kind: BookDeconstructionNodeKind.internal,
    agentId: 'book_style_fingerprint',
    dependsOn: ['book_plot_structure', 'style_chapter_statistics'],
  ),
  BookDeconstructionNode(
    id: 'foreshadowing_review',
    name: '07 伏笔悬念 Agent: 复核',
    kind: BookDeconstructionNodeKind.internal,
    agentId: 'book_foreshadowing_suspense',
    dependsOn: ['book_plot_structure', 'book_relationships'],
  ),
  BookDeconstructionNode(
    id: 'gate_4_multidimensional_analysis',
    name: 'Gate 4: multidimensional analysis passed',
    kind: BookDeconstructionNodeKind.gate,
    dependsOn: [
      'book_business_mechanism',
      'style_character_voice',
      'style_scene_voice',
      'foreshadowing_review',
      'style_global',
    ],
    requiredArtifacts: [
      'analysis/plot/global_plot_arc.json',
      'analysis/plot/chapter_function_map.json',
      'analysis/commercial/commercial_mechanics.json',
      'analysis/characters/index.json',
      'analysis/characters/character_network.json',
      'analysis/foreshadowing/foreshadow_map.json',
      'analysis/style/style_fingerprint_global.json',
      'analysis/style/style_guide.md',
    ],
  ),
  BookDeconstructionNode(
    id: 'book_overview',
    name: '03 全书总览 Agent: 最终版',
    kind: BookDeconstructionNodeKind.agent,
    agentId: 'book_overview',
    dependsOn: ['gate_4_multidimensional_analysis'],
  ),
  BookDeconstructionNode(
    id: 'gate_5_book_overview',
    name: 'Gate 5: book overview passed',
    kind: BookDeconstructionNodeKind.gate,
    dependsOn: ['book_overview'],
    requiredArtifacts: [
      'analysis/overview/book_overview.md',
      'analysis/overview/book_overview.json',
    ],
  ),
  BookDeconstructionNode(
    id: 'book_template_distillation',
    name: '09 模板蒸馏 Agent',
    kind: BookDeconstructionNodeKind.agent,
    agentId: 'book_template_distillation',
    dependsOn: ['gate_5_book_overview'],
  ),
  BookDeconstructionNode(
    id: 'gate_6_template_distillation',
    name: 'Gate 6: template distillation passed',
    kind: BookDeconstructionNodeKind.gate,
    dependsOn: ['book_template_distillation'],
    requiredArtifacts: [
      'analysis/templates/transfer_templates.md',
      'analysis/templates/transfer_templates.json',
      'analysis/templates/chapter_templates.json',
      'analysis/templates/dialogue_templates.json',
      'analysis/templates/hook_templates.json',
    ],
  ),
  BookDeconstructionNode(
    id: 'book_skill_compile',
    name: '10 Skill 编译 Agent',
    kind: BookDeconstructionNodeKind.agent,
    agentId: 'book_skill_compile',
    dependsOn: ['gate_6_template_distillation'],
  ),
  BookDeconstructionNode(
    id: 'gate_7_skill_compile',
    name: 'Gate 7: skill compile passed',
    kind: BookDeconstructionNodeKind.gate,
    dependsOn: ['book_skill_compile'],
    requiredArtifacts: [
      'compiled_skill/book_001.skill/skill_manifest.json',
      'compiled_skill/book_001.skill/README.md',
      'compiled_skill/book_001.skill/style_guide.md',
      'compiled_skill/book_001.skill/structure_patterns.md',
      'compiled_skill/book_001.skill/commercial_patterns.md',
      'compiled_skill/book_001.skill/character_patterns.md',
      'compiled_skill/book_001.skill/foreshadow_patterns.md',
      'compiled_skill/book_001.skill/chapter_rhythm.json',
      'compiled_skill/book_001.skill/character_voice_patterns.json',
      'compiled_skill/book_001.skill/scene_style_patterns.json',
      'compiled_skill/book_001.skill/writing_constraints.json',
      'compiled_skill/book_001.skill/forbidden_copy_rules.md',
      'compiled_skill/book_001.skill/usage_examples.md',
    ],
  ),
  BookDeconstructionNode(
    id: 'book_quality_check',
    name: '11 拆书质检 Agent',
    kind: BookDeconstructionNodeKind.agent,
    agentId: 'book_quality_check',
    dependsOn: ['gate_7_skill_compile'],
  ),
  BookDeconstructionNode(
    id: 'gate_8_quality_check',
    name: 'Gate 8: quality check passed',
    kind: BookDeconstructionNodeKind.gate,
    dependsOn: ['book_quality_check'],
    requiredArtifacts: [
      'analysis/qa/analysis_quality_report.md',
      'analysis/qa/analysis_quality_report.json',
      'meta/quality_report.json',
    ],
  ),
];
