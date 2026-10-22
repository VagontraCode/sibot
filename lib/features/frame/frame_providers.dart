import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot/features/frame/frame_repository.dart';
import 'package:sibot_engine/sibot_engine.dart';

enum FrameTool { select, node, member, support, load }

/// What is selected on the canvas.
sealed class Selection {
  const Selection();
}

class NodeSelection extends Selection {
  final int index;
  const NodeSelection(this.index);
}

class ElementSelection extends Selection {
  final int index;
  const ElementSelection(this.index);
}

class FrameEditorState {
  final FrameModelRecord record;
  final List<Model2D> undo;
  final List<Model2D> redo;
  final FrameTool tool;
  final Selection? selection;

  /// Node chosen as the start of a new member (member tool).
  final int? pendingNode;
  final int activeCase;
  final int activeSection;

  /// Snap grid, m.
  final double grid;

  const FrameEditorState({
    required this.record,
    this.undo = const [],
    this.redo = const [],
    this.tool = FrameTool.select,
    this.selection,
    this.pendingNode,
    this.activeCase = 0,
    this.activeSection = 0,
    this.grid = 0.5,
  });

  Model2D get model => record.model;

  FrameEditorState copyWith({
    FrameModelRecord? record,
    List<Model2D>? undo,
    List<Model2D>? redo,
    FrameTool? tool,
    Selection? selection,
    bool clearSelection = false,
    int? pendingNode,
    bool clearPending = false,
    int? activeCase,
    int? activeSection,
    double? grid,
  }) => FrameEditorState(
    record: record ?? this.record,
    undo: undo ?? this.undo,
    redo: redo ?? this.redo,
    tool: tool ?? this.tool,
    selection: clearSelection ? null : (selection ?? this.selection),
    pendingNode: clearPending ? null : (pendingNode ?? this.pendingNode),
    activeCase: activeCase ?? this.activeCase,
    activeSection: activeSection ?? this.activeSection,
    grid: grid ?? this.grid,
  );
}

final frameEditorProvider =
    NotifierProvider.family<FrameEditorNotifier, FrameEditorState, String>(
      FrameEditorNotifier.new,
    );

class FrameEditorNotifier extends Notifier<FrameEditorState> {
  FrameEditorNotifier(this.modelId);
  final String modelId;

  @override
  FrameEditorState build() {
    final r = FrameRepository.get(modelId);
    if (r == null) throw StateError('Model $modelId not found');
    return FrameEditorState(record: r);
  }

  /// Applies an edit, records undo, saves.
  void _apply(Model2D next, {bool keepSelection = false}) {
    final undo = [...state.undo, state.model];
    if (undo.length > 100) undo.removeAt(0);
    final record = state.record.copyWith(model: next);
    state = state.copyWith(
      record: record,
      undo: undo,
      redo: const [],
      clearSelection: !keepSelection,
    );
    FrameRepository.save(record);
  }

  void undo() {
    if (state.undo.isEmpty) return;
    final prev = state.undo.last;
    final record = state.record.copyWith(model: prev);
    state = state.copyWith(
      record: record,
      undo: state.undo.sublist(0, state.undo.length - 1),
      redo: [...state.redo, state.model],
      clearSelection: true,
      clearPending: true,
    );
    FrameRepository.save(record);
  }

  void redo() {
    if (state.redo.isEmpty) return;
    final next = state.redo.last;
    final record = state.record.copyWith(model: next);
    state = state.copyWith(
      record: record,
      undo: [...state.undo, state.model],
      redo: state.redo.sublist(0, state.redo.length - 1),
      clearSelection: true,
      clearPending: true,
    );
    FrameRepository.save(record);
  }

  void rename(String name) {
    final record = state.record.copyWith(name: name);
    state = state.copyWith(record: record);
    FrameRepository.save(record);
  }

  void setTool(FrameTool t) =>
      state = state.copyWith(tool: t, clearPending: true, clearSelection: true);

  void select(Selection? s) => s == null
      ? state = state.copyWith(clearSelection: true)
      : state = state.copyWith(selection: s);

  void setActiveCase(int i) => state = state.copyWith(activeCase: i);
  void setActiveSection(int i) => state = state.copyWith(activeSection: i);
  void setGrid(double g) => state = state.copyWith(grid: g);

  double _snap(double v) => (v / state.grid).round() * state.grid;

  /// Node at the snapped position, created if needed. Returns its index.
  int _nodeAt(double x, double y, List<Node2D> nodes) {
    final sx = _snap(x), sy = _snap(y);
    for (var i = 0; i < nodes.length; i++) {
      if ((nodes[i].x - sx).abs() < 1e-6 && (nodes[i].y - sy).abs() < 1e-6) {
        return i;
      }
    }
    nodes.add(Node2D(sx, sy));
    return nodes.length - 1;
  }

