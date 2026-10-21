import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibot/core/note/calc_note.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/calculations/shared/diagrams.dart';
import 'package:sibot/features/calculations/shared/note_extract.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

void main() {
  testWidgets('a beam note has inputs, checks with clauses and a diagram', (
    tester,
  ) async {
    final r = designBeam(
      const BeamInput(
        code: DesignCode.ec2,
        span: 6,
        b: 300,
        h: 600,
        g: 20,
        q: 15,
        fck: 25,
        fyk: 500,
      ),
    );
    final keys = [GlobalKey(), GlobalKey(), GlobalKey(), GlobalKey()];
    late BuildContext ctx;
    late List<Widget> inputs, results;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              ctx = context;
              inputs = [
                FormSection(
                  title: 'Géométrie',
                  children: [
                    CodeChoice(value: DesignCode.ec2, onChanged: (_) {}),
                    FieldRow(
                      children: [
                        NumberField(
                          label: 'Portée',
                          unit: 'm',
                          value: 6,
                          onChanged: (_) {},
                        ),
                        NumberField(
                          label: 'b',
                          unit: 'mm',
                          value: 300,
                          onChanged: (_) {},
                        ),
                      ],
                    ),
                  ],
                ),
              ];
              results = [
                VerdictBanner(checks: r.checks),
                const ResultCard(
                  title: 'Armatures',
                  rows: [ResultRow(label: 'Inférieures', value: '4 Ø16')],
                ),
                SectionSketch(
                  b: 300,
                  h: 600,
                  cover: 30,
                  bottom: const BarSet(4, 16),
                  top: const BarSet(2, 12),
                ),
                ChecksCard(checks: r.checks),
              ];
              return SingleChildScrollView(
                child: Column(
                  children: [
                    for (var i = 0; i < results.length; i++)
                      RepaintBoundary(key: keys[i], child: results[i]),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final note = (await tester.runAsync(
      () => collectNote(
        ctx,
        title: 'Poutre',
        project: 'Projet test',
        inputs: inputs,
        results: results,
        keys: keys,
      ),
    ))!;
    expect(note.inputs.single.rows, hasLength(3));
    expect(note.results.whereType<NoteImage>(), hasLength(1));
    final checks = note.results.whereType<NoteChecks>().single;
    expect(checks.checks, hasLength(r.checks.length));
    expect(checks.checks.first.clause, isNotEmpty);

    final bytes = (await tester.runAsync(
      () => renderNote(
        note,
        noteLabels(AppLocalizations.of(ctx)),
        dateText: '21/10/2026',
      ),
    ))!;
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    final out = Platform.environment['SIBOT_NOTE'];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });
}
