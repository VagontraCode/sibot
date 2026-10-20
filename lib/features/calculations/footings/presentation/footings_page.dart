import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/calculations/footings/presentation/footings_provider.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
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

    final labels = {
      'a': l.footingColumnA,
      'b': l.footingColumnB,
      'g': l.loadPermanentPoint,
      'q': l.loadVariablePoint,
      'mg': l.footingMomentG,
      'mq': l.footingMomentQ,
      'qAdm': l.footingAllowable,
      'qAllowable': l.footingAllowable,
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

    return CalculatorScaffold(
      title: l.modFooting,
      subtitle: l.footingSubtitle,
      module: moduleByRoute('footing'),
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
          title: l.footingColumnActions,
          icon: Icons.south_rounded,
          children: [
            FieldRow(
              children: [field('a', 'mm', '300'), field('b', 'mm', '300')],
            ),
            FieldRow(
              children: [field('g', 'kN', '400'), field('q', 'kN', '150')],
            ),
            FieldRow(children: [field('mg', 'kN·m'), field('mq', 'kN·m')]),
            Text(l.footingCharacteristicNote, style: context.text.bodySmall),
          ],
        ),
        FormSection(
          title: l.footingSoil,
          icon: Icons.terrain_outlined,
          children: [
            field('qAdm', 'kPa', '200'),
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

  List<Widget> _results(BuildContext context, FootingDesign r) {
    final l = context.l10n;
    final notes = [
      for (final note in r.notes)
        switch (note) {
          FootingNote.sizeLimitReached => l.noteSizeLimit,
          FootingNote.barsNotFound => l.noteBarsDoNotFit,
        },
      r.input.code == DesignCode.bael ? l.noteFootingBael : l.noteFootingEc2,
    ];
    return [
      VerdictBanner(checks: r.checks),
      ResultCard(
        title: l.footingDimensions,
        icon: Icons.crop_free_rounded,
        rows: [
          ResultRow(
            label: l.footingLxB,
            symbol: 'A × B',
            value:
                '${fmt(context, r.lengthA, 2)} × ${fmt(context, r.widthB, 2)}',
            unit: 'm',
            emphasize: true,
          ),
          ResultRow(
            label: l.footingThickness,
            symbol: 'h',
            value: fmt(context, r.h, 0),
            unit: 'mm',
            emphasize: true,
          ),
          ResultRow(
            label: l.footingSelfWeight,
            value: fmt(context, r.weight),
            unit: 'kN',
          ),
          ResultRow(
            label: l.footingPressure,
            symbol: 'σ',
            value: fmt(context, r.pressure),
            unit: 'kPa',
          ),
          if (r.eccentricity > 0)
            ResultRow(
              label: l.checkEccentricity,
              symbol: 'e',
              value: fmt(context, r.eccentricity * 1000, 0),
              unit: 'mm',
            ),
        ],
      ),
      ResultCard(
        title: l.footingReinforcement,
        icon: Icons.grid_on_rounded,
        rows: [
          ResultRow(
            label: l.footingBarsAlongA,
            symbol:
                '${fmt(context, r.asA > r.asMinA ? r.asA : r.asMinA, 0)} mm²',
            value: r.barsA?.toString() ?? '—',
            emphasize: true,
          ),
          ResultRow(
            label: l.footingBarsAlongB,
            symbol:
                '${fmt(context, r.asB > r.asMinB ? r.asB : r.asMinB, 0)} mm²',
            value: r.barsB?.toString() ?? '—',
            emphasize: true,
          ),
          ResultRow(
            label: l.resultUlsLoad,
            symbol: 'NEd',
            value: fmt(context, r.nUls),
            unit: 'kN',
          ),
        ],
      ),
      ChecksCard(checks: r.checks),
      NotesCard(notes: notes),
    ];
  }
}
