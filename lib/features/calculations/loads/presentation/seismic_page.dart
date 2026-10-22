import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';
import 'seismic_provider.dart';

/// Accidental torsion factor, or null when the inputs are missing.
double? _torsion(double? le, double? x) {
  if (le == null || x == null || le <= 0 || x < 0 || x > le / 2) return null;
  return accidentalTorsionFactor(x, le);
}

class SeismicPage extends ConsumerWidget {
  final String projectId;
  const SeismicPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(seismicStateProvider(projectId));
    final n = ref.read(seismicStateProvider(projectId).notifier);
    final l = context.l10n;

    final labels = {
      'agR': l.seismicAgR,
      'q': l.seismicQ,
      'storeys': l.seismicStoreys,
      'storeyHeight': l.seismicStoreyHeight,
      'mass': l.seismicFloorMass,
      'roofMass': l.seismicRoofMass,
      'period': l.seismicPeriodOverride,
      'height': l.seismicStoreyHeight,
      'le': l.seismicLe,
      'xe': l.seismicXe,
      'x': l.seismicXe,
    };
    Widget field(String key, String unit, {String? hint, String? helper}) =>
        FormNumber(
          state: s,
          notifier: n,
          field: key,
          label: labels[key]!,
          unit: unit,
          hint: hint,
          helper: helper,
        );

    return CalculatorScaffold(
      title: l.modSeismic,
      subtitle: l.seismicSubtitle,
      module: moduleByRoute('seismic'),
      onCalculate: n.calculate,
      error: s.problem == null ? null : problemMessage(l, s.problem!, labels),
      resultKey: s.runId,
      inputs: [
        FormSection(
          title: l.seismicHazard,
          icon: Icons.waves_outlined,
          children: [
            ChoiceField<String>(
              label: l.seismicRegulation,
              value: s.options['regulation']!,
              options: const {'ec8': 'EN 1998-1', 'ps92': 'PS92'},
              onChanged: (v) => n.setOption('regulation', v),
            ),
            if (n.ps92) ...[
              ChoiceField<String>(
                label: l.seismicZone,
                value: s.options['ps92Zone']!,
                options: const {
                  'ia': 'Ia',
                  'ib': 'Ib',
                  'ii': 'II',
                  'iii': 'III',
                },
                onChanged: (v) => n.setOption('ps92Zone', v),
              ),
              ChoiceField<String>(
                label: l.seismicPs92Class,
                value: s.options['ps92Class']!,
                options: const {'B': 'B', 'C': 'C', 'D': 'D'},
                onChanged: (v) => n.setOption('ps92Class', v),
              ),
              ChoiceField<String>(
                label: l.seismicPs92Site,
                value: s.options['ps92Site']!,
                options: {
                  for (final v in Ps92Site.values) v.name: v.name.toUpperCase(),
                },
                onChanged: (v) => n.setOption('ps92Site', v),
              ),
              Text(
                l.seismicPs92Note(fmt(context, n.ps92Acceleration(s), 1)),
                style: context.text.bodySmall,
              ),
            ] else ...[
              PickerField<String>(
                key: ValueKey('zone-${s.options['zone']}'),
                label: l.seismicZone,
                value: s.options['zone']!,
                options: {
                  'custom': l.seismicZoneCustom,
                  for (final z in frenchZones.entries)
                    '${z.key}': l.seismicZoneN(z.key, fmt(context, z.value, 1)),
                },
                onChanged: n.setZone,
              ),
              field('agR', 'm/s²', hint: '1.6'),
              ChoiceField<String>(
                label: l.seismicImportance,
                value: s.options['importance']!,
                options: const {'1': 'I', '2': 'II', '3': 'III', '4': 'IV'},
                onChanged: (v) => n.setOption('importance', v),
              ),
              ChoiceField<String>(
                label: l.seismicGround,
                value: s.options['ground']!,
                options: {
                  for (final g in GroundType.values)
                    g.name: g.name.toUpperCase(),
                },
                onChanged: (v) => n.setOption('ground', v),
              ),
              ChoiceField<String>(
                label: l.seismicSpectrumType,
                value: s.options['type']!,
                options: const {'1': 'Type 1', '2': 'Type 2'},
                onChanged: (v) => n.setOption('type', v),
              ),
              Text(l.seismicHazardNote, style: context.text.bodySmall),
            ],
          ],
        ),
        FormSection(
          title: l.seismicBuilding,
          icon: Icons.apartment_rounded,
          children: [
            PickerField<String>(
              label: l.seismicSystem,
              value: s.options['system']!,
              options: {
                PeriodSystem.concreteFrame.name: l.seismicSysConcrete,
                PeriodSystem.steelFrame.name: l.seismicSysSteel,
                PeriodSystem.other.name: l.seismicSysOther,
              },
              onChanged: (v) => n.setOption('system', v),
            ),
            FieldRow(
              children: [
                field('storeys', '', hint: '4'),
                field('storeyHeight', 'm'),
              ],
            ),
            FieldRow(
              children: [
                field('mass', 't', hint: '300'),
                field('roofMass', 't'),
              ],
            ),
            FieldRow(children: [field('q', ''), field('period', 's')]),
            FieldRow(children: [field('le', 'm'), field('xe', 'm')]),
            Text(l.seismicTorsionNote, style: context.text.bodySmall),
            Text(
              '${l.seismicRoofHelp} · ${l.seismicQHelp} · ${l.seismicPeriodHelp}',
              style: context.text.bodySmall,
            ),
          ],
        ),
      ],
      results: s.result == null
          ? null
          : _results(
              context,
              s.result!,
              ps92: s.options['regulation'] == 'ps92',
              torsion: _torsion(s['le'], s['xe']),
            ),
    );
  }

  List<Widget> _results(
    BuildContext context,
    SeismicResult r, {
    required bool ps92,
    double? torsion,
  }) {
    final l = context.l10n;
    String f3(double v) => fmt(context, v, 3);
    return [
      StatusBanner(
        tone: r.periodInRange ? Tone.success : Tone.warning,
        title: l.seismicBaseShear(fmt(context, r.baseShear, 0)),
        message: r.periodInRange
            ? l.seismicMassRatio(
                fmt(context, r.baseShear / (r.totalMass * 9.81) * 100, 1),
              )
            : l.seismicPeriodOut,
      ),
      ResultCard(
        title: l.seismicSpectrumTitle,
        icon: Icons.show_chart_rounded,
        rows: [
          if (!ps92)
            ResultRow(
              label: l.seismicDesignAg,
              symbol: 'ag = γI · agR',
              value: fmt(context, r.ag, 2),
              unit: 'm/s²',
            ),
          if (!ps92)
            ResultRow(
              label: l.seismicSpectrumParams,
              symbol: 'S / TB / TC / TD',
              value:
                  '${fmt(context, r.spectrum.s, 2)} / ${fmt(context, r.spectrum.tb, 2)} / ${fmt(context, r.spectrum.tc, 2)} / ${fmt(context, r.spectrum.td, 2)}',
            ),
          ResultRow(
            label: l.seismicPeriod,
            symbol: 'T1',
            value: f3(r.t1),
            unit: 's',
          ),
          ResultRow(
            label: l.seismicSd,
            symbol: 'Sd(T1)',
            value: f3(r.sd),
            unit: 'm/s²',
            emphasize: true,
          ),
          ResultRow(
            label: l.seismicLambda,
            symbol: 'λ',
            value: fmt(context, r.lambda, 2),
          ),
          ResultRow(
            label: l.seismicTotalMass,
            symbol: 'm',
            value: fmt(context, r.totalMass, 0),
            unit: 't',
          ),
          if (torsion != null)
            ResultRow(
              label: l.seismicTorsion,
              symbol: 'δ = 1 + 0.6 x / Le',
              value: fmt(context, torsion, 3),
            ),
          ResultRow(
            label: l.seismicOverturning,
            symbol: 'M0',
            value: fmt(context, r.overturning, 0),
            unit: 'kN·m',
          ),
        ],
      ),
      SpectrumChart(result: r),
      ResultCard(
        title: l.seismicStoreyForces,
        icon: Icons.stacked_bar_chart_rounded,
        rows: [
          for (final st in r.storeys.reversed)
            ResultRow(
              label: l.seismicLevel(fmt(context, st.height, 1)),
              symbol: 'F = ${fmt(context, st.force, 0)} kN',
              value: fmt(context, st.shear, 0),
              unit: 'kN',
            ),
        ],
      ),
      NotesCard(notes: [l.seismicNoteScope]),
    ];
  }
}

