import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/calculations/shared/diagrams.dart';
import 'package:sibot/features/frame/frame_canvas.dart';
import 'package:sibot/features/frame/frame_member_design.dart';
import 'package:sibot/features/frame/frame_providers.dart';
import 'package:sibot/features/frame/section_library.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

enum _Mode { model, results }

class FrameEditorPage extends ConsumerStatefulWidget {
  final String projectId;
  final String modelId;
  const FrameEditorPage({
    super.key,
    required this.projectId,
    required this.modelId,
  });

  @override
  ConsumerState<FrameEditorPage> createState() => _FrameEditorPageState();
}

class _FrameEditorPageState extends ConsumerState<FrameEditorPage> {
  _Mode _mode = _Mode.model;
  ResultView _view = ResultView.moment;

  /// 'c:i' load case, 'k:i' combination, 'env' ULS envelope.
  String _source = 'env';
  int? _resultMember;
  final _canvasKey = GlobalKey<FrameCanvasState>();

  FrameEditorNotifier get _n =>
      ref.read(frameEditorProvider(widget.modelId).notifier);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = ref.watch(frameEditorProvider(widget.modelId));
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.medium + 100;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _rename(context, s.record.name),
          child: Text(s.record.name, overflow: TextOverflow.ellipsis),
        ),
        actions: [
          IconButton(
            tooltip: l.frameUndo,
            onPressed: s.undo.isEmpty ? null : _n.undo,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: l.frameRedo,
            onPressed: s.redo.isEmpty ? null : _n.redo,
            icon: const Icon(Icons.redo_rounded),
          ),
          IconButton(
            tooltip: l.frameFit,
            onPressed: () => _canvasKey.currentState?.fit(),
            icon: const Icon(Icons.fit_screen_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: (v) =>
                v == 'cases' ? _manageCases(context) : _manageSections(context),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'cases', child: Text(l.frameLoadCases)),
              PopupMenuItem(value: 'sections', child: Text(l.frameSections)),
            ],
          ),
          const SizedBox(width: Gap.sm),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm),
            child: SegmentedButton<_Mode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: _Mode.model,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l.frameModeModel),
                ),
                ButtonSegment(
                  value: _Mode.results,
                  icon: const Icon(Icons.insights_rounded, size: 18),
                  label: Text(l.frameModeResults),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (v) => setState(() {
                _mode = v.first;
                _resultMember = null;
              }),
            ),
          ),
          if (_mode == _Mode.results) _resultsBar(context, s),
          Expanded(
            child: _mode == _Mode.model
                ? _modelBody(context, s, wide)
                : _resultsBody(context, s, wide),
          ),
        ],
      ),
    );
  }

  // ------------------------------ MODEL ------------------------------

  Widget _modelBody(BuildContext context, FrameEditorState s, bool wide) {
    final canvas = Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: context.colors.surface,
            child: FrameCanvas(
              key: _canvasKey,
              model: s.model,
              selection: s.selection,
              pendingNode: s.pendingNode,
              activeCase: s.activeCase,
              grid: s.grid,
              onTapEmpty: (x, y) => switch (s.tool) {
                FrameTool.node => _n.addNodeAt(x, y),
                FrameTool.member => _n.memberTap(x: x, y: y),
                _ => _n.select(null),
              },
              onTapNode: (i) => switch (s.tool) {
                FrameTool.member => _n.memberTap(node: i),
                FrameTool.support => _n.cycleSupport(i),
                _ => _n.select(NodeSelection(i)),
              },
              onTapElement: (k) => _n.select(ElementSelection(k)),
            ),
          ),
        ),
        Positioned(
          left: Gap.md,
          right: Gap.md,
          bottom: Gap.md,
          child: _Toolbar(state: s, notifier: _n),
        ),
      ],
    );
    final panel = s.selection == null
        ? null
        : _PropertiesPanel(state: s, notifier: _n);
    if (wide) {
      return Row(
        children: [
          Expanded(child: canvas),
          if (panel != null)
            SizedBox(
              width: 340,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: context.colors.outlineVariant),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Gap.lg),
                  child: panel,
                ),
              ),
            ),
        ],
      );
    }
    return Column(
      children: [
        Expanded(child: canvas),
        if (panel != null)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.42,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.colors.surface,
                border: Border(
                  top: BorderSide(color: context.colors.outlineVariant),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Gap.lg),
                child: panel,
              ),
            ),
          ),
      ],
    );
  }

  // ----------------------------- RESULTS -----------------------------

  Widget _resultsBar(BuildContext context, FrameEditorState s) {
    final l = context.l10n;
    final out = ref.watch(frameAnalysisProvider(widget.modelId)).value;
    final sources = <String, String>{
      'env': l.frameEnvelope,
      for (var i = 0; i < s.model.cases.length; i++)
        'c:$i': s.model.cases[i].name,
      if (out != null)
        for (var i = 0; i < out.combinations.length; i++)
          'k:$i': out.combinations[i].name,
    };
    if (!sources.containsKey(_source)) _source = 'env';
    final views = {
      ResultView.deformed: l.frameViewDeformed,
      ResultView.moment: 'M',
      ResultView.shear: 'V',
      ResultView.axial: 'N',
      ResultView.reactions: l.frameViewReactions,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _source,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l.frameResultSource,
              isDense: true,
            ),
            items: [
              for (final e in sources.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => setState(() => _source = v ?? 'env'),
          ),
          const SizedBox(height: Gap.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final e in views.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: Gap.sm),
                    child: ChoiceChip(
                      label: Text(e.value),
                      selected: _view == e.key,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _view = e.key),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The result shown for the current source (envelope uses the first ULS
  /// combination for station positions and deformed shape).
  (FrameResult?, List<List<(double, double)>>?) _selected(
    FrameAnalysisOutput out,
  ) {
    if (_source == 'env') {
      final uls = [
        for (var i = 0; i < out.combinations.length; i++)
          if (out.combinations[i].kind == CombinationKind.uls)
            out.combinationResults[i],
      ];
      final env = switch (_view) {
        ResultView.moment => out.envelopeM,
        ResultView.shear => out.envelopeV,
        ResultView.axial => out.envelopeN,
        _ => null,
      };
      return (uls.isEmpty ? null : uls.first, env);
    }
    final i = int.parse(_source.substring(2));
    return _source.startsWith('c:')
        ? (out.cases[i], null)
        : (out.combinationResults[i], null);
  }

  Widget _resultsBody(BuildContext context, FrameEditorState s, bool wide) {
    final l = context.l10n;
    final async = ref.watch(frameAnalysisProvider(widget.modelId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: StatusBanner(
          tone: Tone.danger,
          title: l.frameAnalysisFailed,
          message: '$e',
        ),
      ),
      data: (out) {
        if (out.error != null) {
          return Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: StatusBanner(
              tone: Tone.danger,
              title: l.frameAnalysisFailed,
              message: _problem(l, out.error!),
            ),
          );
        }
        final (result, env) = _selected(out);
        final canvas = ColoredBox(
          color: context.colors.surface,
          child: FrameCanvas(
            key: _canvasKey,
            model: s.model,
            selection: _resultMember == null
                ? null
                : ElementSelection(_resultMember!),
            overlay: ResultOverlay(view: _view, result: result, envelope: env),
            onTapElement: (k) => setState(() => _resultMember = k),
            onTapEmpty: (_, _) => setState(() => _resultMember = null),
            onTapNode: (_) {},
          ),
        );
        final panel = _resultMember == null || result == null
            ? null
            : _MemberResultPanel(
                index: _resultMember!,
                model: s.model,
                result: result,
                envelope: _source == 'env' ? out : null,
                output: out,
              );
        if (wide) {
          return Row(
            children: [
              Expanded(child: canvas),
              if (panel != null)
                SizedBox(
                  width: 360,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(Gap.lg),
                    child: panel,
                  ),
                ),
            ],
          );
        }
        return Column(
          children: [
            Expanded(child: canvas),
            if (panel != null)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Gap.lg),
                  child: panel,
                ),
              ),
          ],
        );
      },
    );
  }

  String _problem(AppLocalizations l, ModelError e) => switch (e.problem) {
    ModelProblem.noNodes || ModelProblem.noElements => l.frameErrEmpty,
    ModelProblem.zeroLength => l.frameErrZeroLength,
    ModelProblem.unstable => l.frameErrUnstable,
    _ => l.frameErrInvalid,
  };

  // ----------------------------- DIALOGS -----------------------------

  Future<void> _rename(BuildContext context, String current) async {
    final l = context.l10n;
    final ctrl = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.frameRename),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(l.projectFormSave),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) _n.rename(name);
  }

  void _manageCases(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => _CasesSheet(modelId: widget.modelId),
    );
  }

  void _manageSections(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => _SectionsSheet(modelId: widget.modelId),
    );
  }
}

