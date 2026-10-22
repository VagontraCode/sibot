import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';
import 'slope_provider.dart';

class SlopePage extends ConsumerWidget {
  final String projectId;
  const SlopePage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(slopeStateProvider(projectId));
    final n = ref.read(slopeStateProvider(projectId).notifier);
    final l = context.l10n;

    final labels = {
      'height': l.slopeHeight,
      'angle': l.slopeAngle,
      'gamma': l.slopeGamma,
      'cohesion': l.slopeCohesion,
      'phi': l.slopePhi,
      'ru': 'ru',
      'surcharge': l.slopeSurcharge,
      'maxDepth': l.slopeMaxDepth,
      'waterLevel': l.slopeWater,
      'layers': l.slopeLayers,
      for (final [top, gamma, c, phi] in slopeLayerKeys) ...{
        top: l.slopeLayerTop,
        gamma: l.slopeGamma,
        c: l.slopeCohesion,
        phi: l.slopePhi,
      },
    };
    Widget field(
      String key,
      String unit, {
      String? hint,
      bool negative = false,
    }) => FormNumber(
      state: s,
      notifier: n,
      field: key,
      label: labels[key]!,
      unit: unit,
      hint: hint,
      allowNegative: negative,
    );

    return CalculatorScaffold(
      title: l.modSlope,
      subtitle: l.slopeSubtitle,
      module: moduleByRoute('slope'),
      onCalculate: n.calculate,
      error: s.problem == null ? null : problemMessage(l, s.problem!, labels),
      resultKey: s.runId,
      inputs: [
        FormSection(
          title: l.slopeGeometry,
          icon: Icons.terrain_rounded,
          children: [
            ChoiceField<String>(
              label: l.slopeMethod,
              value: s.options['method']!,
              options: {'bishop': l.slopeBishop, 'janbu': l.slopeJanbu},
              onChanged: (v) => n.setOption('method', v),
            ),
            FieldRow(
              children: [
                field('height', 'm', hint: '8'),
                field('angle', '°', hint: '33.7'),
              ],
            ),
            FieldRow(
              children: [field('surcharge', 'kPa'), field('maxDepth', 'm')],
            ),
            Text(l.slopeGeometryNote, style: context.text.bodySmall),
          ],
        ),
        FormSection(
          title: l.slopeSoil,
          icon: Icons.layers_outlined,
          children: [
            FieldRow(
              children: [
                field('cohesion', 'kPa', hint: '10'),
                field('phi', '°', hint: '28'),
              ],
            ),
            FieldRow(children: [field('gamma', 'kN/m³'), field('ru', '')]),
            Text(l.slopeSoilNote, style: context.text.bodySmall),
          ],
        ),
        FormSection(
          title: l.slopeLayers,
          icon: Icons.water_drop_outlined,
          children: [
            field('waterLevel', 'm', negative: true),
            for (final [top, gamma, c, phi] in slopeLayerKeys) ...[
              FieldRow(
                children: [
                  field(top, 'm', negative: true),
                  field(gamma, 'kN/m³'),
                ],
              ),
              FieldRow(children: [field(c, 'kPa'), field(phi, '°')]),
            ],
            Text(l.slopeLayersNote, style: context.text.bodySmall),
          ],
        ),
      ],
      results: s.result == null ? null : _results(context, s.result!),
    );
  }

  List<Widget> _results(BuildContext context, SlopeResult r) {
    final l = context.l10n;
    String f2(double v) => fmt(context, v, 2);
    return [
      VerdictBanner(checks: r.checks),
      ResultCard(
        title: l.slopeCritical,
        icon: Icons.radio_button_unchecked_rounded,
        rows: [
          ResultRow(
            label: l.slopeFactor,
            symbol: 'F',
            value: fmt(context, r.factor, 3),
            emphasize: true,
          ),
          ResultRow(
            label: l.slopeFactorEc7,
            symbol: 'Fd',
            value: fmt(context, r.factorEc7, 3),
          ),
          ResultRow(
            label: l.slopeMethod,
            value: r.method == SlopeMethod.bishop
                ? l.slopeBishop
                : l.slopeJanbu,
          ),
          if (r.circle case final c?) ...[
            ResultRow(
              label: l.slopeCentre,
              symbol: 'xc / yc',
              value: '${f2(c.xc)} / ${f2(c.yc)}',
              unit: 'm',
            ),
            ResultRow(
              label: l.slopeRadius,
              symbol: 'R',
              value: f2(c.r),
              unit: 'm',
            ),
          ] else
            ResultRow(
              label: l.slopeF0,
              symbol: 'f0',
              value: fmt(context, r.f0, 3),
            ),
          ResultRow(label: l.slopeCircles, value: '${r.circles}'),
        ],
      ),
      SlopeSketch(result: r),
      ChecksCard(checks: r.checks),
      NotesCard(notes: [l.slopeNoteScope]),
    ];
  }
}

/// Slope profile with the critical slip surface, its slices, the layer
/// boundaries and the water table.
class SlopeSketch extends StatelessWidget {
  final SlopeResult result;
  const SlopeSketch({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: AspectRatio(
        aspectRatio: 1.5,
        child: CustomPaint(
          painter: _SlopePainter(
            result,
            soil: context.colors.surfaceContainerHigh,
            edge: context.colors.outline,
            slip: context.appColors.danger,
            mass: context.appColors.danger.withValues(alpha: 0.12),
            ink: context.colors.onSurfaceVariant,
            water: context.colors.primary,
          ),
        ),
      ),
    );
  }
}

