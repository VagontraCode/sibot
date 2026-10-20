import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'beams_provider.dart';

class BeamPage extends ConsumerWidget {
  final String projectId;
  const BeamPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(beamStateProvider(projectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beam Design'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInputForm(context, ref, state),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: state.isLoading ? null : () => ref.read(beamStateProvider(projectId).notifier).calculate(),
              icon: const Icon(Icons.calculate),
              label: Text(state.isLoading ? 'Calculating...' : 'Calculate'),
            ),
            if (state.error != null) ...[
              const SizedBox(height: 16),
              Text(state.error!, style: const TextStyle(color: Colors.red)),
            ],
            if (state.lastCalculation != null) ...[
              const SizedBox(height: 24),
              _buildResults(context, state.lastCalculation!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputForm(BuildContext context, WidgetRef ref, BeamCalculationState state) {
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
              onChanged: (v) => ref.read(beamStateProvider(projectId).notifier).updateSpan(double.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Total Load (kN/m)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (v) => ref.read(beamStateProvider(projectId).notifier).updateLoad(double.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Width (mm)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => ref.read(beamStateProvider(projectId).notifier).updateWidth(double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Depth (mm)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => ref.read(beamStateProvider(projectId).notifier).updateDepth(double.tryParse(v) ?? 0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
             Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Concrete (MPa)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => ref.read(beamStateProvider(projectId).notifier).updateConcreteStrength(double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Steel (MPa)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => ref.read(beamStateProvider(projectId).notifier).updateSteelStrength(double.tryParse(v) ?? 0),
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
      color: calc.isValid ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Results', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _resultRow('Steel Area Required', '${(metadata['ast'] as double).toStringAsFixed(0)} mm²'),
            _resultRow('Recommended Bars', '${metadata['barNumber']}x ${metadata['barSize']}'),
            _resultRow('Lever Arm (z)', '${(metadata['z'] as double).toStringAsFixed(1)} mm'),
            const Divider(),
            Text(calc.isValid ? 'DESIGN IS SAFE' : 'DESIGN UNSAFE', 
              style: TextStyle(fontWeight: FontWeight.bold, color: calc.isValid ? Colors.green.shade700 : Colors.red.shade700)),
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
