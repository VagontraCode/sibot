import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/calculations/shared/diagrams.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';
import 'steel_member_provider.dart';

class SteelMemberPage extends ConsumerWidget {
  final String projectId;
  const SteelMemberPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(steelMemberStateProvider(projectId));
    final n = ref.read(steelMemberStateProvider(projectId).notifier);
    final l = context.l10n;
    final linear = s.options['shape'] == MomentShape.linear.name;

    final labels = {
      'length': l.steelLength,
      'nEd': l.steelAxialForce,
      'myEd': l.steelMoment,
      'vEd': l.steelShear,
      'ky': 'ky',
      'kz': 'kz',
      'kLT': 'kLT',
      'psi': 'ψ',
      'grade': l.steelGrade,
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

    final series = s.options['series']!;
    final profile = steelProfiles[s.options['profile']]!;

    return CalculatorScaffold(
      title: l.modSteelMember,
      subtitle: l.steelSubtitle,
      module: moduleByRoute('steel-member'),
      onCalculate: n.calculate,
      error: s.problem == null ? null : problemMessage(l, s.problem!, labels),
      resultKey: s.runId,
      inputs: [
        FormSection(
          title: l.steelProfileTitle,
          icon: Icons.horizontal_split_outlined,
          children: [
            PickerField<String>(
              key: ValueKey('series-$series'),
              label: l.steelSeries,
              value: series,
              options: {for (final x in designSeries) x: x},
              onChanged: n.setSeries,
            ),
            FieldRow(
              children: [
                PickerField<String>(
                  key: ValueKey('profile-${s.options['profile']}'),
                  label: l.steelProfile,
                  value: profile.name,
                  options: {for (final p in profilesOf(series)) p: p},
                  onChanged: (v) => n.setOption('profile', v),
                ),
                PickerField<String>(
                  label: l.steelGrade,
                  value: s.options['grade']!,
                  options: {for (final g in steelGrades.keys) g: g},
                  onChanged: (v) => n.setOption('grade', v),
                ),
              ],
            ),
            Text(l.steelBasisNote, style: context.text.bodySmall),
          ],
        ),
        FormSection(
          title: l.steelForcesTitle,
          icon: Icons.south_rounded,
          children: [
            field('length', 'm', hint: '6', helper: l.steelLengthHelp),
            field('nEd', 'kN', helper: l.steelAxialHelp, negative: true),
            FieldRow(
              children: [
                field('myEd', 'kN·m', hint: '80'),
                field('vEd', 'kN'),
              ],
            ),
            ChoiceField<String>(
              label: l.steelMomentShape,
              value: s.options['shape']!,
              options: {
                MomentShape.udl.name: l.steelShapeUdl,
                MomentShape.pointLoad.name: l.steelShapePoint,
                MomentShape.uniform.name: l.steelShapeUniform,
                MomentShape.linear.name: l.steelShapeLinear,
              },
              onChanged: (v) => n.setOption('shape', v),
            ),
            if (linear)
              field('psi', '', helper: l.steelPsiHelp, negative: true),
          ],
        ),
        FormSection(
          title: l.steelBucklingTitle,
          icon: Icons.unfold_more_rounded,
          children: [
            FieldRow(
              children: [field('ky', ''), field('kz', ''), field('kLT', '')],
            ),
            Text(l.steelBucklingNote, style: context.text.bodySmall),
          ],
        ),
      ],
      results: s.result == null
          ? null
          : _results(context, s.result!, profile, n),
    );
  }

