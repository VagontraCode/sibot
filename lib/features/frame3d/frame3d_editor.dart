import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/frame3d/frame3d_data.dart';
import 'package:sibot/features/frame3d/frame3d_view.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// Editing tools: pick one item, draw members on the working plane, or
/// build a multi-selection.
enum EditTool { select, draw, multi }

/// Editing state of a 3D model: tools, selection, working plane, undo
/// and autosave.
class Frame3DEditController extends ChangeNotifier {
  Frame3DRecord _record;
  Model3D? _model;
  final List<Frame3DRecord> _undo = [];

  EditTool tool = EditTool.select;
  int? node;
  int? member;

  /// Multi-selection.
  final Set<int> nodes = {};
  final Set<int> members = {};

  /// Last node of the line being drawn.
  int? connectFrom;

  WorkPlane plane;
  final ViewCamera camera = ViewCamera();

  int activeCase = 0;
  int activeSection = 0;

  /// Persists a record (the repository by default).
  final Future<void> Function(Frame3DRecord) save;

  Frame3DEditController(this._record, {this.save = Frame3DRepository.save})
    : plane = _record.model.plane
          ? const WorkPlane(PlaneAxis.y, 0)
          : const WorkPlane(PlaneAxis.z, 0);

  Frame3DRecord get record => _record;
  Model3D get model => _model ??= _record.model;
  bool get canUndo => _undo.isNotEmpty;

  /// Kept for older callers: drawing is the connect tool.
  bool get connecting => tool == EditTool.draw;

  bool get hasSelection => nodes.isNotEmpty || members.isNotEmpty;

  /// Takes a record coming back from storage (ignores our own saves).
  /// Called while building: updates silently.
  void sync(Frame3DRecord r) {
    if (!r.updatedAt.isAfter(_record.updatedAt)) return;
    _record = r;
    _model = null;
    _clampSelection();
  }

  void _clampSelection() {
    final m = model;
    if (node != null && node! >= m.nodes.length) node = null;
    if (member != null && member! >= m.elements.length) member = null;
    if (connectFrom != null && connectFrom! >= m.nodes.length) {
      connectFrom = null;
    }
    nodes.removeWhere((i) => i >= m.nodes.length);
    members.removeWhere((i) => i >= m.elements.length);
    activeCase = activeCase.clamp(0, math.max(0, m.cases.length - 1));
    activeSection = activeSection.clamp(0, math.max(0, m.sections.length - 1));
  }

  /// Applies an edited model: rigid floors follow the levels, the record
  /// becomes a custom model and is saved.
  Future<void> apply(Model3D m) async {
    _undo.add(_record);
    if (_undo.length > 40) _undo.removeAt(0);
    if (_record.params.rigidFloors) {
      m = m.copyWith(diaphragms: m.floorsByLevel());
    }
    _record = _record.withModel(m);
    _model = m;
    _clampSelection();
    notifyListeners();
    await save(_record);
  }

  Future<void> undo() async {
    if (_undo.isEmpty) return;
    _record = _undo.removeLast();
    _model = null;
    _clampSelection();
    notifyListeners();
    await save(_record);
  }

  Future<void> regenerate() async {
    _undo.add(_record);
    _record = _record.regenerated();
    _model = null;
    node = member = connectFrom = null;
    nodes.clear();
    members.clear();
    _clampSelection();
    notifyListeners();
    await save(_record);
  }

  Future<void> setRigidFloors(bool on) async {
    _undo.add(_record);
    final m = model.copyWith(diaphragms: on ? model.floorsByLevel() : const []);
    _record = _record.withRigidFloors(on).withModel(m);
    _model = m;
    notifyListeners();
    await save(_record);
  }

  void setTool(EditTool t) {
    tool = t;
    connectFrom = null;
    if (t != EditTool.multi) {
      nodes.clear();
      members.clear();
    }
    notifyListeners();
  }

  /// Older API: the connect switch.
  void setConnecting(bool v) => setTool(v ? EditTool.draw : EditTool.select);

  void setPlane(WorkPlane p) {
    plane = model.plane ? WorkPlane(PlaneAxis.y, 0, step: p.step) : p;
    notifyListeners();
  }

  /// Turns the camera to look straight at the working plane.
  void facePlane() => camera.show(switch (plane.axis) {
    PlaneAxis.z => ViewPreset.top,
    PlaneAxis.y => ViewPreset.front,
    PlaneAxis.x => ViewPreset.side,
  });

  void pick(Pick3D? p) {
    switch (tool) {
      case EditTool.draw:
        if (p is NodePick) _drawTo(p.node);
      case EditTool.multi:
        switch (p) {
          case NodePick(:final node):
            nodes.contains(node) ? nodes.remove(node) : nodes.add(node);
          case MemberPick(:final member):
            members.contains(member)
                ? members.remove(member)
                : members.add(member);
          case null:
            break;
        }
        notifyListeners();
      case EditTool.select:
        switch (p) {
          case NodePick(:final node):
            this.node = node;
            member = null;
          case MemberPick(:final member):
            this.member = member;
            node = null;
          case null:
            node = member = null;
        }
        notifyListeners();
    }
  }

