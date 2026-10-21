import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// A calculation note: plain data rendered to PDF.
class CalcNote {
  final String title;
  final String? subtitle;
  final String? project;
  final DateTime date;
  final List<NoteSection> inputs;
  final List<NoteBlock> results;

  const CalcNote({
    required this.title,
    required this.date,
    this.subtitle,
    this.project,
    this.inputs = const [],
    this.results = const [],
  });
}

class NoteRow {
  final String label;
  final String value;
  final String? symbol;
  final String? unit;
  final bool emphasize;
  const NoteRow(
    this.label,
    this.value, {
    this.symbol,
    this.unit,
    this.emphasize = false,
  });
}

class NoteSection {
  final String title;
  final List<NoteRow> rows;
  const NoteSection(this.title, this.rows);
}

sealed class NoteBlock {
  const NoteBlock();
}

/// Overall verdict or a highlighted message.
class NoteBanner extends NoteBlock {
  final String title;
  final String? message;

  /// true = success, false = failure, null = neutral.
  final bool? ok;
  const NoteBanner(this.title, {this.message, this.ok});
}

class NoteTable extends NoteBlock {
  final String title;
  final List<NoteRow> rows;
  const NoteTable(this.title, this.rows);
}

class NoteCheck {
  final String label;
  final String clause;
  final String relation;
  final String ratio;
  final bool ok;
  const NoteCheck({
    required this.label,
    required this.clause,
    required this.relation,
    required this.ratio,
    required this.ok,
  });
}

class NoteChecks extends NoteBlock {
  final String title;
  final List<NoteCheck> checks;
  const NoteChecks(this.title, this.checks);
}

class NoteText extends NoteBlock {
  final List<String> lines;
  const NoteText(this.lines);
}

/// A diagram captured from the screen (PNG).
class NoteImage extends NoteBlock {
  final Uint8List png;
  final double aspect;
  const NoteImage(this.png, this.aspect);
}

/// Labels of the note frame, in the user's language.
class NoteLabels {
  final String inputs;
  final String results;
  final String project;
  final String date;
  final String page;
  final String disclaimer;
  final String ratio;
  const NoteLabels({
    required this.inputs,
    required this.results,
    required this.project,
    required this.date,
    required this.page,
    required this.disclaimer,
    required this.ratio,
  });
}

const _ink = PdfColor.fromInt(0xFF111827);
const _muted = PdfColor.fromInt(0xFF6B7280);
const _line = PdfColor.fromInt(0xFFE5E7EB);
const _accent = PdfColor.fromInt(0xFF2F5BFF);
const _okColor = PdfColor.fromInt(0xFF16803C);
const _failColor = PdfColor.fromInt(0xFFC0262D);

Future<pw.ThemeData> _theme() async {
  Future<pw.Font> font(String f) async =>
      pw.Font.ttf(await rootBundle.load('assets/fonts/$f'));
  return pw.ThemeData.withFont(
    base: await font('Inter-Regular.ttf'),
    bold: await font('Inter-SemiBold.ttf'),
  );
}

/// Renders a note to PDF bytes (A4).
Future<Uint8List> renderNote(
  CalcNote note,
  NoteLabels labels, {
  String dateText = '',
}) async {
  final theme = await _theme();
  final mono = pw.Font.ttf(
    await rootBundle.load('assets/fonts/JetBrainsMono-Regular.ttf'),
  );
  final doc = pw.Document(title: note.title, author: 'Sibot');

  pw.Widget row(NoteRow r) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.5)),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 5,
          child: pw.Text(
            r.symbol == null ? r.label : '${r.label}  (${r.symbol})',
            style: const pw.TextStyle(fontSize: 9, color: _ink),
          ),
        ),
        pw.Expanded(
          flex: 3,
          child: pw.Text(
            r.unit == null || r.unit!.isEmpty
                ? r.value
                : '${r.value} ${r.unit}',
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              font: mono,
              fontSize: 9,
              fontWeight: r.emphasize ? pw.FontWeight.bold : null,
              color: _ink,
            ),
          ),
        ),
      ],
    ),
  );

  pw.Widget heading(String t) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
    child: pw.Text(
      t,
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: _accent,
      ),
    ),
  );

  pw.Widget block(NoteBlock b) => switch (b) {
    NoteBanner(:final title, :final message, :final ok) => pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(
            color: ok == null ? _accent : (ok ? _okColor : _failColor),
            width: 3,
          ),
        ),
        color: const PdfColor.fromInt(0xFFF6F7F9),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: ok == null ? _ink : (ok ? _okColor : _failColor),
            ),
          ),
          if (message != null && message.isNotEmpty)
            pw.Text(
              message,
              style: const pw.TextStyle(fontSize: 9, color: _muted),
            ),
        ],
      ),
    ),
    NoteTable(:final title, :final rows) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [heading(title), ...rows.map(row)],
    ),
    NoteChecks(:final title, :final checks) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        heading(title),
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(4),
            1: pw.FlexColumnWidth(3),
            2: pw.FlexColumnWidth(1.2),
          },
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _line, width: 0.5),
          ),
          children: [
            for (final c in checks)
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 3),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          c.label,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.Text(
                          c.clause,
                          style: const pw.TextStyle(
                            fontSize: 7.5,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 3),
                    child: pw.Text(
                      c.relation,
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(font: mono, fontSize: 8),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 3),
                    child: pw.Text(
                      c.ratio,
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        font: mono,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: c.ok ? _okColor : _failColor,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    ),
    NoteText(:final lines) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (final t in lines)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(
                '• $t',
                style: const pw.TextStyle(fontSize: 8.5, color: _muted),
              ),
            ),
        ],
      ),
    ),
    NoteImage(:final png, :final aspect) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Center(
        child: pw.ConstrainedBox(
          constraints: const pw.BoxConstraints(maxWidth: 360, maxHeight: 300),
          child: pw.AspectRatio(
            aspectRatio: aspect,
            child: pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.contain),
          ),
        ),
      ),
    ),
  };

  doc.addPage(
    pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
      header: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 6),
        margin: const pw.EdgeInsets.only(bottom: 8),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _line)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'SIBOT',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: _accent,
                letterSpacing: 1.5,
              ),
            ),
            pw.Text(
              [if (note.project != null) note.project!, note.title].join(' · '),
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
          ],
        ),
      ),
      footer: (ctx) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              labels.disclaimer,
              style: const pw.TextStyle(fontSize: 7, color: _muted),
            ),
          ),
          pw.Text(
            '${labels.page} ${ctx.pageNumber}/${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ],
      ),
      build: (ctx) => [
        pw.Text(
          note.title,
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        if (note.subtitle != null)
          pw.Text(
            note.subtitle!,
            style: const pw.TextStyle(fontSize: 10, color: _muted),
          ),
        pw.SizedBox(height: 6),
        pw.Text(
          [
            if (note.project != null) '${labels.project}: ${note.project}',
            '${labels.date}: $dateText',
          ].join('   ·   '),
          style: const pw.TextStyle(fontSize: 9, color: _muted),
        ),
        if (note.inputs.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          pw.Text(
            labels.inputs.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.2,
              color: _muted,
            ),
          ),
          for (final s in note.inputs) ...[
            heading(s.title),
            ...s.rows.map(row),
          ],
        ],
        if (note.results.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          pw.Text(
            labels.results.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.2,
              color: _muted,
            ),
          ),
          ...note.results.map(block),
        ],
      ],
    ),
  );
  return doc.save();
}
