import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/ui/ui.dart';
import 'slabs_provider.dart';

class SlabPage extends ConsumerWidget {
  final String projectId;
  const SlabPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(slabStateProvider(projectId));
    final n = ref.read(slabStateProvider(projectId).notifier);
    final calc = state.lastCalculation;
    final m = calc?.metadata;

    return CalculatorScaffold(
      title: 'Slab Design',
      subtitle: 'One-way slab, simply supported.',
      module: moduleByRoute('slab'),
      isLoading: state.isLoading,
      error: state.error,
      onCalculate: n.calculate,
      resultKey: calc?.id,
      inputs: [
        FormSection(
          title: 'Span & load',
          icon: Icons.layers_outlined,
          children: [
            NumberField(
              label: 'Span',
              unit: 'm',
              hint: '4',
              value: state.span,
              onChanged: (v) => n.updateSpan(v ?? 0),
            ),
            NumberField(
              label: 'Load',
              unit: 'kN/m²',
              hint: '7.5',
              value: state.load,
              onChanged: (v) => n.updateLoad(v ?? 0),
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
              ResultCard(
                title: 'One-way slab',
                icon: Icons.layers_outlined,
                rows: [
                  ResultRow(
                    label: 'Recommended thickness',
                    symbol: 'h',
                    value: _f(m['recommendedDepth'], 0),
                    unit: 'mm',
                    emphasize: true,
                  ),
                  ResultRow(
                    label: 'Design moment',
                    symbol: 'MEd',
                    value: _f(m['bendingMoment'], 1),
                    unit: 'kN·m/m',
                  ),
                  ResultRow(
                    label: 'Steel required',
                    symbol: 'As',
                    value: _f(m['ast_per_m'], 0),
                    unit: 'mm²/m',
                    emphasize: true,
                  ),
                ],
              ),
            ],
    );
  }
}

String _f(Object? v, int digits) => v is num ? v.toStringAsFixed(digits) : '—';