  /// Draw tool: a tap on the working plane adds a node there and
  /// continues the line.
  Future<void> planeTap(Node3D p) async {
    final (m, i) = model.addNode(p);
    await _drawTo(i, m);
  }

  Future<void> _drawTo(int n, [Model3D? base]) async {
    final from = connectFrom;
    connectFrom = n;
    node = n;
    member = null;
    var m = base ?? model;
    if (from != null && from != n) {
      final (m2, e) = m.addElement(from, n, activeSection);
      m = m2;
      member = e;
    }
    if (identical(m, model)) {
      notifyListeners();
    } else {
      await apply(m);
    }
  }

  void endLine() {
    connectFrom = null;
    notifyListeners();
  }

  // ─────────────────────────── selection ───────────────────────────

  void selectAll() {
    nodes
      ..clear()
      ..addAll([for (var i = 0; i < model.nodes.length; i++) i]);
    members
      ..clear()
      ..addAll([for (var e = 0; e < model.elements.length; e++) e]);
    notifyListeners();
  }

  void selectKind(MemberKind k) {
    members.addAll(model.elementsOfKind(k));
    notifyListeners();
  }

  void selectLevel(double z) {
    members.addAll(model.elementsAtLevel(z));
    nodes.addAll(model.nodesAtLevel(z));
    notifyListeners();
  }

  void clearSelection() {
    nodes.clear();
    members.clear();
    notifyListeners();
  }

  // ─────────────────────────── bulk edits ───────────────────────────

  Future<void> setSelectionSection(int s) =>
      apply(model.updateElements({...members}, section: s));

  Future<void> setSelectionReleases(List<int> r) =>
      apply(model.updateElements({...members}, releases: r));

  Future<void> setSelectionSupport(Support3D? s) =>
      apply(model.setSupports({...nodes}, s));

  /// Nodes moved: the selected nodes and those of the selected members.
  Set<int> get _movedNodes => {
    ...nodes,
    ...model.nodesOf({...members}),
  };

  Future<void> moveSelection(double dx, double dy, double dz) =>
      apply(model.moveNodes(_movedNodes, dx, dy, dz));

  Future<void> copySelection(double dx, double dy, double dz, int count) {
    final r = model.copyItems(
      elems: {...members},
      extraNodes: {...nodes},
      dx: dx,
      dy: dy,
      dz: dz,
      count: count,
    );
    members
      ..clear()
      ..addAll(r.elements);
    nodes
      ..clear()
      ..addAll(r.nodes);
    return apply(r.model);
  }

  Future<void> mirrorSelection(MirrorPlane about, double c) {
    final r = model.mirrorItems(
      elems: {...members},
      extraNodes: {...nodes},
      about: about,
      c: c,
    );
    members
      ..clear()
      ..addAll(r.elements);
    nodes
      ..clear()
      ..addAll(r.nodes);
    return apply(r.model);
  }

  Future<void> deleteSelection() {
    var m = model.deleteElements({...members});
    m = m.deleteNodes({...nodes});
    nodes.clear();
    members.clear();
    node = member = connectFrom = null;
    return apply(m);
  }

  // ─────────────────────────── member loads ───────────────────────────

  /// Distributed load of a member in the active case (global or local).
  MemberLoad3D? memberLoad(int e) {
    if (model.cases.isEmpty) return null;
    for (final q in model.cases[activeCase].member) {
      if (q.element == e) return q;
    }
    return null;
  }

  /// Replaces every distributed load of [e] in the active case.
  Future<void> setMemberLoad(int e, MemberLoad3D? load) {
    final c = model.cases[activeCase];
    final next = c.copyWith(
      member: [
        for (final q in c.member)
          if (q.element != e) q,
        ?load,
      ],
    );
    return apply(model.copyWith(cases: [...model.cases]..[activeCase] = next));
  }

  Future<void> setPointLoad(int e, PointLoad3D? load) {
    final c = model.cases[activeCase];
    final next = c.copyWith(
      point: [
        for (final p in c.point)
          if (p.element != e) p,
        ?load,
      ],
    );
    return apply(model.copyWith(cases: [...model.cases]..[activeCase] = next));
  }

  void setActiveCase(int i) {
    activeCase = i;
    notifyListeners();
  }

  void setActiveSection(int i) {
    activeSection = i;
    notifyListeners();
  }
}

/// Release presets for both bending moments.
const _releasePresets = <String, List<int>>{
  'rigid': [],
  'both': Element3D.pinnedEnds,
  'start': [4, 5],
  'end': [10, 11],
};

String _presetLabel(AppLocalizations l, String k) => switch (k) {
  'rigid' => l.f3dRigid,
  'both' => l.f3dPinBoth,
  'start' => l.f3dPinStart,
  _ => l.f3dPinEnd,
};

