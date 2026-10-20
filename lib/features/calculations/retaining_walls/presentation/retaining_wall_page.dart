import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/modules/module_registry.dart';
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
    final m = calc?.metadata;
    final s = state.suggestions;

    final results = <Widget>[
      if (calc != null && m != null) ...[
        StatusBanner(
          tone: calc.isValid ? Tone.success : Tone.danger,
          title: calc.isValid
              ? 'Stable against overturning'
              : 'Overturning risk',
        ),
        ResultCard(
          title: 'Stability',
          icon: Icons.balance_rounded,
          rows: [
            ResultRow(
              label: 'Factor of safety, overturning',
              symbol: 'FS',
              value: _f(m['fos'], 2),
              emphasize: true,
            ),
            ResultRow(
              label: 'Active earth thrust',
              symbol: 'Pa',
              value: _f(m['earthPressure'], 1),
              unit: 'kN/m',
            ),
          ],
        ),
      ],
      if (s != null) ...[
        ResultCard(
          title: 'Pre-sizing (cantilever wall)',
          icon: Icons.architecture_rounded,
          rows: [
            ResultRow(
              label: 'Base width',
              value: _f(s['cantilever']['baseWidth'], 2),
              unit: 'm',
            ),
            ResultRow(
              label: 'Stem thickness',
              value: _f(s['cantilever']['stemThickness'], 0),
              unit: 'mm',
            ),
            ResultRow(
              label: 'Base thickness',
              value: _f(s['cantilever']['footingThickness'], 0),
              unit: 'mm',
            ),
            ResultRow(
              label: 'Toe / heel',
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
      title: 'Retaining Wall',
      subtitle: 'Cantilever wall: overturning check and pre-sizing.',
      module: moduleByRoute('retaining-wall'),
      isLoading: state.isLoading,
      error: state.error,
      onCalculate: n.calculate,
      resultKey: calc?.id,
      inputs: [
        FormSection(
          title: 'Wall & soil',
          icon: Icons.stairs_outlined,
          children: [
            NumberField(
              label: 'Retained height',
              unit: 'm',
              hint: '3',
              value: state.height,
              onChanged: (v) => n.updateHeight(v ?? 0),
            ),
            FieldRow(
              children: [
                NumberField(
                  label: 'Soil unit weight',
                  unit: 'kN/m³',
                  hint: '18',
                  value: state.soilDensity,
                  onChanged: (v) => n.updateSoilDensity(v ?? 0),
                ),
                NumberField(
                  label: 'Friction angle φ',
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
      results: results.isEmpty ? null : results,
    );
  }
}

class _Alternatives extends StatelessWidget {
  final List<dynamic> alternatives;
  const _Alternatives({required this.alternatives});

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
              'Alternative wall types',
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
              title: Text(alt['type'] as String),
              subtitle: Text(
                'Base ≈ ${_f(alt['recommendedBase'], 2)} m',
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
                Text(
                  alt['description'] as String,
                  style: context.text.bodyMedium,
                ),
                const SizedBox(height: Gap.md),
                _ProCon(
                  icon: Icons.add_circle_outline,
                  color: context.appColors.success,
                  text: alt['pros'] as String,
                ),
                const SizedBox(height: Gap.sm),
                _ProCon(
                  icon: Icons.remove_circle_outline,
                  color: context.appColors.danger,
                  text: alt['cons'] as String,
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
