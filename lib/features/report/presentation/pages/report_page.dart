import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/shared/providers/app_providers.dart';
import '../../../../core/services/report_service.dart';
import '../../../../core/models/entities.dart';

// ============ REPORTS PAGE ============

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProjectId = ref.watch(selectedProjectIdProvider);
    final projectsAsync = ref.watch(projectsProvider);

    if (selectedProjectId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reports')),
        body: projectsAsync.when(
          data: (projects) => projects.isEmpty
              ? const Center(
                  child: Text('No projects found. Create one first.'),
                )
              : ListView.builder(
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(project.name),
                      onTap: () =>
                          ref.read(selectedProjectIdProvider.notifier).state =
                              project.id,
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      );
    }

    final projectAsync = ref.watch(projectByIdProvider(selectedProjectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () =>
                ref.read(selectedProjectIdProvider.notifier).state = null,
          ),
        ],
      ),
      body: projectAsync.when(
        data: (project) => project == null
            ? const Center(child: Text('Project not found'))
            : _buildReportList(context, ref, project),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildReportList(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(project.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          _buildReportCard(
            context,
            title: 'Full Project Summary',
            description: 'Comprehensive PDF with all design and field data',
            icon: Icons.description,
            onTap: () async {
              final footings = await ref.read(
                projectCalculationsProvider(project.id).future,
              );
              final beams = await ref.read(
                projectBeamCalculationsProvider(project.id).future,
              );
              final punchItems = ref
                  .read(punchListProvider(project.id))
                  .maybeWhen(
                    data: (items) => items,
                    orElse: () => <PunchListItem>[],
                  );

              await ReportService.generateProjectSummary(
                project,
                footings: footings,
                beams: beams,
                punchList: punchItems,
              );
            },
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            context,
            title: 'Calculation Log',
            description: 'Export design results only',
            icon: Icons.calculate,
            onTap: () => _generateReport(context, 'calculations'),
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            context,
            title: 'Field Audit',
            description: 'Export punch list and daily reports',
            icon: Icons.assignment_turned_in,
            onTap: () => _generateReport(context, 'field'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.blue.shade600),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward),
            ],
          ),
        ),
      ),
    );
  }

  void _generateReport(BuildContext context, String type) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Generating $type report...')));
  }
}
