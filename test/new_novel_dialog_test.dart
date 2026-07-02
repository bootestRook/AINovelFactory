import 'package:ai_novel_factory/src/app/app_theme.dart';
import 'package:ai_novel_factory/src/dashboard/dashboard_models.dart';
import 'package:ai_novel_factory/src/dashboard/new_novel_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('category menu shows four rows before scrolling', (tester) async {
    await tester.pumpWidget(const _DialogHarness());

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('select-field-分类')));
    await tester.pumpAndSettle();

    final menuSize =
        tester.getSize(find.byKey(const ValueKey('select-menu-分类')));
    expect(menuSize.height, 48 * 4);
    expect(find.byKey(const ValueKey('select-scrollbar-分类')), findsOneWidget);
  });

  testWidgets('select field keeps label outside the input border',
      (tester) async {
    await tester.pumpWidget(const _DialogHarness());

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    final decorator = tester.widget<InputDecorator>(
      find.descendant(
        of: find.byKey(const ValueKey('select-field-分类')),
        matching: find.byType(InputDecorator),
      ),
    );

    expect(decorator.decoration.labelText, isNull);
    expect(find.text('分类'), findsOneWidget);
  });

  testWidgets('tags can be added and removed', (tester) async {
    await tester.pumpWidget(const _DialogHarness());

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('add-tag')));
    await tester.tap(find.byKey(const ValueKey('add-tag')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('tag-input')), 'AI');
    await tester.tap(find.byKey(const ValueKey('confirm-tag')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tag-chip-AI')), findsOneWidget);
    expect(find.byKey(const ValueKey('add-tag')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('tag-chip-AI')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byKey(const ValueKey('tag-chip-AI')),
      matching: find.byIcon(Icons.close),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tag-chip-AI')), findsNothing);
  });

  testWidgets('edit dialog starts with existing novel info', (tester) async {
    await tester.pumpWidget(const _EditDialogHarness());

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('编辑作品信息'), findsOneWidget);
    expect(find.text('Existing Book'), findsOneWidget);
    expect(find.text('Existing summary'), findsOneWidget);
    expect(find.byKey(const ValueKey('tag-chip-AI')), findsOneWidget);
  });
}

class _DialogHarness extends StatelessWidget {
  const _DialogHarness();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showNewNovelDialog(context),
                child: const Text('打开'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EditDialogHarness extends StatelessWidget {
  const _EditDialogHarness();

  @override
  Widget build(BuildContext context) {
    final novel = NovelSummary(
      id: 1,
      title: 'Existing Book',
      summary: 'Existing summary',
      status: '',
      category: 'Sci-fi',
      workType: 'Original',
      tags: const ['AI'],
      coverPath: null,
      updatedAt: DateTime(2026, 6, 29),
      wordCount: 0,
    );

    return MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showEditNovelDialog(context, novel),
                child: const Text('Edit'),
              ),
            ),
          );
        },
      ),
    );
  }
}
