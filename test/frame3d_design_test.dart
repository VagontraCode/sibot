import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibot/config/theme.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/frame3d/frame3d_design.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot_engine/sibot_engine.dart';

void main() {
  BuildingParams params(bool steel) => BuildingParams(
    spansX: const [5, 5],
    spansY: const [4.5],
    storeyHeights: const [3.5, 3],
    column: steel ? Section3D.steel('HEB 240') : Section3D.rectangle(350, 350),
    beam: steel ? Section3D.steel('IPE 300') : Section3D.rectangle(250, 500),
  );

  for (final steel in [false, true]) {
    final model = buildingFrame(params(steel));
    final an = Frame3DAnalysis(model);
    final g = an.solveCase(0), q = an.solveCase(1);
    final uls = g.scaled(1.35).plus(q.scaled(1.5));
    // Element 0 is a ground-floor column; the first beam follows the
    // storey's columns.
    final beam = model.elements.indexWhere((e) => e.section == 1);
    for (final index in [0, beam]) {
      testWidgets(
        '${steel ? 'steel' : 'concrete'} member $index design sheet',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: FilledButton(
                      onPressed: () => showMember3DDesign(
                        context,
                        model: model,
                        index: index,
                        results: [uls],
                      ),
                      child: const Text('open'),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();
          expect(find.byType(VerdictBanner), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
