import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/calculations/shared/diagrams.dart';
import 'package:sibot/features/frame3d/model_link.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';
import 'beam_section_provider.dart';

class BeamSectionPage extends ConsumerWidget {
  final String projectId;
  const BeamSectionPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(beamSectionStateProvider(projectId));
    final n = ref.read(beamSectionStateProvider(projectId).notifier);
    final l = context.l10n;
    final labels = {
      'b': l.beamWidth,
      'h': l.beamDepth,
      'mSag': l.frameMaxSagging,
      'mHog': l.frameMaxHogging,
      'mEd': l.frameMaxSagging,
      'vEd': l.frameMaxShear,
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
      title: l.modBeamSection,
      subtitle: l.beamSectionSubtitle,
      module: moduleByRoute('beam-section'),
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
          children: [CodeChoice(value: s.code, onChanged: n.setCode)],
        ),
        FormSection(
          title: l.beamGeometryLoad,
          icon: Icons.crop_square,
          children: [
            FieldRow(
              children: [field('b', 'mm', '300'), field('h', 'mm', '500')],
            ),
            FieldRow(
              children: [field('mSag', 'kN·m', '120'), field('mHog', 'kN·m')],
            ),
            field('vEd', 'kN'),
            Text(l.beamSectionNote, style: context.text.bodySmall),
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
      results: s.result == null ? null : _results(context, s.result!),
    );
  }

  List<Widget> _results(BuildContext context, BeamSectionDesign r) {
    final l = context.l10n;
    return [
      VerdictBanner(checks: r.checks),
      ResultCard(
        title: l.footingReinforcement,
        icon: Icons.grid_on_rounded,
        rows: [
          ResultRow(
            label: l.resultBottomBars,
            symbol: '${fmt(context, r.asBottom, 0)} mm²',
            value: r.bottomBars?.toString() ?? '—',
            emphasize: true,
          ),
          ResultRow(
            label: l.resultTopBars,
            symbol: '${fmt(context, r.asTop, 0)} mm²',
            value: r.topBars?.toString() ?? '—',
            emphasize: true,
          ),
          ResultRow(
            label: l.resultLinks,
            value: r.shear.links?.toString() ?? '—',
          ),
        ],
      ),
      SectionSketch(
        b: r.input.b,
        h: r.input.h,
        cover: r.input.cover,
        linkDiameter: r.input.linkDiameter,
        bottom: r.bottomBars,
        top: r.topBars,
      ),
      ChecksCard(checks: r.checks),
    ];
  }
}
