import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/calculations/loads/presentation/seismic_provider.dart'
    show frenchZones;
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/frame3d/frame3d_data.dart';
import 'package:sibot/features/frame3d/frame3d_view.dart';
import 'package:sibot/features/projects/presentation/widgets/project_widgets.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// 3D building models of a project.
class Frame3DModelsPage extends ConsumerWidget {
  final String projectId;
  const Frame3DModelsPage({super.key, required this.projectId});

  Future<void> _create(BuildContext context) async {
    final record = await showBuildingWizard(context, projectId: projectId);
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
      eyebrow: l.catAnalysis,
      subtitle: l.f3dSubtitle,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.f3dNewBuilding),
      ),
      children: [
        const BetaNotice(),
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
                    label: Text(l.f3dNewBuilding),
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
                                    '${l.f3dGridSummary(r.params.spansX.length, r.params.spansY.length, r.params.storeyHeights.length)}  ·  ${relativeDate(context, r.updatedAt)}',
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
    final profiles = {for (final k in steelSections.keys) k: k};
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

enum _Tab { model, statics, modes, seismic, buckling }

/// Analysis of one 3D building: viewer and result panels.
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
  _Tab _tab = _Tab.statics;
  int? _combo;
  MemberValue _colorBy = MemberValue.my;
  bool _pDelta = false;
  int _mode = 0;
  final DesignCode _code = defaultDesignCode();

  // Seismic input; the analysis runs when [_spectrum] is set.
  String _zone = '4';
  double? _agR = frenchZones[4];
  int _importance = 2;
  GroundType _ground = GroundType.b;
  double? _q = 1.5;
  int _direction = 2;
  bool _torsion = true;
  SpectrumRequest? _spectrum;

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
    final key = paramsKey(record.params);
    final output = ref.watch(frame3dAnalysisProvider((key, _code)));
    final out = output.value;
    final model = out?.model ?? buildingFrame(record.params);

    final combo = _combo ?? out?.firstUls ?? 0;
    Frame3DResult? staticResult;
    if (out != null && out.error == null && out.results.isNotEmpty) {
      final c = combo.clamp(0, out.results.length - 1);
      final uls = out.combinations[c].kind == CombinationKind.uls;
      staticResult = _pDelta && uls
          ? ref.watch(frame3dPDeltaProvider((key, c, _code))).value
          : out.results[c];
    }
    SeismicOutput? spectrum;
    if (_spectrum != null) {
      spectrum = ref.watch(frame3dSpectrumProvider((key, _spectrum!))).value;
    }

    Widget viewer = switch (_tab) {
      _Tab.modes when out != null && out.modes.isNotEmpty => Frame3DView(
        model: model,
        shape: out.modes[_mode.clamp(0, out.modes.length - 1)].shape,
        animate: true,
      ),
      _Tab.buckling when out?.bucklingShape != null => Frame3DView(
        model: model,
        shape: out!.bucklingShape,
      ),
      _Tab.seismic when spectrum != null => Frame3DView(
        model: model,
        result: spectrum.envelope,
        colorBy: _colorBy,
      ),
      _Tab.statics when staticResult != null => Frame3DView(
        model: model,
        result: staticResult,
        colorBy: _colorBy,
      ),
      _ => Frame3DView(model: model),
    };
    viewer = Stack(
      children: [
        Positioned.fill(child: viewer),
        if (output.isLoading)
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );

    final panel = ListView(
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
                      _Tab.statics => l.f3dTabStatic,
                      _Tab.modes => l.f3dTabModes,
                      _Tab.seismic => l.f3dTabSeismic,
                      _Tab.buckling => l.f3dTabBuckling,
                    }),
                    selected: _tab == t,
                    onSelected: (_) => setState(() => _tab = t),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Gap.lg),
        if (out?.error != null)
          StatusBanner(
            tone: Tone.danger,
            title: l.frameAnalysisFailed,
            message: out!.error,
          )
        else
          ...switch (_tab) {
            _Tab.model => _modelPanel(context, record, model, out),
            _Tab.statics => _staticPanel(context, out, combo, staticResult),
            _Tab.modes => _modesPanel(context, out),
            _Tab.seismic => _seismicPanel(context, spectrum),
            _Tab.buckling => _bucklingPanel(context, out),
          },
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(record.name),
        actions: [
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

  List<Widget> _modelPanel(
    BuildContext context,
    Frame3DRecord record,
    Model3D model,
    Frame3DOutput? out,
  ) {
    final l = context.l10n;
    final p = record.params;
    final mass = out?.totalMass[0];
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
      },
      onChanged: (v) => setState(() => _colorBy = v),
    );
  }

  List<Widget> _staticPanel(
    BuildContext context,
    Frame3DOutput? out,
    int combo,
    Frame3DResult? r,
  ) {
    final l = context.l10n;
    if (out == null) return const [LinearProgressIndicator()];
    final c = combo.clamp(0, out.combinations.length - 1);
    final uls = out.combinations[c].kind == CombinationKind.uls;
    return [
      PickerField<int>(
        key: ValueKey('combo-$c'),
        label: l.f3dCombination,
        value: c,
        options: {
          for (var i = 0; i < out.combinations.length; i++)
            i: out.combinations[i].name,
        },
        onChanged: (v) => setState(() => _combo = v),
      ),
      const SizedBox(height: Gap.md),
      _colorChoice(context),
      if (uls)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.f3dPDelta),
          subtitle: Text(l.f3dPDeltaHelp),
          value: _pDelta,
          onChanged: (v) => setState(() => _pDelta = v),
        ),
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

  List<Widget> _modesPanel(BuildContext context, Frame3DOutput? out) {
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
    return [
      PickerField<String>(
        key: ValueKey('zone-$_zone'),
        label: l.seismicZone,
        value: _zone,
        options: {
          'custom': l.seismicZoneCustom,
          for (final z in frenchZones.entries)
            '${z.key}': l.seismicZoneN(z.key, fmt(context, z.value, 1)),
        },
        onChanged: (v) => setState(() {
          _zone = v;
          final n = int.tryParse(v);
          if (n != null) _agR = frenchZones[n];
        }),
      ),
      const SizedBox(height: Gap.md),
      FieldRow(
        children: [
          NumberField(
            key: ValueKey('ag-$_zone'),
            label: l.seismicAgR,
            unit: 'm/s²',
            value: _agR,
            onChanged: (v) => _agR = v,
          ),
          NumberField(label: l.seismicQ, value: _q, onChanged: (v) => _q = v),
        ],
      ),
      const SizedBox(height: Gap.md),
      ChoiceField<GroundType>(
        label: l.seismicGround,
        value: _ground,
        options: {for (final g in GroundType.values) g: g.name.toUpperCase()},
        onChanged: (v) => setState(() => _ground = v),
      ),
      const SizedBox(height: Gap.md),
      ChoiceField<int>(
        label: l.seismicImportance,
        value: _importance,
        options: const {1: 'I', 2: 'II', 3: 'III', 4: 'IV'},
        onChanged: (v) => setState(() => _importance = v),
      ),
      const SizedBox(height: Gap.md),
      ChoiceField<int>(
        label: l.f3dDirection,
        value: _direction,
        options: {0: 'X', 1: 'Y', 2: l.f3dBothDirections},
        onChanged: (v) => setState(() => _direction = v),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l.f3dAccidentalTorsion),
        subtitle: Text(l.f3dAccidentalTorsionHelp),
        value: _torsion,
        onChanged: (v) => setState(() => _torsion = v),
      ),
      const SizedBox(height: Gap.sm),
      FilledButton.icon(
        onPressed: () {
          if ((_agR ?? 0) <= 0 || (_q ?? 0) < 1) return;
          setState(
            () => _spectrum = SpectrumRequest(
              agR: _agR!,
              ground: _ground,
              importance: _importance,
              type1: _zone == '5',
              q: _q!,
              direction: _direction,
              torsion: _torsion,
            ),
          );
        },
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(l.f3dRunSpectrum),
      ),
      const SizedBox(height: Gap.md),
      if (_spectrum != null && s == null) const LinearProgressIndicator(),
      if (s != null) ...[
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
      ],
    ];
  }

  List<Widget> _bucklingPanel(BuildContext context, Frame3DOutput? out) {
    final l = context.l10n;
    if (out == null) return const [LinearProgressIndicator()];
    final a = out.alphaCr;
    if (a == null) {
      return [StatusBanner(tone: Tone.success, title: l.f3dNoBuckling)];
    }
    final tone = a >= 10 ? Tone.success : (a >= 3 ? Tone.warning : Tone.danger);
    final message = a >= 10
        ? l.f3dAlphaFirstOrder
        : (a >= 3 ? l.f3dAlphaSecondOrder : l.f3dAlphaTooLow);
    return [
      StatusBanner(
        tone: tone,
        title: l.f3dAlphaCr(fmt(context, a, 2)),
        message: message,
      ),
      const SizedBox(height: Gap.md),
      NotesCard(
        notes: [
          l.f3dBucklingNote(
            out.firstUls == null ? '' : out.combinations[out.firstUls!].name,
          ),
        ],
      ),
    ];
  }
}
