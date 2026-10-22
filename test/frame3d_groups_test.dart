// Design groups in the app: the isolate runner and the group sheet.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibot/features/frame3d/frame3d_data.dart';
import 'package:sibot/features/frame3d/frame3d_groups_ui.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

void main() {
  Model3D portal({List<DesignGroup> groups = const []}) => Model3D(
    nodes: const [
      Node3D(0, 0, 0),
      Node3D(0, 0, 4),
      Node3D(6, 0, 4),
      Node3D(6, 0, 0),
    ],
    supports: const {0: Support3D.fixed, 3: Support3D.fixed},
    sections: [Section3D.rectangle(300, 300), Section3D.rectangle(300, 600)],
    elements: const [
      Element3D(0, 1, 0),
      Element3D(1, 2, 1),
      Element3D(3, 2, 0),
    ],
    cases: const [
      LoadCase3D(
        name: 'G',
        selfWeight: true,
        member: [MemberLoad3D(1, qz: -25)],
      ),
      LoadCase3D(
        name: 'Q',
        type: LoadType.imposed,
        member: [MemberLoad3D(1, qz: -10)],
      ),
    ],
    groups: groups,
  );

  test('runDesign designs the grouped members and counts the others', () {
    const beams = DesignGroup(
      id: 'b',
      name: 'Beams',
      members: [1],
      material: DesignMaterial.concrete,
      role: ConcreteRole.beam,
    );
    final r = runDesign(
      sourceKey(
        Frame3DRecord.free(
          id: 'x',
          projectId: 'p',
          name: 'n',
          model: portal(groups: const [beams]),
        ),
      ),
      DesignCode.ec2,
    );
    expect(r.error, isNull);
    expect(r.members.single.member, 1);
    expect(r.ungrouped, 2);
    expect(r.ratios(3), [null, r.members.single.ratio, null]);
  });

  testWidgets('group sheet: members by kind, material settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    DesignGroup? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showGroupSettings(
                context,
                group: const DesignGroup(
                  id: 'g',
                  name: 'Columns',
                  members: [],
                  material: DesignMaterial.concrete,
                ),
                model: portal(),
                selection: {1},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // Saving without members is refused.
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    expect(find.text('Give a name and at least one member.'), findsOneWidget);
    await tester.tap(find.text('+ Columns'));
    await tester.pump();
    expect(find.text('2 members'), findsOneWidget);
    await tester.tap(find.text('Edit selection (1)'));
    await tester.pump();
    await tester.tap(find.text('Steel'));
    await tester.pumpAndSettle();
    expect(find.text('kLT'), findsOneWidget);
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
    expect(result!.members, [0, 1, 2]);
    expect(result!.material, DesignMaterial.steel);
    expect(tester.takeException(), isNull);
  });
}