// ============================== TOOLBAR ==============================

class _Toolbar extends StatelessWidget {
  final FrameEditorState state;
  final FrameEditorNotifier notifier;
  const _Toolbar({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tools = {
      FrameTool.select: (Icons.near_me_outlined, l.frameToolSelect),
      FrameTool.node: (Icons.add_circle_outline_rounded, l.frameToolNode),
      FrameTool.member: (Icons.linear_scale_rounded, l.frameToolMember),
      FrameTool.support: (Icons.change_history_rounded, l.frameToolSupport),
      FrameTool.load: (Icons.south_rounded, l.frameToolLoad),
    };
    final hint = switch (state.tool) {
      FrameTool.select => l.frameHintSelect,
      FrameTool.node => l.frameHintNode(fmt(context, state.grid, 2)),
      FrameTool.member => l.frameHintMember,
      FrameTool.support => l.frameHintSupport,
      FrameTool.load => l.frameHintLoad,
    };
    final cases = state.model.cases;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Gap.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHigh.withValues(
                alpha: 0.95,
              ),
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: Text(hint, style: context.text.bodySmall),
          ),
        ),
        const SizedBox(height: Gap.sm),
        Card(
          elevation: 3,
          shadowColor: Colors.black26,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Gap.sm,
              vertical: 4,
            ),
            child: Row(
              children: [
                for (final e in tools.entries)
                  IconButton(
                    tooltip: e.value.$2,
                    isSelected: state.tool == e.key,
                    style: IconButton.styleFrom(
                      backgroundColor: state.tool == e.key
                          ? context.colors.primaryContainer
                          : null,
                    ),
                    onPressed: () => notifier.setTool(e.key),
                    icon: Icon(e.value.$1),
                  ),
                const Spacer(),
                if (cases.isNotEmpty)
                  PopupMenuButton<int>(
                    tooltip: l.frameActiveCase,
                    initialValue: state.activeCase,
                    onSelected: notifier.setActiveCase,
                    itemBuilder: (_) => [
                      for (var i = 0; i < cases.length; i++)
                        PopupMenuItem(value: i, child: Text(cases[i].name)),
                    ],
                    child: Chip(
                      avatar: const Icon(Icons.layers_outlined, size: 16),
                      label: Text(
                        cases[math.min(state.activeCase, cases.length - 1)]
                            .name,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ========================== PROPERTIES PANEL ==========================

class _PropertiesPanel extends StatelessWidget {
  final FrameEditorState state;
  final FrameEditorNotifier notifier;
  const _PropertiesPanel({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) => switch (state.selection) {
    NodeSelection(:final index) when index < state.model.nodes.length =>
      _NodePanel(
        key: ValueKey('n$index${state.activeCase}'),
        state: state,
        notifier: notifier,
        index: index,
      ),
    ElementSelection(:final index) when index < state.model.elements.length =>
      _ElementPanel(
        key: ValueKey('e$index${state.activeCase}'),
        state: state,
        notifier: notifier,
        index: index,
      ),
    _ => const SizedBox.shrink(),
  };
}

class _PanelHeader extends StatelessWidget {
  final String title;
  final VoidCallback onDelete;
  final VoidCallback onClose;
  const _PanelHeader({
    required this.title,
    required this.onDelete,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: context.text.titleMedium)),
        IconButton(
          tooltip: context.l10n.commonDelete,
          onPressed: onDelete,
          icon: Icon(
            Icons.delete_outline_rounded,
            color: context.appColors.danger,
          ),
        ),
        IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
      ],
    );
  }
}

class _NodePanel extends StatefulWidget {
  final FrameEditorState state;
  final FrameEditorNotifier notifier;
  final int index;
  const _NodePanel({
    super.key,
    required this.state,
    required this.notifier,
    required this.index,
  });

  @override
  State<_NodePanel> createState() => _NodePanelState();
}

class _NodePanelState extends State<_NodePanel> {
  late double? _x = widget.state.model.nodes[widget.index].x;
  late double? _y = widget.state.model.nodes[widget.index].y;
  late final NodalLoad? _load = () {
    final c = widget.state.model.cases;
    if (c.isEmpty) return null;
    for (final l in c[widget.state.activeCase].nodal) {
      if (l.node == widget.index) return l;
    }
    return null;
  }();
  late double? _fx = _load?.fx ?? 0,
      _fy = -(_load?.fy ?? 0),
      _mz = _load?.mz ?? 0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final i = widget.index;
    final sup = widget.state.model.supports[i];
    String supportKey() {
      if (sup == null || sup.isEmpty) return 'free';
      if (sup.ux && sup.uy && sup.rz) return 'fixed';
      if (sup.ux && sup.uy) return 'pinned';
      if (sup.uy) return 'rollerX';
      if (sup.ux) return 'rollerY';
      return 'free';
    }

    final caseName = widget.state.model.cases.isEmpty
        ? ''
        : widget.state.model.cases[widget.state.activeCase].name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PanelHeader(
          title: l.frameNodeTitle(i + 1),
          onDelete: widget.notifier.deleteSelected,
          onClose: () => widget.notifier.select(null),
        ),
        const SizedBox(height: Gap.sm),
        FieldRow(
          children: [
            NumberField(
              label: 'x',
              unit: 'm',
              value: _x,
              allowNegative: true,
              onChanged: (v) => _x = v,
            ),
            NumberField(
              label: 'y',
              unit: 'm',
              value: _y,
              allowNegative: true,
              onChanged: (v) => _y = v,
            ),
          ],
        ),
        const SizedBox(height: Gap.sm),
        OutlinedButton(
          onPressed: _x == null || _y == null
              ? null
              : () => widget.notifier.moveNode(i, _x!, _y!),
          child: Text(l.frameApply),
        ),
        const SizedBox(height: Gap.lg),
        Text(l.frameSupport, style: context.text.labelMedium),
        const SizedBox(height: Gap.sm),
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            for (final e in {
              'free': (l.frameSupportFree, null),
              'pinned': (l.frameSupportPinned, Support.pinned),
              'fixed': (l.frameSupportFixed, Support.fixed),
              'rollerX': (l.frameSupportRollerX, Support.rollerX),
              'rollerY': (l.frameSupportRollerY, const Support(ux: true)),
            }.entries)
              ChoiceChip(
                label: Text(e.value.$1),
                selected: supportKey() == e.key,
                showCheckmark: false,
                onSelected: (_) => widget.notifier.setSupport(i, e.value.$2),
              ),
          ],
        ),
        const SizedBox(height: Gap.lg),
        Text(l.frameNodalLoad(caseName), style: context.text.labelMedium),
        const SizedBox(height: Gap.sm),
        FieldRow(
          children: [
            NumberField(
              label: 'Fx →',
              unit: 'kN',
              value: _fx,
              allowNegative: true,
              onChanged: (v) => _fx = v,
            ),
            NumberField(
              label: 'Fy ↓',
              unit: 'kN',
              value: _fy,
              allowNegative: true,
              onChanged: (v) => _fy = v,
            ),
          ],
        ),
        const SizedBox(height: Gap.sm),
        NumberField(
          label: 'Mz ↺',
          unit: 'kN·m',
          value: _mz,
          allowNegative: true,
          onChanged: (v) => _mz = v,
        ),
        const SizedBox(height: Gap.sm),
        OutlinedButton(
          onPressed: widget.state.model.cases.isEmpty
              ? null
              : () => widget.notifier.setNodalLoad(
                  i,
                  _fx ?? 0,
                  -(_fy ?? 0),
                  _mz ?? 0,
                ),
          child: Text(l.frameApplyLoad),
        ),
      ],
    );
  }
}

