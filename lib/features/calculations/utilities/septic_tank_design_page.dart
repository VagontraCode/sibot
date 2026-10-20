import 'package:flutter/material.dart';

class SepticTankDesignPage extends StatefulWidget {
  final String projectId;
  const SepticTankDesignPage({super.key, required this.projectId});

  @override
  State<SepticTankDesignPage> createState() => _SepticTankDesignPageState();
}

class _SepticTankDesignPageState extends State<SepticTankDesignPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Septic Tank Design')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tank Dimensioning',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Population Served'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Wastewater per Capita (L/day)',
              ),
              controller: TextEditingController(text: '150'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Text('Tank Type', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton(
              segments: const [
                ButtonSegment(label: Text('Single'), value: 'single'),
                ButtonSegment(label: Text('Two Chamber'), value: 'two'),
              ],
              selected: const {'two'},
              onSelectionChanged: (value) {},
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tank: 2.5×1.8×1.5m, Vol: 6.75 m³'),
                  ),
                );
              },
              child: const Text('Design Tank'),
            ),
          ],
        ),
      ),
    );
  }
}
