import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'retaining_wall_provider.dart';

class RetainingWallPage extends ConsumerWidget {
  final String projectId;
  const RetainingWallPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(retainingWallStateProvider(projectId));
    final n = ref.read(retainingWallStateProvider(projectId).notifier);
    final calc = state.lastCalculation;
    final l = context.l10n;
    final m = calc?.metadata;
    final s = state.suggestions;

    final results = <Widget>[
      if (calc != null && m != null) ...[
        StatusBanner(
          tone: calc.isValid ? Tone.success : Tone.danger,
          title: calc.isValid ? l.wallStable : l.wallOverturningRisk,
        ),
        ResultCard(
          title: l.wallStability,
          icon: Icons.balance_rounded,
          rows: [
            ResultRow(
              label: l.wallFosOverturning,
              symbol: 'FS',
              value: _f(m['fos'], 2),
              emphasize: true,
            ),
            ResultRow(
              label: l.wallActiveThrust,
              symbol: 'Pa',
              value: _f(m['earthPressure'], 1),
              unit: 'kN/m',
            ),
          ],
        ),
      ],
      if (s != null) ...[
        ResultCard(
          title: l.wallPresizing,
          icon: Icons.architecture_rounded,
          rows: [
            ResultRow(
              label: l.wallBaseWidth,
              value: _f(s['cantilever']['baseWidth'], 2),
              unit: 'm',
            ),
            ResultRow(
              label: l.wallStemThickness,
              value: _f(s['cantilever']['stemThickness'], 0),
              unit: 'mm',
            ),
            ResultRow(
              label: l.wallBaseThickness,
              value: _f(s['cantilever']['footingThickness'], 0),
              unit: 'mm',
            ),
            ResultRow(
              label: l.wallToeHeel,
              value:
                  '${_f(s['cantilever']['toeWidth'], 2)} / ${_f(s['cantilever']['heelWidth'], 2)}',
              unit: 'm',
            ),
          ],
        ),
        _Alternatives(alternatives: s['alternatives'] as List<dynamic>),
      ],
    ];

    return CalculatorScaffold(
      title: l.modRetainingWall,
      subtitle: l.wallSubtitle,
      module: moduleByRoute('retaining-wall'),
      isLoading: state.isLoading,
      error: state.error,
      onCalculate: n.calculate,
      resultKey: calc?.id,
      inputs: [
        FormSection(
          title: l.wallWallSoil,
          icon: Icons.stairs_outlined,
          children: [
            NumberField(
              label: l.wallRetainedHeight,
              unit: 'm',
              hint: '3',
              value: state.height,
              onChanged: (v) => n.updateHeight(v ?? 0),
            ),
            FieldRow(
              children: [
                NumberField(
                  label: l.wallSoilUnitWeight,
                  unit: 'kN/m³',
                  hint: '18',
                  value: state.soilDensity,
                  onChanged: (v) => n.updateSoilDensity(v ?? 0),
                ),
                NumberField(
                  label: l.wallFrictionAngle,
                  unit: '°',
                  hint: '30',
                  value: state.frictionAngle,
                  onChanged: (v) => n.updateFrictionAngle(v ?? 0),
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
      results: results.isEmpty ? null : results,
    );
  }
}

class _Alternatives extends StatelessWidget {
  final List<dynamic> alternatives;
  const _Alternatives({required this.alternatives});

  /// Localized [name, description, pros, cons] for an alternative returned
  /// by SuggestionEngine (which keys them by English type name).
  List<String> _text(BuildContext context, dynamic alt) {
    final l = context.l10n;
    final type = alt['type'] as String;
    if (type.contains('Gabion')) {
      return [
        l.wallGabion,
        l.wallGabionDesc,
        l.wallGabionPros,
        l.wallGabionCons,
      ];
    }
    if (type.contains('Stone')) {
      return [l.wallStone, l.wallStoneDesc, l.wallStonePros, l.wallStoneCons];
    }
    if (type.contains('Blocks')) {
      return [
        l.wallBlocks,
        l.wallBlocksDesc,
        l.wallBlocksPros,
        l.wallBlocksCons,
      ];
    }
    return [
      type,
      alt['description'] as String,
      alt['pros'] as String,
      alt['cons'] as String,
    ];
  }

  IconData _icon(String type) {
    if (type.contains('Gabion')) return Icons.grid_view_rounded;
    if (type.contains('Stone')) return Icons.landscape_outlined;
    if (type.contains('Blocks')) return Icons.view_agenda_outlined;
    return Icons.architecture;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.xs),
            child: Text(
              context.l10n.wallAlternatives,
              style: context.text.titleMedium,
            ),
          ),
          for (final alt in alternatives)
            ExpansionTile(
              leading: IconBadge(
                _icon(alt['type'] as String),
                tone: Tone.neutral,
                size: 36,
              ),
              title: Text(_text(context, alt)[0]),
              subtitle: Text(
                context.l10n.wallBaseApprox(_f(alt['recommendedBase'], 2)),
                style: context.text.bodySmall,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(
                Gap.lg,
                0,
                Gap.lg,
                Gap.lg,
              ),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_text(context, alt)[1], style: context.text.bodyMedium),
                const SizedBox(height: Gap.md),
                _ProCon(
                  icon: Icons.add_circle_outline,
                  color: context.appColors.success,
                  text: _text(context, alt)[2],
                ),
                const SizedBox(height: Gap.sm),
                _ProCon(
                  icon: Icons.remove_circle_outline,
                  color: context.appColors.danger,
                  text: _text(context, alt)[3],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ProCon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _ProCon({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: Gap.sm),
        Expanded(child: Text(text, style: context.text.bodySmall)),
      ],
    );
  }
}

String _f(Object? v, int digits) => v is num ? v.toStringAsFixed(digits) : '—';
