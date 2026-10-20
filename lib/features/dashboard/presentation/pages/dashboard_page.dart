import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/features/modules/module_tile.dart';
import 'package:sibot/features/projects/presentation/widgets/project_widgets.dart';
import 'package:sibot/features/shared/providers/app_providers.dart';
import 'package:sibot/features/shared/providers/calculation_summary_provider.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  Future<void> _openModule(
    BuildContext context,
    WidgetRef ref,
    EngModule module,
  ) async {
    final id = await showProjectPicker(
      context,
      ref,
      title: context.l10n.dashOpenModuleIn(module.title(context.l10n)),
    );
    if (id != null && context.mounted) {
      context.go('/projects/$id/${module.route}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider).value ?? const [];
    final calcs = ref.watch(allCalculationsProvider).value ?? const [];
    final l = context.l10n;

    final recent = [...projects]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final available = modules.where((m) => m.isAvailable).toList();
    final roadmap = modules.where((m) => !m.isAvailable).toList()
      ..sort((a, b) => (a.phase ?? 9).compareTo(b.phase ?? 9));

    return AppPage(
      title: l.navHome,
      actions: [
        IconButton(
          tooltip: l.settingsTitle,
          onPressed: () => context.push('/dashboard/settings'),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      header: _Hero(
        onNewProject: () async {
          final p = await showProjectForm(context, ref);
          if (p != null && context.mounted) context.go('/projects/${p.id}');
        },
        onProjects: () => context.go('/projects'),
      ),
      children: [
        ResponsiveGrid(
          minTileWidth: 150,
          children: [
            StatTile(
              label: l.dashStatProjects,
              value: '${projects.length}',
              icon: Icons.folder_outlined,
              onTap: () => context.go('/projects'),
            ),
            StatTile(
              label: l.dashStatCalculations,
              value: '${calcs.length}',
              icon: Icons.functions_rounded,
            ),
            StatTile(
              label: l.dashStatModules,
              value: '${available.length}',
              icon: Icons.widgets_outlined,
            ),
            StatTile(
              label: l.dashStatRoadmap,
              value: '${roadmap.length}',
              icon: Icons.route_outlined,
            ),
          ],
        ),
        if (recent.isNotEmpty) ...[
          SectionHeader(
            title: l.dashRecentProjects,
            trailing: TextButton(
              onPressed: () => context.go('/projects'),
              child: Text(l.commonSeeAll),
            ),
          ),
          ResponsiveGrid(
            minTileWidth: 300,
            children: [
              for (final p in recent.take(context.isCompact ? 3 : 4))
                ProjectCard(
                  project: p,
                  onTap: () => context.go('/projects/${p.id}'),
                ),
            ],
          ),
        ],
        SectionHeader(
          title: l.dashDesignModules,
          subtitle: l.dashDesignModulesSubtitle,
        ),
        ResponsiveGrid(
          minTileWidth: 160,
          children: [
            for (final m in available)
              ModuleTile(module: m, onOpen: () => _openModule(context, ref, m)),
          ],
        ),
        SectionHeader(title: l.dashRoadmap, subtitle: l.dashRoadmapSubtitle),
        ResponsiveGrid(
          minTileWidth: 160,
          children: [for (final m in roadmap) ModuleTile(module: m)],
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  final VoidCallback onNewProject;
  final VoidCallback onProjects;

  const _Hero({required this.onNewProject, required this.onProjects});

  String _greeting(AppLocalizations l) {
    final h = DateTime.now().hour;
    if (h < 12) return l.dashGreetingMorning;
    if (h < 18) return l.dashGreetingAfternoon;
    return l.dashGreetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final wide = !context.isCompact;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.xl),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border.all(color: context.colors.outlineVariant),
          borderRadius: BorderRadius.circular(Radii.xl),
        ),
        child: BlueprintGrid(
          child: Padding(
            padding: EdgeInsets.all(wide ? Gap.xxl : Gap.xl),
            child: Row(
              children: [
                Expanded(child: _heroText(context, wide)),
                if (MediaQuery.sizeOf(context).width >= Breakpoints.expanded)
                  const Expanded(
                    child: SizedBox(height: 260, child: FrameSketch()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroText(BuildContext context, bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const BrandMark(size: 30),
            const SizedBox(width: Gap.md),
            Text(
              DateFormat(
                'EEEE d MMMM',
                context.localeName,
              ).format(DateTime.now()),
              style: context.text.labelMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: wide ? Gap.xxl : Gap.xl),
        Text(
          _greeting(context.l10n),
          style: context.text.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Gap.xs),
        Text(
          context.l10n.dashHeroTitle,
          style: wide ? context.text.displaySmall : context.text.headlineMedium,
        ),
        SizedBox(height: wide ? Gap.xxl : Gap.xl),
        Wrap(
          spacing: Gap.md,
          runSpacing: Gap.md,
          children: [
            FilledButton.icon(
              onPressed: onNewProject,
              icon: const Icon(Icons.add_rounded),
              label: Text(context.l10n.dashNewProject),
            ),
            OutlinedButton.icon(
              onPressed: onProjects,
              icon: const Icon(Icons.folder_open_outlined),
              label: Text(context.l10n.dashOpenProjects),
            ),
          ],
        ),
      ],
    );
  }
}
