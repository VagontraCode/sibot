import 'package:flutter/material.dart';

// ============ PILE SLAB PAGE ============

class PileSlabPage extends StatefulWidget {
  final String projectId;
  const PileSlabPage({super.key, required this.projectId});

  @override
  State<PileSlabPage> createState() => _PileSlabPageState();
}

class _PileSlabPageState extends State<PileSlabPage> {
  final slabLoadCtrl = TextEditingController();
  final pileCapacityCtrl = TextEditingController();
  final spacingCtrl = TextEditingController();
  final depthCtrl = TextEditingController();
  final concreteCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pile Slab Design'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Slab & Pile Parameters',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInput(slabLoadCtrl, 'Slab Load (kN/m²)', '10'),
            _buildInput(pileCapacityCtrl, 'Pile Capacity (kN)', '500'),
            _buildInput(spacingCtrl, 'Pile Spacing (m)', '3'),
            _buildInput(depthCtrl, 'Cap Thickness (mm)', '600'),
            _buildInput(concreteCtrl, 'Concrete (fck MPa)', '30'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _calculate,
              child: const Text('Calculate'),
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

  void _calculate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pile slab analysis: Piles required: 4')),
    );
  }

  @override
  void dispose() {
    slabLoadCtrl.dispose();
    pileCapacityCtrl.dispose();
    spacingCtrl.dispose();
    depthCtrl.dispose();
    concreteCtrl.dispose();
    super.dispose();
  }
}
