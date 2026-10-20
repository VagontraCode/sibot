import 'package:flutter/material.dart';

class SectionPropertiesPage extends StatefulWidget {
  final String projectId;
  const SectionPropertiesPage({super.key, required this.projectId});

  @override
  State<SectionPropertiesPage> createState() => _SectionPropertiesPageState();
}

class _SectionPropertiesPageState extends State<SectionPropertiesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedSection = 'rectangular';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Section Properties Calculator'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Rectangular'),
            Tab(text: 'Circular'),
            Tab(text: 'I-Beam'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRectangularTab(),
          _buildCircularTab(),
          _buildIBeamTab(),
        ],
      ),
    );
  }

  Widget _buildRectangularTab() {
    final widthCtrl = TextEditingController();
    final depthCtrl = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: widthCtrl,
            decoration: const InputDecoration(labelText: 'Width (mm)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: depthCtrl,
            decoration: const InputDecoration(labelText: 'Depth (mm)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Area calculated')));
            },
            child: const Text('Calculate Properties'),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Diameter (mm)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Circular properties calculated')),
              );
            },
            child: const Text('Calculate'),
          ),
        ],
      ),
    );
  }

  Widget _buildIBeamTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Web Height (mm)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(labelText: 'Flange Width (mm)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Flange Thickness (mm)',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(labelText: 'Web Thickness (mm)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('I-beam properties calculated')),
              );
            },
            child: const Text('Calculate I-Beam Properties'),
          ),
        ],
      ),
    );
  }
}