  void addNodeAt(double x, double y) {
    final nodes = [...state.model.nodes];
    final before = nodes.length;
    final i = _nodeAt(x, y, nodes);
    if (nodes.length == before) {
      state = state.copyWith(selection: NodeSelection(i));
      return;
    }
    _apply(state.model.copyWith(nodes: nodes));
    state = state.copyWith(selection: NodeSelection(i));
  }

  /// Member tool: first tap picks the start, second tap creates the member.
  void memberTap({int? node, double? x, double? y}) {
    final nodes = [...state.model.nodes];
    final i = node ?? _nodeAt(x!, y!, nodes);
    final start = state.pendingNode;
    if (start == null || start == i) {
      if (nodes.length != state.model.nodes.length) {
        _apply(state.model.copyWith(nodes: nodes));
      }
      state = state.copyWith(pendingNode: i);
      return;
    }
    final exists = state.model.elements.any(
      (e) => (e.n1 == start && e.n2 == i) || (e.n1 == i && e.n2 == start),
    );
    if (!exists) {
      _apply(
        state.model.copyWith(
          nodes: nodes,
          elements: [
            ...state.model.elements,
            Element2D(start, i, section: state.activeSection),
          ],
        ),
      );
    }
    // Chain: the end becomes the next start.
    state = state.copyWith(pendingNode: i);
  }

  void cycleSupport(int node) {
    const order = [null, Support.pinned, Support.fixed, Support.rollerX];
    final current = state.model.supports[node];
    var k = 0;
    for (var j = 0; j < order.length; j++) {
      final o = order[j];
      if (o == null && (current == null || current.isEmpty)) k = j;
      if (o != null &&
          current != null &&
          o.ux == current.ux &&
          o.uy == current.uy &&
          o.rz == current.rz &&
          current.kx == 0 &&
          current.ky == 0 &&
          current.kr == 0) {
        k = j;
      }
    }
    setSupport(node, order[(k + 1) % order.length]);
  }

  void setSupport(int node, Support? s) {
    final sup = {...state.model.supports};
    if (s == null || s.isEmpty) {
      sup.remove(node);
    } else {
      sup[node] = s;
    }
    _apply(state.model.copyWith(supports: sup), keepSelection: true);
  }

  /// Moves [node] to the grid point nearest to (x, y), e.g. at the end of
  /// a drag on the canvas.
  void dragNode(int node, double x, double y) {
    final sx = _snap(x), sy = _snap(y);
    final n = state.model.nodes[node];
    if ((n.x - sx).abs() < 1e-9 && (n.y - sy).abs() < 1e-9) return;
    moveNode(node, sx, sy);
  }

  void moveNode(int node, double x, double y) {
    final nodes = [...state.model.nodes];
    nodes[node] = Node2D(x, y);
    _apply(state.model.copyWith(nodes: nodes), keepSelection: true);
  }

  void updateElement(int index, Element2D e) {
    final els = [...state.model.elements];
    els[index] = e;
    _apply(state.model.copyWith(elements: els), keepSelection: true);
  }

  LoadCase get _case => state.model.cases[state.activeCase];

  void _replaceCase(LoadCase c, {bool keepSelection = true}) {
    final cases = [...state.model.cases];
    cases[state.activeCase] = c;
    _apply(state.model.copyWith(cases: cases), keepSelection: keepSelection);
  }

  /// Sets the nodal load of [node] in the active case (zeros remove it).
  void setNodalLoad(int node, double fx, double fy, double mz) {
    final list = [
      for (final l in _case.nodal)
        if (l.node != node) l,
      if (fx != 0 || fy != 0 || mz != 0)
        NodalLoad(node, fx: fx, fy: fy, mz: mz),
    ];
    _replaceCase(_case.copyWith(nodal: list));
  }

  /// Sets the distributed load on [element] in the active case: [w] at
  /// [start] to [w2] (null = uniform) at [end] (m from the start node,
  /// null = member end). Zero intensities remove it.
  void setMemberLoad(
    int element,
    double w,
    LoadAxis axis, {
    double? w2,
    double start = 0,
    double? end,
  }) {
    final list = [
      for (final l in _case.distributed)
        if (l.element != element) l,
      if (w != 0 || (w2 ?? 0) != 0)
        DistributedLoad(element, w, w2: w2, axis: axis, start: start, end: end),
    ];
    _replaceCase(_case.copyWith(distributed: list));
  }