class _SlopePainter extends CustomPainter {
  final SlopeResult r;
  final Color soil, edge, slip, mass, ink, water;
  _SlopePainter(
    this.r, {
    required this.water,
    required this.soil,
    required this.edge,
    required this.slip,
    required this.mass,
    required this.ink,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sl = r.slices;
    final surface = r.surface;
    final c = r.circle;
    final g = r.input;
    final h = g.height;
    final a = sl.first.x - sl.first.width / 2;
    final b = sl.last.x + sl.last.width / 2;
    final x0 = math.min(a, c?.xc ?? a) - h * 0.3;
    final x1 = math.max(math.max(b, g.toeX), c?.xc ?? b) + h * 0.3;
    final yMin =
        math.min(0.0, sl.map((p) => p.base).reduce(math.min)) - h * 0.2;
    final yMax = (c == null ? h : math.max(h, c.yc)) + h * 0.15;
    const pad = 12.0;
    final k = math.min(
      (size.width - 2 * pad) / (x1 - x0),
      (size.height - 2 * pad) / (yMax - yMin),
    );
    final ox = (size.width - (x1 - x0) * k) / 2;
    final oy = (size.height - (yMax - yMin) * k) / 2;
    Offset at(double x, double y) =>
        Offset(ox + (x - x0) * k, size.height - oy - (y - yMin) * k);
    double baseAt(double x) {
      final y = surface.baseY(x);
      return y.isNaN ? g.groundY(x) : y;
    }

    final profile = [at(x0, h), at(0, h), at(g.toeX, 0), at(x1, 0)];
    final ground = Path()
      ..addPolygon([...profile, at(x1, yMin), at(x0, yMin)], true);
    canvas.drawPath(ground, Paint()..color = soil);

    // Layer boundaries (dashed) clipped to the ground.
    canvas.save();
    canvas.clipPath(ground);
    final layerPaint = Paint()
      ..color = edge.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    final dash = (x1 - x0) / 40;
    for (final layer in g.layers) {
      for (var x = x0; x < x1; x += dash) {
        canvas.drawLine(
          at(x, layer.top),
          at(math.min(x + dash / 2, x1), layer.top),
          layerPaint,
        );
      }
    }
    canvas.restore();

    // Sliding mass and every fourth slice boundary.
    final massPath = Path();
    for (var i = 0; i <= 60; i++) {
      final x = a + (b - a) * i / 60;
      final p = at(x, g.groundY(x));
      i == 0 ? massPath.moveTo(p.dx, p.dy) : massPath.lineTo(p.dx, p.dy);
    }
    for (var i = 60; i >= 0; i--) {
      final x = a + (b - a) * i / 60;
      final p = at(x, baseAt(x));
      massPath.lineTo(p.dx, p.dy);
    }
    massPath.close();
    canvas.drawPath(massPath, Paint()..color = mass);
    final thin = Paint()
      ..color = slip.withValues(alpha: 0.35)
      ..strokeWidth = 0.8;
    for (var i = 4; i < sl.length; i += 4) {
      final x = sl[i].x - sl[i].width / 2;
      canvas.drawLine(at(x, g.groundY(x)), at(x, baseAt(x)), thin);
    }

    canvas.drawPath(
      Path()..addPolygon(profile, false),
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Water table with its marker.
    if (g.waterLevel case final zw?) {
      canvas.drawLine(
        at(x0, zw),
        at(x1, zw),
        Paint()
          ..color = water
          ..strokeWidth = 1.5,
      );
      final tip = at(x0 + (x1 - x0) * 0.85, zw);
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(tip.dx - 5, tip.dy - 8)
          ..lineTo(tip.dx + 5, tip.dy - 8)
          ..close(),
        Paint()..color = water,
      );
    }

    // Slip surface; for circles also the centre and the end radii.
    final arc = Path();
    for (var i = 0; i <= 60; i++) {
      final x = a + (b - a) * i / 60;
      final p = at(x, baseAt(x));
      i == 0 ? arc.moveTo(p.dx, p.dy) : arc.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      arc,
      Paint()
        ..color = slip
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    var labelAt = at((a + b) / 2, h) + const Offset(0, -18);
    if (c != null) {
      final centre = at(c.xc, c.yc);
      canvas.drawCircle(centre, 3.5, Paint()..color = slip);
      final radius = Paint()
        ..color = slip.withValues(alpha: 0.5)
        ..strokeWidth = 1;
      canvas.drawLine(centre, at(a, c.baseY(a)), radius);
      canvas.drawLine(centre, at(b, c.baseY(b)), radius);
      labelAt = centre + const Offset(8, -6);
    } else if (surface is SlipPolyline) {
      for (final (x, y) in surface.points) {
        canvas.drawCircle(at(x, y), 3, Paint()..color = slip);
      }
    }

    final label = TextPainter(
      text: TextSpan(
        text: 'F = ${r.factor.toStringAsFixed(2)}',
        style: TextStyle(
          color: ink,
          fontSize: 12,
          fontFamily: AppTheme.monoFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, labelAt);
  }

  @override
  bool shouldRepaint(_SlopePainter old) => old.r != r;
}
