import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/l10n/l10n.dart';
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
    final l = context.l10n;
    final m = calc?.metadata;

    return CalculatorScaffold(
      title: l.modColumn,
      subtitle: l.columnSubtitle,
      module: moduleByRoute('column'),
      isLoading: state.isLoading,
      error: state.error,
      onCalculate: n.calculate,
      resultKey: calc?.id,
      inputs: [
        FormSection(
          title: l.columnLoadGeometry,
          icon: Icons.view_column_outlined,
          children: [
            NumberField(
              label: l.columnAxialLoad,
              unit: 'kN',
              hint: '1200',
              value: state.axialLoad,
              onChanged: (v) => n.updateAxialLoad(v ?? 0),
            ),
            NumberField(
              label: l.calcHeight,
              unit: 'm',
              hint: '3',
              value: state.height,
              onChanged: (v) => n.updateHeight(v ?? 0),
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
                tone: calc.isValid ? Tone.success : Tone.warning,
                title: m['isSlender'] == true ? l.columnSlender : l.columnShort,
                message: m['isSlender'] == true
                    ? l.columnSlenderMsg
                    : l.columnShortMsg,
              ),
              ResultCard(
                title: l.columnSection,
                icon: Icons.circle_outlined,
                rows: [
                  ResultRow(
                    label: l.columnDiameter,
                    symbol: 'D',
                    value: _f(m['diameter'], 0),
                    unit: 'mm',
                    emphasize: true,
                  ),
                  ResultRow(
                    label: l.columnRequiredArea,
                    symbol: 'Ac',
                    value: _f(m['requiredArea'], 0),
                    unit: 'mm²',
                  ),
                  ResultRow(
                    label: l.columnHeightRatio,
                    value: _f(m['slenderness'], 1),
                  ),
                ],
              ),
            ],
    );
  }
}

String _f(Object? v, int digits) => v is num ? v.toStringAsFixed(digits) : '—';
