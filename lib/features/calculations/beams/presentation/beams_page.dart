import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/modules/module_registry.dart';
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
    final m = calc?.metadata;

    return CalculatorScaffold(
      title: 'Beam Design',
      subtitle: 'Simply supported beam under a uniform load.',
      module: moduleByRoute('beam'),
      isLoading: state.isLoading,
      error: state.error,
      onCalculate: n.calculate,
      resultKey: calc?.id,
      inputs: [
        FormSection(
          title: 'Geometry & load',
          icon: Icons.straighten,
          children: [
            NumberField(
              label: 'Span',
              unit: 'm',
              hint: '6',
              value: state.span,
              onChanged: (v) => n.updateSpan(v ?? 0),
            ),
            NumberField(
              label: 'Total design load',
              unit: 'kN/m',
              hint: '25',
              value: state.load,
              onChanged: (v) => n.updateLoad(v ?? 0),
            ),
            FieldRow(
              children: [
                NumberField(
                  label: 'Width b',
                  unit: 'mm',
                  hint: '250',
                  value: state.width,
                  onChanged: (v) => n.updateWidth(v ?? 0),
                ),
                NumberField(
                  label: 'Depth h',
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
          title: 'Materials',
          icon: Icons.science_outlined,
          children: [
            FieldRow(
              children: [
                NumberField(
                  label: 'Concrete fck',
                  unit: 'MPa',
                  hint: '25',
                  value: state.concreteStrength,
                  onChanged: (v) => n.updateConcreteStrength(v ?? 0),
                ),
                NumberField(
                  label: 'Steel fyk',
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
                title: calc.isValid ? 'Section adequate' : 'Section inadequate',
                message: calc.isValid
                    ? 'Bending reinforcement found for the design moment.'
                    : 'Increase the section or the concrete class.',
              ),
              ResultCard(
                title: 'Bending reinforcement',
                icon: Icons.linear_scale_rounded,
                rows: [
                  ResultRow(
                    label: 'Steel area required',
                    symbol: 'As',
                    value: _f(m['ast'], 0),
                    unit: 'mm²',
                    emphasize: true,
                  ),
                  ResultRow(
                    label: 'Suggested bars',
                    value: '${m['barNumber']} × ${m['barSize']}',
                  ),
                  ResultRow(
                    label: 'Lever arm',
                    symbol: 'z',
                    value: _f(m['z'], 1),
                    unit: 'mm',
                  ),
                  ResultRow(
                    label: 'Moment ratio',
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
