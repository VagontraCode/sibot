import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';
import 'pile_cap_provider.dart';

class PileCapPage extends ConsumerWidget {
  final String projectId;
  const PileCapPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(pileCapStateProvider(projectId));
    final n = ref.read(pileCapStateProvider(projectId).notifier);
    final l = context.l10n;

    final labels = {
      'nEd': l.pileCapLoad,
      'spacing': l.pileCapSpacing,
      'pileDiameter': l.pileCapDiameter,
      'column': l.pileCapColumn,
      'h': l.pileCapDepth,
      'cover': l.calcCover,
      'edge': l.pileCapEdge,
      'fck': l.calcConcreteFck,
      'fyk': l.calcSteelFyk,
      'piles': l.pileCapPiles,
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
      title: l.modPileCap,
      subtitle: l.pileCapSubtitle,
      module: moduleByRoute('pile-cap'),
      onCalculate: n.calculate,
      error: s.problem == null ? null : problemMessage(l, s.problem!, labels),
      resultKey: s.runId,
      inputs: [
        FormSection(
          title: l.footingDesignBasis,
          icon: Icons.rule_rounded,
          children: [
            CodeChoice(value: s.code, onChanged: n.setCode),
            ChoiceField<String>(
              label: l.pileCapPiles,
              value: s.options['piles']!,
              options: const {'2': '2', '3': '3', '4': '4'},
              onChanged: (v) => n.setOption('piles', v),
            ),
          ],
        ),
        FormSection(
          title: l.pileCapGeometry,
          icon: Icons.view_module_outlined,
          children: [
            field('nEd', 'kN', hint: '2500'),
            FieldRow(
              children: [
                field('spacing', 'm', hint: '1.5'),
                field('pileDiameter', 'mm', hint: '500'),
              ],
            ),
            FieldRow(
              children: [
                field('column', 'mm', hint: '400'),
                field('h', 'mm', hint: '900'),
              ],
            ),
            FieldRow(children: [field('cover', 'mm'), field('edge', 'mm')]),
            Text(l.pileCapGeometryNote, style: context.text.bodySmall),
          ],
        ),
        FormSection(
          title: l.calcMaterials,
          icon: Icons.science_outlined,
          children: [
            FieldRow(children: [field('fck', 'MPa'), field('fyk', 'MPa')]),
          ],
        ),
      ],
      results: s.result == null ? null : _results(context, s.result!, n),
    );
  }

  List<Widget> _results(
    BuildContext context,
    PileCapResult r,
    PileCapNotifier n,
  ) {
    final l = context.l10n;
    final angleOk = r.theta >= 45 && r.theta <= 55;
    return [
      VerdictBanner(checks: r.checks),
      if (!angleOk)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatusBanner(
              tone: Tone.warning,
              title: l.pileCapDepthRange(
                fmt(context, r.hMin, 0),
                fmt(context, r.hMax, 0),
              ),
              message: l.pileCapDepthMsg,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: n.useSuggestedDepth,
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: Text(l.pileCapUseDepth),
              ),
            ),
          ],
        ),
      ResultCard(
        title: l.pileCapModel,
        icon: Icons.change_history_rounded,
        rows: [
          ResultRow(
            label: l.pileCapPlan,
            symbol: 'L × B',
            value: '${fmt(context, r.length, 2)} × ${fmt(context, r.width, 2)}',
            unit: 'm',
          ),
          ResultRow(
            label: l.pileCapSelfWeight,
            symbol: 'Gk',
            value: fmt(context, r.selfWeight, 1),
            unit: 'kN',
          ),
          ResultRow(
            label: l.pileCapReaction,
            symbol: 'R',
            value: fmt(context, r.reaction, 0),
            unit: 'kN',
            emphasize: true,
          ),
          ResultRow(
            label: l.pileCapAngle,
            symbol: 'θ',
            value: fmt(context, r.theta, 1),
            unit: '°',
          ),
          ResultRow(
            label: l.pileCapTie(r.ties),
            symbol: 'T',
            value: fmt(context, r.tieForce, 0),
            unit: 'kN',
          ),
        ],
      ),
      ResultCard(
        title: l.footingReinforcement,
        icon: Icons.grid_on_rounded,
        rows: [
          ResultRow(
            label: l.pileCapTieSteel,
            symbol: 'As',
            value: fmt(context, r.asTie, 0),
            unit: 'mm²',
          ),
          ResultRow(
            label: l.pileCapTieBars,
            value: r.bars?.toString() ?? '—',
            emphasize: true,
          ),
          ResultRow(
            label: l.pileCapNodeColumn,
            symbol: 'σ / σRd',
            value:
                '${fmt(context, r.sigmaColumn, 1)} / ${fmt(context, r.limitColumn, 1)}',
            unit: 'MPa',
          ),
          ResultRow(
            label: l.pileCapNodePile,
            symbol: 'σ / σRd',
            value:
                '${fmt(context, r.sigmaPile, 1)} / ${fmt(context, r.limitPile, 1)}',
            unit: 'MPa',
          ),
        ],
      ),
      PileCapSketch(
        piles: r.ties == 1 ? 2 : r.ties,
        length: r.length,
        width: r.width,
      ),
      ChecksCard(checks: r.checks),
      NotesCard(notes: [l.pileCapNoteScope]),
    ];
  }
}

