import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/app_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final calculationsAsync = ref.watch(footingCalculationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sibot Engineering'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats
            _buildStatsSection(context, projectsAsync, calculationsAsync),
            const SizedBox(height: 24),

            // Design Modules
            _buildModulesSection(context),
            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActionsSection(context),
            const SizedBox(height: 24),

            // Recent Projects
            _buildRecentProjectsSection(context, projectsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    AsyncValue<List<dynamic>> projectsAsync,
    AsyncValue<List<dynamic>> calculationsAsync,
  ) {
    final projectCount = projectsAsync.maybeWhen(
      data: (projects) => projects.length.toString(),
      orElse: () => '...',
    );

    final calculationCount = calculationsAsync.maybeWhen(
      data: (calcs) => calcs.length.toString(),
      orElse: () => '...',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Projects',
                value: projectCount,
                icon: Icons.folder,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Calculations',
                value: calculationCount,
                icon: Icons.calculate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Reports',
                value: '0',
                icon: Icons.description,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesSection(BuildContext context) {
    final modules = [
      {
        'title': 'Footing Design',
        'icon': Icons.foundation,
        'route': '/projects',
      },
      {'title': 'Beam Design', 'icon': Icons.straighten, 'route': '/projects'},
      {
        'title': 'Column Design',
        'icon': Icons.architecture,
        'route': '/projects',
      },
      {'title': 'Slab Design', 'icon': Icons.square, 'route': '/projects'},
      {
        'title': 'Retaining Wall',
        'icon': Icons.wallpaper,
        'route': '/projects',
      },
      {
        'title': 'Analysis Tools',
        'icon': Icons.analytics,
        'route': '/projects',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Design Modules',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: modules.length,
          itemBuilder: (context, index) {
            final module = modules[index];
            return Card(
              child: InkWell(
                onTap: () => context.go(module['route'] as String),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      module['icon'] as IconData,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      module['title'] as String,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.go('/projects'),
                icon: const Icon(Icons.add),
                label: const Text('New Project'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/field'),
                icon: const Icon(Icons.construction),
                label: const Text('Field Tools'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentProjectsSection(
    BuildContext context,
    AsyncValue<List<dynamic>> projectsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Projects',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        projectsAsync.when(
          data: (projects) {
            if (projects.isEmpty) {
              return const Card(
                child: ListTile(
                  title: Text('No projects yet'),
                  subtitle: Text('Create your first project to get started'),
                ),
              );
            }

            final sortedProjects =
                List.from(projects)..sort(
                  (a, b) => b.updatedAt.compareTo(a.updatedAt),
                );
            final recentProjects = sortedProjects.take(3).toList();

            return Column(
              children:
                  recentProjects
                      .map(
                        (project) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.folder),
                            title: Text(project.name),
                            subtitle: Text(project.location),
                            trailing: const Icon(Icons.arrow_forward),
                            onTap: () => context.push('/projects/${project.id}'),
                          ),
                        ),
                      )
                      .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Card(child: ListTile(title: Text('Error: $e'))),
        ),
      ],
    );
  }
}

