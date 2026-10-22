import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibot/features/frame3d/frame3d_data.dart';
import 'package:sibot/features/frame3d/frame3d_editor.dart';
import 'package:sibot/features/frame3d/frame3d_view.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// The text field of the [NumberField] labelled [label].
Finder _field(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is NumberField && w.label == label),
  matching: find.byType(TextField),
);

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

  Frame3DRecord free({bool plane = false}) => Frame3DRecord.free(
    id: 'FREE',
    projectId: 'P',
    name: 'Free',
    model: Model3D.empty(plane: plane),
  );

  Widget host(Frame3DEditController c) => MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ListenableBuilder(
        listenable: c,
        builder: (_, _) => SingleChildScrollView(child: Frame3DEditPanel(c: c)),
      ),
    ),
  );

  test('draw tool: taps on the plane chain nodes and members', () async {
    final c = Frame3DEditController(free(), save: (_) async {});
    expect(c.record.free, isTrue);
    c.setTool(EditTool.draw);
    await c.planeTap(const Node3D(0, 0, 0));
    await c.planeTap(const Node3D(0, 0, 3));
    await c.planeTap(const Node3D(5, 0, 3));
    expect(c.model.nodes, hasLength(3));
    expect(c.model.elements, hasLength(2));
    // Tapping an existing node continues the line to it.
    c.pick(const NodePick(0));
    await Future<void>.delayed(Duration.zero);
    expect(c.model.elements, hasLength(3));
    c.endLine();
    expect(c.connectFrom, isNull);
    await c.planeTap(const Node3D(9, 0, 0));
    expect(c.model.elements, hasLength(3));
    // Regenerating a free model keeps it.
    await c.regenerate();
    expect(c.model.nodes, hasLength(4));
  });

  test('plane models keep nodes in the X–Z plane', () async {
    final c = Frame3DEditController(free(plane: true), save: (_) async {});
    expect(c.plane.axis, PlaneAxis.y);
    c.setPlane(const WorkPlane(PlaneAxis.z, 3));
    expect(c.plane.axis, PlaneAxis.y);
    c.setTool(EditTool.draw);
    await c.planeTap(const Node3D(1, 4, 2));
    expect(c.model.nodes.single.y, 0);
  });

  test('working plane snapping and extent', () {
    const w = WorkPlane(PlaneAxis.z, 3, step: 0.5);
    final p = w.snap(const Node3D(1.26, -0.74, 9));
    expect((p.x, p.y, p.z), (1.5, -0.5, 3.0));
    final (u0, u1, v0, v1) = w.extent(Model3D.empty());
    expect((u0, u1, v0, v1), (0.0, 10.0, 0.0, 10.0));
  });

  test('multi-selection: copy, releases, support, delete', () async {
    final c = Frame3DEditController(record(), save: (_) async {});
    c.setTool(EditTool.multi);
    c.selectKind(MemberKind.column);
    final columns = c.members.length;
    expect(columns, greaterThan(0));
    await c.setSelectionReleases(Element3D.pinnedEnds);
    expect(c.model.elements[c.members.first].releases, Element3D.pinnedEnds);
    final before = c.model.elements.length;
    await c.copySelection(0, 10, 0, 1);
    expect(c.model.elements.length, before + columns);
    // The copies are now the selection.
    expect(c.members, hasLength(columns));
    c.clearSelection();
    c.selectLevel(0);
    await c.setSelectionSupport(Support3D.pinned);
    for (final n in c.model.nodesAtLevel(0)) {
      expect(c.model.supports[n]?.rx, isFalse);
    }
    c.clearSelection();
    c.pick(const MemberPick(0));
    await c.deleteSelection();
    expect(c.model.elements.length, before + columns - 1);
  });

  test('rigid floors can be switched on a free model', () async {
    final c = Frame3DEditController(free(), save: (_) async {});
    c.setTool(EditTool.draw);
    for (final p in const [
      Node3D(0, 0, 0),
      Node3D(0, 0, 3),
      Node3D(4, 0, 3),
      Node3D(4, 0, 0),
    ]) {
      await c.planeTap(p);
    }
    await c.setRigidFloors(true);
    expect(c.record.params.rigidFloors, isTrue);
    expect(c.model.diaphragms, hasLength(1));
    await c.setRigidFloors(false);
    expect(c.model.diaphragms, isEmpty);
  });

  testWidgets('member card: releases and a partial load', (tester) async {
    final c = Frame3DEditController(record(), save: (_) async {});
    c.pick(const MemberPick(0));
    await tester.pumpWidget(host(c));
    await tester.ensureVisible(find.text('Pinned both ends'));
    await tester.tap(find.text('Pinned both ends'));
    await tester.pumpAndSettle();
    expect(c.model.elements[0].releases, Element3D.pinnedEnds);
    // w1 = −10 from 1 m, w2 = −20.
    final fields = find.byType(TextField);
    Future<void> enter(String label, String v) async {
      final f = _field(label);
      await tester.ensureVisible(f.first);
      await tester.enterText(f.first, v);
    }

    expect(fields, findsWidgets);
    await enter('w1', '-10');
    await enter('w2', '-20');
    await enter('From a', '1');
    await tester.ensureVisible(find.text('Apply load').last);
    await tester.tap(find.text('Apply load').last);
    await tester.pumpAndSettle();
    final q = c.memberLoad(0)!;
    expect(q.qz, -10);
    expect(q.q2[2], -20);
    expect(q.start, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('node card: support restraints and springs', (tester) async {
    final c = Frame3DEditController(free(), save: (_) async {});
    c.setTool(EditTool.draw);
    await c.planeTap(const Node3D(0, 0, 0));
    c.setTool(EditTool.select);
    c.pick(const NodePick(0));
    await tester.pumpWidget(host(c));
    await tester.ensureVisible(find.text('uz'));
    await tester.tap(find.text('uz'));
    await tester.pump();
    await tester.tap(find.text('Springs'));
    await tester.pump();
    final kx = _field('kux');
    await tester.ensureVisible(kx);
    await tester.enterText(kx, '2000');
    await tester.ensureVisible(find.text('Apply the support'));
    await tester.tap(find.text('Apply the support'));
    await tester.pumpAndSettle();
    final s = c.model.supports[0]!;
    expect(s.uz, isTrue);
    expect(s.ux, isFalse);
    expect(s.springs[0], 2000);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bulk card copies the selection', (tester) async {
    final c = Frame3DEditController(record(), save: (_) async {});
    c.setTool(EditTool.multi);
    c.selectKind(MemberKind.beam);
    final beams = c.members.length;
    await tester.pumpWidget(host(c));
    final dz = _field('Δz');
    await tester.ensureVisible(dz);
    await tester.enterText(dz, '3');
    final before = c.model.elements.length;
    await tester.ensureVisible(find.text('Copy'));
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(c.model.elements.length, before + beams);
    expect(tester.takeException(), isNull);
  });
}
