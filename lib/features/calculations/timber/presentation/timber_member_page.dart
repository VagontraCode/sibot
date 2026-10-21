import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';
import 'timber_member_provider.dart';

class TimberMemberPage extends ConsumerWidget {
  final String projectId;
  const TimberMemberPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(timberMemberStateProvider(projectId));
    final n = ref.read(timberMemberStateProvider(projectId).notifier);
    final l = context.l10n;

    final labels = {
      'b': l.timberWidth,
      'h': l.timberDepth,
      'length': l.steelLength,
      'nEd': l.steelAxialForce,
      'myEd': l.steelMoment,
      'vEd': l.steelShear,
      'ky': 'ky',
      'kz': 'kz',
      'kLT': 'kLT',
      'gk': l.timberGk,
      'qk': l.timberQk,
      'psi2': 'ψ2',
      'serviceClass': l.timberServiceClass,
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
      title: l.modTimberMember,
      subtitle: l.timberSubtitle,
      module: moduleByRoute('timber-member'),
      onCalculate: n.calculate,
      error: s.problem == null ? null : problemMessage(l, s.problem!, labels),
      resultKey: s.runId,
      inputs: [
        FormSection(
          title: l.timberMaterialTitle,
          icon: Icons.forest_outlined,
          children: [
            FieldRow(
              children: [
                PickerField<String>(
                  label: l.timberStrengthClass,
                  value: s.options['class']!,
                  options: {for (final c in timberClasses.keys) c: c},
                  onChanged: (v) => n.setOption('class', v),
                ),
              ],
            ),
            PickerField<String>(
              label: l.timberDuration,
              value: s.options['duration']!,
              options: {
                LoadDuration.permanent.name: l.timberDurPermanent,
                LoadDuration.longTerm.name: l.timberDurLong,
                LoadDuration.mediumTerm.name: l.timberDurMedium,
                LoadDuration.shortTerm.name: l.timberDurShort,
                LoadDuration.instantaneous.name: l.timberDurInstant,
              },
              onChanged: (v) => n.setOption('duration', v),
            ),
            ChoiceField<String>(
              label: l.timberServiceClass,
              value: s.options['service']!,
              options: const {'1': '1', '2': '2', '3': '3'},
              onChanged: (v) => n.setOption('service', v),
            ),
            Text(l.timberServiceNote, style: context.text.bodySmall),
          ],
        ),
        FormSection(
          title: l.steelForcesTitle,
          icon: Icons.south_rounded,
          children: [
            FieldRow(
              children: [
                field('b', 'mm', hint: '75'),
                field('h', 'mm', hint: '200'),
              ],
            ),
            field('length', 'm', hint: '4', helper: l.steelLengthHelp),
            field('nEd', 'kN', helper: l.steelAxialHelp, negative: true),
            FieldRow(children: [field('myEd', 'kN·m'), field('vEd', 'kN')]),
            FieldRow(
              children: [field('ky', ''), field('kz', ''), field('kLT', '')],
            ),
            Text(l.timberBucklingNote, style: context.text.bodySmall),
          ],
        ),
        FormSection(
          title: l.timberSlsTitle,
          icon: Icons.straighten,
          children: [
            FieldRow(children: [field('gk', 'kN/m'), field('qk', 'kN/m')]),
            field('psi2', ''),
            Text(l.timberSlsNote, style: context.text.bodySmall),
          ],
        ),
      ],
      results: s.result == null ? null : _results(context, s.result!),
    );
  }

  List<Widget> _results(BuildContext context, TimberMemberResult r) {
    final l = context.l10n;
    String f2(double v) => fmt(context, v, 2);
    String f3(double v) => fmt(context, v, 3);
    return [
      VerdictBanner(checks: r.checks),
      ResultCard(
        title: l.timberStrengths,
        icon: Icons.science_outlined,
        rows: [
          ResultRow(
            label: l.timberFactors,
            symbol: 'kmod / kh',
            value: '${f2(r.kmod)} / ${f3(r.kh)}',
          ),
          ResultRow(
            label: l.steelMomentResistance,
            symbol: 'σm / fm,d',
            value: '${f2(r.sigmaM)} / ${f2(r.fmd)}',
            unit: 'MPa',
            emphasize: true,
          ),
          ResultRow(
            label: l.timberAxialStress,
            symbol: 'σ0 / fc,0,d',
            value: '${f2(r.sigmaN)} / ${f2(r.fc0d)}',
            unit: 'MPa',
          ),
          ResultRow(
            label: l.steelShearResistance,
            symbol: 'τ / fv,d',
            value: '${f2(r.tau)} / ${f2(r.fvd)}',
            unit: 'MPa',
          ),
        ],
      ),
      ResultCard(
        title: l.steelStability,
        icon: Icons.unfold_more_rounded,
        rows: [
          ResultRow(
            label: l.steelFlexuralY,
            symbol: 'λrel,y / kc,y',
            value: '${f3(r.lambdaRelY)} / ${f3(r.kcY)}',
          ),
          ResultRow(
            label: l.steelFlexuralZ,
            symbol: 'λrel,z / kc,z',
            value: '${f3(r.lambdaRelZ)} / ${f3(r.kcZ)}',
          ),
          ResultRow(
            label: l.steelLtb,
            symbol: 'λrel,m / kcrit',
            value: '${f3(r.lambdaRelM)} / ${f3(r.kcrit)}',
          ),
        ],
      ),
      if (r.wFin != null)
        ResultCard(
          title: l.timberSlsTitle,
          icon: Icons.straighten,
          rows: [
            ResultRow(
              label: l.checkDeflectionInstant,
              symbol: 'winst,Q',
              value: fmt(context, r.wInstQ!, 1),
              unit: 'mm',
            ),
            ResultRow(
              label: l.checkDeflectionFinal,
              symbol: 'wfin',
              value: fmt(context, r.wFin!, 1),
              unit: 'mm',
              emphasize: true,
            ),
          ],
        ),
      ChecksCard(checks: r.checks),
      NotesCard(notes: [l.timberNoteScope]),
    ];
  }
}