class _ElementPanel extends StatefulWidget {
  final FrameEditorState state;
  final FrameEditorNotifier notifier;
  final int index;
  const _ElementPanel({
    super.key,
    required this.state,
    required this.notifier,
    required this.index,
  });

  @override
  State<_ElementPanel> createState() => _ElementPanelState();
}

class _ElementPanelState extends State<_ElementPanel> {
  late final DistributedLoad? _load = () {
    final c = widget.state.model.cases;
    if (c.isEmpty) return null;
    for (final l in c[widget.state.activeCase].distributed) {
      if (l.element == widget.index) return l;
    }
    return null;
  }();
  late double? _w = -(_load?.w1 ?? 0);
  late LoadAxis _axis = _load?.axis ?? LoadAxis.globalY;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final m = widget.state.model;
    final e = m.elements[widget.index];
    final a = m.nodes[e.n1], b = m.nodes[e.n2];
    final length = math.sqrt(math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2));
    final caseName = m.cases.isEmpty
        ? ''
        : m.cases[widget.state.activeCase].name;
    Element2D copy({int? section, ElementKind? kind, bool? hs, bool? he}) =>
        Element2D(
          e.n1,
          e.n2,
          section: section ?? e.section,
          kind: kind ?? e.kind,
          hingeStart: hs ?? e.hingeStart,
          hingeEnd: he ?? e.hingeEnd,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PanelHeader(
          title: l.frameMemberTitle(widget.index + 1),
          onDelete: widget.notifier.deleteSelected,
          onClose: () => widget.notifier.select(null),
        ),
        Text(
          '${l.frameMemberNodes(e.n1 + 1, e.n2 + 1)}  ·  L = ${fmt(context, length, 2)} m',
          style: context.text.bodySmall,
        ),
        const SizedBox(height: Gap.md),
        DropdownButtonFormField<int>(
          initialValue: e.section.clamp(0, m.sections.length - 1),
          decoration: InputDecoration(labelText: l.frameSection),
          items: [
            for (var i = 0; i < m.sections.length; i++)
              DropdownMenuItem(value: i, child: Text(m.sections[i].name)),
          ],
          onChanged: (v) =>
              widget.notifier.updateElement(widget.index, copy(section: v)),
        ),
        const SizedBox(height: Gap.md),
        ChoiceField<ElementKind>(
          label: l.frameMemberKind,
          value: e.kind,
          options: {
            ElementKind.beam: l.frameKindBeam,
            ElementKind.truss: l.frameKindTruss,
          },
          onChanged: (v) =>
              widget.notifier.updateElement(widget.index, copy(kind: v)),
        ),
        if (e.kind == ElementKind.beam) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.frameHingeStart),
            value: e.hingeStart,
            onChanged: (v) =>
                widget.notifier.updateElement(widget.index, copy(hs: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.frameHingeEnd),
            value: e.hingeEnd,
            onChanged: (v) =>
                widget.notifier.updateElement(widget.index, copy(he: v)),
          ),
        ],
        const SizedBox(height: Gap.md),
        Text(l.frameMemberLoad(caseName), style: context.text.labelMedium),
        const SizedBox(height: Gap.sm),
        ChoiceField<LoadAxis>(
          label: l.frameLoadDirection,
          value: _axis,
          options: {
            LoadAxis.globalY: l.frameLoadGravity,
            LoadAxis.localY: l.frameLoadNormal,
          },
          onChanged: (v) => setState(() => _axis = v),
        ),
        const SizedBox(height: Gap.sm),
        NumberField(
          label: _axis == LoadAxis.globalY ? 'w ↓' : 'w ⟂',
          unit: 'kN/m',
          value: _w,
          allowNegative: true,
          onChanged: (v) => _w = v,
        ),
        const SizedBox(height: Gap.sm),
        OutlinedButton(
          onPressed: m.cases.isEmpty
              ? null
              : () => widget.notifier.setMemberLoad(
                  widget.index,
                  -(_w ?? 0),
                  _axis,
                ),
          child: Text(l.frameApplyLoad),
        ),
      ],
    );
  }
}

