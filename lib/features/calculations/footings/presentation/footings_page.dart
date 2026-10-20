import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/services/calculation_engine.dart';
import 'package:sibot/features/calculations/footings/presentation/footings_provider.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';

class FootingPage extends ConsumerWidget {
  final String projectId;

  const FootingPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(footingStateProvider(projectId));
    final n = ref.read(footingStateProvider(projectId).notifier);
    final calc = state.lastCalculation;
    final l = context.l10n;
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
      title: l.modFooting,
      subtitle: l.footingSubtitle,
      module: moduleByRoute('footing'),
      isLoading: state.isLoading,
      error: state.error,
      onCalculate: n.calculate,
      resultKey: calc?.id,
      inputs: [
        FormSection(
          title: l.footingDesignBasis,
          icon: Icons.rule_rounded,
          children: [
            ChoiceField<String>(
              label: l.footingCode,
              value: state.code,
              options: {'eurocode': l.codeEurocode, 'bael99': l.codeBael},
              onChanged: n.updateCode,
            ),
            ChoiceField<String>(
              label: l.footingType,
              value: state.footingType,
              options: {
                'isolated': l.footingIsolated,
                'combined': l.footingCombined,
              },
              onChanged: n.updateFootingType,
            ),
          ],
        ),
        FormSection(
          title: l.footingColumnActions,
          icon: Icons.south_rounded,
          children: [
            FieldRow(
              children: [
                NumberField(
                  label: l.footingAxialLoad,
                  unit: 'kN',
                  hint: '500',
                  value: state.columnLoad,
                  onChanged: (v) => n.updateColumnLoad(v ?? 0),
                ),
                NumberField(
                  label: l.footingMoment,
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
          title: l.footingSoil,
          icon: Icons.terrain_outlined,
          children: [
            FieldRow(
              children: [
                NumberField(
                  label: l.footingBearing,
                  unit: 'kPa',
                  hint: '250',
                  value: state.soilBearingCapacity,
                  onChanged: (v) => n.updateSoilBearingCapacity(v ?? 0),
                ),
                NumberField(
                  label: l.footingUnitWeight,
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
        if (hint != null)
          StatusBanner(
            tone: Tone.primary,
            icon: Icons.lightbulb_outline_rounded,
            title: l.footingPresizing(_f(hint['recommendedArea'], 2)),
            message: l.footingPresizingReason(
              state.code == 'eurocode' ? '3.0' : '2.5',
            ),
          ),
      ],
      results: calc == null
          ? null
          : [
              StatusBanner(
                tone: calc.isValid ? Tone.success : Tone.danger,
                title: calc.isValid ? l.footingAdequate : l.footingReview,
              ),
              ResultCard(
                title: l.footingDimensions,
                icon: Icons.crop_free_rounded,
                rows: [
                  ResultRow(
                    label: l.footingLxB,
                    symbol: 'L × B',
                    value:
                        '${_f(dims?['length'], 2)} × ${_f(dims?['width'], 2)}',
                    unit: 'm',
                    emphasize: true,
                  ),
                  ResultRow(
                    label: l.footingPlanArea,
                    symbol: 'A',
                    value: _f(dims?['area'], 2),
                    unit: 'm²',
                  ),
                  ResultRow(
                    label: l.footingRequiredArea,
                    symbol: 'Areq',
                    value: _f(calc.requiredArea, 2),
                    unit: 'm²',
                  ),
                  ResultRow(
                    label: l.footingThickness,
                    symbol: 'h',
                    value: _f(calc.footingDepth, 0),
                    unit: 'mm',
                  ),
                ],
              ),
              ResultCard(
                title: l.footingReinforcement,
                icon: Icons.grid_on_rounded,
                rows: [
                  ResultRow(
                    label: l.footingSteelArea,
                    symbol: 'As',
                    value: _f(reinf?['ast'], 0),
                    unit: 'mm²',
                    emphasize: true,
                  ),
                  ResultRow(
                    label: l.footingBarSize,
                    value: '${reinf?['barSize'] ?? '—'}',
                  ),
                  ResultRow(
                    label: l.footingSpacing,
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
