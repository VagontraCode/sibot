import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibot/config/theme.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/frame/frame_member_design.dart';
import 'package:sibot/features/frame/frame_providers.dart';
import 'package:sibot/features/frame/section_library.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot_engine/sibot_engine.dart';

void main() {
  test('steel profiles carry the engine section properties', () {
    final s = steelProfile('HEB 200');
    expect(s.area * 1e4, closeTo(78.1, 0.8));
    expect(s.inertia * 1e8, closeTo(5696, 57));
    expect(s.material, SectionMaterial.steel);
  });

  final model = portalFrame(
    bays: 1,
    bayWidth: 6,
    storeys: 1,
    storeyHeight: 4,
    column: steelProfile('HEB 200'),
    beam: steelProfile('IPE 300'),
    g: 10,
    q: 5,
  );
  final out = runFrameAnalysis(model, DesignCode.ec2);

  for (final index in [2, 0]) {
    testWidgets('steel design sheet for member $index shows EC3 checks', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showMemberDesign(
                    context,
                    model: model,
                    output: out,
                    index: index,
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
      expect(find.text('Lateral-torsional buckling'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
