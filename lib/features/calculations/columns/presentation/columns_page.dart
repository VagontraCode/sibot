import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'columns_provider.dart';

class ColumnPage extends ConsumerWidget {
  final String projectId;
  const ColumnPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(columnStateProvider(projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('Column Design'), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInputForm(context, ref, state),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: state.isLoading ? null : () => ref.read(columnStateProvider(projectId).notifier).calculate(),
              icon: const Icon(Icons.calculate),
              label: Text(state.isLoading ? 'Calculating...' : 'Calculate'),
            ),
            if (state.error != null) Text(state.error!, style: const TextStyle(color: Colors.red)),
            if (state.lastCalculation != null) _buildResults(context, state.lastCalculation!),
          ],
        ),
      ),
    );
  }

  Widget _buildInputForm(BuildContext context, WidgetRef ref, ColumnCalculationState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Design Parameters', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Axial Load (kN)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (v) => ref.read(columnStateProvider(projectId).notifier).updateAxialLoad(double.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Height (m)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (v) => ref.read(columnStateProvider(projectId).notifier).updateHeight(double.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 12),
             Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Concrete (MPa)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => ref.read(columnStateProvider(projectId).notifier).updateConcreteStrength(double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Steel (MPa)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => ref.read(columnStateProvider(projectId).notifier).updateSteelStrength(double.tryParse(v) ?? 0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, dynamic calc) {
    final metadata = calc.metadata;
    return Card(
      color: calc.isValid ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Results', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _resultRow('Rec. Diameter', '${metadata['diameter']} mm'),
            _resultRow('Slenderness', (metadata['slenderness'] as double).toStringAsFixed(1)),
            _resultRow('Status', metadata['isSlender'] ? 'SLENDER' : 'SHORT'),
            const Divider(),
            Text(calc.isValid ? 'COLUMN IS SAFE' : 'REQUIRES SLENDERNESS ANALYSIS', 
              style: TextStyle(fontWeight: FontWeight.bold, color: calc.isValid ? Colors.green.shade700 : Colors.orange.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))],
      ),
    );
  }
}
