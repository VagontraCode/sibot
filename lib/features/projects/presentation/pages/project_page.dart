import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibot/features/projects/presentation/widgets/project_widgets.dart';
import 'package:sibot/features/shared/providers/app_providers.dart';
import 'package:sibot/ui/ui.dart';

class ProjectsPage extends ConsumerStatefulWidget {
  const ProjectsPage({super.key});

  @override
  ConsumerState<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends ConsumerState<ProjectsPage> {
  String _query = '';
  String _status = 'all';

  Future<void> _create() async {
    final p = await showProjectForm(context, ref);
    if (p != null && mounted) context.push('/projects/${p.id}');
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);

    return AppPage(
      title: 'Projects',
      subtitle: 'Every calculation, photo and report, grouped by project.',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New project'),
      ),
      children: [
        projectsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(Gap.xxl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => StatusBanner(
            tone: Tone.danger,
            title: 'Could not load projects',
            message: '$e',
          ),
          data: (projects) {
            if (projects.isEmpty) {
              return EmptyState(
                icon: Icons.folder_open_outlined,
                title: 'No projects yet',
                message:
                    'Create a project to keep its calculations and field data together.',
                action: FilledButton.icon(
                  onPressed: _create,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New project'),
                ),
              );
            }

            final q = _query.toLowerCase();
            final filtered = projects.where((p) {
              final matchQ =
                  q.isEmpty ||
                  p.name.toLowerCase().contains(q) ||
                  p.location.toLowerCase().contains(q) ||
                  p.engineer.toLowerCase().contains(q);
              final matchS = _status == 'all' || p.status == _status;
              return matchQ && matchS;
            }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by name, location or engineer',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: Gap.md),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final s in const {
                        'all': 'All',
                        'active': 'Active',
                        'completed': 'Completed',
                        'archived': 'Archived',
                      }.entries)
                        Padding(
                          padding: const EdgeInsets.only(right: Gap.sm),
                          child: ChoiceChip(
                            label: Text(s.value),
                            selected: _status == s.key,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _status = s.key),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: Gap.lg),
                if (filtered.isEmpty)
                  const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No matching projects',
                  )
                else
                  ResponsiveGrid(
                    minTileWidth: 320,
                    children: [
                      for (final p in filtered)
                        ProjectCard(
                          project: p,
                          onTap: () => context.push('/projects/${p.id}'),
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
