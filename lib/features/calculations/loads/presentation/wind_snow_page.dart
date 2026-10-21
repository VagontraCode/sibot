import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';
import 'wind_snow_provider.dart';

class WindSnowPage extends ConsumerWidget {
  final String projectId;
  const WindSnowPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(windSnowStateProvider(projectId));
    final n = ref.read(windSnowStateProvider(projectId).notifier);
    final l = context.l10n;
    final roof = RoofShape.values.byName(s.options['roof']!);

    final labels = {
      'vb': l.windVb,
      'h': l.windHeight,
      'b': l.windWidth,
      'd': l.windDepth,
      'z': l.windHeight,
      'sk': l.snowSk,
      'alpha1': roof == RoofShape.duopitch ? l.snowPitch1 : l.snowPitch,
      'alpha2': l.snowPitch2,
      'ce': 'Ce',
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
      title: l.modWindSnow,
      subtitle: l.windSubtitle,
      module: moduleByRoute('wind-snow'),
      onCalculate: n.calculate,
      error: s.problem == null ? null : problemMessage(l, s.problem!, labels),
      resultKey: s.runId,
      inputs: [
        FormSection(
          title: l.windTitle,
          icon: Icons.air_rounded,
          children: [
            field('vb', 'm/s', hint: '24', helper: l.windVbHelp),
            PickerField<String>(
              label: l.windTerrain,
              value: s.options['terrain']!,
              options: {
                TerrainCategory.cat0.name: l.windTerrain0,
                TerrainCategory.catI.name: l.windTerrainI,
                TerrainCategory.catII.name: l.windTerrainII,
                TerrainCategory.catIII.name: l.windTerrainIII,
                TerrainCategory.catIV.name: l.windTerrainIV,
              },
              onChanged: (v) => n.setOption('terrain', v),
            ),
            field('h', 'm', hint: '10'),
            FieldRow(
              children: [
                field('b', 'm', hint: '20'),
                field('d', 'm', hint: '10'),
              ],
            ),
            Text(l.windGeometryNote, style: context.text.bodySmall),
          ],
        ),
        FormSection(
          title: l.snowTitle,
          icon: Icons.ac_unit_rounded,
          children: [
            field('sk', 'kN/m²', hint: '0.45', helper: l.snowSkHelp),
            ChoiceField<String>(
              label: l.snowRoof,
              value: roof.name,
              options: {
                RoofShape.flat.name: l.snowRoofFlat,
                RoofShape.monopitch.name: l.snowRoofMono,
                RoofShape.duopitch.name: l.snowRoofDuo,
              },
              onChanged: (v) => n.setOption('roof', v),
            ),
            if (roof == RoofShape.monopitch) field('alpha1', '°'),
            if (roof == RoofShape.duopitch)
              FieldRow(children: [field('alpha1', '°'), field('alpha2', '°')]),
            field('ce', '', helper: l.snowCeHelp),
          ],
        ),
      ],
      results: s.result == null ? null : _results(context, s.result!),
    );
  }

  List<Widget> _results(BuildContext context, ClimateResult r) {
    final l = context.l10n;
    final p = r.wind.peak;
    String f2(double v) => fmt(context, v, 2);
    String f3(double v) => fmt(context, v, 3);
    ResultRow zone(WindZone z) => ResultRow(
      label: z.extent == null
          ? l.windZone(z.zone)
          : l.windZoneExtent(z.zone, fmt(context, z.extent!, 1)),
      symbol: 'cpe,10 = ${f2(z.cpe)}',
      value: f2(z.pressure),
      unit: 'kPa',
    );
    return [
      ResultCard(
        title: l.windPeakTitle,
        icon: Icons.air_rounded,
        rows: [
          ResultRow(
            label: l.windMeanVelocity,
            symbol: 'cr / vm',
            value: '${f3(p.cr)} / ${fmt(context, p.vm, 1)} m/s',
          ),
          ResultRow(label: l.windTurbulence, symbol: 'Iv', value: f3(p.iv)),
          ResultRow(label: l.windExposure, symbol: 'ce(z)', value: f3(p.ce)),
          ResultRow(
            label: l.windPeakPressure,
            symbol: 'qp(z)',
            value: f3(p.qp),
            unit: 'kPa',
            emphasize: true,
          ),
        ],
      ),
      ResultCard(
        title: l.windWallsTitle(fmt(context, r.wind.e, 1)),
        icon: Icons.crop_portrait_rounded,
        rows: [
          ...r.wind.walls.map(zone),
          ResultRow(
            label: l.windNetWall,
            symbol: 'ρ = ${f2(r.wind.correlation)}',
            value: f2(r.wind.netWall),
            unit: 'kPa',
            emphasize: true,
          ),
        ],
      ),
      if (r.flatRoof)
        ResultCard(
          title: l.windRoofTitle,
          icon: Icons.roofing_rounded,
          rows: r.wind.roof.map(zone).toList(),
        ),
      ResultCard(
        title: l.snowResultTitle,
        icon: Icons.ac_unit_rounded,
        rows: [
          ResultRow(
            label: l.snowShape,
            symbol: 'μ1',
            value: r.snow.mu1Left == r.snow.mu1Right
                ? f3(r.snow.mu1Left)
                : '${f3(r.snow.mu1Left)} / ${f3(r.snow.mu1Right)}',
          ),
          for (final c in r.snow.cases)
            ResultRow(
              label: l.snowCase(c.arrangement),
              symbol: 's',
              value: c.left == c.right
                  ? f2(c.left)
                  : '${f2(c.left)} / ${f2(c.right)}',
              unit: 'kN/m²',
              emphasize: c == r.snow.cases.first,
            ),
        ],
      ),
      NotesCard(
        notes: [
          l.windNoteScope,
          if (!r.flatRoof) l.windPitchedNote,
          l.snowNoteScope,
        ],
      ),
    ];
  }
}
