import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/calculations/shared/diagrams.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';
import 'beams_provider.dart';

class BeamPage extends ConsumerWidget {
  final String projectId;
  const BeamPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(beamStateProvider(projectId));
    final n = ref.read(beamStateProvider(projectId).notifier);
    final l = context.l10n;
    final r = s.result;

    final labels = {
      'span': l.calcSpan,
      'b': l.beamWidth,
      'h': l.beamDepth,
      'd': l.beamDepth,
      'd2': l.beamDepth,
      'g': l.loadPermanent,
      'q': l.loadVariable,
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

    return CalculatorScaffold(
      title: l.modBeam,
      subtitle: l.beamSubtitle,
      module: moduleByRoute('beam'),
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
              label: l.beamSupport,
              value: s.options['support']!,
              options: {
                'simple': l.beamSimplySupported,
                'cantilever': l.beamCantilever,
              },
              onChanged: (v) => n.setOption('support', v),
            ),
          ],
        ),
        FormSection(
          title: l.beamGeometryLoad,
          icon: Icons.straighten,
          children: [
            field('span', 'm', '6'),
            FieldRow(
              children: [field('b', 'mm', '250'), field('h', 'mm', '500')],
            ),
            FieldRow(
              children: [field('g', 'kN/m', '20'), field('q', 'kN/m', '10')],
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
      ],
      results: r == null ? null : _results(context, r),
    );
  }

  List<Widget> _results(BuildContext context, BeamDesign r) {
    final l = context.l10n;
    final b = r.bending;
    final notes = [
      for (final note in r.notes)
        switch (note) {
          BeamNote.compressionSteelRequired => l.noteCompressionSteel,
          BeamNote.barsDoNotFit => l.noteBarsDoNotFit,
          BeamNote.linksNotFound => l.noteLinksNotFound,
          BeamNote.deflectionNotCovered => l.noteDeflectionNotCovered,
        },
    ];
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
            unit: 'kN/m',
          ),
          ResultRow(
            label: l.resultMoment,
            symbol: 'MEd',
            value: fmt(context, r.mEd),
            unit: 'kN·m',
            emphasize: true,
          ),
          ResultRow(
            label: l.resultShear,
            symbol: 'VEd',
            value: fmt(context, r.vEd),
            unit: 'kN',
          ),
          ResultRow(
            label: l.resultEffectiveDepth,
            symbol: 'd',
            value: fmt(context, r.d, 0),
            unit: 'mm',
          ),
        ],
      ),
      ResultCard(
        title: l.beamBending,
        icon: Icons.linear_scale_rounded,
        rows: [
          ResultRow(
            label: l.beamMomentRatio,
            symbol: 'μ / μlim',
            value: '${fmt(context, b.mu, 3)} / ${fmt(context, b.muLim, 3)}',
          ),
          ResultRow(
            label: l.beamSteelRequired,
            symbol: 'As',
            value: fmt(context, b.asTension, 0),
            unit: 'mm²',
          ),
          ResultRow(
            label: l.resultBottomBars,
            value: r.tensionBars?.toString() ?? '—',
            emphasize: true,
          ),
          if (b.needsCompressionSteel)
            ResultRow(
              label: l.resultTopBars,
              symbol: 'As2',
              value:
                  '${r.compressionBars?.toString() ?? '—'} '
                  '(${fmt(context, b.asCompression, 0)} mm²)',
            ),
          ResultRow(
            label: l.resultLinks,
            value: r.shear.links?.toString() ?? '—',
            emphasize: true,
          ),
        ],
      ),
      SectionSketch(
        b: r.input.b,
        h: r.input.h,
        cover: r.input.cover,
        linkDiameter: r.shear.links?.diameter ?? 8,
        bottom: r.tensionBars,
        top: r.compressionBars ?? const BarSet(2, 10),
      ),
      ChecksCard(checks: r.checks),
      NotesCard(notes: notes),
    ];
  }
}
