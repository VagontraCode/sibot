import 'package:flutter/material.dart';

class MaterialCalculatorPage extends StatefulWidget {
  final String projectId;
  const MaterialCalculatorPage({super.key, required this.projectId});

  @override
  State<MaterialCalculatorPage> createState() => _MaterialCalculatorPageState();
}

class _MaterialCalculatorPageState extends State<MaterialCalculatorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Calculators'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Concrete'),
            Tab(text: 'Rebar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildConcreteTab(), _buildRebarTab()],
      ),
    );
  }

  Widget _buildConcreteTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Length (m)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(labelText: 'Width (m)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(labelText: 'Height/Depth (m)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Volume: 18 m³')));
            },
            child: const Text('Calculate Volume'),
          ),
        ],
      ),
    );
  }

  Widget _buildRebarTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Number of Bars'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(labelText: 'Diameter (mm)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(labelText: 'Length (m)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Total Weight: 125 kg')),
              );
            },
            child: const Text('Calculate Weight'),
          ),
        ],
      ),
    );
  }
}