/// Panel of the Edit tab.
class Frame3DEditPanel extends StatelessWidget {
  final Frame3DEditController c;
  const Frame3DEditPanel({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final m = c.model;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.record.free)
          if (m.plane)
            Text(l.f3dPlaneModel, style: context.text.bodySmall)
          else
            const SizedBox.shrink()
        else if (c.record.custom == null)
          StatusBanner(
            tone: Tone.primary,
            title: l.f3dEditGenerated,
            message: l.f3dEditGeneratedMsg,
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                final ok = await _confirm(context, l.f3dRegenerateConfirm);
                if (ok) await c.regenerate();
              },
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(l.f3dRegenerate),
            ),
          ),
        const SizedBox(height: Gap.md),
        Row(
          children: [
            Expanded(
              child: SegmentedButton<EditTool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: EditTool.select,
                    icon: const Icon(Icons.touch_app_outlined),
                    label: Text(l.f3dToolSelect),
                  ),
                  ButtonSegment(
                    value: EditTool.draw,
                    icon: const Icon(Icons.draw_outlined),
                    label: Text(l.f3dToolDraw),
                  ),
                  ButtonSegment(
                    value: EditTool.multi,
                    icon: const Icon(Icons.select_all_rounded),
                    label: Text(l.f3dToolMulti),
                  ),
                ],
                selected: {c.tool},
                onSelectionChanged: (s) => c.setTool(s.first),
              ),
            ),
            IconButton(
              tooltip: l.f3dUndo,
              onPressed: c.canUndo ? c.undo : null,
              icon: const Icon(Icons.undo_rounded),
            ),
          ],
        ),
        const SizedBox(height: Gap.sm),
        Text(switch (c.tool) {
          EditTool.select => l.f3dSelectHelp,
          EditTool.draw => l.f3dDrawHelp,
          EditTool.multi => l.f3dMultiHelp,
        }, style: context.text.bodySmall),
        const SizedBox(height: Gap.sm),
        _CameraRow(c: c),
        if (c.tool == EditTool.draw) ...[
          const SizedBox(height: Gap.md),
          _PlaneCard(c: c),
        ],
        if (c.tool == EditTool.multi) ...[
          const SizedBox(height: Gap.md),
          _SelectRow(c: c),
        ],
        const SizedBox(height: Gap.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: PickerField<int>(
                key: ValueKey('case-${c.activeCase}-${m.cases.length}'),
                label: l.f3dLoadCase,
                value: c.activeCase,
                options: {
                  for (var i = 0; i < m.cases.length; i++) i: m.cases[i].name,
                },
                onChanged: c.setActiveCase,
              ),
            ),
            IconButton(
              tooltip: l.f3dAddCase,
              onPressed: () => _addCase(context),
              icon: const Icon(Icons.playlist_add_rounded),
            ),
          ],
        ),
        const SizedBox(height: Gap.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: PickerField<int>(
                key: ValueKey(
                  'section-${c.activeSection}-${m.sections.length}',
                ),
                label: l.f3dActiveSection,
                value: c.activeSection,
                options: {
                  for (var i = 0; i < m.sections.length; i++)
                    i: m.sections[i].name,
                },
                onChanged: c.setActiveSection,
              ),
            ),
            IconButton(
              tooltip: l.f3dAddSection,
              onPressed: () => _addSection(context),
              icon: const Icon(Icons.add_box_outlined),
            ),
          ],
        ),
        const SizedBox(height: Gap.sm),
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            OutlinedButton.icon(
              onPressed: () => _addNode(context),
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: Text(l.f3dAddNode),
            ),
          ],
        ),
        if (!m.plane)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.f3dRigidFloors),
            subtitle: Text(l.f3dRigidFloorsHelp),
            value: c.record.params.rigidFloors,
            onChanged: c.setRigidFloors,
          ),
        const SizedBox(height: Gap.lg),
        if (c.tool == EditTool.multi && c.hasSelection)
          _BulkCard(key: ValueKey('bulk-${m.nodes.length}'), c: c)
        else if (c.tool != EditTool.multi && c.node != null)
          _NodeCard(key: ValueKey('node-${c.node}-${c.activeCase}'), c: c)
        else if (c.tool != EditTool.multi && c.member != null)
          _MemberCard(
            key: ValueKey('member-${c.member}-${c.activeCase}'),
            c: c,
          ),
      ],
    );
  }

  Future<void> _addNode(BuildContext context) async {
    final l = context.l10n;
    final base = c.node == null ? null : c.model.nodes[c.node!];
    double? x = base?.x ?? 0, y = base?.y ?? 0, z = base?.z ?? 0;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.f3dAddNode),
        content: SizedBox(
          width: 360,
          child: FieldRow(
            children: [
              NumberField(
                label: 'X',
                unit: 'm',
                value: x,
                allowNegative: true,
                onChanged: (v) => x = v,
              ),
              if (!c.model.plane)
                NumberField(
                  label: 'Y',
                  unit: 'm',
                  value: y,
                  allowNegative: true,
                  onChanged: (v) => y = v,
                ),
              NumberField(
                label: 'Z',
                unit: 'm',
                value: z,
                allowNegative: true,
                onChanged: (v) => z = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.f3dAddNode),
          ),
        ],
      ),
    );
    if (ok != true || x == null || y == null || z == null) return;
    final (m, i) = c.model.addNode(Node3D(x!, y!, z!));
    c.node = i;
    c.member = null;
    await c.apply(m);
  }

  Future<void> _addCase(BuildContext context) async {
    final l = context.l10n;
    final name = TextEditingController(text: 'W');
    var type = LoadType.wind;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(l.f3dAddCase),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: name,
                  decoration: InputDecoration(labelText: l.f3dCaseName),
                ),
                const SizedBox(height: Gap.md),
                PickerField<LoadType>(
                  label: l.f3dCaseType,
                  value: type,
                  options: {
                    LoadType.permanent: l.f3dTypePermanent,
                    LoadType.imposed: l.f3dTypeImposed,
                    LoadType.snow: l.f3dTypeSnow,
                    LoadType.wind: l.f3dTypeWind,
                  },
                  onChanged: (v) => set(() => type = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.f3dAddCase),
            ),
          ],
        ),
      ),
    );
    final text = name.text.trim();
    name.dispose();
    if (ok != true || text.isEmpty) return;
    final m = c.model.addCase(text, type);
    c.activeCase = m.cases.length - 1;
    await c.apply(m);
  }

  Future<void> _addSection(BuildContext context) async {
    final l = context.l10n;
    var material = DesignMaterial.concrete;
    double? b = 300, h = 500;
    var profile = 'IPE 300';
    var timber = 'C24';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(l.f3dAddSection),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChoiceField<DesignMaterial>(
                  label: l.f3dMaterial,
                  value: material,
                  options: {
                    DesignMaterial.concrete: l.catConcrete,
                    DesignMaterial.steel: l.catSteel,
                    DesignMaterial.timber: l.catTimber,
                  },
                  onChanged: (v) => set(() => material = v),
                ),
                const SizedBox(height: Gap.md),
                if (material == DesignMaterial.timber) ...[
                  PickerField<String>(
                    label: l.timberStrengthClass,
                    value: timber,
                    options: {for (final k in timberClasses.keys) k: k},
                    onChanged: (v) => timber = v,
                  ),
                  const SizedBox(height: Gap.md),
                ],
                if (material == DesignMaterial.steel)
                  PickerField<String>(
                    label: l.steelProfile,
                    value: profile,
                    options: {for (final k in steelProfiles.keys) k: k},
                    onChanged: (v) => profile = v,
                  )
                else
                  FieldRow(
                    children: [
                      NumberField(
                        label: 'b',
                        unit: 'mm',
                        value: b,
                        onChanged: (v) => b = v,
                      ),
                      NumberField(
                        label: 'h',
                        unit: 'mm',
                        value: h,
                        onChanged: (v) => h = v,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.f3dAddSection),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final steel = material == DesignMaterial.steel;
    if (!steel && ((b ?? 0) <= 0 || (h ?? 0) <= 0)) return;
    final m = c.model.addSection(switch (material) {
      DesignMaterial.steel => Section3D.steel(profile),
      DesignMaterial.concrete => Section3D.rectangle(b!, h!),
      DesignMaterial.timber => timberSection(timberClasses[timber]!, b!, h!),
    });
    c.activeSection = m.sections.length - 1;
    await c.apply(m);
  }
}

Future<bool> _confirm(BuildContext context, String message) async {
  final l = context.l10n;
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(message),
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
      ) ??
      false;
}

