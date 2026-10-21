import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';
import 'masonry_wall_provider.dart';

String masonryUnitLabel(AppLocalizations l, MasonryUnit u) => switch (u) {
  MasonryUnit.clayGroup1 => '${l.masonryClay} · ${l.masonryGroup(1)}',
  MasonryUnit.clayGroup2 => '${l.masonryClay} · ${l.masonryGroup(2)}',
  MasonryUnit.clayGroup3 => '${l.masonryClay} · ${l.masonryGroup(3)}',
  MasonryUnit.concreteGroup1 => '${l.masonryConcrete} · ${l.masonryGroup(1)}',
  MasonryUnit.concreteGroup2 => '${l.masonryConcrete} · ${l.masonryGroup(2)}',
  MasonryUnit.concreteGroup3 => '${l.masonryConcrete} · ${l.masonryGroup(3)}',
  MasonryUnit.calciumSilicateGroup1 =>
    '${l.masonryCalciumSilicate} · ${l.masonryGroup(1)}',
  MasonryUnit.calciumSilicateGroup2 =>
    '${l.masonryCalciumSilicate} · ${l.masonryGroup(2)}',
  MasonryUnit.aac => l.masonryAac,
};

class MasonryWallPage extends ConsumerWidget {
  final String projectId;
  const MasonryWallPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(masonryWallStateProvider(projectId));
    final n = ref.read(masonryWallStateProvider(projectId).notifier);
    final l = context.l10n;

    final labels = {
      'fb': l.masonryFb,
      'fm': l.masonryFm,
      't': l.masonryThickness,
      'height': l.masonryHeight,
      'nEd': l.masonryLoad,
      'eTop': l.masonryETop,
      'eBottom': l.masonryEBottom,
      'gammaM': 'γM',
      'rhoN': 'ρn',
    };
    Widget field(
      String key,
      String unit, {
      String? hint,
      String? helper,
      bool negative = false,
    }) => FormNumber(
      state: s,
      notifier: n,
      field: key,
      label: labels[key]!,
      unit: unit,
      hint: hint,
      helper: helper,
      allowNegative: negative,
    );

    return CalculatorScaffold(
      title: l.modMasonryWall,
      subtitle: l.masonrySubtitle,
      module: moduleByRoute('masonry-wall'),
      onCalculate: n.calculate,
      error: s.problem == null ? null : problemMessage(l, s.problem!, labels),
      resultKey: s.runId,
      inputs: [
        FormSection(
          title: l.calcMaterials,
          icon: Icons.science_outlined,
          children: [
            PickerField<String>(
              label: l.masonryUnit,
              value: s.options['unit']!,
              options: {
                for (final u in MasonryUnit.values)
                  u.name: masonryUnitLabel(l, u),
              },
              onChanged: (v) => n.setOption('unit', v),
            ),
            FieldRow(children: [field('fb', 'MPa'), field('fm', 'MPa')]),
            field('gammaM', '', helper: l.masonryGammaHelp),
          ],
        ),
        FormSection(
          title: l.masonryWallTitle,
          icon: Icons.view_agenda_outlined,
          children: [
            FieldRow(
              children: [
                field('t', 'mm', hint: '200'),
                field('height', 'm', hint: '2.7'),
              ],
            ),
            ChoiceField<String>(
              label: l.masonryRestraint,
              value: s.options['rho']!,
              options: {'0.75': l.masonryRhoFloors, '1.0': l.masonryRhoOther},
              onChanged: (v) => n.setOption('rho', v),
            ),
            field('nEd', 'kN/m', hint: '300'),
            FieldRow(
              children: [
                field('eTop', 'mm', negative: true),
                field('eBottom', 'mm', negative: true),
              ],
            ),
            Text(l.masonryEccNote, style: context.text.bodySmall),
          ],
        ),
      ],
      results: s.result == null ? null : _results(context, s.result!),
    );
  }

  List<Widget> _results(BuildContext context, MasonryWallResult r) {
    final l = context.l10n;
    String f1(double v) => fmt(context, v, 1);
    String f3(double v) => fmt(context, v, 3);
    return [
      VerdictBanner(checks: r.checks),
      ResultCard(
        title: l.masonryStrength,
        icon: Icons.science_outlined,
        rows: [
          ResultRow(
            label: l.masonryFk,
            symbol: 'fk',
            value: fmt(context, r.fk, 2),
            unit: 'MPa',
          ),
          ResultRow(
            label: l.masonryFd,
            symbol: 'fd',
            value: fmt(context, r.fd, 2),
            unit: 'MPa',
          ),
        ],
      ),
      ResultCard(
        title: l.masonryCapacityTitle,
        icon: Icons.view_agenda_outlined,
        rows: [
          ResultRow(
            label: l.masonryEffHeight,
            symbol: 'hef / tef',
            value: '${fmt(context, r.hef, 2)} m / ${f1(r.slenderness)}',
          ),
          ResultRow(
            label: l.masonryEInit,
            symbol: 'einit',
            value: f1(r.eInit),
            unit: 'mm',
          ),
          ResultRow(
            label: l.masonryEnds,
            symbol: 'ei / Φi',
            value: '${f1(r.eEnd)} mm / ${f3(r.phiEnd)}',
          ),
          ResultRow(
            label: l.masonryMid,
            symbol: 'emk / Φm',
            value: '${f1(r.eMid)} mm / ${f3(r.phiMid)}',
          ),
          if (r.eCreep > 0)
            ResultRow(
              label: l.masonryCreep,
              symbol: 'ek',
              value: f1(r.eCreep),
              unit: 'mm',
            ),
          ResultRow(
            label: l.masonryNRd,
            symbol: 'NRd',
            value: fmt(context, r.nRd),
            unit: 'kN/m',
            emphasize: true,
          ),
        ],
      ),
      ChecksCard(checks: r.checks),
      NotesCard(notes: [l.masonryNoteScope]),
    ];
  }
}
