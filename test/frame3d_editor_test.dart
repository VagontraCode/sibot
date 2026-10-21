import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibot/config/theme.dart';
import 'package:sibot/features/frame3d/frame3d_data.dart';
import 'package:sibot/features/frame3d/frame3d_editor.dart';
import 'package:sibot/features/frame3d/frame3d_view.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot_engine/sibot_engine.dart';

void main() {
  Frame3DRecord record() => Frame3DRecord(
    id: 'F',
    projectId: 'P',
    name: 'Test',
    updatedAt: DateTime(2026),
    params: BuildingParams(
      spansX: const [5, 5],
      spansY: const [4],
      storeyHeights: const [3],
      column: Section3D.rectangle(300, 300),
      beam: Section3D.rectangle(250, 500),
    ),
  );

  test('editing keeps masses while nodes are unchanged, then drops them', () {
    final saved = <Frame3DRecord>[];
    final c = Frame3DEditController(record(), save: (r) async => saved.add(r));
    final beam = c.model.elements.indexWhere((e) => e.section == 1);
    c.apply(c.model.setMemberLoad(1, MemberLoad3D(beam, qz: -20)));
    expect(c.record.custom, isNotNull);
    expect(c.record.masses, hasLength(c.model.nodes.length));
    // Rigid floors follow the levels.
    expect(c.model.diaphragms, hasLength(1));

    final (m, _) = c.model.addNode(const Node3D(15, 0, 3));
    c.apply(m);
    expect(c.record.masses, isNull);
    expect(saved, hasLength(2));

    c.undo();
    expect(c.model.nodes, hasLength(m.nodes.length - 1));
  });

  test('connect tool joins successive nodes', () {
    final c = Frame3DEditController(record(), save: (_) async {});
    final before = c.model.elements.length;
    c.setConnecting(true);
    // Ground node 0 to the top node of the opposite corner: a brace.
    final top = c.model.nodeAt(10, 4, 3);
    c.pick(const NodePick(0));
    c.pick(NodePick(top));
    expect(c.model.elements, hasLength(before + 1));
    expect(c.connectFrom, top);
  });

  testWidgets('member card edits the section and deletes the member', (
    tester,
  ) async {
    final c = Frame3DEditController(record(), save: (_) async {});
    c.pick(const MemberPick(0));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListenableBuilder(
            listenable: c,
            builder: (_, _) =>
                SingleChildScrollView(child: Frame3DEditPanel(c: c)),
          ),
        ),
      ),
    );
    expect(find.text('Member 1'), findsOneWidget);
    final count = c.model.elements.length;
    await tester.ensureVisible(find.text('Delete member'));
    await tester.tap(find.text('Delete member'));
    await tester.pumpAndSettle();
    expect(c.model.elements, hasLength(count - 1));
    expect(find.text('Member 1'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
