import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'slabs_provider.dart';

class SlabPage extends ConsumerWidget {
  final String projectId;
  const SlabPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(slabStateProvider(projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('Slab Design'), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInputForm(context, ref, state),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: state.isLoading ? null : () => ref.read(slabStateProvider(projectId).notifier).calculate(),
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

  Widget _buildInputForm(BuildContext context, WidgetRef ref, SlabCalculationState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Design Parameters', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Span (m)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (v) => ref.read(slabStateProvider(projectId).notifier).updateSpan(double.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Load (kN/m²)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (v) => ref.read(slabStateProvider(projectId).notifier).updateLoad(double.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 12),
             Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Concrete (MPa)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => ref.read(slabStateProvider(projectId).notifier).updateConcreteStrength(double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Steel (MPa)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => ref.read(slabStateProvider(projectId).notifier).updateSteelStrength(double.tryParse(v) ?? 0),
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
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Results', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _resultRow('Rec. Depth', '${metadata['recommendedDepth']} mm'),
            _resultRow('Steel Req.', '${(metadata['ast_per_m'] as double).toStringAsFixed(0)} mm²/m'),
            _resultRow('Bending Moment', '${(metadata['bendingMoment'] as double).toStringAsFixed(1)} kN.m'),
            const Divider(),
            const Text('ONE-WAY SLAB DESIGN', style: TextStyle(fontWeight: FontWeight.bold)),
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
