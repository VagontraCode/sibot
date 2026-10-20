import 'package:flutter/material.dart';

class StructureAnalysisPage extends StatefulWidget {
  final String projectId;
  const StructureAnalysisPage({super.key, required this.projectId});

  @override
  State<StructureAnalysisPage> createState() => _StructureAnalysisPageState();
}

class _StructureAnalysisPageState extends State<StructureAnalysisPage> {
  final heightCtrl = TextEditingController();
  final spanCtrl = TextEditingController();
  final loadCtrl = TextEditingController();
  final bayCountCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Structure Analysis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portal Frame Analysis',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInput(heightCtrl, 'Height (m)', '4'),
            _buildInput(spanCtrl, 'Span (m)', '6'),
            _buildInput(loadCtrl, 'Distributed Load (kN/m)', '25'),
            _buildInput(bayCountCtrl, 'Number of Bays', '3'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _analyze,
              child: const Text('Analyze Frame'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }

  void _analyze() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Frame analysis complete')));
  }

  @override
  void dispose() {
    heightCtrl.dispose();
    spanCtrl.dispose();
    loadCtrl.dispose();
    bayCountCtrl.dispose();
    super.dispose();
  }
}