Widget _num(
  String label,
  double? v,
  ValueChanged<double?> f, [
  String unit = '',
  bool negative = true,
]) => NumberField(
  label: label,
  unit: unit,
  value: v,
  allowNegative: negative,
  onChanged: f,
);

class _CameraRow extends StatelessWidget {
  final Frame3DEditController c;
  const _CameraRow({required this.c});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Wrap(
      spacing: Gap.xs,
      runSpacing: Gap.xs,
      children: [
        for (final (p, label) in [
          (ViewPreset.iso, l.f3dViewIso),
          (ViewPreset.top, l.f3dViewTop),
          (ViewPreset.front, l.f3dViewFront),
          (ViewPreset.side, l.f3dViewSide),
        ])
          ActionChip(
            avatar: const Icon(Icons.videocam_outlined, size: 16),
            label: Text(label),
            onPressed: () => c.camera.show(p),
          ),
      ],
    );
  }
}

class _PlaneCard extends StatefulWidget {
  final Frame3DEditController c;
  const _PlaneCard({required this.c});

  @override
  State<_PlaneCard> createState() => _PlaneCardState();
}

class _PlaneCardState extends State<_PlaneCard> {
  late double? _value = widget.c.plane.value;
  late double? _step = widget.c.plane.step;

  void _apply({PlaneAxis? axis}) {
    final c = widget.c;
    final v = _value ?? 0, s = (_step ?? 1) <= 0 ? 1.0 : _step!;
    c.setPlane(WorkPlane(axis ?? c.plane.axis, v, step: s));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = widget.c;
    final m = c.model;
    final levels = m.levels();
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.f3dPlane, style: context.text.titleMedium),
          const SizedBox(height: Gap.sm),
          if (!m.plane) ...[
            ChoiceField<PlaneAxis>(
              label: l.f3dPlane,
              value: c.plane.axis,
              options: {
                PlaneAxis.z: l.f3dPlaneLevel,
                PlaneAxis.y: l.f3dPlaneFront,
                PlaneAxis.x: l.f3dPlaneSide,
              },
              onChanged: (a) => setState(() => _apply(axis: a)),
            ),
            const SizedBox(height: Gap.sm),
          ],
          FieldRow(
            children: [
              if (!m.plane)
                _num(l.f3dPlaneValue, _value, (v) => _value = v, 'm'),
              _num(l.f3dGridStep, _step, (v) => _step = v, 'm', false),
            ],
          ),
          if (!m.plane && c.plane.axis == PlaneAxis.z && levels.isNotEmpty)
            Wrap(
              spacing: Gap.xs,
              children: [
                for (final z in levels)
                  ChoiceChip(
                    label: Text('Z = ${fmt(context, z, 2)}'),
                    selected: (c.plane.value - z).abs() < 1e-6,
                    onSelected: (_) => setState(() {
                      _value = z;
                      _apply();
                    }),
                  ),
              ],
            ),
          const SizedBox(height: Gap.sm),
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              OutlinedButton(onPressed: _apply, child: Text(l.f3dApply)),
              OutlinedButton.icon(
                onPressed: c.facePlane,
                icon: const Icon(Icons.center_focus_strong_outlined),
                label: Text(l.f3dLookAtPlane),
              ),
              FilledButton.tonalIcon(
                onPressed: c.connectFrom == null ? null : c.endLine,
                icon: const Icon(Icons.stop_circle_outlined),
                label: Text(l.f3dEndLine),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectRow extends StatelessWidget {
  final Frame3DEditController c;
  const _SelectRow({required this.c});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final levels = c.model.levels();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.f3dSelection(c.nodes.length, c.members.length),
          style: context.text.labelLarge,
        ),
        const SizedBox(height: Gap.xs),
        Wrap(
          spacing: Gap.xs,
          runSpacing: Gap.xs,
          children: [
            ActionChip(label: Text(l.f3dSelectAll), onPressed: c.selectAll),
            ActionChip(
              label: Text(l.f3dSelectColumns),
              onPressed: () => c.selectKind(MemberKind.column),
            ),
            ActionChip(
              label: Text(l.f3dSelectBeams),
              onPressed: () => c.selectKind(MemberKind.beam),
            ),
            ActionChip(
              label: Text(l.f3dSelectBraces),
              onPressed: () => c.selectKind(MemberKind.brace),
            ),
            for (final z in levels.skip(1))
              ActionChip(
                label: Text('${l.f3dSelectLevel} ${fmt(context, z, 2)}'),
                onPressed: () => c.selectLevel(z),
              ),
            ActionChip(
              avatar: const Icon(Icons.clear_rounded, size: 16),
              label: Text(l.f3dSelectClear),
              onPressed: c.clearSelection,
            ),
          ],
        ),
      ],
    );
  }
}

