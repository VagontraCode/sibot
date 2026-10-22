import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/frame/frame_repository.dart';
import 'package:sibot/features/frame3d/frame3d_analyses_ui.dart';
import 'package:sibot/features/frame3d/frame3d_data.dart';
import 'package:sibot/features/frame3d/frame3d_groups_ui.dart';
import 'package:sibot/features/frame3d/frame3d_design.dart';
import 'package:sibot/features/frame3d/frame3d_editor.dart';
import 'package:sibot/features/frame3d/frame_notes.dart';
import 'package:sibot/features/calculations/shared/note_extract.dart';
import 'package:sibot/features/frame3d/frame3d_view.dart';
import 'package:sibot/features/projects/presentation/widgets/project_widgets.dart';
import 'package:sibot/features/exchange/exchange.dart';
import 'package:sibot/features/exchange/exchange_ui.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// 3D building models of a project.
class Frame3DModelsPage extends ConsumerWidget {
  final String projectId;
  const Frame3DModelsPage({super.key, required this.projectId});

  Future<void> _create(BuildContext context) async {
    final record = await showNewModelSheet(context, projectId: projectId);
    if (record != null && context.mounted) {
      context.push('/projects/$projectId/frame3d/${record.id}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final models = ref.watch(frame3dModelsProvider(projectId));
    return AppPage(
      title: l.modFrame3d,
      actions: [ImportButton(projectId: projectId, threeD: true)],
      eyebrow: l.catAnalysis,
      subtitle: l.f3dSubtitle,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.f3dNewModel),
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
                  icon: Icons.view_in_ar_outlined,
                  title: l.f3dEmptyTitle,
                  message: l.f3dEmptyMessage,
                  action: FilledButton.icon(
                    onPressed: () => _create(context),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l.f3dNewModel),
                  ),
                )
              : ResponsiveGrid(
                  minTileWidth: 300,
                  children: [
                    for (final r in list)
                      SurfaceCard(
                        onTap: () => context.push(
                          '/projects/$projectId/frame3d/${r.id}',
                        ),
                        child: Row(
                          children: [
                            const IconBadge(Icons.view_in_ar_outlined),
                            const SizedBox(width: Gap.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.name, style: context.text.titleMedium),
                                  Text(
                                    '${r.free ? l.f3dFreeSummary(r.model.nodes.length, r.model.elements.length) : l.f3dGridSummary(r.params.spansX.length, r.params.spansY.length, r.params.storeyHeights.length)}  ·  ${relativeDate(context, r.updatedAt)}',
                                    style: context.text.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: l.commonDelete,
                              icon: const Icon(Icons.delete_outline_rounded),
                              onPressed: () => Frame3DRepository.delete(r.id),
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

/// Asks how to start a new 3D model (empty space, plane frame, building
/// generator or one of the project's 2D frames); saves and returns it.
Future<Frame3DRecord?> showNewModelSheet(
  BuildContext context, {
  required String projectId,
}) async {
  final l = context.l10n;
  final frames = FrameRepository.forProject(projectId);
  final choice = await showModalBottomSheet<Object>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 680),
    builder: (ctx) => SingleChildScrollView(
      padding: const EdgeInsets.all(Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.f3dNewModelTitle, style: ctx.text.titleLarge),
          const SizedBox(height: Gap.md),
          for (final (key, icon, title, sub) in [
            (
              'empty',
              Icons.view_in_ar_outlined,
              l.f3dEmptyModel,
              l.f3dEmptyModelSub,
            ),
            (
              'plane',
              Icons.crop_landscape_rounded,
              l.f3dPlaneFrameNew,
              l.f3dPlaneFrameNewSub,
            ),
            (
              'building',
              Icons.apartment_rounded,
              l.f3dGeneratorNew,
              l.f3dGeneratorNewSub,
            ),
          ])
            ListTile(
              leading: Icon(icon),
              title: Text(title),
              subtitle: Text(sub),
              onTap: () => Navigator.pop(ctx, key),
            ),
          if (frames.isNotEmpty) ...[
            const Divider(),
            Text(l.f3dFrom2d, style: ctx.text.titleMedium),
            Text(l.f3dFrom2dSub, style: ctx.text.bodySmall),
            for (final f in frames)
              ListTile(
                leading: const Icon(Icons.hub_outlined),
                title: Text(f.name),
                subtitle: Text(
                  l.f3dFreeSummary(
                    f.model.nodes.length,
                    f.model.elements.length,
                  ),
                ),
                onTap: () => Navigator.pop(ctx, f),
              ),
          ],
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return null;
  if (choice == 'building') {
    return showBuildingWizard(context, projectId: projectId);
  }
  final id = IdService.generateCalculationId();
  final Frame3DRecord record;
  if (choice is FrameModelRecord) {
    record = Frame3DRecord.free(
      id: id,
      projectId: projectId,
      name: choice.name,
      model: planeModelFrom2D(choice.model),
    );
  } else {
    final plane = choice == 'plane';
    record = Frame3DRecord.free(
      id: id,
      projectId: projectId,
      name: plane ? l.f3dPlaneFrameNew : l.f3dEmptyModel,
      model: Model3D.empty(plane: plane),
    );
  }
  await Frame3DRepository.save(record);
  return record;
}

/// Opens the building wizard; saves and returns the record.
Future<Frame3DRecord?> showBuildingWizard(
  BuildContext context, {
  required String projectId,
  Frame3DRecord? existing,
}) => showModalBottomSheet<Frame3DRecord>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 680),
  builder: (_) => _BuildingWizard(projectId: projectId, existing: existing),
);

class _BuildingWizard extends StatefulWidget {
  final String projectId;
  final Frame3DRecord? existing;
  const _BuildingWizard({required this.projectId, this.existing});

  @override
  State<_BuildingWizard> createState() => _BuildingWizardState();
}

class _BuildingWizardState extends State<_BuildingWizard> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  double? _baysX = 3, _spanX = 5, _baysY = 2, _spanY = 4.5;
  double? _storeys = 3, _groundHeight = 3.5, _height = 3;
  double? _colB = 300, _colH = 300, _beamB = 250, _beamH = 500;
  double? _g = 5, _q = 2.5, _facade = 0;
  bool _steel = false;
  bool _rigid = true;
  String _colProfile = 'HEB 240', _beamProfile = 'IPE 300';
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.existing?.params;
    if (p != null) {
      _baysX = p.spansX.length.toDouble();
      _spanX = p.spansX.first;
      _baysY = p.spansY.length.toDouble();
      _spanY = p.spansY.first;
      _storeys = p.storeyHeights.length.toDouble();
      _groundHeight = p.storeyHeights.first;
      _height = p.storeyHeights.length > 1
          ? p.storeyHeights[1]
          : p.storeyHeights.first;
      _g = p.g;
      _q = p.q;
      _facade = p.facade;
      _steel = p.column.profile != null;
      _rigid = p.rigidFloors;
      if (_steel) {
        _colProfile = p.column.profile!;
        _beamProfile = p.beam.profile ?? _beamProfile;
      } else {
        _colB = p.column.b;
        _colH = p.column.h;
        _beamB = p.beam.b;
        _beamH = p.beam.h;
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  int? _count(double? v, int max) {
    if (v == null || v < 1 || v > max || v != v.roundToDouble()) return null;
    return v.round();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final bx = _count(_baysX, 20), by = _count(_baysY, 20);
    final ns = _count(_storeys, 40);
    final ok =
        bx != null &&
        by != null &&
        ns != null &&
        [_spanX, _spanY, _groundHeight, _height].every((v) => (v ?? 0) > 0) &&
        [_g, _q, _facade].every((v) => v != null && v >= 0) &&
        (_steel || [_colB, _colH, _beamB, _beamH].every((v) => (v ?? 0) > 0));
    if (!ok) {
      setState(() => _error = l.f3dWizardInvalid);
      return;
    }
    final params = BuildingParams(
      spansX: List.filled(bx, _spanX!),
      spansY: List.filled(by, _spanY!),
      storeyHeights: [
        for (var k = 0; k < ns; k++) k == 0 ? _groundHeight! : _height!,
      ],
      column: _steel
          ? Section3D.steel(_colProfile)
          : Section3D.rectangle(_colB!, _colH!),
      beam: _steel
          ? Section3D.steel(_beamProfile)
          : Section3D.rectangle(_beamB!, _beamH!),
      g: _g!,
      q: _q!,
      facade: _facade!,
      rigidFloors: _rigid,
    );
    final name = _name.text.trim().isEmpty
        ? l.f3dDefaultName(bx, by, ns)
        : _name.text.trim();
    final record =
        widget.existing?.copyWith(name: name, params: params) ??
        Frame3DRecord(
          id: IdService.generateCalculationId(),
          projectId: widget.projectId,
          name: name,
          updatedAt: DateTime.now(),
          params: params,
        );
    await Frame3DRepository.save(record);
    if (mounted) Navigator.of(context).pop(record);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget num(String label, double? v, ValueChanged<double?> f, [String? u]) =>
        NumberField(label: label, unit: u, value: v, onChanged: f);
    final profiles = {for (final k in steelProfiles.keys) k: k};
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
              widget.existing == null ? l.f3dNewBuilding : l.f3dEditBuilding,
              style: context.text.headlineSmall,
            ),
            const SizedBox(height: Gap.lg),
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: l.frameModelName),
            ),
            const SizedBox(height: Gap.lg),
            Text(l.f3dGrid, style: context.text.titleMedium),
            const SizedBox(height: Gap.sm),
            FieldRow(
              children: [
                num(l.f3dBaysX, _baysX, (v) => _baysX = v),
                num(l.f3dSpanX, _spanX, (v) => _spanX = v, 'm'),
              ],
            ),
            const SizedBox(height: Gap.md),
            FieldRow(
              children: [
                num(l.f3dBaysY, _baysY, (v) => _baysY = v),
                num(l.f3dSpanY, _spanY, (v) => _spanY = v, 'm'),
              ],
            ),
            const SizedBox(height: Gap.md),
            FieldRow(
              children: [
                num(l.f3dStoreys, _storeys, (v) => _storeys = v),
                num(
                  l.f3dGroundHeight,
                  _groundHeight,
                  (v) => _groundHeight = v,
                  'm',
                ),
                num(l.f3dStoreyHeight, _height, (v) => _height = v, 'm'),
              ],
            ),
            const SizedBox(height: Gap.lg),
            Text(l.f3dSections, style: context.text.titleMedium),
            const SizedBox(height: Gap.sm),
            ChoiceField<bool>(
              label: l.f3dMaterial,
              value: _steel,
              options: {false: l.catConcrete, true: l.catSteel},
              onChanged: (v) => setState(() => _steel = v),
            ),
            const SizedBox(height: Gap.md),
            if (_steel)
              FieldRow(
                children: [
                  PickerField<String>(
                    label: l.f3dColumns,
                    value: _colProfile,
                    options: profiles,
                    onChanged: (v) => _colProfile = v,
                  ),
                  PickerField<String>(
                    label: l.f3dBeams,
                    value: _beamProfile,
                    options: profiles,
                    onChanged: (v) => _beamProfile = v,
                  ),
                ],
              )
            else ...[
              FieldRow(
                children: [
                  num('${l.f3dColumns} b', _colB, (v) => _colB = v, 'mm'),
                  num('${l.f3dColumns} h', _colH, (v) => _colH = v, 'mm'),
                ],
              ),
              const SizedBox(height: Gap.md),
              FieldRow(
                children: [
                  num('${l.f3dBeams} b', _beamB, (v) => _beamB = v, 'mm'),
                  num('${l.f3dBeams} h', _beamH, (v) => _beamH = v, 'mm'),
                ],
              ),
            ],
            const SizedBox(height: Gap.lg),
            Text(l.f3dLoads, style: context.text.titleMedium),
            const SizedBox(height: Gap.sm),
            FieldRow(
              children: [
                num(l.f3dFloorG, _g, (v) => _g = v, 'kN/m²'),
                num(l.f3dFloorQ, _q, (v) => _q = v, 'kN/m²'),
              ],
            ),
            const SizedBox(height: Gap.md),
            num(l.f3dFacade, _facade, (v) => _facade = v, 'kN/m'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.f3dRigidFloors),
              subtitle: Text(l.f3dRigidFloorsHelp),
              value: _rigid,
              onChanged: (v) => setState(() => _rigid = v),
            ),
            const SizedBox(height: Gap.sm),
            Text(l.f3dLoadsNote, style: context.text.bodySmall),
            if (_error != null) ...[
              const SizedBox(height: Gap.md),
              StatusBanner(tone: Tone.danger, title: _error!),
            ],
            const SizedBox(height: Gap.lg),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: Text(l.f3dSave),
            ),
          ],
        ),
      ),
    );
  }
}

