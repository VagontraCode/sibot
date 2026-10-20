import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibot/features/projects/presentation/widgets/project_widgets.dart';
import 'package:sibot/features/shared/providers/app_providers.dart';
import 'package:sibot/ui/ui.dart';

class FieldHubPage extends ConsumerWidget {
  const FieldHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = activeProject(ref);

    if (project == null) {
      return AppPage(
        title: 'Field',
        subtitle: 'Photos, daily reports and punch lists from the site.',
        children: [
          EmptyState(
            icon: Icons.construction_outlined,
            title: 'No projects yet',
            message: 'Field data is filed under a project. Create one first.',
            action: FilledButton.icon(
              onPressed: () async {
                final p = await showProjectForm(context, ref);
                if (p != null) {
                  ref.read(selectedProjectIdProvider.notifier).state = p.id;
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('New project'),
            ),
          ),
        ],
      );
    }

    final id = project.id;
    final photos = ref.watch(photoLogsProvider(id)).value?.length ?? 0;
    final reports = ref.watch(dailyReportsProvider(id)).value?.length ?? 0;
    final openPunch =
        ref
            .watch(punchListProvider(id))
            .value
            ?.where((i) => i.status != 'closed')
            .length ??
        0;

    return AppPage(
      title: 'Field',
      subtitle: 'Photos, daily reports and punch lists from the site.',
      children: [
        ProjectSwitcher(project: project),
        const SectionHeader(title: 'Tools'),
        ResponsiveGrid(
          minTileWidth: 220,
          children: [
            _ToolTile(
              icon: Icons.photo_camera_outlined,
              title: 'Photo log',
              value: '$photos',
              caption: 'photos',
              onTap: () => context.push('/field/photo-log/$id'),
            ),
            _ToolTile(
              icon: Icons.assignment_outlined,
              title: 'Daily reports',
              value: '$reports',
              caption: 'reports',
              onTap: () => context.push('/field/daily-report/$id'),
            ),
            _ToolTile(
              icon: Icons.checklist_rounded,
              title: 'Punch list',
              value: '$openPunch',
              caption: 'open items',
              onTap: () => context.push('/field/punch-list/$id'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ToolTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String caption;
  final VoidCallback onTap;

  const _ToolTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.caption,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Gap.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon, size: 44),
              const Spacer(),
              Icon(
                Icons.arrow_forward_rounded,
                color: context.colors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: Gap.xl),
          Text(title, style: context.text.titleLarge),
          const SizedBox(height: Gap.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTheme.mono(
                  context,
                  size: 18,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
              Text(caption, style: context.text.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
