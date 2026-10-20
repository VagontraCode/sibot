import 'package:flutter/material.dart';

// BEAM DESIGN PAGE
class BeamPage extends StatelessWidget {
  final String projectId;
  const BeamPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beam Design'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _buildPlaceholder(context, 'Beam Design'),
    );
  }

  Widget _buildPlaceholder(BuildContext context, String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.straighten, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Coming soon with complete flexural and shear design\nper Eurocode 2 and BAEL 99',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// COLUMN DESIGN PAGE
class ColumnPage extends StatelessWidget {
  final String projectId;
  const ColumnPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Column Design'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _buildPlaceholder(context, 'Column Design'),
    );
  }

  Widget _buildPlaceholder(BuildContext context, String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.architecture, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Axial and biaxial bending with interaction diagrams',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// SLAB DESIGN PAGE
class SlabPage extends StatelessWidget {
  final String projectId;
  const SlabPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Slab Design'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _buildPlaceholder(context, 'Slab Design'),
    );
  }

  Widget _buildPlaceholder(BuildContext context, String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.square, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'One-way and two-way slab design with punching shear check',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// RETAINING WALL PAGE
class RetainingWallPage extends StatelessWidget {
  final String projectId;
  const RetainingWallPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retaining Wall Design'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _buildPlaceholder(context, 'Retaining Wall Design'),
    );
  }

  Widget _buildPlaceholder(BuildContext context, String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wallpaper, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Cantilever wall stability checks: overturning, sliding, bearing',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