  /// Sets the point load [p] at [a] (m from the start node) on [element]
  /// in the active case (0 removes it).
  void setMemberPointLoad(int element, double a, double p, LoadAxis axis) {
    final list = [
      for (final l in _case.point)
        if (l.element != element) l,
      if (p != 0) MemberPointLoad(element, a, p, axis: axis),
    ];
    _replaceCase(_case.copyWith(point: list));
  }

  /// Copies [element] [count] times, each shifted by ([dx], [dy]) from the
  /// previous one, with its section, hinges and loads in every case.
  /// Nodes at an existing position are shared.
  void arrayElement(int element, double dx, double dy, int count) {
    if (count < 1 || (dx == 0 && dy == 0)) return;
    final m = state.model;
    final nodes = [...m.nodes];
    final elements = [...m.elements];
    final src = m.elements[element];
    final cases = [
      for (final c in m.cases)
        (distributed: [...c.distributed], point: [...c.point]),
    ];
    int nodeAt(double x, double y) {
      for (var i = 0; i < nodes.length; i++) {
        if ((nodes[i].x - x).abs() < 1e-6 && (nodes[i].y - y).abs() < 1e-6) {
          return i;
        }
      }
      nodes.add(Node2D(x, y));
      return nodes.length - 1;
    }

    final a = m.nodes[src.n1], b = m.nodes[src.n2];
    for (var k = 1; k <= count; k++) {
      final n1 = nodeAt(a.x + k * dx, a.y + k * dy);
      final n2 = nodeAt(b.x + k * dx, b.y + k * dy);
      // Skip copies that would duplicate an existing member.
      final exists = elements.any(
        (e) => (e.n1 == n1 && e.n2 == n2) || (e.n1 == n2 && e.n2 == n1),
      );
      if (exists || n1 == n2) continue;
      elements.add(
        Element2D(
          n1,
          n2,
          section: src.section,
          kind: src.kind,
          hingeStart: src.hingeStart,
          hingeEnd: src.hingeEnd,
        ),
      );
      final index = elements.length - 1;
      for (var c = 0; c < m.cases.length; c++) {
        for (final l in m.cases[c].distributed) {
          if (l.element != element) continue;
          cases[c].distributed.add(
            DistributedLoad(
              index,
              l.w1,
              w2: l.w2,
              axis: l.axis,
              start: l.start,
              end: l.end,
              projected: l.projected,
            ),
          );
        }
        for (final l in m.cases[c].point) {
          if (l.element != element) continue;
          cases[c].point.add(MemberPointLoad(index, l.a, l.p, axis: l.axis));
        }
      }
    }
    _apply(
      m.copyWith(
        nodes: nodes,
        elements: elements,
        cases: [
          for (var c = 0; c < m.cases.length; c++)
            m.cases[c].copyWith(
              distributed: cases[c].distributed,
              point: cases[c].point,
            ),
        ],
      ),
      keepSelection: true,
    );
  }

  void addCase(String name, LoadType type) {
    _apply(
      state.model.copyWith(
        cases: [
          ...state.model.cases,
          LoadCase(name: name, type: type),
        ],
      ),
      keepSelection: true,
    );
    state = state.copyWith(activeCase: state.model.cases.length - 1);
  }

  void updateCase(int index, LoadCase c) {
    final cases = [...state.model.cases];
    cases[index] = c;
    _apply(state.model.copyWith(cases: cases), keepSelection: true);
  }

  void deleteCase(int index) {
    if (state.model.cases.length <= 1) return;
    final cases = [...state.model.cases]..removeAt(index);
    state = state.copyWith(
      activeCase: math.min(state.activeCase, cases.length - 1),
    );
    _apply(state.model.copyWith(cases: cases), keepSelection: true);
  }

  void addSection(FrameSection s) {
    _apply(
      state.model.copyWith(sections: [...state.model.sections, s]),
      keepSelection: true,
    );
    state = state.copyWith(activeSection: state.model.sections.length - 1);
  }