/// Restraint toggles, presets and springs of one support.
class _SupportEditor extends StatefulWidget {
  final Support3D? initial;
  final ValueChanged<Support3D?> onApply;
  const _SupportEditor({required this.initial, required this.onApply});

  @override
  State<_SupportEditor> createState() => _SupportEditorState();
}

class _SupportEditorState extends State<_SupportEditor> {
  late final List<bool> _d = [
    ...(widget.initial?.dofs ?? List.filled(6, false)),
  ];
  late final List<double?> _k = [
    ...(widget.initial?.springs ?? List.filled(6, 0.0)),
  ];
  bool _showSprings = false;

  static const _labels = ['ux', 'uy', 'uz', 'rx', 'ry', 'rz'];

  void _preset(Support3D? s) => setState(() {
    for (var i = 0; i < 6; i++) {
      _d[i] = s?.dofs[i] ?? false;
      _k[i] = 0;
    }
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.f3dRestraints, style: context.text.labelLarge),
        const SizedBox(height: Gap.xs),
        Wrap(
          spacing: Gap.xs,
          runSpacing: Gap.xs,
          children: [
            for (var i = 0; i < 6; i++)
              FilterChip(
                label: Text(_labels[i]),
                selected: _d[i],
                onSelected: (v) => setState(() => _d[i] = v),
              ),
          ],
        ),
        const SizedBox(height: Gap.xs),
        Wrap(
          spacing: Gap.xs,
          children: [
            TextButton(
              onPressed: () => _preset(null),
              child: Text(l.f3dSupportFree),
            ),
            TextButton(
              onPressed: () => _preset(Support3D.pinned),
              child: Text(l.f3dSupportPinned),
            ),
            TextButton(
              onPressed: () => _preset(Support3D.fixed),
              child: Text(l.f3dSupportFixed),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _showSprings = !_showSprings),
              icon: Icon(
                _showSprings
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
              ),
              label: Text(l.f3dSprings),
            ),
          ],
        ),
        if (_showSprings) ...[
          for (final row in const [
            [0, 1, 2],
            [3, 4, 5],
          ])
            FieldRow(
              children: [
                for (final i in row)
                  _num(
                    'k${_labels[i]}',
                    _k[i],
                    (v) => _k[i] = v,
                    i < 3 ? 'kN/m' : 'kN·m',
                    false,
                  ),
              ],
            ),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => widget.onApply(
              Support3D.of(_d, [for (final k in _k) (k ?? 0).abs()]),
            ),
            child: Text(l.f3dApplySupport),
          ),
        ),
      ],
    );
  }
}