// ======================== MEMBER RESULT PANEL ========================

class _MemberResultPanel extends StatelessWidget {
  final int index;
  final Model2D model;
  final FrameResult result;

  /// Full analysis output (for member design).
  final FrameAnalysisOutput output;

  /// Present when the ULS envelope is shown.
  final FrameAnalysisOutput? envelope;

  const _MemberResultPanel({
    required this.index,
    required this.model,
    required this.result,
    required this.output,
    this.envelope,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _content(context),
      const SizedBox(height: Gap.md),
      FilledButton.icon(
        onPressed: () => showMemberDesign(
          context,
          model: model,
          output: output,
          index: index,
        ),
        icon: const Icon(Icons.architecture_rounded),
        label: Text(context.l10n.memberDesignButton),
      ),
    ],
  );

  Widget _content(BuildContext context) {
    final l = context.l10n;
    final mem = result.members[index];
    final env = envelope;
    final title = l.frameMemberTitle(index + 1);
    if (env != null && env.envelopeM.isNotEmpty) {
      final mm = env.envelopeM[index],
          vv = env.envelopeV[index],
          nn = env.envelopeN[index];
      double maxOf(List<(double, double)> e) =>
          e.map((p) => p.$2).reduce(math.max);
      double minOf(List<(double, double)> e) =>
          e.map((p) => p.$1).reduce(math.min);
      return ResultCard(
        title: '$title — ${l.frameEnvelope}',
        icon: Icons.insights_rounded,
        rows: [
          ResultRow(
            label: l.frameMaxSagging,
            symbol: 'M+',
            value: fmt(context, maxOf(mm)),
            unit: 'kN·m',
            emphasize: true,
          ),
          ResultRow(
            label: l.frameMaxHogging,
            symbol: 'M−',
            value: fmt(context, minOf(mm)),
            unit: 'kN·m',
            emphasize: true,
          ),
          ResultRow(
            label: l.frameMaxShear,
            symbol: '|V|',
            value: fmt(context, math.max(maxOf(vv), -minOf(vv))),
            unit: 'kN',
          ),
          ResultRow(
            label: l.frameAxialRange,
            symbol: 'N',
            value: '${fmt(context, minOf(nn))} … ${fmt(context, maxOf(nn))}',
            unit: 'kN',
          ),
        ],
      );
    }
    final wMax = mem.stations.map((s) => s.w.abs()).reduce(math.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResultCard(
          title: title,
          icon: Icons.insights_rounded,
          rows: [
            ResultRow(
              label: l.frameMaxSagging,
              symbol: 'M+',
              value: fmt(context, mem.maxMoment),
              unit: 'kN·m',
              emphasize: true,
            ),
            ResultRow(
              label: l.frameMaxHogging,
              symbol: 'M−',
              value: fmt(context, mem.minMoment),
              unit: 'kN·m',
              emphasize: true,
            ),
            ResultRow(
              label: l.frameMaxShear,
              symbol: '|V|',
              value: fmt(context, mem.maxAbsShear),
              unit: 'kN',
            ),
            ResultRow(
              label: l.frameAxialRange,
              symbol: 'N',
              value:
                  '${fmt(context, mem.minAxial)} … ${fmt(context, mem.maxAxial)}',
              unit: 'kN',
            ),
            ResultRow(
              label: l.frameMaxDeflection,
              symbol: 'w',
              value: fmt(context, wMax * 1000, 1),
              unit: 'mm',
            ),
          ],
        ),
        const SizedBox(height: Gap.md),
        ForceDiagram(
          points: [for (final s in mem.stations) ForcePoint(s.x, s.v, s.m)],
        ),
      ],
    );
  }
}