  void deleteSelected() {
    final sel = state.selection;
    final m = state.model;
    switch (sel) {
      case ElementSelection(:final index):
        _apply(_withoutElements(m, {index}));
      case NodeSelection(:final index):
        // Remove the node, its members and its loads; renumber.
        final dropEls = {
          for (var k = 0; k < m.elements.length; k++)
            if (m.elements[k].n1 == index || m.elements[k].n2 == index) k,
        };
        final m2 = _withoutElements(m, dropEls);
        int map(int n) => n > index ? n - 1 : n;
        _apply(
          Model2D(
            nodes: [...m2.nodes]..removeAt(index),
            supports: {
              for (final e in m2.supports.entries)
                if (e.key != index) map(e.key): e.value,
            },
            sections: m2.sections,
            elements: [
              for (final e in m2.elements)
                Element2D(
                  map(e.n1),
                  map(e.n2),
                  section: e.section,
                  kind: e.kind,
                  hingeStart: e.hingeStart,
                  hingeEnd: e.hingeEnd,
                ),
            ],
            cases: [
              for (final c in m2.cases)
                c.copyWith(
                  nodal: [
                    for (final l in c.nodal)
                      if (l.node != index)
                        NodalLoad(map(l.node), fx: l.fx, fy: l.fy, mz: l.mz),
                  ],
                ),
            ],
          ),
        );
      case null:
        return;
    }
  }

  /// Model without the elements in [drop], with member loads renumbered.
  Model2D _withoutElements(Model2D m, Set<int> drop) {
    final newIndex = <int, int>{};
    var k = 0;
    for (var i = 0; i < m.elements.length; i++) {
      if (!drop.contains(i)) newIndex[i] = k++;
    }
    return m.copyWith(
      elements: [
        for (var i = 0; i < m.elements.length; i++)
          if (!drop.contains(i)) m.elements[i],
      ],
      cases: [
        for (final c in m.cases)
          c.copyWith(
            distributed: [
              for (final l in c.distributed)
                if (newIndex.containsKey(l.element))
                  DistributedLoad(
                    newIndex[l.element]!,
                    l.w1,
                    w2: l.w2,
                    axis: l.axis,
                    start: l.start,
                    end: l.end,
                    projected: l.projected,
                  ),
            ],
            point: [
              for (final l in c.point)
                if (newIndex.containsKey(l.element))
                  MemberPointLoad(newIndex[l.element]!, l.a, l.p, axis: l.axis),
            ],
          ),
      ],
    );
  }
}

// ============================== ANALYSIS ==============================

/// Everything the results view needs, computed off the UI thread.
class FrameAnalysisOutput {
  final List<FrameResult> cases;
  final List<Combination> combinations;
  final List<FrameResult> combinationResults;

  /// Indices of members with their ULS envelope (min, max) per station.
  final List<List<(double, double)>> envelopeM;
  final List<List<(double, double)>> envelopeV;
  final List<List<(double, double)>> envelopeN;

  final ModelError? error;

  const FrameAnalysisOutput({
    required this.cases,
    required this.combinations,
    required this.combinationResults,
    required this.envelopeM,
    required this.envelopeV,
    required this.envelopeN,
    this.error,
  });

  const FrameAnalysisOutput.failed(ModelError this.error)
    : cases = const [],
      combinations = const [],
      combinationResults = const [],
      envelopeM = const [],
      envelopeV = const [],
      envelopeN = const [];
}

FrameAnalysisOutput runFrameAnalysis(Model2D model, DesignCode code) {
  try {
    final a = FrameAnalysis(model);
    final cases = a.solveAll();
    final combos = generateCombinations(model.cases, code);
    final combResults = [
      for (final c in combos) combineResults(cases, c.factors),
    ];
    final uls = [
      for (var i = 0; i < combos.length; i++)
        if (combos[i].kind == CombinationKind.uls) combResults[i],
    ];
    List<List<(double, double)>> env(double Function(MemberStation) f) => [
      for (var m = 0; m < model.elements.length; m++)
        [
          for (var s = 0; s < uls.first.members[m].stations.length; s++)
            () {
              var lo = double.infinity, hi = -double.infinity;
              for (final r in uls) {
                final v = f(r.members[m].stations[s]);
                lo = math.min(lo, v);
                hi = math.max(hi, v);
              }
              return (lo, hi);
            }(),
        ],
    ];
    return FrameAnalysisOutput(
      cases: cases,
      combinations: combos,
      combinationResults: combResults,
      envelopeM: uls.isEmpty ? const [] : env((s) => s.m),
      envelopeV: uls.isEmpty ? const [] : env((s) => s.v),
      envelopeN: uls.isEmpty ? const [] : env((s) => s.n),
    );
  } on ModelError catch (e) {
    return FrameAnalysisOutput.failed(e);
  }
}

/// Runs the analysis of the current model in a background isolate.
final frameAnalysisProvider =
    FutureProvider.family<FrameAnalysisOutput, String>((ref, modelId) {
      final model = ref.watch(frameEditorProvider(modelId)).model;
      final code = defaultDesignCode();
      return Isolate.run(() => runFrameAnalysis(model, code));
    });
