import 'package:ai_novel_factory/src/book_lab/book_deconstruction_workflow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('workflow exposes only top-level book deconstruction agents', () {
    expect(
      bookDeconstructionAgentIds,
      [
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
      ],
    );

    final internalNodes = bookDeconstructionWorkflowNodes
        .where((node) => node.isInternal)
        .toList();

    expect(internalNodes, isNotEmpty);
    expect(internalNodes.every((node) => !node.isUserCallableAgent), isTrue);
    expect(
      internalNodes
          .where((node) => node.agentId == 'book_style_fingerprint')
          .map((node) => node.id),
      containsAll([
        'style_chapter_statistics',
        'style_global',
        'style_character_voice',
        'style_scene_voice',
      ]),
    );
    expect(
      internalNodes
          .where((node) => node.agentId == 'book_foreshadowing_suspense')
          .map((node) => node.id),
      containsAll(['foreshadowing_initial', 'foreshadowing_review']),
    );
  });

  test('runner follows gates and dependency order', () async {
    final completed = <String>[];
    final runner = BookDeconstructionWorkflowRunner();

    final report = await runner.run(
      runAgent: (node) async {
        completed.add(node.id);
        return bookDeconstructionPass();
      },
      runInternalStep: (node) async {
        completed.add(node.id);
        return bookDeconstructionPass();
      },
      checkGate: (node) async {
        completed.add(node.id);
        return bookDeconstructionPass();
      },
    );

    expect(report.passed, isTrue);
    expect(completed.first, 'gate_0_task_initialized');
    expect(
      completed.indexOf('book_business_mechanism'),
      greaterThan(completed.indexOf('book_plot_structure')),
    );
    expect(
      completed.indexOf('style_character_voice'),
      greaterThan(completed.indexOf('book_relationships')),
    );
    expect(
      completed.indexOf('book_overview'),
      greaterThan(completed.indexOf('gate_4_multidimensional_analysis')),
    );
    expect(completed.last, 'gate_8_quality_check');
  });

  test('runner stops downstream nodes when a gate fails', () async {
    final runner = BookDeconstructionWorkflowRunner();

    final report = await runner.run(
      runAgent: (_) => bookDeconstructionPass(),
      runInternalStep: (_) => bookDeconstructionPass(),
      checkGate: (node) {
        if (node.id == 'gate_1_text_cleaned') {
          return bookDeconstructionFail('missing chapters');
        }
        return bookDeconstructionPass();
      },
    );

    expect(report.passed, isFalse);
    expect(report.failedRecord?.node.id, 'gate_1_text_cleaned');
    expect(
      report.records
          .where(
              (record) => record.status == BookDeconstructionNodeStatus.skipped)
          .map((record) => record.node.id),
      contains('book_chapter_content'),
    );
  });

  test('gate definitions keep required artifact contracts', () {
    final gates = {
      for (final node in bookDeconstructionWorkflowNodes)
        if (node.isGate) node.id: node,
    };

    expect(
      gates['gate_3_base_indexes']?.requiredArtifacts,
      containsAll([
        'analysis/indexes/entity_index.json',
        'analysis/indexes/event_index.json',
        'analysis/indexes/term_alias_map.json',
      ]),
    );
    expect(
      gates['gate_7_skill_compile']?.requiredArtifacts,
      contains('compiled_skill/book_001.skill/skill_manifest.json'),
    );
  });
}
