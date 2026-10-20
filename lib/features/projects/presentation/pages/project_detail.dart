import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/report_service.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/features/modules/module_tile.dart';
import 'package:sibot/features/projects/presentation/widgets/project_widgets.dart';
import 'package:sibot/features/shared/providers/app_providers.dart';
import 'package:sibot/features/shared/providers/calculation_summary_provider.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';

class ProjectDetailPage extends ConsumerWidget {
  final String projectId;

  const ProjectDetailPage({super.key, required this.projectId});

  Future<void> _export(WidgetRef ref, Project project) async {
    final footings = await ref.read(
      projectCalculationsProvider(projectId).future,
    );
    final beams = await ref.read(
      projectBeamCalculationsProvider(projectId).future,
    );
    final punchItems =
        ref.read(punchListProvider(projectId)).value ?? <PunchListItem>[];
    await ReportService.generateProjectSummary(
      project,
      footings: footings,
      beams: beams,
      punchList: punchItems,
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.projectDeleteTitle),
        content: Text(context.l10n.projectDeleteMessage(project.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.appColors.danger,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(projectsProvider.notifier).deleteProject(project.id);
    if (context.mounted) context.go('/projects');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectByIdProvider(projectId));

    return projectAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => AppPage(
        title: context.l10n.commonProject,
        children: [
          StatusBanner(
            tone: Tone.danger,
            title: context.l10n.projectLoadError,
            message: '$e',
          ),
        ],
      ),
      data: (project) {
        if (project == null) {
          return AppPage(
            title: context.l10n.commonProject,
            children: [
              EmptyState(
                icon: Icons.folder_off_outlined,
                title: context.l10n.projectNotFound,
                message: context.l10n.projectNotFoundMessage,
              ),
            ],
          );
        }
        return _ProjectView(
          project: project,
          onEdit: () => showProjectForm(context, ref, existing: project),
          onExport: () => _export(ref, project),
          onDelete: () => _delete(context, ref, project),
        );
      },
    );
  }
}

class _ProjectView extends ConsumerWidget {
  final Project project;
  final VoidCallback onEdit;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  const _ProjectView({
    required this.project,
    required this.onEdit,
    required this.onExport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = project.id;
    final calcs = ref.watch(projectCalcSummariesProvider(id));
    final photos = ref.watch(photoLogsProvider(id)).value?.length ?? 0;
    final openPunch =
        ref
            .watch(punchListProvider(id))
            .value
            ?.where((i) => i.status != 'closed')
            .length ??
        0;
    final reports = ref.watch(dailyReportsProvider(id)).value?.length ?? 0;
    final available = modules.where((m) => m.isAvailable).toList();
    final l = context.l10n;

    final designPane = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l.projectDesignModules),
        ResponsiveGrid(
          minTileWidth: 150,
          children: [
            for (final m in available)
              ModuleTile(
                module: m,
                onOpen: () => context.push('/projects/$id/${m.route}'),
              ),
          ],
        ),
      ],
    );

    final sidePane = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l.projectField),
        Card(
          child: Column(
            children: [
              _FieldRow(
                icon: Icons.photo_camera_outlined,
                title: l.photoLog,
                detail: l.countPhotos(photos),
                onTap: () => context.push('/projects/$id/photo-log'),
              ),
              const Divider(),
              _FieldRow(
                icon: Icons.assignment_outlined,
                title: l.reportDaily,
                detail: l.countReports(reports),
                onTap: () => context.push('/projects/$id/daily-report'),
              ),
              const Divider(),
              _FieldRow(
                icon: Icons.checklist_rounded,
                title: l.punchList,
                detail: l.countOpen(openPunch),
                onTap: () => context.push('/projects/$id/punch-list'),
              ),
            ],
          ),
        ),
        SectionHeader(title: l.projectCalculations),
        calcs.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => StatusBanner(
            tone: Tone.danger,
            title: l.projectCalcLoadError,
            message: '$e',
          ),
          data: (list) => list.isEmpty
              ? EmptyState(
                  icon: Icons.functions_rounded,
                  title: l.projectCalcEmptyTitle,
                  message: l.projectCalcEmptyMessage,
                )
              : Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < list.length; i++) ...[
                        if (i > 0) const Divider(),
                        ListTile(
                          leading: IconBadge(
                            list[i].icon,
                            tone: Tone.neutral,
                            size: 36,
                          ),
                          title: Text(
                            moduleById(list[i].moduleId)?.title(l) ??
                                list[i].moduleId,
                          ),
                          subtitle: Text(
                            relativeDate(context, list[i].createdAt),
                          ),
                          trailing: StatusPill(
                            list[i].isValid ? l.commonOk : l.commonReview,
                            tone: list[i].isValid ? Tone.success : Tone.warning,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );

    return AppPage(
      title: project.name,
      actions: [
        IconButton(
          tooltip: l.projectExportPdf,
          onPressed: onExport,
          icon: const Icon(Icons.ios_share_rounded),
        ),
        PopupMenuButton<String>(
          tooltip: l.commonMore,
          onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text(l.projectEdit),
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline),
                title: Text(l.projectDelete),
              ),
            ),
          ],
        ),
      ],
      header: _ProjectHeader(project: project, onEdit: onEdit),
      children: [
        AdaptiveSplit(
          primaryFlex: 7,
          secondaryFlex: 5,
          primary: designPane,
          secondary: sidePane,
        ),
      ],
    );
  }
}

class _ProjectHeader extends StatelessWidget {
  final Project project;
  final VoidCallback onEdit;

  const _ProjectHeader({required this.project, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final big = !context.isCompact;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ProjectAvatar(project.name, size: big ? 64 : 52),
            const SizedBox(width: Gap.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusPill(
                    context.l10n.projectStatus(project.status),
                    tone: projectStatusTone(project.status),
                  ),
                  const SizedBox(height: Gap.sm),
                  Text(
                    project.name,
                    style: big
                        ? context.text.displaySmall
                        : context.text.headlineMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (project.description.isNotEmpty) ...[
          const SizedBox(height: Gap.lg),
          Text(
            project.description,
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: Gap.lg),
        Wrap(
          spacing: Gap.lg,
          runSpacing: Gap.sm,
          children: [
            if (project.location.isNotEmpty)
              _Meta(Icons.place_outlined, project.location),
            if (project.engineer.isNotEmpty)
              _Meta(Icons.person_outline, project.engineer),
            _Meta(
              Icons.schedule_rounded,
              context.l10n.timeUpdated(
                relativeDate(context, project.updatedAt),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Meta(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: context.colors.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(label, style: context.text.bodySmall),
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  const _FieldRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: IconBadge(icon, size: 36),
      title: Text(title),
      subtitle: Text(detail),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
