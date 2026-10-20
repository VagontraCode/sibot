import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============ REFERENCE PAGE ============

class ReferencePage extends ConsumerWidget {
  const ReferencePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reference'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Steel Sections'),
                Tab(text: 'Materials'),
                Tab(text: 'Standards'),
                Tab(text: 'Tools'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildSteelSectionsTab(context),
                  _buildMaterialsTab(context),
                  _buildStandardsTab(context),
                  _buildToolsTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSteelSectionsTab(BuildContext context) {
    final sections = [
      {
        'type': 'I-Beam',
        'sizes': ['100×50', '150×75', '200×100', '250×125'],
      },
      {
        'type': 'Channel',
        'sizes': ['75×40', '100×50', '125×60', '150×75'],
      },
      {
        'type': 'Angle',
        'sizes': ['50×50', '60×60', '75×75', '100×100'],
      },
      {
        'type': 'Tube',
        'sizes': ['50×50', '75×75', '100×100', '150×150'],
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: sections
          .map(
            (section) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                title: Text(section['type'] as String),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (section['sizes'] as List<String>)
                          .map((size) => Chip(label: Text(size)))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMaterialsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMaterialCard('Concrete', 'fck = 20 to 50 MPa', Icons.extension),
        const SizedBox(height: 12),
        _buildMaterialCard(
          'Steel',
          'fy = 250 to 500 MPa',
          Icons.rounded_corner,
        ),
        const SizedBox(height: 12),
        _buildMaterialCard('Masonry', 'fm = 5 to 20 MPa', Icons.square),
        const SizedBox(height: 12),
        _buildMaterialCard('Wood', 'Grades: I to IV', Icons.mood),
      ],
    );
  }

  Widget _buildMaterialCard(String title, String subtitle, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.info_outline),
      ),
    );
  }

  Widget _buildStandardsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStandardCard('Eurocode 2', 'EN 1992-1-1', 'Concrete Design'),
        const SizedBox(height: 12),
        _buildStandardCard('Eurocode 3', 'EN 1993-1-1', 'Steel Design'),
        const SizedBox(height: 12),
        _buildStandardCard('BAEL 99', 'French Standard', 'Concrete'),
        const SizedBox(height: 12),
        _buildStandardCard('ISO 3898', 'Rebar Code', 'Reinforcement'),
      ],
    );
  }

  Widget _buildStandardCard(String code, String standard, String scope) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(code, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(standard),
            const SizedBox(height: 4),
            Text(scope, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.calculate),
          title: const Text('Unit Converter'),
          subtitle: const Text('Convert between units'),
          trailing: const Icon(Icons.arrow_forward),
          onTap: () {},
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.straighten),
          title: const Text('Section Properties'),
          subtitle: const Text('Calculate I, A, r values'),
          trailing: const Icon(Icons.arrow_forward),
          onTap: () {},
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.wind_power),
          title: const Text('Wind Load Calculator'),
          subtitle: const Text('EN 1991-1-4'),
          trailing: const Icon(Icons.arrow_forward),
          onTap: () {},
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.grain),
          title: const Text('Soil Pressure'),
          subtitle: const Text('Bearing capacity analysis'),
          trailing: const Icon(Icons.arrow_forward),
          onTap: () {},
        ),
      ],
    );
  }
}
