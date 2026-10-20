import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/shared/providers/app_providers.dart';

class FieldHubPage extends ConsumerWidget {
  const FieldHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProjectId = ref.watch(selectedProjectIdProvider);
    final projectsAsync = ref.watch(projectsProvider);

    if (selectedProjectId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Field Tools'),
        ),
        body: projectsAsync.when(
          data: (projects) {
            if (projects.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.construction, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('No projects found'),
                    const SizedBox(height: 8),
                    const Text('Create a project first to use field tools'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.goNamed('projects'),
                      child: const Text('Go to Projects'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Select a project to manage field data',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      return ListTile(
                        leading: const Icon(Icons.folder),
                        title: Text(project.name),
                        subtitle: Text(project.location),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          ref.read(selectedProjectIdProvider.notifier).state = project.id;
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      );
    }

    // If project is selected, show the hub
    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Switch Project',
            onPressed: () {
              ref.read(selectedProjectIdProvider.notifier).state = null;
            },
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildHubCard(
            context,
            'Photo Log',
            Icons.photo_library,
            Colors.orange,
            () => context.pushNamed('photo-log', pathParameters: {'projectId': selectedProjectId}),
          ),
          _buildHubCard(
            context,
            'Daily Report',
            Icons.assignment,
            Colors.blue,
            () => context.pushNamed('daily-report', pathParameters: {'projectId': selectedProjectId}),
          ),
          _buildHubCard(
            context,
            'Punch List',
            Icons.checklist,
            Colors.red,
            () => context.pushNamed('punch-list', pathParameters: {'projectId': selectedProjectId}),
          ),
        ],
      ),
    );
  }

  Widget _buildHubCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
