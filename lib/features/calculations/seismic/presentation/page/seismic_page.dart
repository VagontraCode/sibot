import 'package:flutter/material.dart';

class SeismicAnalysisPage extends StatefulWidget {
  final String projectId;
  const SeismicAnalysisPage({super.key, required this.projectId});

  @override
  State<SeismicAnalysisPage> createState() => _SeismicAnalysisPageState();
}

class _SeismicAnalysisPageState extends State<SeismicAnalysisPage> {
  String selectedSoil = 'B';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seismic Analysis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EC8 Seismic Design',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Building Mass (t)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Peak Ground Accel. (g)',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            Text('Soil Type', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton(
              segments: const [
                ButtonSegment(label: Text('A'), value: 'A'),
                ButtonSegment(label: Text('B'), value: 'B'),
                ButtonSegment(label: Text('C'), value: 'C'),
                ButtonSegment(label: Text('D'), value: 'D'),
              ],
              selected: {selectedSoil},
              onSelectionChanged: (value) {
                setState(() => selectedSoil = value.first);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Base Shear = 250 kN (Spectrum Analysis)'),
                  ),
                );
              },
              child: const Text('Analyze Seismic'),
            ),
          ],
        ),
      ),
    );
  }
}
