import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/calculations/shared/diagrams.dart';
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

    final labels = {
      'b': l.columnWidthB,
      'h': l.columnDepthH,
      'd': l.columnDepthH,
      'l0': l.columnBucklingLength,
      'nEd': l.columnAxialLoad,
      'm0Ed': l.columnMoment,
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
        FormSection(
          title: l.footingDesignBasis,
          icon: Icons.rule_rounded,
          children: [CodeChoice(value: s.code, onChanged: n.setCode)],
        ),
        FormSection(
          title: l.columnLoadGeometry,
          icon: Icons.view_column_outlined,
          children: [
            FieldRow(
              children: [field('b', 'mm', '300'), field('h', 'mm', '300')],
            ),
            field('l0', 'm', '3'),
            FieldRow(
              children: [field('nEd', 'kN', '1200'), field('m0Ed', 'kN·m')],
            ),
            Text(l.columnUlsNote, style: context.text.bodySmall),
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
    final notes = [
      for (final note in r.notes)
        switch (note) {
          ColumnNote.secondOrderIncluded => l.noteSecondOrder,
          ColumnNote.baelCentredCompression => l.noteBaelCentred,
          ColumnNote.slendernessOutOfScope => l.noteSlendernessOutOfScope,
          ColumnNote.sectionTooSmall => l.noteSectionTooSmall,
        },
    ];
    final perFace = r.bars == null
        ? null
        : BarSet(r.bars!.count ~/ 2, r.bars!.diameter);
    return [
      VerdictBanner(checks: r.checks),
      ResultCard(
        title: l.columnSlendernessTitle,
        icon: Icons.height_rounded,
        rows: [
          ResultRow(
            label: l.checkSlenderness,
            symbol: 'λ / λlim',
            value:
                '${fmt(context, r.slenderness, 1)} / ${fmt(context, r.slendernessLimit, 1)}',
          ),
          if (r.imperfection > 0)
            ResultRow(
              label: l.columnImperfection,
              symbol: 'ei',
              value: fmt(context, r.imperfection, 1),
              unit: 'mm',
            ),
          if (r.secondOrder > 0)
            ResultRow(
              label: l.columnSecondOrder,
              symbol: 'e2',
              value: fmt(context, r.secondOrder, 1),
              unit: 'mm',
            ),
          ResultRow(
            label: l.resultMoment,
            symbol: 'MEd',
            value: fmt(context, r.mEd),
            unit: 'kN·m',
            emphasize: true,
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
            value: r.bars?.toString() ?? '—',
            emphasize: true,
          ),
          ResultRow(
            label: l.resultLinks,
            value: 'Ø${r.linkDiameter} @ ${r.linkSpacing}',
          ),
          ResultRow(
            label: r.mRd == null
                ? l.columnAxialResistance
                : l.columnMomentResistance,
            symbol: r.mRd == null ? 'NRd' : 'MRd',
            value: fmt(context, r.mRd ?? r.nRd),
            unit: r.mRd == null ? 'kN' : 'kN·m',
          ),
        ],
      ),
      if (r.mRd != null)
        InteractionDiagram(
          curve: r.interaction,
          nEd: r.input.nEd,
          mEd: r.mEd,
          ok: r.ok,
        ),
      SectionSketch(
        b: r.input.b,
        h: r.input.h,
        cover: r.input.cover,
        linkDiameter: r.linkDiameter,
        bottom: perFace,
        top: perFace,
      ),
      ChecksCard(checks: r.checks),
      NotesCard(notes: notes),
    ];
  }
}
