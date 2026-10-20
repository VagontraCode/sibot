import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/report_service.dart';
import 'package:sibot/features/projects/presentation/widgets/project_widgets.dart';
import 'package:sibot/features/shared/providers/app_providers.dart';
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

    return AppPage(
      title: 'Reports',
      subtitle: 'PDF calculation notes and site records.',
      children: [
        if (project == null)
          const EmptyState(
            icon: Icons.description_outlined,
            title: 'No projects yet',
            message: 'Reports are generated per project.',
          )
        else ...[
          ProjectSwitcher(project: project),
          const SectionHeader(title: 'Generate'),
          ResponsiveGrid(
            minTileWidth: 280,
            children: [
              _ReportTile(
                icon: Icons.summarize_outlined,
                title: 'Project summary',
                description:
                    'Footing and beam calculations, and the punch list, in one PDF.',
                onTap: () => _projectSummary(ref, project),
              ),
              const _ReportTile(
                icon: Icons.functions_rounded,
                title: 'Calculation notes',
                description:
                    'Formulas, code clauses and diagrams for each module.',
                badge: 'Phase 5',
              ),
              const _ReportTile(
                icon: Icons.fact_check_outlined,
                title: 'Field audit',
                description: 'Daily reports, photos and punch list.',
                badge: 'Planned',
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