class _NodeCard extends StatefulWidget {
  final Frame3DEditController c;
  const _NodeCard({super.key, required this.c});

  @override
  State<_NodeCard> createState() => _NodeCardState();
}

class _NodeCardState extends State<_NodeCard> {
  late final Model3D m = widget.c.model;
  late final int i = widget.c.node!;
  late double? x = m.nodes[i].x, y = m.nodes[i].y, z = m.nodes[i].z;
  late final NodalLoad3D load = m.cases.isEmpty
      ? NodalLoad3D(i)
      : m.nodalLoadOf(widget.c.activeCase, i);
  late double? fx = load.fx, fy = load.fy, fz = load.fz;
  late double? mx = load.mx, my = load.my, mz = load.mz;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = widget.c;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.f3dNodeN(i + 1), style: context.text.titleMedium),
          const SizedBox(height: Gap.md),
          FieldRow(
            children: [
              _num('X', x, (v) => x = v, 'm'),
              if (!m.plane) _num('Y', y, (v) => y = v, 'm'),
              _num('Z', z, (v) => z = v, 'm'),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                if (x == null || y == null || z == null) return;
                c.apply(m.moveNode(i, Node3D(x!, y!, z!)));
              },
              child: Text(l.f3dMove),
            ),
          ),
          Text(l.f3dSupport, style: context.text.labelLarge),
          const SizedBox(height: Gap.xs),
          _SupportEditor(
            initial: m.supports[i],
            onApply: (s) => c.apply(m.setSupport(i, s)),
          ),
          if (m.cases.isNotEmpty) ...[
            const SizedBox(height: Gap.lg),
            Text(
              l.f3dNodalLoad(m.cases[c.activeCase].name),
              style: context.text.labelLarge,
            ),
            const SizedBox(height: Gap.sm),
            FieldRow(
              children: [
                _num('Fx', fx, (v) => fx = v, 'kN'),
                _num('Fy', fy, (v) => fy = v, 'kN'),
                _num('Fz', fz, (v) => fz = v, 'kN'),
              ],
            ),
            FieldRow(
              children: [
                _num('Mx', mx, (v) => mx = v, 'kN·m'),
                _num('My', my, (v) => my = v, 'kN·m'),
                _num('Mz', mz, (v) => mz = v, 'kN·m'),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => c.apply(
                  m.setNodalLoad(
                    c.activeCase,
                    NodalLoad3D(
                      i,
                      fx: fx ?? 0,
                      fy: fy ?? 0,
                      fz: fz ?? 0,
                      mx: mx ?? 0,
                      my: my ?? 0,
                      mz: mz ?? 0,
                    ),
                  ),
                ),
                child: Text(l.f3dApplyLoad),
              ),
            ),
          ],
          const Divider(),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: context.appColors.danger,
              ),
              onPressed: () {
                c.node = null;
                c.apply(m.deleteNode(i));
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(l.f3dDeleteNode),
            ),
          ),
        ],
      ),
    );
  }
}

/// Direction of a member load: a global axis or a local one.
enum _Dir { x, y, z, localZ, localY }

class _MemberCard extends StatefulWidget {
  final Frame3DEditController c;
  const _MemberCard({super.key, required this.c});

