import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';
import 'continuous_beam_provider.dart';

class ContinuousBeamPage extends ConsumerWidget {
  final String projectId;
  const ContinuousBeamPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(continuousBeamStateProvider(projectId));
    final n = ref.read(continuousBeamStateProvider(projectId).notifier);
    final l = context.l10n;

    final labels = {
      for (var k = 0; k < continuousSpanKeys.length; k++)
        continuousSpanKeys[k]: '${l.contSpan} ${k + 1}',
      'spans': l.contSpans,
      'b': l.beamWidth,
      'h': l.beamDepth,
      'g': l.loadPermanent,
      'q': l.loadVariable,
      'cover': l.calcCover,
      'fck': l.calcConcreteFck,
      'fyk': l.calcSteelFyk,
    };
    Widget field(String key, String unit, {String? hint}) => FormNumber(
      state: s,
      notifier: n,
      field: key,
      label: labels[key]!,
      unit: unit,
      hint: hint,
    );

    return CalculatorScaffold(
      title: l.modContinuousBeam,
      subtitle: l.contSubtitle,
      module: moduleByRoute('continuous-beam'),
      onCalculate: n.calculate,
      error: s.problem == null ? null : problemMessage(l, s.problem!, labels),
      resultKey: s.runId,
      inputs: [
        FormSection(
          title: l.contSpans,
          icon: Icons.linear_scale_rounded,
          children: [
            FieldRow(
              children: [
                field('span1', 'm', hint: '5'),
                field('span2', 'm', hint: '5'),
                field('span3', 'm'),
              ],
            ),
            FieldRow(
              children: [
                field('span4', 'm'),
                field('span5', 'm'),
                field('span6', 'm'),
              ],
            ),
            ChoiceField<String>(
              label: l.contEnds,
              value: s.options['ends']!,
              options: {
                'pinned': l.contEndsPinned,
                'fixedLeft': l.contEndsFixedLeft,
                'fixed': l.contEndsFixed,
              },
              onChanged: (v) => n.setOption('ends', v),
            ),
            Text(l.contSpansNote, style: context.text.bodySmall),
          ],
        ),
        FormSection(
          title: l.beamGeometryLoad,
          icon: Icons.crop_square,
          children: [
            FieldRow(
              children: [
                field('b', 'mm', hint: '300'),
                field('h', 'mm', hint: '500'),
              ],
            ),
            FieldRow(
              children: [
                field('g', 'kN/m', hint: '15'),
                field('q', 'kN/m', hint: '10'),
              ],
            ),
            ChoiceField<String>(
              label: l.contSelfWeight,
              value: s.options['selfWeight']!,
              options: {'yes': l.contYes, 'no': l.contNo},
              onChanged: (v) => n.setOption('selfWeight', v),
            ),
          ],
        ),
        FormSection(
          title: l.calcMaterials,
          icon: Icons.science_outlined,
          children: [
            FieldRow(children: [field('fck', 'MPa'), field('fyk', 'MPa')]),
            field('cover', 'mm'),
          ],
        ),
      ],
      results: s.result == null ? null : _results(context, s.result!),
    );
  }

  List<Widget> _results(BuildContext context, ContinuousBeamDesign r) {
    final l = context.l10n;
    String f1(double v) => fmt(context, v, 1);
    return [
      VerdictBanner(checks: r.checks),
      ResultCard(
        title: l.contLoads,
        icon: Icons.south_rounded,
        rows: [
          ResultRow(
            label: l.contDesignLoads,
            symbol: '1.35 G / 1.5 Q',
            value: '${f1(r.gd)} / ${f1(r.qd)}',
            unit: 'kN/m',
          ),
          ResultRow(label: l.contArrangements, value: '${r.arrangements}'),
          for (var k = 0; k < r.supportMoments.length; k++)
            ResultRow(
              label: '${l.contSupport} ${k + 1}',
              symbol: 'M / R',
              value: '${f1(-r.supportMoments[k])} / ${f1(r.reactions[k])}',
              unit: 'kN·m / kN',
            ),
        ],
      ),
      EnvelopeDiagram(design: r),
      for (var k = 0; k < r.spans.length; k++)
        ResultCard(
          title: '${l.contSpan} ${k + 1} · ${f1(r.spans[k].length)} m',
          icon: Icons.straighten,
          rows: [
            ResultRow(
              label: l.contSagging,
              symbol: 'M+',
              value: f1(r.spans[k].mSagging),
              unit: 'kN·m',
            ),
            ResultRow(
              label: l.contHogging,
              symbol: 'M−',
              value: f1(r.spans[k].mHogging),
              unit: 'kN·m',
            ),
            ResultRow(
              label: l.contShear,
              symbol: 'VEd',
              value: f1(r.spans[k].vEd),
              unit: 'kN',
            ),
            ResultRow(
              label: l.contBottomBars,
              value: '${r.spans[k].section.bottomBars ?? '—'}',
              emphasize: true,
            ),
            ResultRow(
              label: l.contTopBars,
              value: '${r.spans[k].section.topBars ?? '—'}',
              emphasize: true,
            ),
            ResultRow(
              label: l.contLinks,
              value: '${r.spans[k].section.shear.links ?? '—'}',
            ),
          ],
        ),
      ChecksCard(checks: r.checks),
      NotesCard(notes: [l.contNoteScope]),
    ];
  }
}

