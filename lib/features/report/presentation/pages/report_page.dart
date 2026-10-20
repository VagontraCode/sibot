import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/report_service.dart';
import 'package:sibot/features/projects/presentation/widgets/project_widgets.dart';
import 'package:sibot/features/shared/providers/app_providers.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  Future<void> _projectSummary(WidgetRef ref, Project project) async {
    final footings = await ref.read(
      projectCalculationsProvider(project.id).future,
    );
    final beams = await ref.read(
      projectBeamCalculationsProvider(project.id).future,
    );
    final punchItems =
        ref.read(punchListProvider(project.id)).value ?? <PunchListItem>[];
    await ReportService.generateProjectSummary(
      project,
      footings: footings,
      beams: beams,
      punchList: punchItems,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = activeProject(ref);
    final l = context.l10n;

    return AppPage(
      title: l.navReports,
      subtitle: l.reportsSubtitle,
      children: [
        if (project == null)
          EmptyState(
            icon: Icons.description_outlined,
            title: l.projectsEmptyTitle,
            message: l.reportsEmptyMessage,
          )
        else ...[
          ProjectSwitcher(project: project),
          SectionHeader(title: l.reportsGenerate),
          ResponsiveGrid(
            minTileWidth: 280,
            children: [
              _ReportTile(
                icon: Icons.summarize_outlined,
                title: l.reportsSummary,
                description: l.reportsSummaryDesc,
                onTap: () => _projectSummary(ref, project),
              ),
              _ReportTile(
                icon: Icons.functions_rounded,
                title: l.reportsCalcNotes,
                description: l.reportsCalcNotesDesc,
                badge: l.commonPhase(5),
              ),
              _ReportTile(
                icon: Icons.fact_check_outlined,
                title: l.reportsFieldAudit,
                description: l.reportsFieldAuditDesc,
                badge: l.commonPlanned,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ReportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final String? badge;

  const _ReportTile({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.62,
      child: SurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(icon, tone: enabled ? Tone.primary : Tone.neutral),
                const Spacer(),
                if (badge != null)
                  StatusPill(badge!)
                else
                  Icon(
                    Icons.picture_as_pdf_outlined,
                    color: context.colors.onSurfaceVariant,
                  ),
              ],
            ),
            const SizedBox(height: Gap.lg),
            Text(title, style: context.text.titleMedium),
            const SizedBox(height: Gap.xs),
            Text(description, style: context.text.bodySmall),
          ],
        ),
      ),
    );
  }
}