  @override
  State<_MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<_MemberCard> {
  late final Model3D m = widget.c.model;
  late final int e = widget.c.member!;
  late double? roll = m.elements[e].roll;

  late final MemberLoad3D? _load = widget.c.memberLoad(e);
  late _Dir _dir = _dirOf(_load);
  late double? _w1 = _load == null ? null : _component(_load.q1, _dir);
  late double? _w2 = _load?.end2 == null ? null : _component(_load!.q2, _dir);
  late double? _a = _load == null || _load.start == 0 ? null : _load.start;
  late double? _b = _load?.end;

  late final PointLoad3D? _point = m.cases.isEmpty
      ? null
      : m.pointLoadOf(widget.c.activeCase, e);
  late _Dir _pDir = _point == null
      ? _Dir.z
      : _dirOfVector(_point.vector, _point.local);
  late double? _p = _point == null ? null : _component(_point.vector, _pDir);
  late double? _pa = _point?.a;

  static _Dir _dirOf(MemberLoad3D? q) =>
      q == null ? _Dir.z : _dirOfVector(q.q1, q.local);

  static _Dir _dirOfVector(List<double> v, bool local) {
    var k = 2;
    for (var i = 0; i < 3; i++) {
      if (v[i].abs() > v[k].abs()) k = i;
    }
    if (local) return k == 1 ? _Dir.localY : _Dir.localZ;
    return _Dir.values[k];
  }

  static double _component(List<double> v, _Dir d) => switch (d) {
    _Dir.x => v[0],
    _Dir.y || _Dir.localY => v[1],
    _Dir.z || _Dir.localZ => v[2],
  };

  static List<double> _vector(_Dir d, double w) => switch (d) {
    _Dir.x => [w, 0, 0],
    _Dir.y || _Dir.localY => [0, w, 0],
    _Dir.z || _Dir.localZ => [0, 0, w],
  };

  Map<_Dir, String> _dirs(AppLocalizations l) => {
    _Dir.x: 'X',
    if (!m.plane) _Dir.y: 'Y',
    _Dir.z: 'Z',
    _Dir.localZ: l.f3dDirLocalZ,
    if (!m.plane) _Dir.localY: l.f3dDirLocalY,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = widget.c;
    final el = m.elements[e];
    final length = m.length(e);
    final rel = el.releases.toSet();
    void toggle(int d, bool on) {
      final next = {...rel};
      on ? next.add(d) : next.remove(d);
      c.apply(m.updateElement(e, releases: next.toList()));
    }

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.frameMemberTitle(e + 1), style: context.text.titleMedium),
          Text(
            '${l.f3dNodeN(el.n1 + 1)} → ${l.f3dNodeN(el.n2 + 1)} · L = ${fmt(context, length, 2)} m',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: Gap.md),
          PickerField<int>(
            label: l.f3dSection,
            value: el.section,
            options: {
              for (var i = 0; i < m.sections.length; i++) i: m.sections[i].name,
            },
            onChanged: (v) => c.apply(m.updateElement(e, section: v)),
          ),
          const SizedBox(height: Gap.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _num(l.f3dRoll, roll, (v) => roll = v, '°')),
              TextButton(
                onPressed: () {
                  if (roll == null) return;
                  c.apply(m.updateElement(e, roll: roll));
                },
                child: Text(l.f3dApply),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          Text(l.f3dReleases, style: context.text.labelLarge),
          const SizedBox(height: Gap.xs),
          for (final (label, offset) in [
            (l.f3dReleaseStart, 0),
            (l.f3dReleaseEnd, 6),
          ])
            Wrap(
              spacing: Gap.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(width: 64, child: Text(label)),
                for (final (d, name) in [(3, 'Mx'), (4, 'My'), (5, 'Mz')])
                  FilterChip(
                    label: Text(name),
                    selected: rel.contains(d + offset),
                    onSelected: (v) => toggle(d + offset, v),
                  ),
              ],
            ),
          Wrap(
            spacing: Gap.xs,
            children: [
              for (final k in _releasePresets.keys)
                TextButton(
                  onPressed: () =>
                      c.apply(m.updateElement(e, releases: _releasePresets[k])),
                  child: Text(_presetLabel(l, k)),
                ),
            ],
          ),
          Text(l.f3dReleasesHelp, style: context.text.bodySmall),
          if (m.cases.isNotEmpty) ...[
            const SizedBox(height: Gap.lg),
            Text(
              l.f3dMemberLoad(m.cases[c.activeCase].name),
              style: context.text.labelLarge,
            ),
            const SizedBox(height: Gap.sm),
            PickerField<_Dir>(
              label: l.f3dDirection,
              value: _dir,
              options: _dirs(l),
              onChanged: (v) => setState(() => _dir = v),
            ),
            FieldRow(
              children: [
                _num('w1', _w1, (v) => _w1 = v, 'kN/m'),
                _num('w2', _w2, (v) => _w2 = v, 'kN/m'),
              ],
            ),
            FieldRow(
              children: [
                _num(l.f3dLoadFrom, _a, (v) => _a = v, 'm', false),
                _num(l.f3dLoadTo, _b, (v) => _b = v, 'm', false),
              ],
            ),
            Text(l.f3dLoadExtentNote, style: context.text.bodySmall),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  final w1 = _w1 ?? 0, w2 = _w2;
                  if (w1 == 0 && (w2 ?? 0) == 0) {
                    c.setMemberLoad(e, null);
                    return;
                  }
                  final local = _dir == _Dir.localY || _dir == _Dir.localZ;
                  final q1 = _vector(_dir, w1);
                  final start = (_a ?? 0).clamp(0.0, length);
                  final end = _b?.clamp(start, length);
                  c.setMemberLoad(
                    e,
                    MemberLoad3D(
                      e,
                      qx: q1[0],
                      qy: q1[1],
                      qz: q1[2],
                      local: local,
                      start: start,
                      end: end == length ? null : end,
                      end2: w2 == null ? null : _vector(_dir, w2),
                    ),
                  );
                },
                child: Text(l.f3dApplyLoad),
              ),
            ),
            const SizedBox(height: Gap.sm),
            Text(
              l.f3dPointLoad(m.cases[c.activeCase].name),
              style: context.text.labelLarge,
            ),
            const SizedBox(height: Gap.sm),
            PickerField<_Dir>(
              label: l.f3dDirection,
              value: _pDir,
              options: _dirs(l),
              onChanged: (v) => setState(() => _pDir = v),
            ),
            FieldRow(
              children: [
                _num('P', _p, (v) => _p = v, 'kN'),
                _num(l.f3dPointAt, _pa, (v) => _pa = v, 'm', false),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  final p = _p ?? 0;
                  if (p == 0) {
                    c.setPointLoad(e, null);
                    return;
                  }
                  final f = _vector(_pDir, p);
                  c.setPointLoad(
                    e,
                    PointLoad3D(
                      e,
                      (_pa ?? length / 2).clamp(0.0, length),
                      fx: f[0],
                      fy: f[1],
                      fz: f[2],
                      local: _pDir == _Dir.localY || _pDir == _Dir.localZ,
                    ),
                  );
                },
                child: Text(l.f3dApplyPointLoad),
              ),
            ),
          ],
          const Divider(),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: context.appColors.danger,
              ),
              onPressed: () {
                c.member = null;
                c.apply(m.deleteElements({e}));
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(l.f3dDeleteMember),
            ),
          ),
        ],
      ),
    );
  }
}

