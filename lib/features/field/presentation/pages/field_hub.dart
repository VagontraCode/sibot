import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibot/features/projects/presentation/widgets/project_widgets.dart';
import 'package:sibot/features/shared/providers/app_providers.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';

class FieldHubPage extends ConsumerWidget {
  const FieldHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = activeProject(ref);
    final l = context.l10n;

    if (project == null) {
      return AppPage(
        title: l.navField,
        subtitle: l.fieldSubtitle,
        children: [
          EmptyState(
            icon: Icons.construction_outlined,
            title: l.projectsEmptyTitle,
            message: l.fieldEmptyMessage,
            action: FilledButton.icon(
              onPressed: () async {
                final p = await showProjectForm(context, ref);
                if (p != null) {
                  ref.read(selectedProjectIdProvider.notifier).state = p.id;
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: Text(l.dashNewProject),
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
      title: l.navField,
      subtitle: l.fieldSubtitle,
      children: [
        ProjectSwitcher(project: project),
        SectionHeader(title: l.fieldTools),
        ResponsiveGrid(
          minTileWidth: 220,
          children: [
            _ToolTile(
              icon: Icons.photo_camera_outlined,
              title: l.photoLog,
              value: '$photos',
              caption: l.fieldPhotosCaption,
              onTap: () => context.push('/field/photo-log/$id'),
            ),
            _ToolTile(
              icon: Icons.assignment_outlined,
              title: l.reportDaily,
              value: '$reports',
              caption: l.fieldReportsCaption,
              onTap: () => context.push('/field/daily-report/$id'),
            ),
            _ToolTile(
              icon: Icons.checklist_rounded,
              title: l.punchList,
              value: '$openPunch',
              caption: l.fieldOpenItemsCaption,
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
