import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/calculations/shared/diagrams.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';
import 'retaining_wall_provider.dart';

class RetainingWallPage extends ConsumerWidget {
  final String projectId;
  const RetainingWallPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(retainingWallStateProvider(projectId));
    final n = ref.read(retainingWallStateProvider(projectId).notifier);
    final l = context.l10n;
    final r = s.result;

    final labels = {
      'stemHeight': l.wallRetainedHeight,
      'baseThickness': l.wallBaseThickness,
      'toe': l.wallToeLength,
      'heel': l.wallHeelLength,
      'stemTop': l.wallStemTop,
      'stemBottom': l.wallStemBottom,
      'gammaSoil': l.wallSoilUnitWeight,
      'phi': l.wallFrictionAngle,
      'surcharge': l.wallSurcharge,
      'qAdm': l.footingAllowable,
      'qAllowable': l.footingAllowable,
      'cover': l.calcCover,
      'fck': l.calcConcreteFck,
      'fyk': l.calcSteelFyk,
    };
    Widget field(String key, String unit, [String? hint]) => FormNumber(
      state: s,
      notifier: n,
      field: key,
      label: labels[key]!,
      unit: unit,
      hint: hint,
    );

    final canSketch = [
      'stemHeight',
      'baseThickness',
      'stemBottom',
    ].every((k) => (s[k] ?? 0) > 0);

    return CalculatorScaffold(
      title: l.modRetainingWall,
      subtitle: l.wallSubtitle,
      module: moduleByRoute('retaining-wall'),
      onCalculate: n.calculate,
      error: s.problem == null ? null : problemMessage(l, s.problem!, labels),
      resultKey: s.runId,
      inputs: [
        FormSection(
          title: l.footingDesignBasis,
          icon: Icons.rule_rounded,
          children: [CodeChoice(value: s.code, onChanged: n.setCode)],
        ),
        FormSection(
          title: l.wallGeometry,
          icon: Icons.stairs_outlined,
          children: [
            field('stemHeight', 'm', '3'),
            OutlinedButton.icon(
              onPressed: n.presize,
              icon: const Icon(Icons.auto_fix_high_outlined),
              label: Text(l.wallPresizeButton),
            ),
            FieldRow(children: [field('toe', 'm'), field('heel', 'm')]),
            FieldRow(
              children: [field('stemTop', 'm'), field('stemBottom', 'm')],
            ),
            field('baseThickness', 'm'),
            if (canSketch)
              WallSketch(
                stemHeight: s['stemHeight']!,
                baseThickness: s['baseThickness']!,
                toe: s['toe'] ?? 0,
                heel: s['heel'] ?? 0,
                stemTop: s['stemTop'] ?? 0.2,
                stemBottom: s['stemBottom']!,
                surcharge: s['surcharge'] ?? 0,
              ),
          ],
        ),
        FormSection(
          title: l.wallWallSoil,
          icon: Icons.terrain_outlined,
          children: [
            FieldRow(
              children: [field('gammaSoil', 'kN/m³'), field('phi', '°')],
            ),
            FieldRow(
              children: [
                field('surcharge', 'kPa'),
                field('qAdm', 'kPa', '200'),
              ],
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
      results: r == null ? null : _results(context, r),
    );
  }

  List<Widget> _results(BuildContext context, WallDesign r) {
    final l = context.l10n;
    return [
      VerdictBanner(checks: r.checks),
      ResultCard(
        title: l.wallStability,
        icon: Icons.balance_rounded,
        rows: [
          ResultRow(
            label: l.wallKa,
            symbol: 'Ka',
            value: fmt(context, r.ka, 3),
          ),
          ResultRow(
            label: l.wallActiveThrust,
            symbol: 'Pa + Pq',
            value: fmt(context, r.thrustSoil + r.thrustSurcharge),
            unit: 'kN/m',
          ),
          ResultRow(
            label: l.wallFosOverturning,
            symbol: 'FSr',
            value: fmt(context, r.fsOverturning, 2),
            emphasize: true,
          ),
          ResultRow(
            label: l.wallFosSliding,
            symbol: 'FSg',
            value: fmt(context, r.fsSliding, 2),
            emphasize: true,
          ),
          ResultRow(
            label: l.footingPressure,
            symbol: 'σ',
            value: fmt(context, r.pressure),
            unit: 'kPa',
          ),
          ResultRow(
            label: l.checkEccentricity,
            symbol: 'e',
            value: fmt(context, r.eccentricity * 1000, 0),
            unit: 'mm',
          ),
        ],
      ),
      ResultCard(
        title: l.wallStem,
        icon: Icons.grid_on_rounded,
        rows: [
          ResultRow(
            label: l.resultMoment,
            symbol: 'MEd',
            value: fmt(context, r.stemMoment),
            unit: 'kN·m/m',
          ),
          ResultRow(
            label: l.beamSteelRequired,
            symbol: 'As',
            value: fmt(context, r.stemAs, 0),
            unit: 'mm²/m',
          ),
          ResultRow(
            label: l.wallStemBars,
            value: r.stemBars?.toString() ?? '—',
            emphasize: true,
          ),
        ],
      ),
      ChecksCard(checks: r.checks),
      NotesCard(
        notes: [
          l.noteWallMethod,
          if (!r.checks.firstWhere((c) => c.kind == CheckKind.sliding).ok)
            l.noteWallShearKey,
        ],
      ),
    ];
  }
}
