import 'package:flutter/material.dart';

class LoadCalculatorPage extends StatefulWidget {
  final String projectId;
  const LoadCalculatorPage({super.key, required this.projectId});

  @override
  State<LoadCalculatorPage> createState() => _LoadCalculatorPageState();
}

class _LoadCalculatorPageState extends State<LoadCalculatorPage>
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
        title: const Text('Wind & Snow Loads (EC1)'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Wind Load'),
            Tab(text: 'Snow Load'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildWindLoadTab(), _buildSnowLoadTab()],
      ),
    );
  }

  Widget _buildWindLoadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Wind Speed (m/s)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(labelText: 'Height (m)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(labelText: 'Building Width (m)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wind Load = 45 kN')),
              );
            },
            child: const Text('Calculate Wind Load'),
          ),
        ],
      ),
    );
  }

  Widget _buildSnowLoadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Altitude (m)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(labelText: 'Roof Slope (°)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(labelText: 'Roof Area (m²)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Snow Load = 3.2 kN')),
              );
            },
            child: const Text('Calculate Snow Load'),
          ),
        ],
      ),
    );
  }
}
