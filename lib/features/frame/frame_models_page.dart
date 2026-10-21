import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/frame/frame_repository.dart';
import 'package:sibot/features/frame/section_library.dart';
import 'package:sibot/features/projects/presentation/widgets/project_widgets.dart';
import 'package:sibot/features/exchange/exchange_ui.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// Frame models of a project.
class FrameModelsPage extends ConsumerWidget {
  final String projectId;
  const FrameModelsPage({super.key, required this.projectId});

  Future<void> _create(BuildContext context) async {
    final record = await showModalBottomSheet<FrameModelRecord>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => _NewModelSheet(projectId: projectId),
    );
    if (record != null && context.mounted) {
      context.push('/projects/$projectId/frame2d/${record.id}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final models = ref.watch(frameModelsProvider(projectId));
    return AppPage(
      title: l.modFrame2d,
      actions: [ImportButton(projectId: projectId, threeD: false)],
      eyebrow: l.catAnalysis,
      subtitle: l.frameSubtitle,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.frameNewModel),
      ),
      children: [
        const BetaNotice(),
        const SizedBox(height: Gap.md),
        const ImportHint(),
        const SizedBox(height: Gap.xl),
        models.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => StatusBanner(
            tone: Tone.danger,
            title: l.frameLoadError,
            message: '$e',
          ),
          data: (list) => list.isEmpty
              ? EmptyState(
                  icon: Icons.hub_outlined,
                  title: l.frameEmptyTitle,
                  message: l.frameEmptyMessage,
                  action: FilledButton.icon(
                    onPressed: () => _create(context),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l.frameNewModel),
                  ),
                )
              : ResponsiveGrid(
                  minTileWidth: 300,
                  children: [
                    for (final r in list)
                      SurfaceCard(
                        onTap: () => context.push(
                          '/projects/$projectId/frame2d/${r.id}',
                        ),
                        child: Row(
                          children: [
                            const IconBadge(Icons.hub_outlined),
                            const SizedBox(width: Gap.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.name, style: context.text.titleMedium),
                                  Text(
                                    '${l.frameCounts(r.model.nodes.length, r.model.elements.length)}  ·  ${relativeDate(context, r.updatedAt)}',
                                    style: context.text.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: l.commonDelete,
                              icon: const Icon(Icons.delete_outline_rounded),
                              onPressed: () => FrameRepository.delete(r.id),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _NewModelSheet extends StatefulWidget {
  final String projectId;
  const _NewModelSheet({required this.projectId});

  @override
  State<_NewModelSheet> createState() => _NewModelSheetState();
}

class _NewModelSheetState extends State<_NewModelSheet> {
  String _template = 'beam';
  final _name = TextEditingController();

  // Template parameters.
  final _spans = TextEditingController(text: '5, 5');
  double? _bays = 2, _bayWidth = 5, _storeys = 2, _height = 3;
  double? _span = 12, _trussHeight = 1.5, _panels = 6;
  TrussType _truss = TrussType.pratt;
  double? _g = 20, _q = 10, _wind = 0;

  @override
  void dispose() {
    _name.dispose();
    _spans.dispose();
    super.dispose();
  }

  Model2D? _build() {
    final g = _g ?? 0, q = _q ?? 0;
    switch (_template) {
      case 'beam':
        final spans = [
          for (final s in _spans.text.split(RegExp(r'[;, ]+')))
            if (parseNumber(s) != null && parseNumber(s)! > 0) parseNumber(s)!,
        ];
        if (spans.isEmpty) return null;
        return continuousBeam(
          spans: spans,
          section: concreteRectangle(300, 500),
          g: g,
          q: q,
        );
      case 'frame':
        final bays = (_bays ?? 0).round(), storeys = (_storeys ?? 0).round();
        if (bays < 1 ||
            storeys < 1 ||
            (_bayWidth ?? 0) <= 0 ||
            (_height ?? 0) <= 0) {
          return null;
        }
        return portalFrame(
          bays: bays,
          bayWidth: _bayWidth!,
          storeys: storeys,
          storeyHeight: _height!,
          column: concreteRectangle(300, 300),
          beam: concreteRectangle(300, 500),
          g: g,
          q: q,
          wind: _wind ?? 0,
        );
      case 'truss':
        final panels = (_panels ?? 0).round();
        if (panels < 2 || (_span ?? 0) <= 0 || (_trussHeight ?? 0) <= 0) {
          return null;
        }
        return flatTruss(
          span: _span!,
          height: _trussHeight!,
          panels: panels,
          section: steelProfile('IPE 160'),
          type: _truss,
          g: g,
          q: q,
        );
      default:
        return Model2D(
          nodes: const [],
          supports: const {},
          sections: [concreteRectangle(300, 500)],
          elements: const [],
          cases: const [LoadCase(name: 'G', selfWeight: true)],
        );
    }
  }

  Future<void> _create() async {
    final l = context.l10n;
    final model = _build();
    if (model == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.frameTemplateInvalid)));
      return;
    }
    final name = _name.text.trim().isEmpty
        ? switch (_template) {
            'beam' => l.frameTemplateBeam,
            'frame' => l.frameTemplateFrame,
            'truss' => l.frameTemplateTruss,
            _ => l.frameTemplateBlank,
          }
        : _name.text.trim();
    final record = FrameModelRecord(
      id: IdService.generateId(),
      projectId: widget.projectId,
      name: name,
      updatedAt: DateTime.now(),
      model: model,
    );
    await FrameRepository.save(record);
    if (mounted) Navigator.pop(context, record);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget num(
      String label,
      double? value,
      ValueChanged<double?> on, [
      String? unit,
    ]) => NumberField(label: label, value: value, unit: unit, onChanged: on);

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
            Text(l.frameNewModel, style: context.text.headlineSmall),
            const SizedBox(height: Gap.lg),
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                for (final e in {
                  'beam': l.frameTemplateBeam,
                  'frame': l.frameTemplateFrame,
                  'truss': l.frameTemplateTruss,
                  'blank': l.frameTemplateBlank,
                }.entries)
                  ChoiceChip(
                    label: Text(e.value),
                    selected: _template == e.key,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _template = e.key),
                  ),
              ],
            ),
            const SizedBox(height: Gap.lg),
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: l.frameModelName),
            ),
            const SizedBox(height: Gap.md),
            if (_template == 'beam')
              TextField(
                decoration: InputDecoration(
                  labelText: l.frameSpans,
                  helperText: l.frameSpansHelp,
                  suffixText: 'm',
                ),
                controller: _spans,
              ),
            if (_template == 'frame') ...[
              FieldRow(
                children: [
                  num(l.frameBays, _bays, (v) => _bays = v),
                  num(l.frameBayWidth, _bayWidth, (v) => _bayWidth = v, 'm'),
                ],
              ),
              const SizedBox(height: Gap.md),
              FieldRow(
                children: [
                  num(l.frameStoreys, _storeys, (v) => _storeys = v),
                  num(l.frameStoreyHeight, _height, (v) => _height = v, 'm'),
                ],
              ),
            ],
            if (_template == 'truss') ...[
              ChoiceField<TrussType>(
                label: l.frameTrussType,
                value: _truss,
                options: const {
                  TrussType.pratt: 'Pratt',
                  TrussType.howe: 'Howe',
                  TrussType.warren: 'Warren',
                },
                onChanged: (v) => setState(() => _truss = v),
              ),
              const SizedBox(height: Gap.md),
              FieldRow(
                children: [
                  num(l.frameSpan, _span, (v) => _span = v, 'm'),
                  num(
                    l.frameTrussHeight,
                    _trussHeight,
                    (v) => _trussHeight = v,
                    'm',
                  ),
                ],
              ),
              const SizedBox(height: Gap.md),
              num(l.framePanels, _panels, (v) => _panels = v),
            ],
            if (_template != 'blank') ...[
              const SizedBox(height: Gap.md),
              FieldRow(
                children: [
                  num(
                    l.loadPermanent,
                    _g,
                    (v) => _g = v,
                    _template == 'truss' ? 'kN' : 'kN/m',
                  ),
                  num(
                    l.loadVariable,
                    _q,
                    (v) => _q = v,
                    _template == 'truss' ? 'kN' : 'kN/m',
                  ),
                ],
              ),
              if (_template == 'frame') ...[
                const SizedBox(height: Gap.md),
                num(l.frameWindPerFloor, _wind, (v) => _wind = v, 'kN'),
              ],
              const SizedBox(height: Gap.sm),
              Text(l.frameTemplateNote, style: context.text.bodySmall),
            ],
            const SizedBox(height: Gap.xl),
            FilledButton(onPressed: _create, child: Text(l.frameCreate)),
          ],
        ),
      ),
    );
  }
}
