import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibot/features/projects/presentation/widgets/project_widgets.dart';
import 'package:sibot/features/shared/providers/app_providers.dart';
import 'package:sibot/l10n/l10n.dart';
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

    final l = context.l10n;
    return AppPage(
      title: l.navProjects,
      subtitle: l.projectsSubtitle,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
        label: Text(l.dashNewProject),
      ),
      children: [
        projectsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(Gap.xxl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => StatusBanner(
            tone: Tone.danger,
            title: l.projectsLoadError,
            message: '$e',
          ),
          data: (projects) {
            if (projects.isEmpty) {
              return EmptyState(
                icon: Icons.folder_open_outlined,
                title: l.projectsEmptyTitle,
                message: l.projectsEmptyMessage,
                action: FilledButton.icon(
                  onPressed: _create,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l.dashNewProject),
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
                  decoration: InputDecoration(
                    hintText: l.projectsSearchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: Gap.md),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final s in {
                        'all': l.statusAll,
                        'active': l.statusActive,
                        'completed': l.statusCompleted,
                        'archived': l.statusArchived,
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
                  EmptyState(
                    icon: Icons.search_off_rounded,
                    title: l.projectsNoMatch,
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
