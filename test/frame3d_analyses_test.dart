// User combinations and analyses of 3D models: runners and editors.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibot/features/frame3d/frame3d_analyses_ui.dart';
import 'package:sibot/features/frame3d/frame3d_data.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

Finder _field(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is NumberField && w.label == label),
  matching: find.byType(TextField),
);

void main() {
  Frame3DRecord portal({List<Combination>? combos}) => Frame3DRecord.free(
    id: 'P',
    projectId: 'X',
    name: 'Portal',
    model: Model3D(
      nodes: const [
        Node3D(0, 0, 0),
        Node3D(0, 0, 4),
        Node3D(6, 0, 4),
        Node3D(6, 0, 0),
      ],
      supports: const {0: Support3D.fixed, 3: Support3D.fixed},
      sections: [Section3D.rectangle(300, 400), Section3D.rectangle(300, 600)],
      elements: const [
        Element3D(0, 1, 0),
        Element3D(1, 2, 1),
        Element3D(3, 2, 0),
      ],
      cases: const [
        LoadCase3D(name: 'G', member: [MemberLoad3D(1, qz: -20)]),
        LoadCase3D(
          name: 'W',
          type: LoadType.wind,
          nodal: [NodalLoad3D(1, fx: 10)],
        ),
      ],
      combinations: combos,
    ),
  );

  test('static run uses the user combinations', () {
    final own = runFrame3d(
      sourceKey(
        portal(
          combos: const [
            Combination('2 G', CombinationKind.uls, {0: 2}),
            Combination('G − W', CombinationKind.uls, {0: 1, 1: -1}),
          ],
        ),
      ),
      DesignCode.ec2,
    );
    expect(own.combinations.map((c) => c.name), ['2 G', 'G − W']);
    final ry = own.results[0].reactions.values.fold<double>(
      0,
      (s, r) => s + r[2],
    );
    expect(ry, closeTo(2 * 20 * 6, 1e-6));
    final rx = own.results[1].reactions.values.fold<double>(
      0,
      (s, r) => s + r[0],
    );
    expect(rx, closeTo(10, 1e-6));
    // Without a list, the generated ones.
    final gen = runFrame3d(sourceKey(portal()), DesignCode.ec2);
    expect(gen.combinations.first.name, startsWith('ULS'));
  });

  test('buckling on a chosen combination, modes as asked', () {
    final key = sourceKey(
      portal(
        combos: const [
          Combination('G', CombinationKind.uls, {0: 1}),
          Combination('3 G', CombinationKind.uls, {0: 3}),
        ],
      ),
    );
    final b1 = runBuckling(key, DesignCode.ec2, 0).alpha!;
    final b3 = runBuckling(key, DesignCode.ec2, 1).alpha!;
    expect(b1 / b3, closeTo(3, 1e-6));
    expect(runBuckling(key, DesignCode.ec2, 9).alpha, isNull);
    expect(runModal(key, 2).modes, hasLength(2));
  });

  test('analyses survive storage', () {
    final r = portal().withAnalyses(const [
      AnalysisSpec(id: 's', kind: AnalysisKind.spectrum, agR: 2.2),
    ]);
    final back = Frame3DRecord.fromStored(r.toStored())!;
    expect(back.analyses.single.agR, 2.2);
    expect(portal().analyses, defaultAnalyses);
  });

  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  testWidgets('combination editor validates and returns the factors', (
    tester,
  ) async {
    Combination? result;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showCombinationEditor(
              context,
              cases: const ['G', 'Q', 'W'],
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    expect(find.text('Give a name and at least one factor.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'ELU vent');
    await tester.enterText(_field('G'), '1');
    await tester.enterText(_field('W'), '1.5');
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    expect(result!.name, 'ELU vent');
    expect(result!.factors, {0: 1.0, 2: 1.5});
    expect(find.byType(BottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('spectrum settings: zone, direction and modes', (tester) async {
    // A tall surface shows the whole sheet.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    AnalysisSpec? result;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showAnalysisSettings(
              context,
              spec: const AnalysisSpec(id: 's', kind: AnalysisKind.spectrum),
              combinations: const [],
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Number of modes'), '20');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Y'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(FilledButton).last);
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    expect(result!.modes, 20);
    expect(result!.direction, 1);
    expect(tester.takeException(), isNull);
  });
}
