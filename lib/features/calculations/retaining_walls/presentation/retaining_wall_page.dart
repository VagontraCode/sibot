import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'retaining_wall_provider.dart';

class RetainingWallPage extends ConsumerWidget {
  final String projectId;
  const RetainingWallPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(retainingWallStateProvider(projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('Retaining Wall Design'), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInputForm(context, ref, state),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: state.isLoading ? null : () => ref.read(retainingWallStateProvider(projectId).notifier).calculate(),
              icon: const Icon(Icons.calculate),
              label: Text(state.isLoading ? 'Calculating...' : 'Calculate'),
            ),
            if (state.error != null) Text(state.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 24),
            if (state.suggestions != null) _buildSuggestions(context, state.suggestions!),
            if (state.lastCalculation != null) _buildResults(context, state.lastCalculation!),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(BuildContext context, Map<String, dynamic> suggestions) {
    final cantilever = suggestions['cantilever'];
    final alternatives = suggestions['alternatives'] as List<dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pre-dimensioning (Cantilever)', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _resultRow('Rec. Base Width', '${(cantilever['baseWidth'] as double).toStringAsFixed(2)} m'),
                _resultRow('Stem Thickness', '${(cantilever['stemThickness'] as double).toStringAsFixed(0)} mm'),
                _resultRow('Footing Thickness', '${(cantilever['footingThickness'] as double).toStringAsFixed(0)} mm'),
                _resultRow('Toe / Heel', '${(cantilever['toeWidth'] as double).toStringAsFixed(2)} / ${(cantilever['heelWidth'] as double).toStringAsFixed(2)} m'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Alternative Solutions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...alternatives.map((alt) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: Icon(_getAltIcon(alt['type']), color: Colors.orange.shade700),
            title: Text(alt['type'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Rec. Base: ${(alt['recommendedBase'] as double).toStringAsFixed(2)} m'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alt['description'], style: const TextStyle(fontStyle: FontStyle.italic)),
                    const SizedBox(height: 8),
                    Text('Pros: ${alt['pros']}', style: const TextStyle(color: Colors.green, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('Cons: ${alt['cons']}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                ),
              )
            ],
          ),
        )),
      ],
    );
  }

  IconData _getAltIcon(String type) {
    if (type.contains('Gabion')) return Icons.grid_view;
    if (type.contains('Stone')) return Icons.landscape;
    if (type.contains('Blocks')) return Icons.reorder;
    return Icons.architecture;
  }

  Widget _buildInputForm(BuildContext context, WidgetRef ref, RetainingWallCalculationState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Design Parameters', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Height (m)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (v) => ref.read(retainingWallStateProvider(projectId).notifier).updateHeight(double.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Soil Density (kN/m³)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (v) => ref.read(retainingWallStateProvider(projectId).notifier).updateSoilDensity(double.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Friction Angle (deg)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (v) => ref.read(retainingWallStateProvider(projectId).notifier).updateFrictionAngle(double.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 12),
             Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Concrete (MPa)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => ref.read(retainingWallStateProvider(projectId).notifier).updateConcreteStrength(double.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Steel (MPa)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => ref.read(retainingWallStateProvider(projectId).notifier).updateSteelStrength(double.tryParse(v) ?? 0),
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
          children: [
            Text('Results', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _resultRow('FOS (Overturning)', (metadata['fos'] as double).toStringAsFixed(2)),
            _resultRow('Earth Pressure', '${(metadata['earthPressure'] as double).toStringAsFixed(1)} kN'),
            const Divider(),
            Text(calc.isValid ? 'STABLE' : 'UNSTABLE', 
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
