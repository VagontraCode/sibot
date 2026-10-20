import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/ui/ui.dart';
import 'columns_provider.dart';

class ColumnPage extends ConsumerWidget {
  final String projectId;
  const ColumnPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(columnStateProvider(projectId));
    final n = ref.read(columnStateProvider(projectId).notifier);
    final calc = state.lastCalculation;
    final m = calc?.metadata;

    return CalculatorScaffold(
      title: 'Column Design',
      subtitle: 'Circular column under axial load.',
      module: moduleByRoute('column'),
      isLoading: state.isLoading,
      error: state.error,
      onCalculate: n.calculate,
      resultKey: calc?.id,
      inputs: [
        FormSection(
          title: 'Load & geometry',
          icon: Icons.view_column_outlined,
          children: [
            NumberField(
              label: 'Axial load',
              unit: 'kN',
              hint: '1200',
              value: state.axialLoad,
              onChanged: (v) => n.updateAxialLoad(v ?? 0),
            ),
            NumberField(
              label: 'Height',
              unit: 'm',
              hint: '3',
              value: state.height,
              onChanged: (v) => n.updateHeight(v ?? 0),
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
                tone: calc.isValid ? Tone.success : Tone.warning,
                title: m['isSlender'] == true
                    ? 'Slender column'
                    : 'Short column',
                message: m['isSlender'] == true
                    ? 'Second-order effects must be checked.'
                    : 'Second-order effects can be neglected.',
              ),
              ResultCard(
                title: 'Section',
                icon: Icons.circle_outlined,
                rows: [
                  ResultRow(
                    label: 'Recommended diameter',
                    symbol: 'D',
                    value: _f(m['diameter'], 0),
                    unit: 'mm',
                    emphasize: true,
                  ),
                  ResultRow(
                    label: 'Required area',
                    symbol: 'Ac',
                    value: _f(m['requiredArea'], 0),
                    unit: 'mm²',
                  ),
                  ResultRow(
                    label: 'Height / diameter',
                    value: _f(m['slenderness'], 1),
                  ),
                ],
              ),
            ],
    );
  }
}

String _f(Object? v, int digits) => v is num ? v.toStringAsFixed(digits) : '—';
