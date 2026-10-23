// Result tables page: tables for combinations and load cases.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibot/features/frame3d/frame3d_data.dart';
import 'package:sibot/features/frame3d/frame3d_tables.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

void main() {
  testWidgets('reactions, displacements and member forces', (tester) async {
    final record = Frame3DRecord.free(
      id: 'T',
      projectId: 'P',
      name: 'Column',
      model: Model3D(
        nodes: const [Node3D(0, 0, 0), Node3D(0, 0, 3)],
        supports: const {0: Support3D.fixed},
        sections: [Section3D.rectangle(300, 300)],
        elements: const [Element3D(0, 1, 0)],
        cases: const [
          LoadCase3D(name: 'G', nodal: [NodalLoad3D(1, fz: -120)]),
        ],
      ),
    );
    final out = runFrame3d(sourceKey(record), DesignCode.ec2);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Frame3DTablesPage(modelName: 'Column', out: out),
      ),
    );
    // First combination: ULS 1.35 G → Rz = 162.
    expect(find.text('162.00'), findsOneWidget);
    await tester.tap(find.text('Member forces'));
    await tester.pumpAndSettle();
    expect(find.text('1 (1-2)'), findsOneWidget);
    expect(find.text('-162.00'), findsWidgets);
    await tester.tap(find.text('Displacements'));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