/// Run marks per model for the session.
final _ranByModel = <String, Map<String, String>>{};

enum _Tab { model, edit, combos, analyses, design }

enum _DesignSort { ratio, member, group }

/// Status of one analysis for the current model.
enum _RunState { notRun, running, done, stale, failed }

/// Analysis of one 3D model: viewer, model editing, combinations and the
/// user's analyses with their results.
class Frame3DPage extends ConsumerStatefulWidget {
  final String projectId;
  final String modelId;
  const Frame3DPage({
    super.key,
    required this.projectId,
    required this.modelId,
  });

  @override
  ConsumerState<Frame3DPage> createState() => _Frame3DPageState();
}

class _Frame3DPageState extends ConsumerState<Frame3DPage> {
  _Tab _tab = _Tab.analyses;
  bool _tabChosen = false;
  int? _combo;
  MemberValue _colorBy = MemberValue.my;
  int _mode = 0;
  int? _selected;

  _DesignSort _designSort = _DesignSort.ratio;
  int _designShown = 50;

  /// Analysis whose results are shown.
  String? _active;

  /// Model (source key) each analysis was last run on; static analyses
  /// run by themselves. Kept for the session when the page is reopened
  /// (the results stay in the providers).
  Map<String, String> get _ran =>
      _ranByModel.putIfAbsent(widget.modelId, () => {});

  // Steel utilisation per member, cached for one set of results.
  List<double?>? _util;
  Object? _utilFor;

