import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/shared/providers/app_providers.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';

Tone projectStatusTone(String status) => switch (status) {
  'active' => Tone.success,
  'completed' => Tone.primary,
  _ => Tone.neutral,
};

String relativeDate(BuildContext context, DateTime d) {
  return context.l10n.relativeDate(
    d,
    (d) => DateFormat.yMMMd(context.localeName).format(d),
  );
}

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const ProjectCard({super.key, required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (project.location.isNotEmpty) project.location,
      if (project.engineer.isNotEmpty) project.engineer,
    ].join('  ·  ');

    return SurfaceCard(
      onTap: onTap,
      child: Row(
        children: [
          ProjectAvatar(project.name),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name.isEmpty
                      ? context.l10n.projectUntitled
                      : project.name,
                  style: context.text.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  meta.isEmpty
                      ? context.l10n.timeUpdated(
                          relativeDate(context, project.updatedAt),
                        )
                      : meta,
                  style: context.text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: Gap.sm),
          StatusPill(
            context.l10n.projectStatus(project.status),
            tone: projectStatusTone(project.status),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet to create a project, or edit [existing]. Returns the saved
/// project, or null if cancelled.
Future<Project?> showProjectForm(
  BuildContext context,
  WidgetRef ref, {
  Project? existing,
}) {
  return showModalBottomSheet<Project>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => _ProjectForm(existing: existing, ref: ref),
  );
}

class _ProjectForm extends StatefulWidget {
  final Project? existing;
  final WidgetRef ref;
  const _ProjectForm({required this.existing, required this.ref});

  @override
  State<_ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<_ProjectForm> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _location = TextEditingController(text: widget.existing?.location);
  late final _engineer = TextEditingController(text: widget.existing?.engineer);
  late final _description = TextEditingController(
    text: widget.existing?.description,
  );
  late String _status = widget.existing?.status ?? 'active';
  bool _nameError = false;

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _engineer.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _nameError = true);
      return;
    }
    final now = DateTime.now();
    final e = widget.existing;
    final project = e == null
        ? Project(
            id: IdService.generateProjectId(),
            name: _name.text.trim(),
            description: _description.text.trim(),
            location: _location.text.trim(),
            engineer: _engineer.text.trim(),
            status: _status,
            createdAt: now,
            updatedAt: now,
            metadata: {},
          )
        : e.copyWith(
            name: _name.text.trim(),
            description: _description.text.trim(),
            location: _location.text.trim(),
            engineer: _engineer.text.trim(),
            status: _status,
            updatedAt: now,
          );

    final notifier = widget.ref.read(projectsProvider.notifier);
    if (e == null) {
      await notifier.addProject(project);
    } else {
      await notifier.updateProject(project);
      widget.ref.invalidate(projectByIdProvider(project.id));
    }
    if (mounted) Navigator.pop(context, project);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Gap.xl,
        0,
        Gap.xl,
        Gap.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              editing
                  ? context.l10n.projectFormEdit
                  : context.l10n.projectFormNew,
              style: context.text.headlineSmall,
            ),
            const SizedBox(height: Gap.xl),
            TextField(
              controller: _name,
              autofocus: !editing,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.l10n.projectFormName,
                errorText: _nameError
                    ? context.l10n.projectFormNameError
                    : null,
              ),
              onChanged: (_) {
                if (_nameError) setState(() => _nameError = false);
              },
            ),
            const SizedBox(height: Gap.md),
            FieldRow(
              children: [
                TextField(
                  controller: _location,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: context.l10n.projectFormLocation,
                    prefixIcon: Icon(Icons.place_outlined, size: 20),
                  ),
                ),
                TextField(
                  controller: _engineer,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: context.l10n.projectFormEngineer,
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.md),
            TextField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: context.l10n.projectFormDescription,
              ),
            ),
            if (editing) ...[
              const SizedBox(height: Gap.lg),
              ChoiceField<String>(
                label: context.l10n.projectFormStatus,
                value: _status,
                options: {
                  'active': context.l10n.statusActive,
                  'completed': context.l10n.statusCompleted,
                  'archived': context.l10n.statusArchived,
                },
                onChanged: (v) => setState(() => _status = v),
              ),
            ],
            const SizedBox(height: Gap.xl),
            FilledButton(
              onPressed: _save,
              child: Text(
                editing
                    ? context.l10n.projectFormSave
                    : context.l10n.projectFormCreate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The project a hub page works on: the user's choice, else the most
/// recently updated project.
Project? activeProject(WidgetRef ref) {
  final projects = ref.watch(projectsProvider).value ?? const <Project>[];
  if (projects.isEmpty) return null;
  final selected = ref.watch(selectedProjectIdProvider);
  for (final p in projects) {
    if (p.id == selected) return p;
  }
  return ([
    ...projects,
  ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt))).first;
}

/// Card showing the active project with a "Switch" action.
class ProjectSwitcher extends ConsumerWidget {
  final Project project;
  const ProjectSwitcher({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.sm, Gap.md),
      child: Row(
        children: [
          ProjectAvatar(project.name, size: 40),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.commonProjectEyebrow.toUpperCase(),
                  style: context.text.labelSmall,
                ),
                Text(
                  project.name,
                  style: context.text.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              final id = await showProjectPicker(context, ref);
              if (id != null) {
                ref.read(selectedProjectIdProvider.notifier).state = id;
              }
            },
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: Text(context.l10n.commonSwitch),
          ),
        ],
      ),
    );
  }
}

/// Lets the user choose a project (or create one). Returns its id.
Future<String?> showProjectPicker(
  BuildContext context,
  WidgetRef ref, {
  String? title,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final projects = ref.watch(projectsProvider).value ?? const [];
        final sorted = [...projects]
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Gap.xl, 0, Gap.xl, Gap.md),
                child: Text(
                  title ?? context.l10n.projectPickerTitle,
                  style: context.text.headlineSmall,
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: Gap.md),
                  children: [
                    for (final p in sorted)
                      ListTile(
                        leading: ProjectAvatar(p.name, size: 38),
                        title: Text(p.name),
                        subtitle: Text(
                          p.location.isEmpty
                              ? context.l10n.timeUpdated(
                                  relativeDate(context, p.updatedAt),
                                )
                              : p.location,
                        ),
                        onTap: () => Navigator.pop(sheetContext, p.id),
                      ),
                    ListTile(
                      leading: const IconBadge(Icons.add, size: 38),
                      title: Text(context.l10n.projectFormNew),
                      onTap: () async {
                        final created = await showProjectForm(context, ref);
                        if (created != null && sheetContext.mounted) {
                          Navigator.pop(sheetContext, created.id);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.lg),
            ],
          ),
        );
      },
    ),
  );
}