/// Design spectrum Sd(T) with the fundamental period marked.
class SpectrumChart extends StatelessWidget {
  final SeismicResult result;
  const SpectrumChart({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: AspectRatio(
        aspectRatio: 1.7,
        child: CustomPaint(
          painter: _SpectrumPainter(
            result,
            line: context.colors.primary,
            grid: context.colors.outlineVariant,
            ink: context.colors.onSurfaceVariant,
            mark: context.appColors.danger,
          ),
        ),
      ),
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  final SeismicResult r;
  final Color line, grid, ink, mark;
  _SpectrumPainter(
    this.r, {
    required this.line,
    required this.grid,
    required this.ink,
    required this.mark,
  });

  TextPainter _t(String s) => TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(
        color: ink,
        fontSize: 10,
        fontFamily: AppTheme.monoFamily,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    const left = 36.0, bottom = 22.0, top = 10.0, right = 10.0;
    final w = size.width - left - right, h = size.height - top - bottom;
    final tMax = r.curve.last.$1;
    final sMax = r.curve.map((p) => p.$2).reduce(math.max) * 1.1;
    Offset at(double t, double s) =>
        Offset(left + t / tMax * w, top + h - s / sMax * h);

    final gp = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var k = 0; k <= 4; k++) {
      final y = top + h * k / 4;
      canvas.drawLine(Offset(left, y), Offset(left + w, y), gp);
      final lab = _t((sMax * (4 - k) / 4).toStringAsFixed(1));
      lab.paint(canvas, Offset(left - lab.width - 4, y - lab.height / 2));
    }
    for (var t = 0.0; t <= tMax + 1e-9; t += 1) {
      final lab = _t('${t.toStringAsFixed(0)} s');
      lab.paint(canvas, Offset(at(t, 0).dx - lab.width / 2, top + h + 4));
    }

    final path = Path();
    for (var k = 0; k < r.curve.length; k++) {
      final p = at(r.curve[k].$1, r.curve[k].$2);
      k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final p1 = at(math.min(r.t1, tMax), r.sd);
    canvas.drawLine(
      Offset(p1.dx, top + h),
      p1,
      Paint()
        ..color = mark
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(p1, 4, Paint()..color = mark);
    final lab = _t('T1 = ${r.t1.toStringAsFixed(2)} s');
    lab.paint(
      canvas,
      Offset(math.min(p1.dx + 6, left + w - lab.width), p1.dy - 16),
    );
    final axis = _t('Sd (m/s²)');
    axis.paint(canvas, Offset(left + 4, top));
  }

  @override
  bool shouldRepaint(_SpectrumPainter old) => old.r != r;
}
