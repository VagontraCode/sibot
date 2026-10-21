import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sibot/core/note/calc_note.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// A widget that contributes a labelled value to a calculation note
/// (for custom inputs the extractor cannot read otherwise).
mixin NoteEntry on Widget {
  String get noteLabel;
  String get noteValue;
}

/// Inputs of a calculator, read from its form widgets.
List<NoteSection> noteInputs(BuildContext context, List<Widget> inputs) {
  final l = context.l10n;
  final sections = <NoteSection>[];
  List<NoteRow>? rows;

  void walk(Widget w) {
    switch (w) {
      case FormSection(:final title, :final children):
        final list = <NoteRow>[];
        final previous = rows;
        rows = list;
        children.forEach(walk);
        rows = previous;
        if (list.isNotEmpty) sections.add(NoteSection(title, list));
      case FieldRow(:final children):
        children.forEach(walk);
      case Flex(:final children):
        children.forEach(walk);
      case Padding(:final child?) || SizedBox(:final child?):
        walk(child);
      case FormNumber(:final label, :final unit, :final state, :final field):
        final v = state[field];
        rows?.add(
          NoteRow(label, v == null ? '—' : fmt(context, v), unit: unit),
        );
      case NumberField(:final label, :final unit, :final value):
        rows?.add(
          NoteRow(label, value == null ? '—' : fmt(context, value), unit: unit),
        );
      case CodeChoice(:final value):
        rows?.add(
          NoteRow(
            l.footingCode,
            value == DesignCode.ec2 ? 'Eurocode 2' : 'BAEL 91/99',
          ),
        );
      case ChoiceField(:final label, :final value, :final options):
        rows?.add(NoteRow(label, options[value] ?? '$value'));
      case PickerField(:final label, :final value, :final options):
        rows?.add(NoteRow(label, options[value] ?? '$value'));
      case final NoteEntry e:
        if (e.noteValue.trim().isNotEmpty) {
          rows?.add(NoteRow(e.noteLabel, e.noteValue));
        }
      default:
        break;
    }
  }

  inputs.forEach(walk);
  return sections;
}

/// Whether a result widget is read as text (else it is captured as an
/// image).
bool isTextResult(Widget w) => switch (w) {
  VerdictBanner() ||
  StatusBanner() ||
  ResultCard() ||
  ChecksCard() ||
  NotesCard() ||
  Column() ||
  Align() ||
  Padding() ||
  SizedBox() => true,
  _ => false,
};

/// Result blocks of a calculator; [images] holds the captured diagrams
/// by result index.
List<NoteBlock> noteResults(
  BuildContext context,
  List<Widget> results,
  Map<int, NoteImage> images,
) {
  final l = context.l10n;
  final out = <NoteBlock>[];

  void walk(Widget w) {
    switch (w) {
      case VerdictBanner(:final checks):
        final failing = checks.where((c) => !c.ok).length;
        final worst = checks.isEmpty
            ? 0.0
            : checks.map((c) => c.ratio).reduce((a, b) => a > b ? a : b);
        out.add(
          NoteBanner(
            failing == 0 ? l.verdictOk : l.verdictFail(failing),
            message: l.verdictUtilisation(
              worst.isFinite ? fmt(context, worst * 100, 0) : '∞',
            ),
            ok: failing == 0,
          ),
        );
      case StatusBanner(:final tone, :final title, :final message):
        out.add(
          NoteBanner(
            title,
            message: message,
            ok: switch (tone) {
              Tone.success => true,
              Tone.danger => false,
              _ => null,
            },
          ),
        );
      case ResultCard(:final title, :final rows):
        out.add(
          NoteTable(title, [
            for (final r in rows)
              if (r is ResultRow)
                NoteRow(
                  r.label,
                  r.value,
                  symbol: r.symbol,
                  unit: r.unit,
                  emphasize: r.emphasize,
                ),
          ]),
        );
      case ChecksCard(:final checks):
        out.add(
          NoteChecks(l.checksTitle, [
            for (final c in checks)
              NoteCheck(
                label: checkLabel(l, c.kind),
                clause: c.clause,
                relation:
                    '${fmt(context, c.demand)} ${c.ok ? '≤' : '>'} '
                    '${fmt(context, c.capacity)}'
                    '${c.unit.isEmpty ? '' : ' ${c.unit}'}',
                ratio: c.ratio.isFinite ? fmt(context, c.ratio, 2) : '∞',
                ok: c.ok,
              ),
          ]),
        );
      case NotesCard(:final notes):
        if (notes.isNotEmpty) out.add(NoteText(notes));
      case Column(:final children):
        children.forEach(walk);
      case Align(:final child?) || Padding(:final child?):
        walk(child);
      default:
        break;
    }
  }

  for (var i = 0; i < results.length; i++) {
    final img = images[i];
    if (img != null) {
      out.add(img);
    } else {
      walk(results[i]);
    }
  }
  return out;
}

/// Captures a painted repaint boundary as PNG.
Future<NoteImage?> captureImage(GlobalKey key) async {
  final ro = key.currentContext?.findRenderObject();
  if (ro is! RenderRepaintBoundary || ro.size.isEmpty) return null;
  try {
    final image = await ro.toImage(pixelRatio: 2.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return null;
    return NoteImage(
      Uint8List.sublistView(data),
      ro.size.width / ro.size.height,
    );
  } catch (_) {
    return null;
  }
}

NoteLabels noteLabels(AppLocalizations l) => NoteLabels(
  inputs: l.noteInputs,
  results: l.noteResults,
  project: l.noteProject,
  date: l.noteDate,
  page: l.notePage,
  disclaimer: l.noteDisclaimer,
  ratio: l.noteRatio,
);

/// Collects a calculator's note: inputs, results and captured diagrams
/// (results wrapped in repaint boundaries keyed by [keys]).
Future<CalcNote> collectNote(
  BuildContext context, {
  required String title,
  String? subtitle,
  String? project,
  required List<Widget> inputs,
  required List<Widget> results,
  required List<GlobalKey> keys,
}) async {
  final images = <int, NoteImage>{};
  for (var i = 0; i < results.length && i < keys.length; i++) {
    if (isTextResult(results[i])) continue;
    final img = await captureImage(keys[i]);
    if (img != null) images[i] = img;
  }
  if (!context.mounted) {
    return CalcNote(title: title, date: DateTime.now());
  }
  return CalcNote(
    title: title,
    subtitle: subtitle,
    project: project,
    date: DateTime.now(),
    inputs: noteInputs(context, inputs),
    results: noteResults(context, results, images),
  );
}