// =========================== CASES & SECTIONS ===========================

class _CasesSheet extends ConsumerWidget {
  final String modelId;
  const _CasesSheet({required this.modelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(frameEditorProvider(modelId));
    final n = ref.read(frameEditorProvider(modelId).notifier);
    String typeLabel(LoadType t) => switch (t) {
      LoadType.permanent => l.loadTypePermanent,
      LoadType.imposed => l.loadTypeImposed,
      LoadType.snow => l.loadTypeSnow,
      LoadType.wind => l.loadTypeWind,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.xl, 0, Gap.xl, Gap.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.frameLoadCases, style: context.text.headlineSmall),
          const SizedBox(height: Gap.md),
          for (var i = 0; i < s.model.cases.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: Gap.sm),
              child: Padding(
                padding: const EdgeInsets.all(Gap.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.model.cases[i].name,
                            style: context.text.titleMedium,
                          ),
                        ),
                        if (s.model.cases.length > 1)
                          IconButton(
                            onPressed: () => n.deleteCase(i),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                      ],
                    ),
                    Wrap(
                      spacing: Gap.sm,
                      children: [
                        for (final t in LoadType.values)
                          ChoiceChip(
                            label: Text(typeLabel(t)),
                            selected: s.model.cases[i].type == t,
                            showCheckmark: false,
                            onSelected: (_) => n.updateCase(
                              i,
                              s.model.cases[i].copyWith(type: t),
                            ),
                          ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.frameSelfWeight),
                      value: s.model.cases[i].selfWeight,
                      onChanged: (v) => n.updateCase(
                        i,
                        s.model.cases[i].copyWith(selfWeight: v),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: Gap.sm),
          OutlinedButton.icon(
            onPressed: () {
              final names = s.model.cases.map((c) => c.name).toSet();
              var k = s.model.cases.length + 1;
              while (names.contains('C$k')) {
                k++;
              }
              n.addCase('C$k', LoadType.imposed);
            },
            icon: const Icon(Icons.add_rounded),
            label: Text(l.frameAddCase),
          ),
          const SizedBox(height: Gap.sm),
          Text(l.frameCombinationsNote, style: context.text.bodySmall),
        ],
      ),
    );
  }
}