  /// Worst EC3 ratio of each steel member under the ULS envelope
  /// (S275, buckling length factors 1); null for other members.
  List<double?> _utilisation(Frame3DOutput out) {
    if (identical(_utilFor, out.results) && _util != null) return _util!;
    final m = out.model;
    final uls = [
      for (var i = 0; i < out.combinations.length; i++)
        if (out.combinations[i].kind == CombinationKind.uls) out.results[i],
    ];
    final values = <double?>[];
    for (var e = 0; e < m.elements.length; e++) {
      final name = m.sections[m.elements[e].section].profile;
      final p = name == null ? null : steelProfiles[name];
      if (p == null || !steelDesignable(p) || uls.isEmpty) {
        values.add(null);
        continue;
      }
      final f = MemberEnvelope3D.of(m, e, uls);
      try {
        final r = designSteelMember(
          SteelMemberInput(
            section: p,
            length: f.length,
            nEd: f.nCompression > 0 ? f.nCompression : -f.nTension,
            myEd: f.myMax,
            mzEd: f.mzMax,
            vEd: f.vzMax,
          ),
        );
        values.add(r.checks.map((c) => c.ratio).fold<double>(0, math.max));
      } on InputError {
        values.add(null);
      }
    }
    _utilFor = out.results;
    return _util = values;
  }

  final DesignCode _code = defaultDesignCode();
  Frame3DEditController? _edit;
  final _viewKey = GlobalKey();

