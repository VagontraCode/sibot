import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/calculations/shared/diagrams.dart';
import 'package:sibot/features/frame3d/model_link.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';
import 'columns_provider.dart';

class ColumnPage extends ConsumerWidget {
  final String projectId;
  const ColumnPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(columnStateProvider(projectId));
    final n = ref.read(columnStateProvider(projectId).notifier);
    final l = context.l10n;
    final r = s.result;
    final circle = s.options['shape'] == 'circle';

    final labels = {
      'b': circle ? l.columnDiameter : l.columnWidthB,
      'h': l.columnDepthH,
      'd': l.columnDepthH,
      'l0': l.columnBucklingLength,
      'nEd': l.columnAxialLoad,
      'm0Ed': circle ? l.columnMomentX : l.columnMomentH,
      'm0EdB': circle ? l.columnMomentY : l.columnMomentB,
      'cover': l.calcCover,
      'creep': l.columnCreep,
      'creepRatio': l.columnCreep,
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
      title: l.modColumn,
      subtitle: l.columnSubtitle,
      module: moduleByRoute('column'),
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
              label: l.columnShape,
              value: s.options['shape']!,
              options: {
                'rect': l.columnRectangular,
                'circle': l.columnCircular,
              },
              onChanged: (v) => n.setOption('shape', v),
            ),
          ],
        ),
        FormSection(
          title: l.columnLoadGeometry,
          icon: Icons.view_column_outlined,
          children: [
            if (circle)
              field('b', 'mm', '400')
            else
              FieldRow(
                children: [field('b', 'mm', '300'), field('h', 'mm', '300')],
              ),
            field('l0', 'm', '3'),
            field('nEd', 'kN', '1200'),
            FieldRow(children: [field('m0Ed', 'kN·m'), field('m0EdB', 'kN·m')]),
            Text(
              circle ? l.columnUlsNoteCircle : l.columnUlsNote,
              style: context.text.bodySmall,
            ),
          ],
        ),
        FormSection(
          title: l.calcMaterials,
          icon: Icons.science_outlined,
          children: [
            FieldRow(children: [field('fck', 'MPa'), field('fyk', 'MPa')]),
            FieldRow(
              children: [
                field('cover', 'mm'),
                if (s.code == DesignCode.ec2) field('creep', ''),
              ],
            ),
          ],
        ),
      ],
      results: r == null ? null : _results(context, r),
    );
  }

  List<Widget> _results(BuildContext context, ColumnDesign r) {
    final l = context.l10n;
    final circle = r.input.circular;
    final notes = [
      for (final note in r.notes)
        switch (note) {
          ColumnNote.secondOrderIncluded => l.noteSecondOrder,
          ColumnNote.baelCentredCompression => l.noteBaelCentred,
          ColumnNote.slendernessOutOfScope => l.noteSlendernessOutOfScope,
          ColumnNote.sectionTooSmall => l.noteSectionTooSmall,
          ColumnNote.biaxial => l.noteBiaxial,
        },
      if (!circle && !r.centred) l.noteImperfectionOneDirection,
    ];

    List<Widget> direction(ColumnDirection d, String suffix) => [
      ResultRow(
        label: '${l.checkSlenderness}$suffix',
        symbol: 'λ / λlim',
        value:
            '${fmt(context, d.slenderness, 1)} / ${fmt(context, d.slendernessLimit, 1)}',
      ),
      if (d.secondOrder > 0)
        ResultRow(
          label: '${l.columnSecondOrder}$suffix',
          symbol: 'e2',
          value: fmt(context, d.secondOrder, 1),
          unit: 'mm',
        ),
      if (!r.centred)
        ResultRow(
          label: '${l.resultMoment}$suffix',
          symbol: 'MEd / MRd',
          value: '${fmt(context, d.mEd)} / ${fmt(context, d.mRd ?? 0)}',
          unit: 'kN·m',
          emphasize: true,
        ),
    ];

    final bars = r.bars;
    return [
      VerdictBanner(checks: r.checks),
      ResultCard(
        title: l.columnSlendernessTitle,
        icon: Icons.height_rounded,
        rows: [
          ...direction(r.dirH, circle ? '' : ' (h)'),
          if (r.dirB != null) ...direction(r.dirB!, ' (b)'),
          if (r.imperfection > 0)
            ResultRow(
              label: l.columnImperfection,
              symbol: 'ei',
              value: fmt(context, r.imperfection, 1),
              unit: 'mm',
            ),
        ],
      ),
      ResultCard(
        title: l.footingReinforcement,
        icon: Icons.grid_on_rounded,
        rows: [
          ResultRow(
            label: l.beamSteelRequired,
            symbol: 'As',
            value: r.asRequired.isFinite ? fmt(context, r.asRequired, 0) : '—',
            unit: 'mm²',
          ),
          ResultRow(
            label: l.columnLongitudinalBars,
            value: bars?.toString() ?? '—',
            emphasize: true,
          ),
          if (bars != null && !circle)
            ResultRow(
              label: l.columnBarsPerFace,
              symbol: 'b / h',
              value: '${bars.perFaceB} / ${bars.perFaceH}',
            ),
          ResultRow(
            label: l.resultLinks,
            value: 'Ø${r.linkDiameter} @ ${r.linkSpacing}',
          ),
          ResultRow(
            label: l.columnAxialResistance,
            symbol: 'NRd',
            value: fmt(context, r.nRd),
            unit: 'kN',
          ),
        ],
      ),
      if (!r.centred)
        InteractionDiagram(
          title: circle ? l.columnInteraction : '${l.columnInteraction} (h)',
          curve: r.dirH.interaction,
          nEd: r.input.nEd,
          mEd: r.dirH.mEd,
          ok: r.ok,
        ),
      if (!r.centred && r.dirB != null && r.input.m0EdB > 0)
        InteractionDiagram(
          title: '${l.columnInteraction} (b)',
          curve: r.dirB!.interaction,
          nEd: r.input.nEd,
          mEd: r.dirB!.mEd,
          ok: r.ok,
        ),
      if (circle)
        CircularSectionSketch(
          diameter: r.input.b,
          cover: r.input.cover,
          linkDiameter: r.linkDiameter,
          bars: bars?.set,
        )
      else
        SectionSketch(
          b: r.input.b,
          h: r.input.h,
          cover: r.input.cover,
          linkDiameter: r.linkDiameter,
          bottom: bars == null ? null : BarSet(bars.perFaceB, bars.diameter),
          top: bars == null ? null : BarSet(bars.perFaceB, bars.diameter),
          sideBars: bars == null ? 0 : bars.perFaceH - 2,
        ),
      ChecksCard(checks: r.checks),
      NotesCard(notes: notes),
    ];
  }
}
