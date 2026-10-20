import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/services/calculation_engine.dart';
import 'package:sibot/features/calculations/footings/presentation/footings_provider.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/ui/ui.dart';

class FootingPage extends ConsumerWidget {
  final String projectId;

  const FootingPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(footingStateProvider(projectId));
    final n = ref.read(footingStateProvider(projectId).notifier);
    final calc = state.lastCalculation;
    final dims = calc?.metadata['dimensions'] as Map?;
    final reinf = calc?.metadata['reinforcement'] as Map?;

    final hint =
        (state.columnLoad ?? 0) > 0 && (state.soilBearingCapacity ?? 0) > 0
        ? SuggestionEngine.suggestFooting(
            load: state.columnLoad!,
            soilBearing: state.soilBearingCapacity!,
            code: state.code,
          )
        : null;

    return CalculatorScaffold(
      title: 'Footing Design',
      subtitle: 'Pad footing under a column.',
      module: moduleByRoute('footing'),
      isLoading: state.isLoading,
      error: state.error,
      onCalculate: n.calculate,
      resultKey: calc?.id,
      inputs: [
        FormSection(
          title: 'Design basis',
          icon: Icons.rule_rounded,
          children: [
            ChoiceField<String>(
              label: 'Design code',
              value: state.code,
              options: const {'eurocode': 'Eurocode', 'bael99': 'BAEL 99'},
              onChanged: n.updateCode,
            ),
            ChoiceField<String>(
              label: 'Footing type',
              value: state.footingType,
              options: const {'isolated': 'Isolated', 'combined': 'Combined'},
              onChanged: n.updateFootingType,
            ),
          ],
        ),
        FormSection(
          title: 'Column actions',
          icon: Icons.south_rounded,
          children: [
            FieldRow(
              children: [
                NumberField(
                  label: 'Axial load',
                  unit: 'kN',
                  hint: '500',
                  value: state.columnLoad,
                  onChanged: (v) => n.updateColumnLoad(v ?? 0),
                ),
                NumberField(
                  label: 'Moment',
                  unit: 'kN·m',
                  hint: '50',
                  value: state.columnMoment,
                  onChanged: (v) => n.updateColumnMoment(v ?? 0),
                ),
              ],
            ),
          ],
        ),
        FormSection(
          title: 'Soil',
          icon: Icons.terrain_outlined,
          children: [
            FieldRow(
              children: [
                NumberField(
                  label: 'Bearing capacity',
                  unit: 'kPa',
                  hint: '250',
                  value: state.soilBearingCapacity,
                  onChanged: (v) => n.updateSoilBearingCapacity(v ?? 0),
                ),
                NumberField(
                  label: 'Unit weight',
                  unit: 'kN/m³',
                  hint: '18',
                  value: state.soilDensity,
                  onChanged: (v) => n.updateSoilDensity(v ?? 0),
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
        if (hint != null)
          StatusBanner(
            tone: Tone.primary,
            icon: Icons.lightbulb_outline_rounded,
            title:
                'Pre-sizing: about ${_f(hint['recommendedArea'], 2)} m² of footing',
            message: hint['reasoning'] as String?,
          ),
      ],
      results: calc == null
          ? null
          : [
              StatusBanner(
                tone: calc.isValid ? Tone.success : Tone.danger,
                title: calc.isValid ? 'Design adequate' : 'Design needs review',
              ),
              ResultCard(
                title: 'Dimensions',
                icon: Icons.crop_free_rounded,
                rows: [
                  ResultRow(
                    label: 'Length × width',
                    symbol: 'L × B',
                    value:
                        '${_f(dims?['length'], 2)} × ${_f(dims?['width'], 2)}',
                    unit: 'm',
                    emphasize: true,
                  ),
                  ResultRow(
                    label: 'Plan area',
                    symbol: 'A',
                    value: _f(dims?['area'], 2),
                    unit: 'm²',
                  ),
                  ResultRow(
                    label: 'Required area',
                    symbol: 'Areq',
                    value: _f(calc.requiredArea, 2),
                    unit: 'm²',
                  ),
                  ResultRow(
                    label: 'Thickness',
                    symbol: 'h',
                    value: _f(calc.footingDepth, 0),
                    unit: 'mm',
                  ),
                ],
              ),
              ResultCard(
                title: 'Reinforcement',
                icon: Icons.grid_on_rounded,
                rows: [
                  ResultRow(
                    label: 'Steel area',
                    symbol: 'As',
                    value: _f(reinf?['ast'], 0),
                    unit: 'mm²',
                    emphasize: true,
                  ),
                  ResultRow(
                    label: 'Bar size',
                    value: '${reinf?['barSize'] ?? '—'}',
                  ),
                  ResultRow(
                    label: 'Spacing',
                    symbol: 's',
                    value: _f(reinf?['spacing'], 0),
                    unit: 'mm',
                  ),
                ],
              ),
            ],
    );
  }
}

String _f(Object? v, int digits) => v is num ? v.toStringAsFixed(digits) : '—';
