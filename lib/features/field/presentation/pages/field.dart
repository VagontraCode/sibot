import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/shared/providers/app_providers.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';

Future<T?> _sheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        Gap.xl,
        0,
        Gap.xl,
        Gap.xl + MediaQuery.viewInsetsOf(ctx).bottom,
      ),
      child: SingleChildScrollView(child: child),
    ),
  );
}

// ============ PHOTO LOG ============

class PhotoLogPage extends ConsumerWidget {
  final String projectId;
  const PhotoLogPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(photoLogsProvider(projectId));
    void add() => _sheet(context, _AddPhotoForm(projectId: projectId));

    return AppPage(
      title: context.l10n.photoLog,
      eyebrow: context.l10n.navField,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: Text(context.l10n.photoAdd),
      ),
      children: [
        photosAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => StatusBanner(
            tone: Tone.danger,
            title: context.l10n.photoLoadError,
            message: '$e',
          ),
          data: (photos) {
            if (photos.isEmpty) {
              return EmptyState(
                icon: Icons.photo_library_outlined,
                title: context.l10n.photoEmptyTitle,
                message: context.l10n.photoEmptyMessage,
                action: FilledButton.icon(
                  onPressed: add,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(context.l10n.photoAdd),
                ),
              );
            }
            final sorted = [...photos]
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
            return ResponsiveGrid(
              minTileWidth: 260,
              children: [for (final ph in sorted) _PhotoCard(photo: ph)],
            );
          },
        ),
      ],
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final PhotoLog photo;
  const _PhotoCard({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ColoredBox(
              color: context.colors.surfaceContainerHigh,
              child: photo.imagePath.startsWith('assets')
                  ? Image.asset(photo.imagePath, fit: BoxFit.cover)
                  : Image.file(
                      File(photo.imagePath),
                      fit: BoxFit.cover,
                      cacheWidth: 800,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.broken_image_outlined,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo.description.isEmpty
                      ? context.l10n.commonUntitled
                      : photo.description,
                  style: context.text.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Gap.xs),
                Text(
                  [
                    if (photo.location.isNotEmpty) photo.location,
                    DateFormat.yMMMd(
                      context.localeName,
                    ).add_Hm().format(photo.timestamp),
                  ].join('  ·  '),
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoForm extends ConsumerStatefulWidget {
  final String projectId;
  const _AddPhotoForm({required this.projectId});

  @override
  ConsumerState<_AddPhotoForm> createState() => _AddPhotoFormState();
}

class _AddPhotoFormState extends ConsumerState<_AddPhotoForm> {
  final _description = TextEditingController();
  final _location = TextEditingController();
  XFile? _file;
  bool _saving = false;

  @override
  void dispose() {
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final image = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2400,
      imageQuality: 85,
    );
    if (image != null) setState(() => _file = image);
  }

  Future<void> _save() async {
    final file = _file;
    if (file == null) return;
    setState(() => _saving = true);
    final appDir = await getApplicationDocumentsDirectory();
    final savedPath = p.join(appDir.path, p.basename(file.path));
    await File(file.path).copy(savedPath);

    await ref
        .read(photoLogsProvider(widget.projectId).notifier)
        .addPhotoLog(
          PhotoLog(
            id: IdService.generatePhotoId(),
            projectId: widget.projectId,
            imagePath: savedPath,
            description: _description.text.trim(),
            timestamp: DateTime.now(),
            location: _location.text.trim(),
            tags: [],
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.photoAdd, style: context.text.headlineSmall),
        const SizedBox(height: Gap.xl),
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.lg),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: _file != null
                ? Image.file(File(_file!.path), fit: BoxFit.cover)
                : ColoredBox(
                    color: context.colors.surfaceContainerLow,
                    child: Icon(
                      Icons.image_outlined,
                      size: 40,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: Gap.md),
        FieldRow(
          children: [
            OutlinedButton.icon(
              onPressed: () => _pick(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(context.l10n.photoCamera),
            ),
            OutlinedButton.icon(
              onPressed: () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(context.l10n.photoGallery),
            ),
          ],
        ),
        const SizedBox(height: Gap.lg),
        TextField(
          controller: _description,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: context.l10n.photoDescription),
        ),
        const SizedBox(height: Gap.md),
        TextField(
          controller: _location,
          decoration: InputDecoration(
            labelText: context.l10n.photoLocation,
            hintText: context.l10n.photoLocationHint,
          ),
        ),
        const SizedBox(height: Gap.xl),
        FilledButton(
          onPressed: _file == null || _saving ? null : _save,
          child: Text(
            _saving ? context.l10n.commonSaving : context.l10n.photoSave,
          ),
        ),
      ],
    );
  }
}

// ============ DAILY REPORTS ============

class DailyReportPage extends ConsumerWidget {
  final String projectId;
  const DailyReportPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(dailyReportsProvider(projectId));
    void add() => _sheet(context, _DailyReportForm(projectId: projectId));

    return AppPage(
      title: context.l10n.reportDaily,
      eyebrow: context.l10n.navField,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.edit_note_rounded),
        label: Text(context.l10n.reportNew),
      ),
      children: [
        reportsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => StatusBanner(
            tone: Tone.danger,
            title: context.l10n.reportLoadError,
            message: '$e',
          ),
          data: (reports) {
            if (reports.isEmpty) {
              return EmptyState(
                icon: Icons.assignment_outlined,
                title: context.l10n.reportEmptyTitle,
                message: context.l10n.reportEmptyMessage,
                action: FilledButton.icon(
                  onPressed: add,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: Text(context.l10n.reportNew),
                ),
              );
            }
            final sorted = [...reports]
              ..sort((a, b) => b.date.compareTo(a.date));
            return ResponsiveGrid(
              minTileWidth: 320,
              children: [
                for (final r in sorted)
                  SurfaceCard(
                    onTap: () => _sheet(context, _ReportDetail(report: r)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DateBadge(date: r.date),
                        const SizedBox(width: Gap.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.progressSummary.isEmpty
                                    ? context.l10n.reportNoSummary
                                    : r.progressSummary,
                                style: context.text.titleMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: Gap.xs),
                              Text(
                                [
                                  if (r.weather.isNotEmpty) r.weather,
                                  context.l10n.reportWorkers(r.workersCount),
                                ].join('  ·  '),
                                style: context.text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DateBadge extends StatelessWidget {
  final DateTime date;
  const _DateBadge({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: Gap.sm),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        children: [
          Text(
            DateFormat.MMM(context.localeName).format(date).toUpperCase(),
            style: context.text.labelSmall?.copyWith(
              color: context.colors.onPrimaryContainer,
            ),
          ),
          Text(
            '${date.day}',
            style: AppTheme.mono(
              context,
              size: 20,
              color: context.colors.onPrimaryContainer,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ReportDetail extends StatelessWidget {
  final DailyReport report;
  const _ReportDetail({required this.report});

  @override
  Widget build(BuildContext context) {
    Widget block(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: context.text.labelSmall),
          const SizedBox(height: Gap.xs),
          Text(value.isEmpty ? '—' : value, style: context.text.bodyMedium),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat.yMMMMEEEEd(context.localeName).format(report.date),
          style: context.text.headlineSmall,
        ),
        const SizedBox(height: Gap.xl),
        FieldRow(
          children: [
            block(context.l10n.reportWeather, report.weather),
            block(context.l10n.reportWorkersOnSite, '${report.workersCount}'),
          ],
        ),
        block(context.l10n.reportProgress, report.progressSummary),
        block(context.l10n.reportSafety, report.safetyNotes),
      ],
    );
  }
}

class _DailyReportForm extends ConsumerStatefulWidget {
  final String projectId;
  const _DailyReportForm({required this.projectId});

  @override
  ConsumerState<_DailyReportForm> createState() => _DailyReportFormState();
}

class _DailyReportFormState extends ConsumerState<_DailyReportForm> {
  final _weather = TextEditingController();
  final _progress = TextEditingController();
  final _safety = TextEditingController();
  int _workers = 10;

  @override
  void dispose() {
    _weather.dispose();
    _progress.dispose();
    _safety.dispose();
    super.dispose();
  }

  void _save() {
    ref
        .read(dailyReportsProvider(widget.projectId).notifier)
        .addReport(
          DailyReport(
            id: IdService.generateReportId(),
            projectId: widget.projectId,
            date: DateTime.now(),
            weather: _weather.text.trim(),
            workersCount: _workers,
            progressSummary: _progress.text.trim(),
            issues: [],
            safetyNotes: _safety.text.trim(),
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.reportDailyTitle, style: context.text.headlineSmall),
        const SizedBox(height: Gap.xs),
        Text(
          DateFormat.yMMMMEEEEd(context.localeName).format(DateTime.now()),
          style: context.text.bodySmall,
        ),
        const SizedBox(height: Gap.xl),
        FieldRow(
          children: [
            TextField(
              controller: _weather,
              decoration: InputDecoration(
                labelText: context.l10n.reportWeather,
                prefixIcon: Icon(Icons.wb_cloudy_outlined, size: 20),
              ),
            ),
            NumberField(
              label: context.l10n.reportWorkersField,
              value: _workers.toDouble(),
              onChanged: (v) => _workers = v?.round() ?? 0,
            ),
          ],
        ),
        const SizedBox(height: Gap.md),
        TextField(
          controller: _progress,
          minLines: 3,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: context.l10n.reportProgress,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: Gap.md),
        TextField(
          controller: _safety,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: context.l10n.reportSafetyNotes,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: Gap.xl),
        FilledButton(onPressed: _save, child: Text(context.l10n.reportSave)),
      ],
    );
  }
}

// ============ PUNCH LIST ============

const _priorityTone = {
  'high': Tone.danger,
  'medium': Tone.warning,
  'low': Tone.success,
};

class PunchListPage extends ConsumerStatefulWidget {
  final String projectId;
  const PunchListPage({super.key, required this.projectId});

  @override
  ConsumerState<PunchListPage> createState() => _PunchListPageState();
}

class _PunchListPageState extends ConsumerState<PunchListPage> {
  bool _showClosed = false;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(punchListProvider(widget.projectId));
    void add() => _sheet(context, _PunchItemForm(projectId: widget.projectId));

    return AppPage(
      title: context.l10n.punchList,
      eyebrow: context.l10n.navField,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.add_task_rounded),
        label: Text(context.l10n.punchAdd),
      ),
      children: [
        itemsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => StatusBanner(
            tone: Tone.danger,
            title: context.l10n.punchLoadError,
            message: '$e',
          ),
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                icon: Icons.checklist_rounded,
                title: context.l10n.punchEmptyTitle,
                message: context.l10n.punchEmptyMessage,
                action: FilledButton.icon(
                  onPressed: add,
                  icon: const Icon(Icons.add_task_rounded),
                  label: Text(context.l10n.punchAdd),
                ),
              );
            }
            const order = {'high': 0, 'medium': 1, 'low': 2};
            final open = items.where((i) => i.status != 'closed').toList()
              ..sort(
                (a, b) =>
                    (order[a.priority] ?? 3).compareTo(order[b.priority] ?? 3),
              );
            final closed = items.where((i) => i.status == 'closed').toList();
            final shown = _showClosed ? closed : open;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ChoiceChip(
                      label: Text(context.l10n.punchOpenTab(open.length)),
                      selected: !_showClosed,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _showClosed = false),
                    ),
                    const SizedBox(width: Gap.sm),
                    ChoiceChip(
                      label: Text(context.l10n.punchClosedTab(closed.length)),
                      selected: _showClosed,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _showClosed = true),
                    ),
                  ],
                ),
                const SizedBox(height: Gap.lg),
                if (shown.isEmpty)
                  EmptyState(
                    icon: Icons.task_alt_rounded,
                    title: _showClosed
                        ? context.l10n.punchNothingClosed
                        : context.l10n.punchAllClear,
                  )
                else
                  Card(
                    child: Column(
                      children: [
                        for (var i = 0; i < shown.length; i++) ...[
                          if (i > 0) const Divider(),
                          _PunchRow(
                            item: shown[i],
                            projectId: widget.projectId,
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: Gap.md),
                Text(
                  context.l10n.punchSwipeHint,
                  style: context.text.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PunchRow extends ConsumerWidget {
  final PunchListItem item;
  final String projectId;
  const _PunchRow({required this.item, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(punchListProvider(projectId).notifier);
    final closed = item.status == 'closed';

    void setClosed(bool value) => notifier.updateItem(
      item.copyWith(
        status: value ? 'closed' : 'open',
        completedAt: value ? DateTime.now() : null,
      ),
    );

    return Dismissible(
      key: ValueKey(item.id),
      background: Container(
        color: context.appColors.success,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
        child: const Icon(Icons.check_rounded, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: context.appColors.danger,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          setClosed(!closed);
          return false;
        }
        return true;
      },
      onDismissed: (_) => notifier.deleteItem(item.id),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(
          Gap.sm,
          Gap.xs,
          Gap.lg,
          Gap.xs,
        ),
        leading: Checkbox(
          value: closed,
          onChanged: (v) => setClosed(v == true),
        ),
        title: Text(
          item.description,
          style: TextStyle(
            decoration: closed ? TextDecoration.lineThrough : null,
            color: closed ? context.colors.onSurfaceVariant : null,
          ),
        ),
        subtitle: item.assignedTo.isEmpty
            ? null
            : Text(context.l10n.punchAssignedTo(item.assignedTo)),
        trailing: StatusPill(
          context.l10n.priority(item.priority),
          tone: _priorityTone[item.priority] ?? Tone.neutral,
        ),
      ),
    );
  }
}

class _PunchItemForm extends ConsumerStatefulWidget {
  final String projectId;
  const _PunchItemForm({required this.projectId});

  @override
  ConsumerState<_PunchItemForm> createState() => _PunchItemFormState();
}

class _PunchItemFormState extends ConsumerState<_PunchItemForm> {
  final _description = TextEditingController();
  final _assigned = TextEditingController();
  String _priority = 'medium';

  @override
  void dispose() {
    _description.dispose();
    _assigned.dispose();
    super.dispose();
  }

  void _save() {
    if (_description.text.trim().isEmpty) return;
    ref
        .read(punchListProvider(widget.projectId).notifier)
        .addItem(
          PunchListItem(
            id: IdService.generateId(),
            projectId: widget.projectId,
            description: _description.text.trim(),
            priority: _priority,
            status: 'open',
            createdAt: DateTime.now(),
            assignedTo: _assigned.text.trim(),
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.punchNew, style: context.text.headlineSmall),
        const SizedBox(height: Gap.xl),
        TextField(
          controller: _description,
          autofocus: true,
          minLines: 1,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: context.l10n.punchWhat),
        ),
        const SizedBox(height: Gap.md),
        TextField(
          controller: _assigned,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: context.l10n.punchAssignedLabel,
            prefixIcon: Icon(Icons.person_outline, size: 20),
          ),
        ),
        const SizedBox(height: Gap.lg),
        ChoiceField<String>(
          label: context.l10n.punchPriority,
          value: _priority,
          options: {
            'high': context.l10n.priorityHigh,
            'medium': context.l10n.priorityMedium,
            'low': context.l10n.priorityLow,
          },
          onChanged: (v) => setState(() => _priority = v),
        ),
        const SizedBox(height: Gap.xl),
        FilledButton(onPressed: _save, child: Text(context.l10n.punchAdd)),
      ],
    );
  }
}
