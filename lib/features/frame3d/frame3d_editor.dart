import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/frame3d/frame3d_data.dart';
import 'package:sibot/features/frame3d/frame3d_view.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// Editing state of a 3D model: selection, tools, undo and autosave.
class Frame3DEditController extends ChangeNotifier {
  Frame3DRecord _record;
  Model3D? _model;
  final List<Frame3DRecord> _undo = [];

  int? node;
  int? member;

  /// Connect tool: tap two nodes to add a member.
  bool connecting = false;
  int? connectFrom;

  int activeCase = 0;
  int activeSection = 0;

  /// Persists a record (the repository by default).
  final Future<void> Function(Frame3DRecord) save;

  Frame3DEditController(this._record, {this.save = Frame3DRepository.save});

  Frame3DRecord get record => _record;
  Model3D get model => _model ??= _record.model;
  bool get canUndo => _undo.isNotEmpty;

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
    _clampSelection();
    notifyListeners();
    await save(_record);
  }

  void pick(Pick3D? p) {
    if (connecting) {
      if (p is NodePick) {
        final from = connectFrom;
        if (from == null || from == p.node) {
          connectFrom = p.node;
          notifyListeners();
        } else {
          final (m, e) = model.addElement(from, p.node, activeSection);
          connectFrom = p.node;
          member = e;
          apply(m);
        }
      }
      return;
    }
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

  void setConnecting(bool v) {
    connecting = v;
    connectFrom = null;
    notifyListeners();
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
        if (c.record.custom == null)
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
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            OutlinedButton.icon(
              onPressed: c.canUndo ? c.undo : null,
              icon: const Icon(Icons.undo_rounded),
              label: Text(l.f3dUndo),
            ),
            FilterChip(
              avatar: const Icon(Icons.timeline_rounded, size: 18),
              label: Text(l.f3dConnect),
              selected: c.connecting,
              onSelected: c.setConnecting,
            ),
            OutlinedButton.icon(
              onPressed: () => _addNode(context),
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: Text(l.f3dAddNode),
            ),
          ],
        ),
        const SizedBox(height: Gap.sm),
        Text(
          c.connecting ? l.f3dConnectHelp : l.f3dSelectHelp,
          style: context.text.bodySmall,
        ),
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
        const SizedBox(height: Gap.lg),
        if (c.node != null)
          _NodeCard(key: ValueKey('node-${c.node}-${c.activeCase}'), c: c)
        else if (c.member != null)
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
    var steel = false;
    double? b = 300, h = 500;
    var profile = 'IPE 300';
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
                ChoiceField<bool>(
                  label: l.f3dMaterial,
                  value: steel,
                  options: {false: l.catConcrete, true: l.catSteel},
                  onChanged: (v) => set(() => steel = v),
                ),
                const SizedBox(height: Gap.md),
                if (steel)
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
    if (!steel && ((b ?? 0) <= 0 || (h ?? 0) <= 0)) return;
    final m = c.model.addSection(
      steel ? Section3D.steel(profile) : Section3D.rectangle(b!, h!),
    );
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

enum _SupportKind { free, pinned, fixed }

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

  _SupportKind get _support {
    final s = m.supports[i];
    if (s == null) return _SupportKind.free;
    return s.rx && s.ry && s.rz ? _SupportKind.fixed : _SupportKind.pinned;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = widget.c;
    Widget n(String label, double? v, ValueChanged<double?> f, String unit) =>
        NumberField(
          label: label,
          unit: unit,
          value: v,
          allowNegative: true,
          onChanged: f,
        );
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.f3dNodeN(i + 1), style: context.text.titleMedium),
          const SizedBox(height: Gap.md),
          FieldRow(
            children: [
              n('X', x, (v) => x = v, 'm'),
              n('Y', y, (v) => y = v, 'm'),
              n('Z', z, (v) => z = v, 'm'),
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
          ChoiceField<_SupportKind>(
            label: l.f3dSupport,
            value: _support,
            options: {
              _SupportKind.free: l.f3dSupportFree,
              _SupportKind.pinned: l.f3dSupportPinned,
              _SupportKind.fixed: l.f3dSupportFixed,
            },
            onChanged: (v) => c.apply(
              m.setSupport(i, switch (v) {
                _SupportKind.free => null,
                _SupportKind.pinned => Support3D.pinned,
                _SupportKind.fixed => Support3D.fixed,
              }),
            ),
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
                n('Fx', fx, (v) => fx = v, 'kN'),
                n('Fy', fy, (v) => fy = v, 'kN'),
                n('Fz', fz, (v) => fz = v, 'kN'),
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
                      mx: load.mx,
                      my: load.my,
                      mz: load.mz,
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
  late final MemberLoad3D load = m.cases.isEmpty
      ? MemberLoad3D(e)
      : m.memberLoadOf(widget.c.activeCase, e);
  late double? qx = load.qx, qy = load.qy, qz = load.qz;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = widget.c;
    final el = m.elements[e];
    final a = m.nodes[el.n1], b = m.nodes[el.n2];
    final length = math.sqrt(
      math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2) + math.pow(b.z - a.z, 2),
    );
    Widget n(String label, double? v, ValueChanged<double?> f, String unit) =>
        NumberField(
          label: label,
          unit: unit,
          value: v,
          allowNegative: true,
          onChanged: f,
        );
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
              Expanded(child: n(l.f3dRoll, roll, (v) => roll = v, '°')),
              TextButton(
                onPressed: () {
                  if (roll == null) return;
                  c.apply(m.updateElement(e, roll: roll));
                },
                child: Text(l.f3dApply),
              ),
            ],
          ),
          if (m.cases.isNotEmpty) ...[
            const SizedBox(height: Gap.lg),
            Text(
              l.f3dMemberLoad(m.cases[c.activeCase].name),
              style: context.text.labelLarge,
            ),
            const SizedBox(height: Gap.sm),
            FieldRow(
              children: [
                n('qx', qx, (v) => qx = v, 'kN/m'),
                n('qy', qy, (v) => qy = v, 'kN/m'),
                n('qz', qz, (v) => qz = v, 'kN/m'),
              ],
            ),
            Text(l.f3dMemberLoadHelp, style: context.text.bodySmall),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => c.apply(
                  m.setMemberLoad(
                    c.activeCase,
                    MemberLoad3D(e, qx: qx ?? 0, qy: qy ?? 0, qz: qz ?? 0),
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