  Future<void> _exportNote(
    Frame3DRecord record,
    Frame3DOutput? out,
    SeismicOutput? seismic,
  ) async {
    final l = context.l10n;
    if (out == null || out.error != null) return;
    final view = await captureImage(_viewKey);
    // The note includes modes and buckling: those of the first modal and
    // buckling analyses of the list (computed if needed).
    final key = sourceKey(record);
    final modalSpec = record.analyses
        .where((a) => a.kind == AnalysisKind.modal)
        .firstOrNull;
    final bucklingSpec = record.analyses
        .where((a) => a.kind == AnalysisKind.buckling)
        .firstOrNull;
    final full = out.merged(
      modal: await ref.read(
        frame3dModalProvider((key, modalSpec?.modes ?? 12)).future,
      ),
      buckling: await ref.read(
        frame3dBucklingProvider((
          key,
          _code,
          bucklingSpec?.combinationIn(out.combinations),
        )).future,
      ),
    );
    if (!mounted) return;
    final ok = await shareNote(
      context,
      frame3dNote(
        context,
        record: record,
        out: full,
        view: view,
        seismic: seismic,
      ),
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.noteFailed)));
    }
  }

  @override
  void didUpdateWidget(Frame3DPage old) {
    super.didUpdateWidget(old);
    // The router may reuse this page for another model: start afresh.
    if (old.modelId != widget.modelId) {
      _edit?.dispose();
      _edit = null;
      _tabChosen = false;
      _tab = _Tab.analyses;
      _active = null;
      _combo = null;
      _selected = null;
      _mode = 0;
      _util = null;
      _utilFor = null;
    }
  }

  @override
  void dispose() {
    _edit?.dispose();
    super.dispose();
  }

  String _analysisName(AppLocalizations l, AnalysisSpec a) {
    if (a.name.isNotEmpty) return a.name;
    return switch (a.kind) {
      AnalysisKind.static => l.f3dTabStatic,
      AnalysisKind.modal => l.f3dTabModes,
      AnalysisKind.spectrum => l.f3dTabSeismic,
      AnalysisKind.buckling => l.f3dTabBuckling,
      AnalysisKind.pDelta => l.f3dPDelta,
    };
  }

  IconData _analysisIcon(AnalysisKind k) => switch (k) {
    AnalysisKind.static => Icons.insights_rounded,
    AnalysisKind.modal => Icons.graphic_eq_rounded,
    AnalysisKind.spectrum => Icons.waves_outlined,
    AnalysisKind.buckling => Icons.compress_rounded,
    AnalysisKind.pDelta => Icons.trending_down_rounded,
  };

  /// Results of the analyses that have run on the current model.
  ({
    Map<String, _RunState> state,
    ModalOutput? modal,
    SeismicOutput? spectrum,
    BucklingOutput? buckling,
    Frame3DResult? pDelta,
  })
  _watchAnalyses(
    String key,
    List<AnalysisSpec> list,
    AnalysisSpec? active,
    Frame3DOutput? out,
  ) {
    final state = <String, _RunState>{};
    ModalOutput? modal;
    SeismicOutput? spectrum;
    BucklingOutput? buckling;
    Frame3DResult? pDelta;
    final combos = out?.combinations ?? const <Combination>[];
    for (final a in list) {
      if (a.kind == AnalysisKind.static) {
        state[a.id] = out == null
            ? _RunState.running
            : (out.error == null ? _RunState.done : _RunState.failed);
        continue;
      }
      final ran = _ran[a.id];
      if (ran == null) {
        state[a.id] = _RunState.notRun;
        continue;
      }
      if (ran != key) {
        state[a.id] = _RunState.stale;
        continue;
      }
      final AsyncValue<Object?> v = switch (a.kind) {
        AnalysisKind.modal => ref.watch(frame3dModalProvider((key, a.modes))),
        AnalysisKind.spectrum => ref.watch(
          frame3dSpectrumProvider((key, SpectrumRequest.of(a))),
        ),
        AnalysisKind.buckling => ref.watch(
          frame3dBucklingProvider((key, _code, a.combinationIn(combos))),
        ),
        _ => () {
          final c = a.combinationIn(combos);
          if (c == null) return const AsyncValue<Object?>.data(null);
          return ref.watch(frame3dPDeltaProvider((key, c, _code)));
        }(),
      };
      state[a.id] = v.isLoading
          ? _RunState.running
          : (v.hasError ? _RunState.failed : _RunState.done);
      if (a.id != active?.id || !v.hasValue) continue;
      switch (v.value) {
        case ModalOutput m:
          modal = m;
        case SeismicOutput s:
          spectrum = s;
        case BucklingOutput b:
          buckling = b;
        case Frame3DResult r:
          pDelta = r;
      }
    }
    return (
      state: state,
      modal: modal,
      spectrum: spectrum,
      buckling: buckling,
      pDelta: pDelta,
    );
  }

  Future<void> _saveAnalyses(
    Frame3DEditController edit,
    List<AnalysisSpec> l,
  ) => Frame3DRepository.save(edit.record.withAnalyses(l));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final record = ref.watch(frame3dRecordProvider(widget.modelId)).value;
    if (record == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final edit = _edit ??= Frame3DEditController(record)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    edit.sync(record);
    // Models without members open on the Edit tab.
    if (!_tabChosen) {
      _tabChosen = true;
      if (edit.model.elements.isEmpty) _tab = _Tab.edit;
    }
    final key = sourceKey(edit.record);
    final output = ref.watch(frame3dAnalysisProvider((key, _code)));
    final out = output.value;
    final analyses = edit.record.analyses;
    final active =
        analyses.where((a) => a.id == _active).firstOrNull ??
        analyses.firstOrNull;
    final runs = _watchAnalyses(key, analyses, active, out);
    // Member design, once asked for this model.
    final designRan = _ran[_designId] == key;
    final designValue = designRan
        ? ref.watch(frame3dDesignProvider((key, _code)))
        : null;
    final design = designValue?.value;
    // The Model tab shows the vibrating mass.
    final modelModal = _tab == _Tab.model
        ? ref.watch(frame3dModalProvider((key, 12))).value
        : null;
    final shown = _tab == _Tab.analyses ? active : null;
    final model = _tab == _Tab.edit ? edit.model : (out?.model ?? edit.model);

    final combos = out?.combinations ?? const <Combination>[];
    final allowed = <int>[
      for (var i = 0; i < combos.length; i++)
        if (shown?.combinations == null || shown!.combinations!.contains(i)) i,
    ];
    final combo = allowed.contains(_combo)
        ? _combo!
        : (allowed
                  .where((i) => combos[i].kind == CombinationKind.uls)
                  .firstOrNull ??
              allowed.firstOrNull ??
              0);
    Frame3DResult? staticResult;
    if (out != null && out.error == null && out.results.isNotEmpty) {
      staticResult = out.results[combo.clamp(0, out.results.length - 1)];
    }

    Widget viewer = switch ((_tab, shown?.kind)) {
      (_Tab.edit, _) => Frame3DView(
        model: edit.model,
        showNodes: true,
        loadCase: edit.activeCase,
        selectedNode: edit.tool == EditTool.multi ? null : edit.node,
        selectedMember: edit.tool == EditTool.multi ? null : edit.member,
        selectedNodes: edit.nodes,
        selectedMembers: edit.members,
        pendingNode: edit.connectFrom,
        onPick: edit.pick,
        workPlane: edit.tool == EditTool.draw || edit.model.nodes.isEmpty
            ? edit.plane
            : null,
        onPlaneTap: edit.tool == EditTool.draw ? edit.planeTap : null,
        camera: edit.camera,
      ),
      (_Tab.combos, _) => Frame3DView(model: model, loadCase: edit.activeCase),
      (_Tab.design, _) when design != null => Frame3DView(
        model: model,
        colorBy: MemberValue.utilisation,
        memberValues: design.ratios(model.elements.length),
        selectedMember: _selected,
        onPick: (p) {
          if (p is! MemberPick) return;
          final d = design.members
              .where((x) => x.member == p.member)
              .firstOrNull;
          if (d == null) return;
          setState(() => _selected = p.member);
          showMemberDesignResult(
            context,
            design: d,
            groupName:
                edit.model.groups
                    .where((g) => g.id == d.group)
                    .firstOrNull
                    ?.name ??
                '',
          );
        },
      ),
      (_, AnalysisKind.modal) when runs.modal?.modes.isNotEmpty ?? false =>
        Frame3DView(
          model: model,
          shape: runs
              .modal!
              .modes[_mode.clamp(0, runs.modal!.modes.length - 1)]
              .shape,
          animate: true,
        ),
      (_, AnalysisKind.buckling) when runs.buckling?.shape != null =>
        Frame3DView(model: model, shape: runs.buckling!.shape),
      (_, AnalysisKind.spectrum) when runs.spectrum != null => Frame3DView(
        model: model,
        result: runs.spectrum!.envelope,
        colorBy: _colorBy,
        selectedMember: _selected,
        onPick: (p) => _design(context, out, p, runs.spectrum),
      ),
      (_, AnalysisKind.pDelta) when runs.pDelta != null => Frame3DView(
        model: model,
        result: runs.pDelta,
        colorBy: _colorBy == MemberValue.utilisation
            ? MemberValue.my
            : _colorBy,
        selectedMember: _selected,
      ),
      (_, AnalysisKind.static) when staticResult != null => Frame3DView(
        model: model,
        result: staticResult,
        colorBy: _colorBy,
        memberValues: _colorBy == MemberValue.utilisation && out != null
            ? _utilisation(out)
            : null,
        selectedMember: _selected,
        onPick: (p) => _design(context, out, p, null),
      ),
      _ => Frame3DView(model: model),
    };
    final busy =
        output.isLoading ||
        runs.state.values.contains(_RunState.running) ||
        (designValue?.isLoading ?? false);
    viewer = RepaintBoundary(
      key: _viewKey,
      child: Stack(
        children: [
          Positioned.fill(child: viewer),
          if (busy)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );

    final panel = ListView(
      key: const ValueKey('frame3d-panel'),
      padding: const EdgeInsets.all(Gap.lg),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final t in _Tab.values)
                Padding(
                  padding: const EdgeInsets.only(right: Gap.sm),
                  child: ChoiceChip(
                    label: Text(switch (t) {
                      _Tab.model => l.f3dTabModel,
                      _Tab.edit => l.f3dTabEdit,
                      _Tab.combos => l.f3dTabCombos,
                      _Tab.analyses => l.f3dTabAnalyses,
                      _Tab.design => l.f3dTabDesign,
                    }),
                    selected: _tab == t,
                    onSelected: (_) => setState(() => _tab = t),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Gap.lg),
        ...switch (_tab) {
          _Tab.edit => [Frame3DEditPanel(c: edit)],
          _Tab.combos => _combosPanel(context, edit),
          _ when edit.model.elements.isEmpty => [
            StatusBanner(
              tone: Tone.primary,
              title: l.f3dEmptyEditTitle,
              message: l.f3dEmptyEdit,
            ),
          ],
          _Tab.design => _designPanel(
            context,
            edit,
            key,
            design,
            designValue?.isLoading ?? false,
          ),
          _Tab.model => _modelPanel(
            context,
            edit.record,
            model,
            out?.merged(modal: modelModal),
          ),
          _Tab.analyses => [
            ..._analysesList(context, edit, analyses, active, runs.state, key),
            const SizedBox(height: Gap.lg),
            if (out?.error != null)
              StatusBanner(
                tone: Tone.danger,
                title: l.frameAnalysisFailed,
                message: out!.error,
              )
            else if (active != null)
              ..._resultsOf(
                context,
                edit,
                active,
                runs.state[active.id] ?? _RunState.notRun,
                out,
                combo,
                allowed,
                staticResult,
                runs,
                key,
              ),
          ],
        },
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(record.name),
        actions: [
          ExportMenu(
            name: edit.record.name,
            sibot: () => encodeFrame3d(edit.record),
            dxf: () => model3dToDxf(edit.model),
          ),
          IconButton(
            tooltip: l.noteExport,
            onPressed: () => _exportNote(edit.record, out, runs.spectrum),
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          if (!edit.record.free)
            IconButton(
              tooltip: l.f3dEditBuilding,
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => showBuildingWizard(
                context,
                projectId: widget.projectId,
                existing: record,
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, box) {
          final card = Padding(
            padding: const EdgeInsets.all(Gap.md),
            child: SurfaceCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.lg),
                child: viewer,
              ),
            ),
          );
          if (box.maxWidth >= 900) {
            return Row(
              children: [
                Expanded(child: card),
                SizedBox(width: 400, child: panel),
              ],
            );
          }
          return Column(
            children: [
              SizedBox(
                height: math.min(420, box.maxHeight * 0.45),
                child: card,
              ),
              Expanded(child: panel),
            ],
          );
        },
      ),
    );
  }

  // ───────────────────────────── analyses ─────────────────────────────

  List<Widget> _analysesList(
    BuildContext context,
    Frame3DEditController edit,
    List<AnalysisSpec> list,
    AnalysisSpec? active,
    Map<String, _RunState> state,
    String key,
  ) {
    final l = context.l10n;
    Widget status(_RunState s) {
      final (text, tone) = switch (s) {
        _RunState.notRun => (l.f3dRunNotRun, context.colors.outline),
        _RunState.running => (l.f3dRunRunning, context.colors.primary),
        _RunState.done => (l.f3dRunDone, context.appColors.success),
        _RunState.stale => (l.f3dRunStale, context.appColors.warning),
        _RunState.failed => (l.f3dRunFailed, context.appColors.danger),
      };
      return Text(text, style: context.text.labelSmall?.copyWith(color: tone));
    }

    final runnable = [
      for (final a in list)
        if (a.kind != AnalysisKind.static) a.id,
    ];
    return [
      Row(
        children: [
          Expanded(
            child: Text(l.f3dAnalysesHelp, style: context.text.bodySmall),
          ),
          PopupMenuButton<AnalysisKind>(
            tooltip: l.f3dAddAnalysis,
            icon: const Icon(Icons.add_rounded),
            onSelected: (k) => _addAnalysis(context, edit, list, k),
            itemBuilder: (_) => [
              for (final k in AnalysisKind.values)
                PopupMenuItem(
                  value: k,
                  child: ListTile(
                    dense: true,
                    leading: Icon(_analysisIcon(k)),
                    title: Text(
                      _analysisName(l, AnalysisSpec(id: '', kind: k)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      const SizedBox(height: Gap.sm),
      SurfaceCard(
        padding: const EdgeInsets.symmetric(vertical: Gap.xs),
        child: Column(
          children: [
            for (final a in list)
              ListTile(
                selected: a.id == active?.id,
                leading: Icon(_analysisIcon(a.kind)),
                title: Text(_analysisName(l, a)),
                subtitle: status(state[a.id] ?? _RunState.notRun),
                onTap: () => setState(() {
                  _active = a.id;
                  _selected = null;
                }),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (a.kind != AnalysisKind.static)
                      IconButton(
                        tooltip: l.f3dRun,
                        icon: const Icon(Icons.play_arrow_rounded),
                        onPressed: () => setState(() {
                          _ran[a.id] = key;
                          _active = a.id;
                        }),
                      ),
                    IconButton(
                      tooltip: l.f3dAnalysisSettings,
                      icon: const Icon(Icons.tune_rounded),
                      onPressed: () => _editAnalysis(context, edit, list, a),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: Gap.sm),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.tonalIcon(
          onPressed: runnable.isEmpty
              ? null
              : () => setState(() {
                  for (final id in runnable) {
                    _ran[id] = key;
                  }
                }),
          icon: const Icon(Icons.playlist_play_rounded),
          label: Text(l.f3dRunAll),
        ),
      ),
    ];
  }

  Future<void> _addAnalysis(
    BuildContext context,
    Frame3DEditController edit,
    List<AnalysisSpec> list,
    AnalysisKind kind,
  ) async {
    final spec = AnalysisSpec(
      id: 'a${DateTime.now().microsecondsSinceEpoch}',
      kind: kind,
    );
    final edited = await showAnalysisSettings(
      context,
      spec: spec,
      combinations: combinationsOf(edit.model, _code),
    );
    if (edited == null) return;
    await _saveAnalyses(edit, [...list, edited]);
    setState(() => _active = edited.id);
  }

  Future<void> _editAnalysis(
    BuildContext context,
    Frame3DEditController edit,
    List<AnalysisSpec> list,
    AnalysisSpec a,
  ) async {
    final result = await showAnalysisSettings(
      context,
      spec: a,
      combinations: combinationsOf(edit.model, _code),
      canDelete: true,
    );
    if (result == null) return;
    if (identical(result, deletedAnalysis)) {
      await _saveAnalyses(edit, [
        for (final x in list)
          if (x.id != a.id) x,
      ]);
      _ran.remove(a.id);
      return;
    }
    await _saveAnalyses(edit, [
      for (final x in list) x.id == a.id ? result : x,
    ]);
    // New settings: the old run no longer applies.
    _ran.remove(a.id);
    setState(() {});
  }

  List<Widget> _resultsOf(
    BuildContext context,
    Frame3DEditController edit,
    AnalysisSpec a,
    _RunState state,
    Frame3DOutput? out,
    int combo,
    List<int> allowed,
    Frame3DResult? staticResult,
    ({
      Map<String, _RunState> state,
      ModalOutput? modal,
      SeismicOutput? spectrum,
      BucklingOutput? buckling,
      Frame3DResult? pDelta,
    })
    runs,
    String key,
  ) {
    final l = context.l10n;
    final title = Text(_analysisName(l, a), style: context.text.titleMedium);
    if (a.kind != AnalysisKind.static) {
      switch (state) {
        case _RunState.notRun || _RunState.stale:
          return [
            title,
            const SizedBox(height: Gap.sm),
            StatusBanner(
              tone: state == _RunState.stale ? Tone.warning : Tone.primary,
              title: state == _RunState.stale ? l.f3dRunStale : l.f3dRunNotRun,
              message: l.f3dRunHelp,
            ),
            const SizedBox(height: Gap.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => setState(() => _ran[a.id] = key),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l.f3dRun),
              ),
            ),
          ];
        case _RunState.running:
          return [title, const LinearProgressIndicator()];
        case _RunState.failed:
          return [
            title,
            StatusBanner(tone: Tone.danger, title: l.frameAnalysisFailed),
          ];
        case _RunState.done:
          break;
      }
    }
    return [
      title,
      const SizedBox(height: Gap.md),
      ...switch (a.kind) {
        AnalysisKind.static => _staticPanel(
          context,
          out,
          combo,
          allowed,
          staticResult,
        ),
        AnalysisKind.modal => _modesPanel(context, runs.modal),
        AnalysisKind.spectrum => _seismicPanel(context, runs.spectrum),
        AnalysisKind.buckling => _bucklingPanel(
          context,
          runs.buckling,
          out == null ? null : a.combinationIn(out.combinations),
          out,
        ),
        AnalysisKind.pDelta => [
          if (out != null)
            Text(
              out.combinations[a.combinationIn(out.combinations) ?? 0].name,
              style: context.text.bodySmall,
            ),
          const SizedBox(height: Gap.sm),
          _colorChoice(context),
          const SizedBox(height: Gap.md),
          if (runs.pDelta != null && out != null)
            _staticSummary(context, out.model, runs.pDelta!),
          const SizedBox(height: Gap.md),
          NotesCard(notes: [l.f3dPDeltaHelp]),
        ],
      },
    ];
  }

  // ───────────────────────────── design ─────────────────────────────

  static const _designId = '__design';

  List<Widget> _designPanel(
    BuildContext context,
    Frame3DEditController edit,
    String key,
    DesignOutput? design,
    bool running,
  ) {
    final l = context.l10n;
    final m = edit.model;
    final groups = m.groups;
    final ran = _ran[_designId];
    final stale = ran != null && ran != key;
    Future<void> setGroups(List<DesignGroup> next) =>
        edit.apply(m.copyWith(groups: next));

    final rows = <Widget>[];
    if (design != null && !stale) {
      final names = {for (final g in groups) g.id: g.name};
      final list = [...design.members];
      switch (_designSort) {
        case _DesignSort.ratio:
          list.sort((a, b) => b.ratio.compareTo(a.ratio));
        case _DesignSort.member:
          list.sort((a, b) => a.member.compareTo(b.member));
        case _DesignSort.group:
          list.sort(
            (a, b) => (names[a.group] ?? '').compareTo(names[b.group] ?? ''),
          );
      }
      final ok = design.members.length - design.failing;
      rows.addAll([
        if (design.error != null)
          StatusBanner(
            tone: Tone.danger,
            title: l.f3dDesignFailed,
            message: design.error == 'uls' ? l.f3dDesignNoUls : design.error,
          )
        else
          StatusBanner(
            tone: design.failing == 0 ? Tone.success : Tone.danger,
            title: l.f3dDesignCounts(ok, design.failing),
            message: design.ungrouped > 0
                ? l.f3dDesignUngrouped(design.ungrouped)
                : null,
          ),
        const SizedBox(height: Gap.md),
        ChoiceField<_DesignSort>(
          label: l.f3dSortBy,
          value: _designSort,
          options: {
            _DesignSort.ratio: l.f3dUtilisation,
            _DesignSort.member: l.f3dSortMember,
            _DesignSort.group: l.f3dSortGroup,
          },
          onChanged: (v) => setState(() => _designSort = v),
        ),
        const SizedBox(height: Gap.sm),
        SurfaceCard(
          padding: const EdgeInsets.symmetric(vertical: Gap.xs),
          child: Column(
            children: [
              for (final d in list.take(_designShown))
                ListTile(
                  dense: true,
                  selected: d.member == _selected,
                  title: Text(
                    '${l.frameMemberTitle(d.member + 1)} · ${names[d.group] ?? ''}',
                  ),
                  subtitle: Text(
                    d.error != null
                        ? l.f3dDesignFailed
                        : '${d.summary}\n${d.governing == null ? '' : checkLabel(l, d.governing!.kind)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    d.ratio.isFinite ? fmt(context, d.ratio, 2) : '—',
                    style: AppTheme.mono(context, size: 15).copyWith(
                      color: d.ok
                          ? context.appColors.success
                          : context.appColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    setState(() => _selected = d.member);
                    showMemberDesignResult(
                      context,
                      design: d,
                      groupName: names[d.group] ?? '',
                    );
                  },
                ),
              if (list.length > _designShown)
                TextButton(
                  onPressed: () => setState(() => _designShown += 50),
                  child: Text(l.f3dShowMore(list.length - _designShown)),
                ),
            ],
          ),
        ),
      ]);
    }

    return [
      Text(l.f3dDesignHelp, style: context.text.bodySmall),
      const SizedBox(height: Gap.md),
      Wrap(
        spacing: Gap.sm,
        runSpacing: Gap.sm,
        children: [
          FilledButton.tonalIcon(
            onPressed: () => _editGroup(context, edit, null),
            icon: const Icon(Icons.add_rounded),
            label: Text(l.f3dGroupAdd),
          ),
          OutlinedButton.icon(
            onPressed: () => setGroups(
              autoGroups(
                m,
                (mat, k) => autoGroupName(l, mat, k),
                existing: groups,
              ),
            ),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(l.f3dGroupAuto),
          ),
        ],
      ),
      const SizedBox(height: Gap.md),
      if (groups.isEmpty)
        StatusBanner(tone: Tone.primary, title: l.f3dNoGroups)
      else
        SurfaceCard(
          padding: const EdgeInsets.symmetric(vertical: Gap.xs),
          child: Column(
            children: [
              for (final g in groups)
                ListTile(
                  leading: Icon(switch (g.material) {
                    DesignMaterial.concrete => Icons.view_column_outlined,
                    DesignMaterial.steel => Icons.horizontal_split_outlined,
                    DesignMaterial.timber => Icons.forest_outlined,
                  }),
                  title: Text(g.name),
                  subtitle: Text(
                    '${materialLabel(l, g.material)} · ${l.f3dGroupMembers(g.members.length)}',
                  ),
                  trailing: const Icon(Icons.tune_rounded),
                  onTap: () => _editGroup(context, edit, g),
                ),
            ],
          ),
        ),
      const SizedBox(height: Gap.md),
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          onPressed: groups.isEmpty
              ? null
              : () => setState(() {
                  _ran[_designId] = key;
                  _designShown = 50;
                }),
          icon: const Icon(Icons.fact_check_outlined),
          label: Text(l.f3dDesignAll),
        ),
      ),
      const SizedBox(height: Gap.md),
      if (stale)
        StatusBanner(
          tone: Tone.warning,
          title: l.f3dRunStale,
          message: l.f3dRunHelp,
        )
      else if (running)
        const LinearProgressIndicator(),
      ...rows,
    ];
  }

  Future<void> _editGroup(
    BuildContext context,
    Frame3DEditController edit,
    DesignGroup? group,
  ) async {
    final l = context.l10n;
    final m = edit.model;
    final g =
        group ??
        DesignGroup(
          id: 'g${DateTime.now().microsecondsSinceEpoch}',
          name: l.f3dGroupDefaultName(m.groups.length + 1),
          members: const [],
          material: DesignMaterial.concrete,
          code: _code,
        );
    final result = await showGroupSettings(
      context,
      group: g,
      model: m,
      selection: {...edit.members},
      canDelete: group != null,
    );
    if (result == null) return;
    final next = [
      for (final x in m.groups)
        if (x.id != g.id) x else if (!identical(result, deletedGroup)) result,
      if (group == null) result,
    ];
    await edit.apply(m.copyWith(groups: next));
  }

  // ─────────────────────────── combinations ───────────────────────────

  List<Widget> _combosPanel(BuildContext context, Frame3DEditController edit) {
    final l = context.l10n;
    final m = edit.model;
    final own = m.combinations != null;
    final list = combinationsOf(m, _code);
    String factors(Combination c) => [
      for (final e in c.factors.entries)
        if (e.key < m.cases.length)
          '${fmt(context, e.value, 2)} ${m.cases[e.key].name}'
        else
          '${fmt(context, e.value, 2)} ?',
    ].join(' + ');
    String kind(CombinationKind k) => switch (k) {
      CombinationKind.uls => l.f3dComboUls,
      CombinationKind.slsCharacteristic => l.f3dComboSlsChar,
      CombinationKind.slsQuasiPermanent => l.f3dComboSlsQp,
    };
    return [
      StatusBanner(
        tone: own ? Tone.primary : Tone.success,
        title: own ? l.f3dCombosOwn : l.f3dCombosAuto,
        message: own ? l.f3dCombosOwnMsg : l.f3dCombosAutoMsg,
      ),
      const SizedBox(height: Gap.sm),
      Wrap(
        spacing: Gap.sm,
        runSpacing: Gap.sm,
        children: [
          FilledButton.tonalIcon(
            onPressed: () => _editCombination(context, edit, list, null),
            icon: const Icon(Icons.add_rounded),
            label: Text(l.f3dComboAdd),
          ),
          if (own)
            OutlinedButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    content: Text(l.f3dCombosResetConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l.commonCancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(l.f3dConfirm),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await edit.apply(m.copyWith(autoCombinations: true));
                }
              },
              icon: const Icon(Icons.auto_mode_rounded),
              label: Text(l.f3dCombosReset),
            ),
        ],
      ),
      const SizedBox(height: Gap.md),
      SurfaceCard(
        padding: const EdgeInsets.symmetric(vertical: Gap.xs),
        child: Column(
          children: [
            for (var i = 0; i < list.length; i++)
              ListTile(
                title: Text(list[i].name),
                subtitle: Text(
                  '${kind(list[i].kind)} · ${factors(list[i])}',
                  style: AppTheme.mono(context, size: 12),
                ),
                leading: combinationValid(m, list[i])
                    ? const Icon(Icons.functions_rounded)
                    : Icon(
                        Icons.error_outline_rounded,
                        color: context.appColors.danger,
                      ),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _editCombination(context, edit, list, i),
              ),
          ],
        ),
      ),
      const SizedBox(height: Gap.sm),
      NotesCard(notes: [l.f3dCombosNote]),
    ];
  }

  Future<void> _editCombination(
    BuildContext context,
    Frame3DEditController edit,
    List<Combination> list,
    int? index,
  ) async {
    final m = edit.model;
    final result = await showCombinationEditor(
      context,
      cases: [for (final c in m.cases) c.name],
      initial: index == null ? null : list[index],
      canDelete: index != null,
    );
    if (result == null) return;
    final next = [...list];
    if (identical(result, deletedCombination)) {
      next.removeAt(index!);
    } else if (index == null) {
      next.add(result);
    } else {
      next[index] = result;
    }
    await edit.apply(m.copyWith(combinations: next));
  }

  List<Widget> _modelPanel(
    BuildContext context,
    Frame3DRecord record,
    Model3D model,
    Frame3DOutput? out,
  ) {
    final l = context.l10n;
    final p = record.params;
    final mass = out?.totalMass[0];
    if (record.free) {
      final kinds = {
        for (final k in MemberKind.values) k: model.elementsOfKind(k).length,
      };
      return [
        ResultCard(
          title: l.f3dTabModel,
          icon: Icons.view_in_ar_outlined,
          rows: [
            ResultRow(
              label: l.f3dNodesMembers,
              value: '${model.nodes.length} / ${model.elements.length}',
            ),
            ResultRow(
              label:
                  '${l.f3dSelectColumns} / ${l.f3dSelectBeams} / ${l.f3dSelectBraces}',
              value:
                  '${kinds[MemberKind.column]} / ${kinds[MemberKind.beam]} / ${kinds[MemberKind.brace]}',
            ),
            ResultRow(label: l.f3dSupport, value: '${model.supports.length}'),
            ResultRow(
              label: l.f3dSection,
              value: model.sections.map((s) => s.name).join(', '),
            ),
            ResultRow(
              label: l.f3dLoadCase,
              value: model.cases.map((c) => c.name).join(', '),
            ),
            if (mass != null)
              ResultRow(
                label: l.f3dSeismicMass,
                symbol: 'G + 0.3 Q',
                value: fmt(context, mass, 0),
                unit: 't',
              ),
          ],
        ),
        const SizedBox(height: Gap.md),
        NotesCard(notes: [if (model.plane) l.f3dPlaneModel, l.f3dFreeNote]),
      ];
    }
    return [
      ResultCard(
        title: l.f3dTabModel,
        icon: Icons.view_in_ar_outlined,
        rows: [
          ResultRow(
            label: l.f3dGrid,
            value: l.f3dGridSummary(
              p.spansX.length,
              p.spansY.length,
              p.storeyHeights.length,
            ),
          ),
          ResultRow(
            label: l.f3dFootprint,
            value:
                '${fmt(context, p.spansX.fold(0.0, (a, b) => a + b), 1)} × ${fmt(context, p.spansY.fold(0.0, (a, b) => a + b), 1)} × ${fmt(context, p.storeyHeights.fold(0.0, (a, b) => a + b), 1)}',
            unit: 'm',
          ),
          ResultRow(
            label: l.f3dNodesMembers,
            value: '${model.nodes.length} / ${model.elements.length}',
          ),
          ResultRow(label: l.f3dColumns, value: p.column.name),
          ResultRow(label: l.f3dBeams, value: p.beam.name),
          ResultRow(
            label: l.f3dLoads,
            symbol: 'g / q',
            value: '${fmt(context, p.g, 2)} / ${fmt(context, p.q, 2)}',
            unit: 'kN/m²',
          ),
          if (mass != null)
            ResultRow(
              label: l.f3dSeismicMass,
              symbol: 'G + 0.3 Q',
              value: fmt(context, mass, 0),
              unit: 't',
            ),
        ],
      ),
      const SizedBox(height: Gap.md),
      NotesCard(notes: [l.f3dModelNote]),
    ];
  }

  ChoiceField<MemberValue> _colorChoice(BuildContext context) {
    final l = context.l10n;
    return ChoiceField<MemberValue>(
      label: l.f3dColourBy,
      value: _colorBy,
      options: {
        MemberValue.none: l.f3dDeformed,
        MemberValue.my: 'My',
        MemberValue.mz: 'Mz',
        MemberValue.n: 'N',
        MemberValue.utilisation: l.f3dUtil,
      },
      onChanged: (v) => setState(() => _colorBy = v),
    );
  }

  List<Widget> _staticPanel(
    BuildContext context,
    Frame3DOutput? out,
    int combo,
    List<int> allowed,
    Frame3DResult? r,
  ) {
    final l = context.l10n;
    if (out == null) return const [LinearProgressIndicator()];
    if (allowed.isEmpty) {
      return [StatusBanner(tone: Tone.warning, title: l.f3dNoCombination)];
    }
    final c = allowed.contains(combo) ? combo : allowed.first;
    return [
      PickerField<int>(
        key: ValueKey('combo-$c-${allowed.length}'),
        label: l.f3dCombination,
        value: c,
        options: {for (final i in allowed) i: out.combinations[i].name},
        onChanged: (v) => setState(() => _combo = v),
      ),
      const SizedBox(height: Gap.md),
      _colorChoice(context),
      const SizedBox(height: Gap.md),
      Text(l.f3dTapToDesign, style: context.text.bodySmall),
      const SizedBox(height: Gap.md),
      if (r == null)
        const LinearProgressIndicator()
      else
        _staticSummary(context, out.model, r),
    ];
  }

  Widget _staticSummary(BuildContext context, Model3D m, Frame3DResult r) {
    final l = context.l10n;
    var uz = 0.0, uxy = 0.0, my = 0.0, nc = 0.0;
    for (final d in r.displacements) {
      uz = math.max(uz, d[2].abs());
      uxy = math.max(uxy, math.sqrt(d[0] * d[0] + d[1] * d[1]));
    }
    for (var e = 0; e < r.members.length; e++) {
      for (final st in r.members[e].stations) {
        if (m.elements[e].section == 1) my = math.max(my, st.my.abs());
        if (m.elements[e].section == 0) nc = math.max(nc, -st.n);
      }
      // Mid-span deflections also count for the vertical maximum.
      for (final st in r.members[e].stations) {
        uz = math.max(uz, st.disp[2].abs());
      }
    }
    final vz = r.reactions.values.fold(0.0, (s, v) => s + v[2]);
    return ResultCard(
      title: l.f3dTabStatic,
      icon: Icons.insights_rounded,
      rows: [
        ResultRow(
          label: l.f3dMaxVertical,
          symbol: 'uz',
          value: fmt(context, uz * 1000, 1),
          unit: 'mm',
        ),
        ResultRow(
          label: l.f3dMaxLateral,
          symbol: 'uxy',
          value: fmt(context, uxy * 1000, 1),
          unit: 'mm',
        ),
        ResultRow(
          label: l.f3dMaxBeamMoment,
          symbol: '|My|',
          value: fmt(context, my),
          unit: 'kN·m',
          emphasize: true,
        ),
        ResultRow(
          label: l.f3dMaxColumnLoad,
          symbol: 'N',
          value: fmt(context, nc),
          unit: 'kN',
          emphasize: true,
        ),
        ResultRow(
          label: l.f3dTotalReaction,
          symbol: 'ΣRz',
          value: fmt(context, vz),
          unit: 'kN',
        ),
      ],
    );
  }

  List<Widget> _modesPanel(BuildContext context, ModalOutput? out) {
    final l = context.l10n;
    if (out == null) return const [LinearProgressIndicator()];
    if (out.modes.isEmpty) {
      return [StatusBanner(tone: Tone.warning, title: l.f3dNoModes)];
    }
    String pct(double v) => '${fmt(context, v * 100, 1)} %';
    final cum = [
      for (var d = 0; d < 2; d++)
        out.modes.fold(0.0, (s, m) => s + m.massRatio[d]),
    ];
    return [
      Text(l.f3dModesHelp, style: context.text.bodySmall),
      const SizedBox(height: Gap.md),
      SurfaceCard(
        padding: const EdgeInsets.symmetric(vertical: Gap.sm),
        child: Column(
          children: [
            for (var k = 0; k < out.modes.length; k++)
              ListTile(
                dense: true,
                selected: k == _mode,
                leading: CircleAvatar(radius: 14, child: Text('${k + 1}')),
                title: Text(
                  'T = ${fmt(context, out.modes[k].period, 3)} s  ·  f = ${fmt(context, out.modes[k].frequency, 2)} Hz',
                  style: AppTheme.mono(context, size: 13),
                ),
                subtitle: Text(
                  'X ${pct(out.modes[k].massRatio[0])}   Y ${pct(out.modes[k].massRatio[1])}',
                ),
                onTap: () => setState(() => _mode = k),
              ),
          ],
        ),
      ),
      const SizedBox(height: Gap.md),
      StatusBanner(
        tone: cum.every((v) => v >= 0.9) ? Tone.success : Tone.warning,
        title: l.f3dCumulativeMass(pct(cum[0]), pct(cum[1])),
        message: l.f3dCumulativeHelp,
      ),
    ];
  }

  List<Widget> _seismicPanel(BuildContext context, SeismicOutput? s) {
    final l = context.l10n;
    if (s == null) return const [LinearProgressIndicator()];
    return [
      for (final run in s.runs) ...[
        StatusBanner(
          tone: run.enoughModes ? Tone.success : Tone.warning,
          title: l.f3dBaseShearDir(
            run.direction == 0 ? 'X' : 'Y',
            fmt(context, run.baseShear, 0),
          ),
          message: [
            l.f3dSpectrumMass(fmt(context, run.massRatio * 100, 1)),
            if (run.torsionMoments.isNotEmpty)
              l.f3dTorsionApplied(
                fmt(context, run.torsionMoments.reduce((a, b) => a + b), 0),
              ),
          ].join(' '),
        ),
        const SizedBox(height: Gap.sm),
      ],
      if (s.runs.length > 1)
        Text(l.f3dCombinedNote, style: context.text.bodySmall),
      Text(l.f3dTapToDesign, style: context.text.bodySmall),
      const SizedBox(height: Gap.md),
      _colorChoice(context),
      const SizedBox(height: Gap.md),
      for (final run in s.runs) ...[
        ResultCard(
          title:
              '${l.f3dModalContributions} (${run.direction == 0 ? 'X' : 'Y'})',
          icon: Icons.stacked_bar_chart_rounded,
          rows: [
            for (final m in run.modal.where(
              (m) => m.baseShear > 0.005 * run.baseShear,
            ))
              ResultRow(
                label: l.f3dModeN(m.mode + 1),
                symbol:
                    'T ${fmt(context, m.period, 3)} s · Sd ${fmt(context, m.sd, 2)}',
                value: fmt(context, m.baseShear, 0),
                unit: 'kN',
              ),
          ],
        ),
        const SizedBox(height: Gap.md),
      ],
      const SizedBox(height: Gap.md),
      NotesCard(notes: [l.f3dSpectrumNote]),
    ];
  }

  List<Widget> _bucklingPanel(
    BuildContext context,
    BucklingOutput? b,
    int? combo,
    Frame3DOutput? out,
  ) {
    final l = context.l10n;
    if (b == null) return const [LinearProgressIndicator()];
    final a = b.alpha;
    if (a == null) {
      return [StatusBanner(tone: Tone.success, title: l.f3dNoBuckling)];
    }
    final tone = a >= 10 ? Tone.success : (a >= 3 ? Tone.warning : Tone.danger);
    final message = a >= 10
        ? l.f3dAlphaFirstOrder
        : (a >= 3 ? l.f3dAlphaSecondOrder : l.f3dAlphaTooLow);
    final name = out != null && combo != null && combo < out.combinations.length
        ? out.combinations[combo].name
        : '';
    return [
      StatusBanner(
        tone: tone,
        title: l.f3dAlphaCr(fmt(context, a, 2)),
        message: message,
      ),
      const SizedBox(height: Gap.md),
      NotesCard(notes: [l.f3dBucklingNote(name)]),
    ];
  }

  /// Opens the design of a tapped member from the ULS envelope, or from
  /// the seismic situations G + 0.3 Q ± E when [seismic] is given.
  Future<void> _design(
    BuildContext context,
    Frame3DOutput? out,
    Pick3D? pick,
    SeismicOutput? seismic,
  ) async {
    if (out == null || pick is! MemberPick) return;
    setState(() => _selected = pick.member);
    final List<Frame3DResult> results;
    final quasi = out.quasiPermanent;
    if (seismic != null && quasi != null) {
      results = seismicSituations(quasi, seismic.envelope);
    } else {
      results = [
        for (var i = 0; i < out.combinations.length; i++)
          if (out.combinations[i].kind == CombinationKind.uls) out.results[i],
      ];
    }
    if (results.isEmpty) return;
    await showMember3DDesign(
      context,
      model: out.model,
      index: pick.member,
      results: results,
      seismic: seismic != null,
    );
  }
}