class _SectionsSheet extends ConsumerStatefulWidget {
  final String modelId;
  const _SectionsSheet({required this.modelId});

  @override
  ConsumerState<_SectionsSheet> createState() => _SectionsSheetState();
}

class _SectionsSheetState extends ConsumerState<_SectionsSheet> {
  String _kind = 'concrete';
  double? _b = 300, _h = 500, _fck = 25;
  String _ipe = 'IPE 300';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = ref.watch(frameEditorProvider(widget.modelId));
    final n = ref.read(frameEditorProvider(widget.modelId).notifier);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Gap.xl,
        0,
        Gap.xl,
        Gap.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.frameSections, style: context.text.headlineSmall),
            const SizedBox(height: Gap.md),
            for (var i = 0; i < s.model.sections.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: IconBadge(
                  Icons.crop_square,
                  tone: i == s.activeSection ? Tone.primary : Tone.neutral,
                  size: 36,
                ),
                title: Text(s.model.sections[i].name),
                subtitle: Text(
                  'A = ${fmt(context, s.model.sections[i].area * 1e4, 1)} cm²  ·  I = ${fmt(context, s.model.sections[i].inertia * 1e8, 0)} cm⁴  ·  E = ${fmt(context, s.model.sections[i].youngModulus, 0)} MPa',
                ),
                trailing: i == s.activeSection
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => n.setActiveSection(i),
              ),
            const Divider(),
            const SizedBox(height: Gap.md),
            Text(l.frameAddSection, style: context.text.titleMedium),
            const SizedBox(height: Gap.sm),
            ChoiceField<String>(
              label: l.frameSectionType,
              value: _kind,
              options: {'concrete': l.frameConcreteRect, 'steel': l.catSteel},
              onChanged: (v) => setState(() => _kind = v),
            ),
            const SizedBox(height: Gap.md),
            if (_kind == 'concrete') ...[
              FieldRow(
                children: [
                  NumberField(
                    label: 'b',
                    unit: 'mm',
                    value: _b,
                    onChanged: (v) => _b = v,
                  ),
                  NumberField(
                    label: 'h',
                    unit: 'mm',
                    value: _h,
                    onChanged: (v) => _h = v,
                  ),
                ],
              ),
              const SizedBox(height: Gap.md),
              NumberField(
                label: l.calcConcreteFck,
                unit: 'MPa',
                value: _fck,
                onChanged: (v) => _fck = v,
              ),
            ] else
              DropdownButtonFormField<String>(
                initialValue: _ipe,
                decoration: InputDecoration(labelText: l.frameProfile),
                items: [
                  for (final k in steelSections.keys)
                    DropdownMenuItem(value: k, child: Text(k)),
                ],
                onChanged: (v) => _ipe = v ?? _ipe,
              ),
            const SizedBox(height: Gap.md),
            FilledButton(
              onPressed: () {
                if (_kind == 'concrete') {
                  if ((_b ?? 0) <= 0 || (_h ?? 0) <= 0) return;
                  n.addSection(concreteRectangle(_b!, _h!, fck: _fck ?? 25));
                } else {
                  n.addSection(steelProfile(_ipe));
                }
              },
              child: Text(l.frameAddSection),
            ),
            const SizedBox(height: Gap.sm),
            Text(l.frameSectionNote, style: context.text.bodySmall),
          ],
        ),
      ),
    );
  }
}
