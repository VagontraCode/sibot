import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/services/calculation_engine.dart';
import 'package:sibot/features/calculations/footings/presentation/footings_provider.dart';
import 'package:sibot/features/calculations/footings/presentation/footing_input_form.dart';

class FootingPage extends ConsumerWidget {
  final String projectId;

  const FootingPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(footingStateProvider(projectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Footing Design'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Input Form
            FootingInputForm(projectId: projectId, state: state),
            const SizedBox(height: 24),

            // Suggestions
            _buildSuggestionsCard(context, ref, state),
            const SizedBox(height: 24),

            // Calculate Button
            ElevatedButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () => ref
                        .read(footingStateProvider(projectId).notifier)
                        .calculate(),
              icon: state.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.calculate),
              label: Text(state.isLoading ? 'Calculating...' : 'Calculate'),
            ),
            const SizedBox(height: 16),

            // Error Message
            if (state.error != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Results
            if (state.lastCalculation != null)
              FootingResults(calculation: state.lastCalculation!),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsCard(
    BuildContext context,
    WidgetRef ref,
    FootingCalculationState state,
  ) {
    if (state.columnLoad == null || state.soilBearingCapacity == null) {
      return const SizedBox.shrink();
    }

    final suggestions = SuggestionEngine.suggestFooting(
      load: state.columnLoad!,
      soilBearing: state.soilBearingCapacity!,
      code: state.code,
    );

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Design Suggestions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${suggestions['reasoning']}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Recommended Area: ${(suggestions['recommendedArea'] as double).toStringAsFixed(2)} m²',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
