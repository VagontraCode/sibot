// "Design in…": a model member or support sent to a calculator, with
// the link back to the model.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sibot/features/calculations/columns/presentation/columns_provider.dart';
import 'package:sibot/features/calculations/footings/presentation/footings_provider.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot/features/calculations/steel/presentation/steel_member_provider.dart';
import 'package:sibot/features/frame3d/frame3d_data.dart';
import 'package:sibot/features/frame3d/model_link.dart';
import 'package:sibot_engine/sibot_engine.dart';

void main() {
  final model = Model3D(
    nodes: const [
      Node3D(0, 0, 0),
      Node3D(0, 0, 4),
      Node3D(6, 0, 4),
      Node3D(6, 0, 0),
    ],
    supports: const {0: Support3D.fixed, 3: Support3D.fixed},
    sections: [Section3D.rectangle(300, 400), Section3D.steel('IPE 300')],
    elements: const [
      Element3D(0, 1, 0),
      Element3D(1, 2, 1),
      Element3D(3, 2, 0),
    ],
    cases: const [
      LoadCase3D(name: 'G', member: [MemberLoad3D(1, qz: -20)]),
      LoadCase3D(
        name: 'Q',
        type: LoadType.imposed,
        member: [MemberLoad3D(1, qz: -10)],
      ),
    ],
    groups: const [
      DesignGroup(
        id: 'c',
        name: 'Columns',
        members: [0, 2],
        material: DesignMaterial.concrete,
        fck: 30,
        l0Factor: 0.7,
      ),
    ],
  );
  final record = Frame3DRecord.free(
    id: 'M1',
    projectId: 'P',
    name: 'Portal',
    model: model,
  );

  test('stamps are stable and change with the model', () {
    final a = modelStamp(sourceKey(record));
    expect(modelStamp(sourceKey(record)), a);
    final edited = record.withModel(model.moveNode(1, const Node3D(0, 0, 5)));
    expect(modelStamp(sourceKey(edited)), isNot(a));
  });

  test('targets from the group, the section and the direction', () {
    final cases = Frame3DAnalysis(model).solveAll();
    final f = MemberEnvelope3D.of(model, 0, cases);
    expect(
      targetFor(model, 0, f, group: model.groups.first),
      MemberTarget.column,
    );
    final fb = MemberEnvelope3D.of(model, 1, cases);
    expect(targetFor(model, 1, fb), MemberTarget.steel);
  });

  test('support loads split permanent and variable reactions', () {
    final cases = Frame3DAnalysis(model).solveAll();
    final s = supportLoads(model, cases, 0);
    // Symmetric portal: each support carries half of the beam load.
    expect(s.g, closeTo(20 * 6 / 2, 1e-6));
    expect(s.q, closeTo(10 * 6 / 2, 1e-6));
    expect(s.mg, greaterThan(0));
  });

  testWidgets('member and support open their calculators, linked', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final cases = Frame3DAnalysis(model).solveAll();
    final uls = [cases[0].scaled(1.35).plus(cases[1].scaled(1.5))];
    late BuildContext ctx;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) {
            ctx = context;
            return const SizedBox();
          },
        ),
        GoRoute(
          path: '/projects/:pid/:module',
          builder: (_, s) => Text(s.pathParameters['module']!),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    designMemberIn(ctx, record: record, model: model, member: 0, results: uls);
    await tester.pumpAndSettle();
    expect(find.text('column'), findsOneWidget);
    final col = container.read(columnStateProvider('P'));
    expect(col.link!.member, 0);
    expect(col.link!.stamp, modelStamp(sourceKey(record)));
    expect(col['fck'], 30);
    expect(col['l0'], closeTo(4 * 0.7, 0.01));
    expect(col['nEd'], greaterThan(0));
    expect(flatMetadata(col, const {})['link_model'], 'M1');

    router.go('/');
    await tester.pumpAndSettle();
    designMemberIn(ctx, record: record, model: model, member: 1, results: uls);
    await tester.pumpAndSettle();
    expect(find.text('steel-member'), findsOneWidget);
    final st = container.read(steelMemberStateProvider('P'));
    expect(st.options['profile'], 'IPE 300');
    expect(st.options['series'], 'IPE');
    expect(st['myEd'], greaterThan(0));

    router.go('/');
    await tester.pumpAndSettle();
    designSupportIn(
      ctx,
      record: record,
      model: model,
      node: 3,
      caseResults: cases,
    );
    await tester.pumpAndSettle();
    expect(find.text('footing'), findsOneWidget);
    final ft = container.read(footingStateProvider('P'));
    expect(ft.link!.node, 3);
    expect(ft['a'], 300);
    expect(ft['g'], closeTo(60, 0.1));
    expect(ft.options['type'], 'isolated');
  });
}
