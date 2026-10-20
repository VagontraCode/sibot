import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/l10n/l10n.dart';
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
    final l = context.l10n;
    final m = calc?.metadata;

    return CalculatorScaffold(
      title: l.modSlab,
      subtitle: l.slabSubtitle,
      module: moduleByRoute('slab'),
      isLoading: state.isLoading,
      error: state.error,
      onCalculate: n.calculate,
      resultKey: calc?.id,
      inputs: [
        FormSection(
          title: l.slabSpanLoad,
          icon: Icons.layers_outlined,
          children: [
            NumberField(
              label: l.calcSpan,
              unit: 'm',
              hint: '4',
              value: state.span,
              onChanged: (v) => n.updateSpan(v ?? 0),
            ),
            NumberField(
              label: l.calcLoad,
              unit: 'kN/m²',
              hint: '7.5',
              value: state.load,
              onChanged: (v) => n.updateLoad(v ?? 0),
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
              ResultCard(
                title: l.slabOneWay,
                icon: Icons.layers_outlined,
                rows: [
                  ResultRow(
                    label: l.slabThickness,
                    symbol: 'h',
                    value: _f(m['recommendedDepth'], 0),
                    unit: 'mm',
                    emphasize: true,
                  ),
                  ResultRow(
                    label: l.slabDesignMoment,
                    symbol: 'MEd',
                    value: _f(m['bendingMoment'], 1),
                    unit: 'kN·m/m',
                  ),
                  ResultRow(
                    label: l.slabSteelRequired,
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
