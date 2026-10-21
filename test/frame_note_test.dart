import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibot/core/note/calc_note.dart';
import 'package:sibot/features/calculations/shared/note_extract.dart';
import 'package:sibot/features/frame3d/frame3d_data.dart';
import 'package:sibot/features/frame3d/frame_notes.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

void main() {
  testWidgets('3D model note lists members, modes and buckling', (
    tester,
  ) async {
    final record = Frame3DRecord(
      id: 'F',
      projectId: 'P',
      name: 'Building',
      updatedAt: DateTime(2026),
      params: BuildingParams(
        spansX: const [5, 5],
        spansY: const [4],
        storeyHeights: const [3, 3],
        column: Section3D.rectangle(300, 300),
        beam: Section3D.rectangle(250, 500),
      ),
    );
    final out = runFrame3d(sourceKey(record), DesignCode.ec2);
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );
    final note = frame3dNote(ctx, record: record, out: out);
    final envelope = note.results.whereType<NoteTable>().firstWhere(
      (t) => t.title == AppLocalizations.of(ctx).noteEnvelope,
    );
    expect(envelope.rows, hasLength(out.model.elements.length));
    expect(note.results.whereType<NoteBanner>(), isNotEmpty);
    final bytes = (await tester.runAsync(
      () => renderNote(note, noteLabels(AppLocalizations.of(ctx))),
    ))!;
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