/// Edits applied to the whole multi-selection.
class _BulkCard extends StatefulWidget {
  final Frame3DEditController c;
  const _BulkCard({super.key, required this.c});

  @override
  State<_BulkCard> createState() => _BulkCardState();
}

class _BulkCardState extends State<_BulkCard> {
  double? _dx = 0, _dy = 0, _dz = 0, _n = 1, _mc = 0;
  MirrorPlane _about = MirrorPlane.x;
  late int _section = widget.c.activeSection;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = widget.c;
    final m = c.model;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.f3dSelection(c.nodes.length, c.members.length),
            style: context.text.titleMedium,
          ),
          if (c.members.isNotEmpty) ...[
            const SizedBox(height: Gap.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: PickerField<int>(
                    label: l.f3dBulkSection,
                    value: _section.clamp(0, m.sections.length - 1),
                    options: {
                      for (var i = 0; i < m.sections.length; i++)
                        i: m.sections[i].name,
                    },
                    onChanged: (v) => setState(() => _section = v),
                  ),
                ),
                TextButton(
                  onPressed: () => c.setSelectionSection(_section),
                  child: Text(l.f3dApply),
                ),
              ],
            ),
            const SizedBox(height: Gap.sm),
            Text(l.f3dBulkReleases, style: context.text.labelLarge),
            Wrap(
              spacing: Gap.xs,
              children: [
                for (final k in _releasePresets.keys)
                  OutlinedButton(
                    onPressed: () =>
                        c.setSelectionReleases(_releasePresets[k]!),
                    child: Text(_presetLabel(l, k)),
                  ),
              ],
            ),
          ],
          if (c.nodes.isNotEmpty) ...[
            const SizedBox(height: Gap.md),
            Text(l.f3dBulkSupport, style: context.text.labelLarge),
            _SupportEditor(initial: null, onApply: c.setSelectionSupport),
          ],
          const SizedBox(height: Gap.md),
          Text(l.f3dMoveCopy, style: context.text.labelLarge),
          const SizedBox(height: Gap.xs),
          FieldRow(
            children: [
              _num('Δx', _dx, (v) => _dx = v, 'm'),
              if (!m.plane) _num('Δy', _dy, (v) => _dy = v, 'm'),
              _num('Δz', _dz, (v) => _dz = v, 'm'),
              _num(l.f3dCopies, _n, (v) => _n = v, '', false),
            ],
          ),
          Text(l.f3dCopyHelp, style: context.text.bodySmall),
          Wrap(
            spacing: Gap.sm,
            children: [
              OutlinedButton.icon(
                onPressed: () =>
                    c.moveSelection(_dx ?? 0, m.plane ? 0 : _dy ?? 0, _dz ?? 0),
                icon: const Icon(Icons.open_with_rounded),
                label: Text(l.f3dMoveBtn),
              ),
              FilledButton.tonalIcon(
                onPressed: () => c.copySelection(
                  _dx ?? 0,
                  m.plane ? 0 : _dy ?? 0,
                  _dz ?? 0,
                  (_n ?? 1).round().clamp(1, 50),
                ),
                icon: const Icon(Icons.copy_all_rounded),
                label: Text(l.f3dCopyBtn),
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          Text(l.f3dMirror, style: context.text.labelLarge),
          const SizedBox(height: Gap.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ChoiceField<MirrorPlane>(
                  label: l.f3dMirrorAbout,
                  value: _about,
                  options: {
                    MirrorPlane.x: 'X = c',
                    if (!m.plane) MirrorPlane.y: 'Y = c',
                    MirrorPlane.z: 'Z = c',
                  },
                  onChanged: (v) => setState(() => _about = v),
                ),
              ),
              const SizedBox(width: Gap.sm),
              SizedBox(width: 96, child: _num('c', _mc, (v) => _mc = v, 'm')),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => c.mirrorSelection(_about, _mc ?? 0),
              icon: const Icon(Icons.flip_rounded),
              label: Text(l.f3dMirrorBtn),
            ),
          ),
          const Divider(),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: context.appColors.danger,
              ),
              onPressed: () async {
                final ok = await _confirm(context, l.f3dDeleteSelection);
                if (ok) await c.deleteSelection();
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(l.f3dDeleteSelection),
            ),
          ),
        ],
      ),
    );
  }
}
