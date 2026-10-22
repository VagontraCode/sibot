import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/calculations/footings/presentation/footings_provider.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/calculations/shared/diagrams.dart';
import 'package:sibot/features/frame3d/model_link.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

class FootingPage extends ConsumerWidget {
  final String projectId;

  const FootingPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(footingStateProvider(projectId));
    final n = ref.read(footingStateProvider(projectId).notifier);
    final l = context.l10n;
    final r = s.result;
    final type = s.options['type']!;
    final soilMode = s.options['bearing'] == 'soil';
    final undrained = s.options['drainage'] == 'undrained';
    final perMetre = type == 'strip';

    final labels = {
      'a': type == 'strip' ? l.footingWallThickness : l.footingColumnA,
      'b': l.footingColumnB,
      'wall': l.footingWallThickness,
      'g': perMetre ? l.loadPermanent : l.loadPermanentPoint,
      'q': perMetre ? l.loadVariable : l.loadVariablePoint,
      'mg': l.footingMomentG,
      'mq': l.footingMomentQ,
      'a1': l.footingCol1A,
      'b1': l.footingCol1B,
      'a2': l.footingCol2A,
      'b2': l.footingCol2B,
      'spacing': l.footingSpacingInput,
      'g1': l.footingG1,
      'q1': l.footingQ1,
      'g2': l.footingG2,
      'q2': l.footingQ2,
      'qAdm': l.footingAllowable,
      'qAllowable': l.footingAllowable,
      'cohesion': l.soilCohesion,
      'phi': l.soilPhi,
      'cu': l.soilCu,
      'depth': l.footingDepthInput,
      'gammaSoil': l.footingUnitWeight,
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

    final load = perMetre ? 'kN/m' : 'kN';
    final moment = perMetre ? 'kN·m/m' : 'kN·m';

    return CalculatorScaffold(
      title: l.modFooting,
      subtitle: l.footingSubtitle,
      module: moduleByRoute('footing'),
      onCalculate: n.calculate,
      error: s.problem == null ? null : problemMessage(l, s.problem!, labels),
      resultKey: s.runId,
      inputs: [
        if (s.link != null)
          ModelLinkBanner(
            link: s.link!,
            projectId: projectId,
            onUnlink: n.unlink,
          ),
        FormSection(
          title: l.footingDesignBasis,
          icon: Icons.rule_rounded,
          children: [
            CodeChoice(value: s.code, onChanged: n.setCode),
            ChoiceField<String>(
              label: l.footingTypeLabel,
              value: type,
              options: {
                'isolated': l.footingIsolatedType,
                'strip': l.footingStripType,
                'combined': l.footingCombinedType,
              },
              onChanged: (v) => n.setOption('type', v),
            ),
          ],
        ),
        FormSection(
          title: type == 'strip'
              ? l.footingWallActions
              : l.footingColumnActions,
          icon: Icons.south_rounded,
          children: [
            if (type == 'combined') ...[
              FieldRow(
                children: [field('a1', 'mm', '300'), field('b1', 'mm', '300')],
              ),
              FieldRow(
                children: [field('g1', 'kN', '400'), field('q1', 'kN', '150')],
              ),
              FieldRow(
                children: [field('a2', 'mm', '400'), field('b2', 'mm', '400')],
              ),
              FieldRow(
                children: [field('g2', 'kN', '600'), field('q2', 'kN', '200')],
              ),
              field('spacing', 'm', '3.5'),
              ChoiceField<String>(
                label: l.footingOptimise,
                value: s.options['optimise']!,
                options: {'no': l.contNo, 'yes': l.contYes},
                onChanged: (v) => n.setOption('optimise', v),
              ),
            ] else ...[
              if (type == 'strip')
                field('a', 'mm', '200')
              else
                FieldRow(
                  children: [field('a', 'mm', '300'), field('b', 'mm', '300')],
                ),
              FieldRow(
                children: [field('g', load, '400'), field('q', load, '150')],
              ),
              FieldRow(children: [field('mg', moment), field('mq', moment)]),
            ],
            Text(l.footingCharacteristicNote, style: context.text.bodySmall),
          ],
        ),
        FormSection(
          title: l.footingSoil,
          icon: Icons.terrain_outlined,
          children: [
            ChoiceField<String>(
              label: l.soilBearingMode,
              value: s.options['bearing']!,
              options: {
                'allowable': l.soilModeAllowable,
                'soil': l.soilModeParameters,
              },
              onChanged: (v) => n.setOption('bearing', v),
            ),
            if (!soilMode)
              field('qAdm', 'kPa', '200')
            else ...[
              ChoiceField<String>(
                label: l.soilDrainage,
                value: s.options['drainage']!,
                options: {
                  'drained': l.soilDrained,
                  'undrained': l.soilUndrained,
                },
                onChanged: (v) => n.setOption('drainage', v),
              ),
              if (undrained)
                field('cu', 'kPa', '50')
              else
                FieldRow(
                  children: [field('cohesion', 'kPa'), field('phi', '°')],
                ),
            ],
            FieldRow(
              children: [field('depth', 'm'), field('gammaSoil', 'kN/m³')],
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

  List<Widget> _results(BuildContext context, Object r) {
    final l = context.l10n;
    final checks = switch (r) {
      FootingDesign f => f.checks,
      StripFootingDesign f => f.checks,
      CombinedFootingDesign f => f.checks,
      _ => const <Check>[],
    };
    final soilNote = switch (r) {
      FootingDesign f => f.input.soil != null,
      StripFootingDesign f => f.input.soil != null,
      CombinedFootingDesign f => f.input.soil != null,
      _ => false,
    };

    ResultRow pressure(double p, double limit) => ResultRow(
      label: l.footingPressure,
      symbol: 'σ / σlim',
      value: '${fmt(context, p)} / ${fmt(context, limit)}',
      unit: 'kPa',
    );

    final body = <Widget>[];
    switch (r) {
      case FootingDesign f:
        body.addAll([
          ResultCard(
            title: l.footingDimensions,
            icon: Icons.crop_free_rounded,
            rows: [
              ResultRow(
                label: l.footingLxB,
                symbol: 'A × B',
                value:
                    '${fmt(context, f.lengthA, 2)} × ${fmt(context, f.widthB, 2)}',
                unit: 'm',
                emphasize: true,
              ),
              ResultRow(
                label: l.footingThickness,
                symbol: 'h',
                value: fmt(context, f.h, 0),
                unit: 'mm',
                emphasize: true,
              ),
              ResultRow(
                label: l.footingSelfWeight,
                value: fmt(context, f.weight),
                unit: 'kN',
              ),
              pressure(f.pressure, f.bearingLimit),
            ],
          ),
          ResultCard(
            title: l.footingReinforcement,
            icon: Icons.grid_on_rounded,
            rows: [
              ResultRow(
                label: l.footingBarsAlongA,
                symbol:
                    '${fmt(context, f.asA > f.asMinA ? f.asA : f.asMinA, 0)} mm²',
                value: f.barsA?.toString() ?? '—',
                emphasize: true,
              ),
              ResultRow(
                label: l.footingBarsAlongB,
                symbol:
                    '${fmt(context, f.asB > f.asMinB ? f.asB : f.asMinB, 0)} mm²',
                value: f.barsB?.toString() ?? '—',
                emphasize: true,
              ),
            ],
          ),
        ]);
      case StripFootingDesign f:
        body.addAll([
          ResultCard(
            title: l.footingDimensions,
            icon: Icons.crop_free_rounded,
            rows: [
              ResultRow(
                label: l.footingWidth,
                symbol: 'B',
                value: fmt(context, f.width, 2),
                unit: 'm',
                emphasize: true,
              ),
              ResultRow(
                label: l.footingThickness,
                symbol: 'h',
                value: fmt(context, f.h, 0),
                unit: 'mm',
                emphasize: true,
              ),
              pressure(f.pressure, f.bearingLimit),
            ],
          ),
          ResultCard(
            title: l.footingReinforcement,
            icon: Icons.grid_on_rounded,
            rows: [
              ResultRow(
                label: l.footingTransverseBars,
                symbol: '${fmt(context, f.asMain, 0)} mm²/m',
                value: f.barsMain?.toString() ?? '—',
                emphasize: true,
              ),
              ResultRow(
                label: l.slabDistribution,
                symbol: '${fmt(context, f.asDistribution, 0)} mm²/m',
                value: f.barsDistribution?.toString() ?? '—',
              ),
            ],
          ),
        ]);
      case CombinedFootingDesign f:
        final x1 = f.overhang1;
        body.addAll([
          ResultCard(
            title: l.footingDimensions,
            icon: Icons.crop_free_rounded,
            rows: [
              ResultRow(
                label: l.footingLxB,
                symbol: 'L × B',
                value:
                    '${fmt(context, f.length, 2)} × ${fmt(context, f.width, 2)}',
                unit: 'm',
                emphasize: true,
              ),
              ResultRow(
                label: l.footingThickness,
                symbol: 'h',
                value: fmt(context, f.h, 0),
                unit: 'mm',
                emphasize: true,
              ),
              ResultRow(
                label: l.footingOverhang,
                value: fmt(context, f.overhang1, 2),
                unit: 'm',
              ),
              pressure(f.pressure, f.bearingLimit),
            ],
          ),
          ForceDiagram(
            points: [for (final p in f.diagram) ForcePoint(p.x, p.v, p.m)],
            marks: [x1, x1 + f.input.spacing],
          ),
          ResultCard(
            title: l.footingReinforcement,
            icon: Icons.grid_on_rounded,
            rows: [
              ResultRow(
                label: l.footingLongBottom,
                symbol: '${fmt(context, f.mBottom)} kN·m',
                value: f.barsBottom?.toString() ?? '—',
                emphasize: true,
              ),
              ResultRow(
                label: l.footingLongTop,
                symbol: '${fmt(context, f.mTop)} kN·m',
                value: f.barsTop?.toString() ?? '—',
                emphasize: true,
              ),
              for (var k = 0; k < f.barsTransverse.length; k++)
                ResultRow(
                  label: l.footingTransverseUnder(k + 1),
                  symbol: '${fmt(context, f.asTransverse[k], 0)} mm²',
                  value: f.barsTransverse[k]?.toString() ?? '—',
                ),
            ],
          ),
        ]);
    }

    final code = switch (r) {
      FootingDesign f => f.input.code,
      StripFootingDesign f => f.input.code,
      CombinedFootingDesign f => f.input.code,
      _ => DesignCode.ec2,
    };
    return [
      VerdictBanner(checks: checks),
      ...body,
      ChecksCard(checks: checks),
      NotesCard(
        notes: [
          if (r is FootingDesign)
            code == DesignCode.bael ? l.noteFootingBael : l.noteFootingEc2,
          if (r is CombinedFootingDesign) l.noteCombinedFooting,
          if (soilNote) l.noteSoilEc7,
        ],
      ),
    ];
  }
}
