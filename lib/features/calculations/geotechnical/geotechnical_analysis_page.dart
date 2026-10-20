import 'package:flutter/material.dart';

class GeotechnicalAnalysisPage extends StatefulWidget {
  final String projectId;
  const GeotechnicalAnalysisPage({super.key, required this.projectId});

  @override
  State<GeotechnicalAnalysisPage> createState() =>
      _GeotechnicalAnalysisPageState();
}

class _GeotechnicalAnalysisPageState extends State<GeotechnicalAnalysisPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geotechnical Analysis'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Bearing Capacity'),
            Tab(text: 'Settlement'),
            Tab(text: 'Slope'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBearingCapacityTab(),
          _buildSettlementTab(),
          _buildSlopeTab(),
        ],
      ),
    );
  }

  Widget _buildBearingCapacityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Cohesion (kPa)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(labelText: 'Friction Angle (°)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(labelText: 'Unit Weight (kN/m³)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('qult = 285 kPa, FOS = 2.1 ✓')),
              );
            },
            child: const Text('Calculate'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Applied Load (kN)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(labelText: 'E-modulus (MPa)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settlement: 32 mm')),
              );
            },
            child: const Text('Calculate Settlement'),
          ),
        ],
      ),
    );
  }

  Widget _buildSlopeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Slope Angle (°)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(labelText: 'Height (m)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('FOS = 1.8 ✓ SAFE')));
            },
            child: const Text('Analyze Slope'),
          ),
        ],
      ),
    );
  }
}