  List<Widget> _results(
    BuildContext context,
    SteelMemberResult r,
    SteelProfile p,
    SteelMemberNotifier n,
  ) {
    final l = context.l10n;
    final lightest = n.lightest();
    String f2(double v) => fmt(context, v, 2);
    String f3(double v) => fmt(context, v, 3);
    return [
      VerdictBanner(checks: r.checks),
      if (lightest != null && lightest.name != p.name)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatusBanner(
              tone: Tone.primary,
              icon: Icons.auto_awesome_rounded,
              title: l.steelLightest(lightest.name),
              message: l.steelLightestMsg(
                fmt(context, lightest.mass, 1),
                fmt(context, p.mass, 1),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => n.useProfile(lightest.name),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: Text(l.steelUseProfile(lightest.name)),
              ),
            ),
          ],
        ),
      ResultCard(
        title: l.steelResistances,
        icon: Icons.shield_outlined,
        rows: [
          ResultRow(
            label: l.steelClass,
            symbol: 'fy = ${fmt(context, r.fy, 0)} MPa',
            value: '${r.sectionClass}',
            emphasize: true,
          ),
          ResultRow(
            label: l.steelAxialResistance,
            symbol: 'Npl,Rd',
            value: fmt(context, r.nPlRd),
            unit: 'kN',
          ),
          ResultRow(
            label: l.steelMomentResistance,
            symbol: r.sectionClass <= 2 ? 'Mpl,Rd' : 'Mel,Rd',
            value: fmt(context, r.mcRd),
            unit: 'kN·m',
          ),
          ResultRow(
            label: l.steelShearResistance,
            symbol: 'Vpl,Rd',
            value: fmt(context, r.vPlRd),
            unit: 'kN',
          ),
          ResultRow(
            label: l.steelReducedMoment,
            symbol: 'MN,V,Rd',
            value: fmt(context, r.mNRd),
            unit: 'kN·m',
          ),
        ],
      ),
      ResultCard(
        title: l.steelStability,
        icon: Icons.unfold_more_rounded,
        rows: [
          ResultRow(
            label: l.steelFlexuralY,
            symbol: 'λ̄y / χy',
            value: '${f3(r.lambdaY)} / ${f3(r.chiY)}',
          ),
          ResultRow(
            label: l.steelFlexuralZ,
            symbol: 'λ̄z / χz',
            value: '${f3(r.lambdaZ)} / ${f3(r.chiZ)}',
          ),
          ResultRow(
            label: l.steelCriticalMoment,
            symbol: 'Mcr',
            value: fmt(context, r.mCr),
            unit: 'kN·m',
          ),
          ResultRow(
            label: l.steelLtb,
            symbol: 'λ̄LT / χLT',
            value: '${f3(r.lambdaLT)} / ${f3(r.chiLT)}',
          ),
          ResultRow(
            label: l.steelLtbResistance,
            symbol: 'Mb,Rd',
            value: fmt(context, r.mbRd),
            unit: 'kN·m',
            emphasize: true,
          ),
          ResultRow(
            label: l.steelInteractionFactors,
            symbol: 'kyy / kzy',
            value: '${f2(r.kyy)} / ${f2(r.kzy)}',
          ),
        ],
      ),
      if (p is ISteelSection) ISectionSketch(section: p),
      ResultCard(
        title: l.steelProperties,
        icon: Icons.straighten,
        rows: [
          ResultRow(
            label: l.steelArea,
            symbol: 'A',
            value: fmt(context, p.area / 100, 1),
            unit: 'cm²',
          ),
          ResultRow(
            label: l.steelInertia,
            symbol: 'Iy / Iz',
            value:
                '${fmt(context, p.iy / 1e4, 0)} / ${fmt(context, p.iz / 1e4, 0)}',
            unit: 'cm⁴',
          ),
          ResultRow(
            label: l.steelPlasticModulus,
            symbol: 'Wpl,y',
            value: fmt(context, p.wplY / 1e3, 1),
            unit: 'cm³',
          ),
          ResultRow(
            label: l.steelMass,
            value: fmt(context, p.mass, 1),
            unit: 'kg/m',
          ),
        ],
      ),
      ChecksCard(checks: r.checks),
      NotesCard(notes: [l.steelNoteScope]),
    ];
  }
}
