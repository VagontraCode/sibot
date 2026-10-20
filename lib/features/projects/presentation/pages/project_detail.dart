import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/shared/providers/app_providers.dart';
import '../../../../core/models/entities.dart';
import '../../../../core/services/report_service.dart';

class ProjectDetailPage extends ConsumerWidget {
  final String projectId;

  const ProjectDetailPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectByIdProvider(projectId));
    final calculationsAsync = ref.watch(projectCalculationsProvider(projectId));
    final photosAsync = ref.watch(photoLogsProvider(projectId));
    final punchListAsync = ref.watch(punchListProvider(projectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Hub'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: projectAsync.when(
        data: (project) {
          if (project == null) {
            return const Center(child: Text('Project not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project Header
                _buildProjectHeader(context, project),
                const SizedBox(height: 24),

                // Design Modules
                _buildDesignModulesSection(context),
                const SizedBox(height: 24),

                // Field Tools
                _buildFieldToolsSection(context, photosAsync, punchListAsync),
                const SizedBox(height: 24),

                // Calculations
                _buildCalculationsSection(context, calculationsAsync),
                const SizedBox(height: 24),

                // Quick Actions
                _buildActionsSection(context, ref, project),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildProjectHeader(BuildContext context, dynamic project) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.name,
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              project.description ?? 'No description',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.location_on, size: 16),
                  label: Text(project.location),
                ),
                const SizedBox(width: 8),
                Chip(
                  avatar: const Icon(Icons.person, size: 16),
                  label: Text(project.engineer),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesignModulesSection(BuildContext context) {
    final modules = [
      {'title': 'Footing', 'icon': Icons.foundation, 'route': 'footing'},
      {'title': 'Beam', 'icon': Icons.straighten, 'route': 'beam'},
      {'title': 'Column', 'icon': Icons.architecture, 'route': 'column'},
      {'title': 'Slab', 'icon': Icons.square, 'route': 'slab'},
      {
        'title': 'Ret. Wall',
        'icon': Icons.wallpaper,
        'route': 'retaining-wall',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Design Modules', style: Theme.of(context).textTheme.titleLarge),
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
                onTap: () =>
                    context.push('/projects/$projectId/${module['route']}'),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      module['icon'] as IconData,
                      size: 32,
                      color: Colors.blue.shade600,
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

  Widget _buildCalculationsSection(
    BuildContext context,
    AsyncValue<List<dynamic>> calculationsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Calculations', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        calculationsAsync.when(
          data: (calculations) {
            if (calculations.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No calculations yet',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: calculations
                  .map(
                    (calc) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.calculate),
                        title: Text(calc.name),
                        subtitle: Text(calc.footing),
                        trailing: Chip(
                          label: Text(calc.isValid ? 'Valid' : 'Review'),
                          backgroundColor: calc.isValid
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, st) => Center(child: Text('Error: $error')),
        ),
      ],
    );
  }

  Widget _buildFieldToolsSection(
    BuildContext context,
    AsyncValue<List<dynamic>> photosAsync,
    AsyncValue<List<dynamic>> punchListAsync,
  ) {
    final photoCount = photosAsync.maybeWhen(
      data: (d) => d.length,
      orElse: () => 0,
    );
    final openPunchCount = punchListAsync.maybeWhen(
      data: (items) => items.where((i) => i.status == 'open').length,
      orElse: () => 0,
    );

    final tools = [
      {
        'title': 'Photo Log',
        'icon': Icons.photo_library,
        'route': 'photo-log',
        'subtitle': '$photoCount photos',
        'color': Colors.blue,
      },
      {
        'title': 'Daily Report',
        'icon': Icons.assignment,
        'route': 'daily-report',
        'subtitle': 'Manage daily',
        'color': Colors.orange,
      },
      {
        'title': 'Punch List',
        'icon': Icons.checklist,
        'route': 'punch-list',
        'subtitle': '$openPunchCount pending',
        'color': Colors.red,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Field Management', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: tools
              .map(
                (tool) => Expanded(
                  child: Card(
                    child: InkWell(
                      onTap: () {
                        ProviderScope.containerOf(context)
                            .read(selectedProjectIdProvider.notifier)
                            .state = projectId;
                        context.pushNamed(
                          tool['route'] as String,
                          pathParameters: {'projectId': projectId},
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 4,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              tool['icon'] as IconData,
                              color: tool['color'] as Color,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tool['title'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              tool['subtitle'] as String,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context, WidgetRef ref, Project project) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.edit),
          label: const Text('Edit'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final footings = await ref.read(projectCalculationsProvider(projectId).future);
            final beams = await ref.read(projectBeamCalculationsProvider(projectId).future);
            final punchItems = ref.read(punchListProvider(projectId)).maybeWhen(
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
          icon: const Icon(Icons.file_download),
          label: const Text('Export'),
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.delete),
          label: const Text('Delete'),
        ),
      ],
    );
  }
}
