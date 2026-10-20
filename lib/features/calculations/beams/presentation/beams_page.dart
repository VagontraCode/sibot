import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'beams_provider.dart';

class BeamPage extends ConsumerWidget {
  final String projectId;
  const BeamPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(beamStateProvider(projectId));
    final n = ref.read(beamStateProvider(projectId).notifier);
    final calc = state.lastCalculation;
    final l = context.l10n;
    final m = calc?.metadata;

    return CalculatorScaffold(
      title: l.modBeam,
      subtitle: l.beamSubtitle,
      module: moduleByRoute('beam'),
      isLoading: state.isLoading,
      error: state.error,
      onCalculate: n.calculate,
      resultKey: calc?.id,
      inputs: [
        FormSection(
          title: l.beamGeometryLoad,
          icon: Icons.straighten,
          children: [
            NumberField(
              label: l.calcSpan,
              unit: 'm',
              hint: '6',
              value: state.span,
              onChanged: (v) => n.updateSpan(v ?? 0),
            ),
            NumberField(
              label: l.beamTotalLoad,
              unit: 'kN/m',
              hint: '25',
              value: state.load,
              onChanged: (v) => n.updateLoad(v ?? 0),
            ),
            FieldRow(
              children: [
                NumberField(
                  label: l.beamWidth,
                  unit: 'mm',
                  hint: '250',
                  value: state.width,
                  onChanged: (v) => n.updateWidth(v ?? 0),
                ),
                NumberField(
                  label: l.beamDepth,
                  unit: 'mm',
                  hint: '500',
                  value: state.depth,
                  onChanged: (v) => n.updateDepth(v ?? 0),
                ),
              ],
            ),
          ],
        ),
        FormSection(
          title: l.calcMaterials,
          icon: Icons.science_outlined,
          children: [
            FieldRow(
              children: [
                NumberField(
                  label: l.calcConcreteFck,
                  unit: 'MPa',
                  hint: '25',
                  value: state.concreteStrength,
                  onChanged: (v) => n.updateConcreteStrength(v ?? 0),
                ),
                NumberField(
                  label: l.calcSteelFyk,
                  unit: 'MPa',
                  hint: '500',
                  value: state.steelStrength,
                  textInputAction: TextInputAction.done,
                  onChanged: (v) => n.updateSteelStrength(v ?? 0),
                ),
              ],
            ),
          ],
        ),
      ],
      results: calc == null || m == null
          ? null
          : [
              StatusBanner(
                tone: calc.isValid ? Tone.success : Tone.danger,
                title: calc.isValid ? l.beamAdequate : l.beamInadequate,
                message: calc.isValid ? l.beamAdequateMsg : l.beamInadequateMsg,
              ),
              ResultCard(
                title: l.beamBending,
                icon: Icons.linear_scale_rounded,
                rows: [
                  ResultRow(
                    label: l.beamSteelRequired,
                    symbol: 'As',
                    value: _f(m['ast'], 0),
                    unit: 'mm²',
                    emphasize: true,
                  ),
                  ResultRow(
                    label: l.beamSuggestedBars,
                    value: '${m['barNumber']} × ${m['barSize']}',
                  ),
                  ResultRow(
                    label: l.beamLeverArm,
                    symbol: 'z',
                    value: _f(m['z'], 1),
                    unit: 'mm',
                  ),
                  ResultRow(
                    label: l.beamMomentRatio,
                    symbol: 'K',
                    value: _f(m['k'], 3),
                  ),
                ],
              ),
            ],
    );
  }
}

String _f(Object? v, int digits) => v is num ? v.toStringAsFixed(digits) : '—';
