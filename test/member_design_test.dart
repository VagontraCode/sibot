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
  final model = portalFrame(
    bays: 1,
    bayWidth: 6,
    storeys: 1,
    storeyHeight: 3.5,
    column: concreteRectangle(300, 300),
    beam: concreteRectangle(300, 500),
    g: 25,
    q: 10,
  );
  final out = runFrameAnalysis(model, DesignCode.ec2);

  test('envelope forces of the beam and a column', () {
    // Elements: columns 0, 1; beam 2.
    final beam = MemberForces.from(model, out, 2)!;
    expect(beam.vertical, isFalse);
    expect(beam.mSagging, greaterThan(0));
    expect(beam.mHogging, greaterThan(0));
    final col = MemberForces.from(model, out, 0)!;
    expect(col.vertical, isTrue);
    expect(col.nCompression, greaterThan(0));
  });

  for (final index in [2, 0]) {
    testWidgets('design sheet for member $index shows a verdict', (
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
      expect(tester.takeException(), isNull);
    });
  }
}
