import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';
import 'slabs_provider.dart';

class SlabPage extends ConsumerWidget {
  final String projectId;
  const SlabPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(slabStateProvider(projectId));
    final n = ref.read(slabStateProvider(projectId).notifier);
    final l = context.l10n;
    final r = s.result;
    final twoWay = s.options['type'] == 'twoWay';

    final labels = {
      'lx': twoWay ? l.slabShortSpan : l.calcSpan,
      'ly': l.slabLongSpan,
      'h': l.slabThicknessInput,
      'g': l.loadPermanentArea,
      'q': l.loadVariableArea,
      'cover': l.calcCover,
      'fck': l.calcConcreteFck,
      'fyk': l.calcSteelFyk,
      'punchLoad': l.punchingLoad,
      'vEd': l.punchingLoad,
      'punchC1': l.punchingC1,
      'c1': l.punchingC1,
      'punchC2': l.punchingC2,
      'c2': l.punchingC2,
    };
    Widget field(String key, String unit, [String? hint]) => FormNumber(
      state: s,
      notifier: n,
      field: key,
      label: labels[key]!,
      unit: unit,
      hint: hint,
    );

    return CalculatorScaffold(
      title: l.modSlab,
      subtitle: l.slabSubtitle,
      module: moduleByRoute('slab'),
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
              label: l.slabType,
              value: s.options['type']!,
              options: {
                'oneWay': l.slabOneWayShort,
                'twoWay': l.slabTwoWayShort,
              },
              onChanged: (v) => n.setOption('type', v),
            ),
            ChoiceField<String>(
              label: l.beamSupport,
              value: s.options['support']!,
              options: {
                'simple': l.beamSimplySupported,
                'continuous': l.slabContinuous,
              },
              onChanged: (v) => n.setOption('support', v),
            ),
          ],
        ),
        FormSection(
          title: l.slabSpanLoad,
          icon: Icons.layers_outlined,
          children: [
            if (twoWay)
              FieldRow(children: [field('lx', 'm', '4'), field('ly', 'm', '5')])
            else
              field('lx', 'm', '4'),
            field('h', 'mm', '180'),
            FieldRow(
              children: [field('g', 'kN/m²', '2'), field('q', 'kN/m²', '2.5')],
            ),
            Text(l.loadSelfWeightNote, style: context.text.bodySmall),
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
        FormSection(
          title: l.punchingTitle,
          icon: Icons.adjust_rounded,
          children: [
            ChoiceField<String>(
              label: l.punchingType,
              value: s.options['punchType']!,
              options: {
                'column': l.punchingColumn,
                'load': l.punchingPointLoad,
              },
              onChanged: (v) => n.setOption('punchType', v),
            ),
            field('punchLoad', 'kN'),
            FieldRow(
              children: [field('punchC1', 'mm'), field('punchC2', 'mm')],
            ),
            Text(l.punchingOptionalNote, style: context.text.bodySmall),
          ],
        ),
      ],
      results: r == null ? null : _results(context, r),
    );
  }

  List<Widget> _results(BuildContext context, SlabDesign r) {
    final l = context.l10n;
    final notes = [
      for (final note in r.notes)
        switch (note) {
          SlabNote.treatedAsOneWay => l.noteTreatedAsOneWay,
          SlabNote.barsNotFound => l.noteBarsDoNotFit,
        },
      if (r.muX != null) l.noteBaelPanel,
      if (r.input.support == SlabSupport.continuous)
        l.noteContinuityCoefficients,
    ];
    String bars(BarSpacing? b) => b?.toString() ?? '—';
    return [
      VerdictBanner(checks: r.checks),
      ResultCard(
        title: l.resultDesignForces,
        icon: Icons.south_rounded,
        rows: [
          ResultRow(
            label: l.resultUlsLoad,
            symbol: 'wEd',
            value: fmt(context, r.wUls),
            unit: 'kN/m²',
          ),
          if (r.muX != null)
            ResultRow(
              label: l.slabCoefficients,
              symbol: 'μx / μy',
              value: '${fmt(context, r.muX!, 4)} / ${fmt(context, r.muY!, 3)}',
            ),
          ResultRow(
            label: l.slabMomentXSpan,
            symbol: 'Mx',
            value: fmt(context, r.x.mSpan),
            unit: 'kN·m/m',
            emphasize: true,
          ),
          if (r.x.mSupport != null)
            ResultRow(
              label: l.slabMomentSupport,
              symbol: 'Ma',
              value: fmt(context, r.x.mSupport!),
              unit: 'kN·m/m',
            ),
          if (r.y.mSpan > 0)
            ResultRow(
              label: l.slabMomentYSpan,
              symbol: 'My',
              value: fmt(context, r.y.mSpan),
              unit: 'kN·m/m',
            ),
        ],
      ),
      ResultCard(
        title: l.footingReinforcement,
        icon: Icons.grid_on_rounded,
        rows: [
          ResultRow(
            label: l.slabBarsXSpan,
            symbol: '${fmt(context, r.x.asSpan, 0)} mm²/m',
            value: bars(r.x.barsSpan),
            emphasize: true,
          ),
          if (r.x.asSupport != null)
            ResultRow(
              label: l.slabBarsSupport,
              symbol: '${fmt(context, r.x.asSupport!, 0)} mm²/m',
              value: bars(r.x.barsSupport),
              emphasize: true,
            ),
          ResultRow(
            label: r.muX != null ? l.slabBarsYSpan : l.slabDistribution,
            symbol: '${fmt(context, r.y.asSpan, 0)} mm²/m',
            value: bars(r.y.barsSpan),
            emphasize: true,
          ),
        ],
      ),
      if (r.punching != null)
        ResultCard(
          title: l.punchingTitle,
          icon: Icons.adjust_rounded,
          rows: [
            ResultRow(
              label: l.punchingPerimeter,
              symbol: 'u1',
              value: fmt(context, r.punching!.u1, 0),
              unit: 'mm',
            ),
            ResultRow(
              label: l.punchingDemand,
              symbol: r.input.code == DesignCode.ec2 ? 'vEd' : 'Qu',
              value: fmt(context, r.punching!.demand),
              unit: r.input.code == DesignCode.ec2 ? 'MPa' : 'kN',
            ),
            ResultRow(
              label: l.punchingResistance,
              symbol: r.input.code == DesignCode.ec2 ? 'vRd,c' : 'Qu,lim',
              value: fmt(context, r.punching!.resistance),
              unit: r.input.code == DesignCode.ec2 ? 'MPa' : 'kN',
            ),
            if (r.punching!.aswPerPerimeter != null)
              ResultRow(
                label: l.punchingReinforcement,
                symbol: 'Asw',
                value: fmt(context, r.punching!.aswPerPerimeter!, 0),
                unit: 'mm²',
                emphasize: true,
              ),
          ],
        ),
      ChecksCard(checks: r.checks),
      NotesCard(notes: notes),
    ];
  }
}