/// Plan view of the cap with piles and ties.
class PileCapSketch extends StatelessWidget {
  final int piles;
  final double length;
  final double width;
  const PileCapSketch({
    super.key,
    required this.piles,
    required this.length,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: AspectRatio(
        aspectRatio: 1.6,
        child: CustomPaint(
          painter: _CapPainter(
            piles,
            length / width,
            cap: context.colors.surfaceContainerHigh,
            edge: context.colors.outline,
            pile: context.colors.onSurfaceVariant,
            tie: context.colors.primary,
          ),
        ),
      ),
    );
  }
}

class _CapPainter extends CustomPainter {
  final int piles;
  final double aspect;
  final Color cap, edge, pile, tie;
  _CapPainter(
    this.piles,
    this.aspect, {
    required this.cap,
    required this.edge,
    required this.pile,
    required this.tie,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final s = math.min(size.width, size.height) * 0.42;
    final fill = Paint()..color = cap;
    final line = Paint()
      ..color = edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final tiePaint = Paint()
      ..color = tie
      ..strokeWidth = 3;
    final List<Offset> pts;
    Path outline;
    switch (piles) {
      case 2:
        final w = math.min(size.width * 0.9, s * 2 * aspect.clamp(1, 4) / 1.4);
        final h = w / aspect;
        outline = Path()
          ..addRect(Rect.fromCenter(center: c, width: w, height: h));
        pts = [c - Offset(w / 2 - h / 2, 0), c + Offset(w / 2 - h / 2, 0)];
      case 3:
        final r = s * 1.05;
        final corners = [
          for (var k = 0; k < 3; k++)
            c +
                Offset(
                  r * math.cos(-math.pi / 2 + k * 2 * math.pi / 3),
                  r * math.sin(-math.pi / 2 + k * 2 * math.pi / 3) + r * 0.2,
                ),
        ];
        outline = Path()..addPolygon(corners, true);
        pts = [
          for (final p in corners) c + (p - c) * 0.55 + Offset(0, r * 0.1),
        ];
      default:
        outline = Path()
          ..addRect(Rect.fromCenter(center: c, width: s * 2, height: s * 2));
        pts = [
          c + Offset(-s * 0.6, -s * 0.6),
          c + Offset(s * 0.6, -s * 0.6),
          c + Offset(s * 0.6, s * 0.6),
          c + Offset(-s * 0.6, s * 0.6),
        ];
    }
    canvas.drawPath(outline, fill);
    canvas.drawPath(outline, line);
    for (var k = 0; k < pts.length; k++) {
      final next = pts[(k + 1) % pts.length];
      if (pts.length == 2 && k == 1) break;
      canvas.drawLine(pts[k], next, tiePaint);
    }
    final pr = s * 0.22;
    for (final p in pts) {
      canvas.drawCircle(p, pr, Paint()..color = pile.withValues(alpha: 0.25));
      canvas.drawCircle(
        p,
        pr,
        Paint()
          ..color = pile
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
    final col = s * 0.28;
    canvas.drawRect(
      Rect.fromCenter(center: c, width: col, height: col),
      Paint()..color = edge,
    );
  }

  @override
  bool shouldRepaint(_CapPainter old) =>
      old.piles != piles || old.aspect != aspect;
}
