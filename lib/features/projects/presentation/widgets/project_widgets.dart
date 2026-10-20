import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/shared/providers/app_providers.dart';
import 'package:sibot/ui/ui.dart';

Tone projectStatusTone(String status) => switch (status) {
  'active' => Tone.success,
  'completed' => Tone.primary,
  _ => Tone.neutral,
};

String relativeDate(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes} min ago';
  if (diff.inDays < 1) return '${diff.inHours} h ago';
  if (diff.inDays < 7) return '${diff.inDays} d ago';
  return DateFormat.yMMMd().format(d);
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
                  project.name.isEmpty ? 'Untitled project' : project.name,
                  style: context.text.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  meta.isEmpty
                      ? 'Updated ${relativeDate(project.updatedAt)}'
                      : meta,
                  style: context.text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: Gap.sm),
          StatusPill(project.status, tone: projectStatusTone(project.status)),
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
              editing ? 'Edit project' : 'New project',
              style: context.text.headlineSmall,
            ),
            const SizedBox(height: Gap.xl),
            TextField(
              controller: _name,
              autofocus: !editing,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Project name',
                errorText: _nameError ? 'Give the project a name' : null,
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
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.place_outlined, size: 20),
                  ),
                ),
                TextField(
                  controller: _engineer,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Engineer',
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
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            if (editing) ...[
              const SizedBox(height: Gap.lg),
              ChoiceField<String>(
                label: 'Status',
                value: _status,
                options: const {
                  'active': 'Active',
                  'completed': 'Completed',
                  'archived': 'Archived',
                },
                onChanged: (v) => setState(() => _status = v),
              ),
            ],
            const SizedBox(height: Gap.xl),
            FilledButton(
              onPressed: _save,
              child: Text(editing ? 'Save changes' : 'Create project'),
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
                Text('PROJECT', style: context.text.labelSmall),
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
            label: const Text('Switch'),
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
  String title = 'Choose a project',
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
                child: Text(title, style: context.text.headlineSmall),
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
                              ? 'Updated ${relativeDate(p.updatedAt)}'
                              : p.location,
                        ),
                        onTap: () => Navigator.pop(sheetContext, p.id),
                      ),
                    ListTile(
                      leading: const IconBadge(Icons.add, size: 38),
                      title: const Text('New project'),
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
