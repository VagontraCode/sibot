import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/calculations/footings/presentation/footings_provider.dart';
import '../../../../core/models/entities.dart';

// ============ FOOTING PAGE ============



class FootingInputForm extends ConsumerWidget {
  final String projectId;
  final FootingCalculationState state;

  const FootingInputForm({
    super.key,
    required this.projectId,
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Design Parameters',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),

        // Code Selection
        _buildCodeSelector(context, ref),
        const SizedBox(height: 16),

        // Footing Type
        _buildFootingTypeSelector(context, ref),
        const SizedBox(height: 16),

        // Column Load
        _buildInputField(
          context,
          label: 'Column Load (kN)',
          value: state.columnLoad?.toString() ?? '',
          onChanged: (value) {
            ref
                .read(footingStateProvider(projectId).notifier)
                .updateColumnLoad(double.tryParse(value) ?? 0);
          },
          hint: 'e.g., 500',
        ),
        const SizedBox(height: 12),

        // Column Moment
        _buildInputField(
          context,
          label: 'Column Moment (kN.m)',
          value: state.columnMoment?.toString() ?? '',
          onChanged: (value) {
            ref
                .read(footingStateProvider(projectId).notifier)
                .updateColumnMoment(double.tryParse(value) ?? 0);
          },
          hint: 'e.g., 50',
        ),
        const SizedBox(height: 12),

        // Soil Properties
        Text('Soil Properties', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),

        _buildInputField(
          context,
          label: 'Bearing Capacity (kPa)',
          value: state.soilBearingCapacity?.toString() ?? '',
          onChanged: (value) {
            ref
                .read(footingStateProvider(projectId).notifier)
                .updateSoilBearingCapacity(double.tryParse(value) ?? 0);
          },
          hint: 'e.g., 250',
        ),
        const SizedBox(height: 12),

        _buildInputField(
          context,
          label: 'Soil Density (kN/m³)',
          value: state.soilDensity?.toString() ?? '',
          onChanged: (value) {
            ref
                .read(footingStateProvider(projectId).notifier)
                .updateSoilDensity(double.tryParse(value) ?? 0);
          },
          hint: 'e.g., 18',
        ),
        const SizedBox(height: 12),

        // Material Properties
        Text(
          'Material Properties',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),

        _buildInputField(
          context,
          label: 'Concrete Strength (fck, MPa)',
          value: state.concreteStrength?.toString() ?? '',
          onChanged: (value) {
            ref
                .read(footingStateProvider(projectId).notifier)
                .updateConcreteStrength(double.tryParse(value) ?? 0);
          },
          hint: 'e.g., 30',
        ),
        const SizedBox(height: 12),

        _buildInputField(
          context,
          label: 'Steel Strength (fy, MPa)',
          value: state.steelStrength?.toString() ?? '',
          onChanged: (value) {
            ref
                .read(footingStateProvider(projectId).notifier)
                .updateSteelStrength(double.tryParse(value) ?? 0);
          },
          hint: 'e.g., 500',
        ),
      ],
    );
  }

  Widget _buildCodeSelector(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Design Code', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(label: Text('Eurocode'), value: 'eurocode'),
            ButtonSegment(label: Text('BAEL 99'), value: 'bael99'),
          ],
          selected: {state.code},
          onSelectionChanged: (value) {
            ref
                .read(
                  footingStateProvider(
                    ref.watch(_dummyProvider as dynamic),
                  ).notifier,
                )
                .updateCode(value.first);
          },
        ),
      ],
    );
  }

  Widget _buildFootingTypeSelector(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Footing Type', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(label: Text('Isolated'), value: 'isolated'),
            ButtonSegment(label: Text('Combined'), value: 'combined'),
          ],
          selected: {state.footingType},
          onSelectionChanged: (value) {
            ref
                .read(footingStateProvider(projectId).notifier)
                .updateFootingType(value.first);
          },
        ),
      ],
    );
  }

  Widget _buildInputField(
    BuildContext context, {
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    required String hint,
  }) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.input),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      controller: TextEditingController(text: value),
    );
  }
}

final _dummyProvider = Provider((ref) => '');

class FootingResults extends StatelessWidget {
  final FootingCalculation calculation;

  const FootingResults({super.key, required this.calculation});

  @override
  Widget build(BuildContext context) {
    final metadata = calculation.metadata;
    final dimensions = metadata['dimensions'] as Map<String, dynamic>?;
    final reinforcement = metadata['reinforcement'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calculation Results',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),

        // Dimensions Card
        _buildResultCard(
          context,
          title: 'Footing Dimensions',
          children: [
            _resultRow('Length', '${dimensions?['length'] ?? 0} m'),
            _resultRow('Width', '${dimensions?['width'] ?? 0} m'),
            _resultRow('Area', '${dimensions?['area'] ?? 0} m²'),
            _resultRow('Depth', '${calculation.footingDepth ?? 0} mm'),
          ],
        ),
        const SizedBox(height: 12),

        // Area Requirements Card
        _buildResultCard(
          context,
          title: 'Area Requirements',
          children: [
            _resultRow(
              'Required Area',
              '${calculation.requiredArea?.toStringAsFixed(2) ?? 0} m²',
            ),
            _resultRow(
              'Soil Bearing Cap.',
              '${calculation.soilBearingCapacity} kPa',
            ),
            _resultRow('Column Load', '${calculation.columnLoad} kN'),
          ],
        ),
        const SizedBox(height: 12),

        // Reinforcement Card
        _buildResultCard(
          context,
          title: 'Reinforcement',
          children: [
            _resultRow(
              'Steel Area',
              '${reinforcement?['ast']?.toStringAsFixed(0) ?? 0} mm²',
            ),
            _resultRow('Bar Size', '${reinforcement?['barSize'] ?? 'N/A'}'),
            _resultRow(
              'Spacing',
              '${(reinforcement?['spacing'] as double?)?.toStringAsFixed(0) ?? 0} mm',
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Status Card
        Card(
          color: calculation.isValid
              ? Colors.green.shade50
              : Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  calculation.isValid ? Icons.check_circle : Icons.error,
                  color: calculation.isValid ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    calculation.isValid
                        ? 'Design is SAFE'
                        : 'Design requires review',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: calculation.isValid
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