/// ULS bending moment envelope (sagging below the axis).
class EnvelopeDiagram extends StatelessWidget {
  final ContinuousBeamDesign design;
  const EnvelopeDiagram({super.key, required this.design});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.contEnvelope, style: context.text.titleMedium),
          const SizedBox(height: Gap.sm),
          SizedBox(
            height: 160,
            child: CustomPaint(
              painter: _EnvelopePainter(
                design,
                axis: context.colors.outline,
                sag: context.colors.primary,
                hog: context.appColors.danger,
                ink: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnvelopePainter extends CustomPainter {
  final ContinuousBeamDesign d;
  final Color axis, sag, hog, ink;
  _EnvelopePainter(
    this.d, {
    required this.axis,
    required this.sag,
    required this.hog,
    required this.ink,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final env = d.envelope;
    final length = d.input.spans.fold<double>(0, (a, b) => a + b);
    final top = env.map((p) => -p.mMin).fold<double>(0, math.max);
    final bottom = env.map((p) => p.mMax).fold<double>(0, math.max);
    final range = math.max(top + bottom, 1e-9);
    const pad = 14.0;
    final h = size.height - 2 * pad;
    final y0 = pad + h * top / range;
    double px(double x) => pad + (size.width - 2 * pad) * x / length;
    double py(double m) => y0 + h * m / range;

    canvas.drawLine(
      Offset(px(0), y0),
      Offset(px(length), y0),
      Paint()
        ..color = axis
        ..strokeWidth = 1.5,
    );
    // Supports.
    var x = 0.0;
    final support = Paint()..color = axis;
    for (var k = 0; k <= d.input.spans.length; k++) {
      final p = Offset(px(x), y0);
      canvas.drawPath(
        Path()
          ..moveTo(p.dx, p.dy)
          ..lineTo(p.dx - 5, p.dy + 8)
          ..lineTo(p.dx + 5, p.dy + 8)
          ..close(),
        support,
      );
      if (k < d.input.spans.length) x += d.input.spans[k];
    }

    void curve(double Function(EnvelopePoint) m, Color c) {
      final path = Path()..moveTo(px(env.first.x), y0);
      for (final p in env) {
        path.lineTo(px(p.x), py(m(p)));
      }
      path.lineTo(px(env.last.x), y0);
      canvas.drawPath(path, Paint()..color = c.withValues(alpha: 0.15));
      canvas.drawPath(
        path,
        Paint()
          ..color = c
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    curve((p) => math.max(p.mMax, 0), sag);
    curve((p) => math.min(p.mMin, 0), hog);

    void label(String text, Offset at) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: ink,
            fontSize: 11,
            fontFamily: AppTheme.monoFamily,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, at - Offset(tp.width / 2, 0));
    }

    if (top > 0) {
      final p = env.reduce((a, b) => a.mMin <= b.mMin ? a : b);
      label(
        (-top).toStringAsFixed(0),
        Offset(px(p.x), math.max(0, py(p.mMin) - 14)),
      );
    }
    if (bottom > 0) {
      final p = env.reduce((a, b) => a.mMax >= b.mMax ? a : b);
      label(
        bottom.toStringAsFixed(0),
        Offset(px(p.x), math.min(size.height - 13, py(p.mMax) + 2)),
      );
    }
  }

  @override
  bool shouldRepaint(_EnvelopePainter old) => old.d != d;
}
