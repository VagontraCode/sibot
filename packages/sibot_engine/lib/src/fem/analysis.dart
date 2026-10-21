import 'dart:math' as math;
import 'dart:typed_data';

import 'banded.dart';
import 'model.dart';

/// Why a model cannot be analysed.
enum ModelProblem {
  noNodes,
  noElements,
  badNodeIndex,
  badSectionIndex,
  zeroLength,
  badSection,

  /// The structure is a mechanism (or insufficiently supported).
  unstable,
}

class ModelError implements Exception {
  final ModelProblem problem;

  /// Element or node index concerned, when known.
  final int? index;
  const ModelError(this.problem, [this.index]);

  @override
  String toString() => 'ModelError($problem, $index)';
}

/// Internal forces and local displacements at a station along a member.
class MemberStation {
  /// Distance from the member start, m.
  final double x;

  /// Axial force (kN, tension +), shear (kN) and moment (kN·m, positive
  /// when the fibre on the −y′ side is in tension, i.e. sagging for a beam
  /// drawn left to right).
  final double n;
  final double v;
  final double m;

  /// Local displacements along (u) and across (v) the member, m.
  final double u;
  final double w;

  const MemberStation(this.x, this.n, this.v, this.m, this.u, this.w);

  MemberStation _comb(MemberStation o, double a, double b) => MemberStation(
    x,
    a * n + b * o.n,
    a * v + b * o.v,
    a * m + b * o.m,
    a * u + b * o.u,
    a * w + b * o.w,
  );
}

class MemberResult {
  /// End forces exerted by the nodes on the member, local axes:
  /// (N1, V1, M1, N2, V2, M2).
  final List<double> endForces;
  final List<MemberStation> stations;

  const MemberResult(this.endForces, this.stations);

  double get maxMoment => stations.map((s) => s.m).reduce(math.max);
  double get minMoment => stations.map((s) => s.m).reduce(math.min);
  double get maxAbsShear => stations.map((s) => s.v.abs()).reduce(math.max);
  double get maxAxial => stations.map((s) => s.n).reduce(math.max);
  double get minAxial => stations.map((s) => s.n).reduce(math.min);
}

/// Results of one load case or combination. Linear: results combine by
/// [scaled] and [plus].
class FrameResult {
  /// Node displacements (ux, uy in m, rz in rad).
  final List<List<double>> displacements;

  /// Support reactions by node (Rx, Ry in kN, Mz in kN·m).
  final Map<int, List<double>> reactions;
  final List<MemberResult> members;

  const FrameResult(this.displacements, this.reactions, this.members);

  FrameResult _combine(FrameResult o, double a, double b) => FrameResult(
    [
      for (var i = 0; i < displacements.length; i++)
        [
          for (var k = 0; k < 3; k++)
            a * displacements[i][k] + b * o.displacements[i][k],
        ],
    ],
    {
      for (final e in reactions.entries)
        e.key: [
          for (var k = 0; k < 3; k++)
            a * e.value[k] + b * o.reactions[e.key]![k],
        ],
    },
    [
      for (var i = 0; i < members.length; i++)
        MemberResult(
          [
            for (var k = 0; k < 6; k++)
              a * members[i].endForces[k] + b * o.members[i].endForces[k],
          ],
          [
            for (var s = 0; s < members[i].stations.length; s++)
              members[i].stations[s]._comb(o.members[i].stations[s], a, b),
          ],
        ),
    ],
  );

  FrameResult scaled(double f) => _combine(this, f, 0);
  FrameResult plus(FrameResult o) => _combine(o, 1, 1);

  /// Largest absolute nodal translation, m.
  double get maxTranslation => displacements
      .map((d) => math.sqrt(d[0] * d[0] + d[1] * d[1]))
      .fold(0.0, math.max);
}

/// Local load description used for equivalent loads and diagrams.
class _Segment {
  final double a, b, px1, px2, qy1, qy2;
  const _Segment(this.a, this.b, this.px1, this.px2, this.qy1, this.qy2);
}

class _Point {
  final double a, px, qy;
  const _Point(this.a, this.px, this.qy);
}

/// Geometry and stiffness of an element.
class _Elem {
  final Element2D e;
  final double l, c, s, ea, ei;
  final List<List<double>> kLocal; // condensed

  _Elem(this.e, this.l, this.c, this.s, this.ea, this.ei, this.kLocal);

  List<int> releasedDofs() => [if (e.releasedStart) 2, if (e.releasedEnd) 5];
}

List<List<double>> _frameStiffness(double ea, double ei, double l) {
  final a = ea / l;
  final b = 12 * ei / (l * l * l);
  final c = 6 * ei / (l * l);
  final d = 4 * ei / l;
  final f = 2 * ei / l;
  return [
    [a, 0, 0, -a, 0, 0],
    [0, b, c, 0, -b, c],
    [0, c, d, 0, -c, f],
    [-a, 0, 0, a, 0, 0],
    [0, -b, -c, 0, b, -c],
    [0, c, f, 0, -c, d],
  ];
}

/// Static condensation of the released dofs [rel] in k (and load f).
void _condense(List<List<double>> k, List<double>? f, List<int> rel) {
  for (final r in rel) {
    final krr = k[r][r];
    if (krr == 0) continue;
    final col = [for (var i = 0; i < 6; i++) k[i][r]];
    final row = List<double>.from(k[r]);
    for (var i = 0; i < 6; i++) {
      for (var j = 0; j < 6; j++) {
        k[i][j] -= col[i] * row[j] / krr;
      }
    }
    if (f != null) {
      final fr = f[r];
      for (var i = 0; i < 6; i++) {
        f[i] -= col[i] * fr / krr;
      }
    }
    for (var i = 0; i < 6; i++) {
      k[i][r] = 0;
      k[r][i] = 0;
    }
    if (f != null) f[r] = 0;
  }
}

/// Shape functions at ξ for (u1, v1, θ1, u2, v2, θ2) of a length-l element:
/// axial (index 0, 3) and transverse Hermite (1, 2, 4, 5).
List<double> _shapes(double xi, double l) => [
  1 - xi,
  1 - 3 * xi * xi + 2 * xi * xi * xi,
  l * (xi - 2 * xi * xi + xi * xi * xi),
  xi,
  3 * xi * xi - 2 * xi * xi * xi,
  l * (-xi * xi + xi * xi * xi),
];

const _gaussX = [
  -0.9061798459386640,
  -0.5384693101056831,
  0.0,
  0.5384693101056831,
  0.9061798459386640,
];
const _gaussW = [
  0.2369268850561891,
  0.4786286704993665,
  0.5688888888888889,
  0.4786286704993665,
  0.2369268850561891,
];

/// Linear elastic first-order analysis of a 2D frame.
class FrameAnalysis {
  final Model2D model;
  late final List<_Elem> _elems;

  /// Equation number of (node, dof), −1 when restrained.
  late final List<List<int>> _eq;
  late final int _neq;
  late final BandedMatrix _k;

  /// Station positions per element, shared by all cases.
  late final List<List<double>> _stationX;

  /// Nodes whose rotation was fixed because nothing resists it
  /// (pin-jointed nodes of trusses).
  final Set<int> freeRotationNodes = {};

  FrameAnalysis(this.model) {
    _validate();
    _prepareElements();
    _number();
    _assemble();
    _prepareStations();
  }

  void _validate() {
    if (model.nodes.isEmpty) throw const ModelError(ModelProblem.noNodes);
    if (model.elements.isEmpty) {
      throw const ModelError(ModelProblem.noElements);
    }
    for (var i = 0; i < model.elements.length; i++) {
      final e = model.elements[i];
      if (e.n1 < 0 ||
          e.n2 < 0 ||
          e.n1 >= model.nodes.length ||
          e.n2 >= model.nodes.length) {
        throw ModelError(ModelProblem.badNodeIndex, i);
      }
      if (e.section < 0 || e.section >= model.sections.length) {
        throw ModelError(ModelProblem.badSectionIndex, i);
      }
      final sec = model.sections[e.section];
      if (!(sec.area > 0) || !(sec.inertia > 0) || !(sec.youngModulus > 0)) {
        throw ModelError(ModelProblem.badSection, i);
      }
    }
  }

  void _prepareElements() {
    _elems = [];
    for (var i = 0; i < model.elements.length; i++) {
      final e = model.elements[i];
      final a = model.nodes[e.n1], b = model.nodes[e.n2];
      final dx = b.x - a.x, dy = b.y - a.y;
      final l = math.sqrt(dx * dx + dy * dy);
      if (l < 1e-9) throw ModelError(ModelProblem.zeroLength, i);
      final sec = model.sections[e.section];
      final ea = sec.eKpa * sec.area, ei = sec.eKpa * sec.inertia;
      final k = _frameStiffness(ea, ei, l);
      final el = _Elem(e, l, dx / l, dy / l, ea, ei, k);
      _condense(k, null, el.releasedDofs());
      _elems.add(el);
    }
  }

  void _number() {
    final n = model.nodes.length;
    // Nodes with no rotational stiffness get their rotation restrained.
    final hasRotation = List.filled(n, false);
    for (final el in _elems) {
      if (!el.e.releasedStart) hasRotation[el.e.n1] = true;
      if (!el.e.releasedEnd) hasRotation[el.e.n2] = true;
    }
    for (final entry in model.supports.entries) {
      if (entry.value.kr > 0) hasRotation[entry.key] = true;
    }
    final order = reverseCuthillMcKee(n, [
      for (final el in _elems) (el.e.n1, el.e.n2),
    ]);
    final byNew = List.filled(n, 0);
    for (var i = 0; i < n; i++) {
      byNew[order[i]] = i;
    }
    _eq = List.generate(n, (_) => [-1, -1, -1]);
    var next = 0;
    for (var k = 0; k < n; k++) {
      final node = byNew[k];
      final sup = model.supports[node] ?? const Support();
      final fixed = [sup.ux, sup.uy, sup.rz];
      if (!hasRotation[node] && !sup.rz) {
        fixed[2] = true;
        freeRotationNodes.add(node);
      }
      for (var d = 0; d < 3; d++) {
        if (!fixed[d]) _eq[node][d] = next++;
      }
    }
    _neq = next;
  }

  List<int> _dofs(Element2D e) => [
    _eq[e.n1][0],
    _eq[e.n1][1],
    _eq[e.n1][2],
    _eq[e.n2][0],
    _eq[e.n2][1],
    _eq[e.n2][2],
  ];

  /// Global stiffness of an element: Tᵀ·k·T.
  List<List<double>> _globalK(_Elem el) {
    final c = el.c, s = el.s;
    final t = [
      [c, s, 0.0, 0.0, 0.0, 0.0],
      [-s, c, 0.0, 0.0, 0.0, 0.0],
      [0.0, 0.0, 1.0, 0.0, 0.0, 0.0],
      [0.0, 0.0, 0.0, c, s, 0.0],
      [0.0, 0.0, 0.0, -s, c, 0.0],
      [0.0, 0.0, 0.0, 0.0, 0.0, 1.0],
    ];
    final kt = List.generate(
      6,
      (i) => List.generate(6, (j) {
        var v = 0.0;
        for (var m = 0; m < 6; m++) {
          v += el.kLocal[i][m] * t[m][j];
        }
        return v;
      }),
    );
    return List.generate(
      6,
      (i) => List.generate(6, (j) {
        var v = 0.0;
        for (var m = 0; m < 6; m++) {
          v += t[m][i] * kt[m][j];
        }
        return v;
      }),
    );
  }

  void _assemble() {
    // A fully restrained model (e.g. a single fixed-fixed beam) has no
    // equations: results come from the fixed-end forces alone.
    var band = 0;
    for (final el in _elems) {
      final d = _dofs(el.e).where((x) => x >= 0).toList();
      if (d.isEmpty) continue;
      band = math.max(band, d.reduce(math.max) - d.reduce(math.min));
    }
    _k = BandedMatrix(_neq, band);
    for (final el in _elems) {
      final kg = _globalK(el);
      final d = _dofs(el.e);
      // Only the upper triangle (row ≤ column) is stored.
      for (var i = 0; i < 6; i++) {
        if (d[i] < 0) continue;
        for (var j = 0; j < 6; j++) {
          if (d[j] < 0 || d[i] > d[j]) continue;
          _k.add(d[i], d[j], kg[i][j]);
        }
      }
    }
    for (final entry in model.supports.entries) {
      final s = entry.value;
      final springs = [s.kx, s.ky, s.kr];
      for (var d = 0; d < 3; d++) {
        final q = _eq[entry.key][d];
        if (q >= 0 && springs[d] > 0) _k.add(q, q, springs[d]);
      }
    }
    try {
      _k.factorize();
    } on SingularStiffness catch (e) {
      // Find the node owning the failing equation.
      for (var i = 0; i < _eq.length; i++) {
        if (_eq[i].contains(e.equation)) {
          throw ModelError(ModelProblem.unstable, i);
        }
      }
      throw const ModelError(ModelProblem.unstable);
    }
  }

  void _prepareStations() {
    final sets = [
      for (final el in _elems)
        <double>{for (var k = 0; k <= 40; k++) el.l * k / 40},
    ];
    bool valid(int e) => e >= 0 && e < _elems.length;
    // Extra stations either side of point loads and at load limits.
    for (final c in model.cases) {
      for (final p in c.point) {
        if (!valid(p.element)) continue;
        final l = _elems[p.element].l;
        if (p.a > 0 && p.a < l) {
          sets[p.element].add(math.max(0, p.a - 1e-7 * l));
          sets[p.element].add(math.min(l, p.a + 1e-7 * l));
        }
      }
      for (final d in c.distributed) {
        if (!valid(d.element)) continue;
        final l = _elems[d.element].l;
        for (final x in [d.start, d.end ?? l]) {
          if (x > 0 && x < l) sets[d.element].add(x);
        }
      }
    }
    _stationX = [for (final s in sets) s.toList()..sort()];
  }

  /// Local components of a load along [axis] on element [el].
  (double, double) _toLocal(_Elem el, LoadAxis axis, double w) =>
      switch (axis) {
        LoadAxis.globalX => (w * el.c, -w * el.s),
        LoadAxis.globalY => (w * el.s, w * el.c),
        LoadAxis.localY => (0, w),
      };

  (List<_Segment>, List<_Point>) _localLoads(
    LoadCase c,
    int index,
    List<DistributedLoad> dist,
    List<MemberPointLoad> point,
  ) {
    final el = _elems[index];
    final segs = <_Segment>[];
    final pts = <_Point>[];
    if (c.selfWeight) {
      final sec = model.sections[el.e.section];
      final w = -sec.unitWeight * sec.area;
      final (px, qy) = _toLocal(el, LoadAxis.globalY, w);
      segs.add(_Segment(0, el.l, px, px, qy, qy));
    }
    for (final d in dist) {
      if (d.element != index) continue;
      final a = d.start.clamp(0.0, el.l), b = (d.end ?? el.l).clamp(0.0, el.l);
      if (b <= a) continue;
      var f = 1.0;
      if (d.projected) {
        f = switch (d.axis) {
          LoadAxis.globalY => el.c.abs(),
          LoadAxis.globalX => el.s.abs(),
          LoadAxis.localY => 1.0,
        };
      }
      final (px1, qy1) = _toLocal(el, d.axis, d.w1 * f);
      final (px2, qy2) = _toLocal(el, d.axis, d.w2 * f);
      segs.add(_Segment(a, b, px1, px2, qy1, qy2));
    }
    for (final p in point) {
      if (p.element != index) continue;
      final (px, qy) = _toLocal(el, p.axis, p.p);
      pts.add(_Point(p.a.clamp(0.0, el.l), px, qy));
    }
    return (segs, pts);
  }

  /// Equivalent nodal loads (local, uncondensed).
  List<double> _equivalent(_Elem el, List<_Segment> segs, List<_Point> pts) {
    final f = List<double>.filled(6, 0);
    for (final sg in segs) {
      final half = (sg.b - sg.a) / 2, mid = (sg.a + sg.b) / 2;
      for (var g = 0; g < 5; g++) {
        final x = mid + half * _gaussX[g];
        final t = (x - sg.a) / (sg.b - sg.a);
        final px = sg.px1 + (sg.px2 - sg.px1) * t;
        final qy = sg.qy1 + (sg.qy2 - sg.qy1) * t;
        final n = _shapes(x / el.l, el.l);
        final w = _gaussW[g] * half;
        f[0] += n[0] * px * w;
        f[3] += n[3] * px * w;
        f[1] += n[1] * qy * w;
        f[2] += n[2] * qy * w;
        f[4] += n[4] * qy * w;
        f[5] += n[5] * qy * w;
      }
    }
    for (final p in pts) {
      final n = _shapes(p.a / el.l, el.l);
      f[0] += n[0] * p.px;
      f[3] += n[3] * p.px;
      f[1] += n[1] * p.qy;
      f[2] += n[2] * p.qy;
      f[4] += n[4] * p.qy;
      f[5] += n[5] * p.qy;
    }
    return f;
  }

  /// Solves load case [caseIndex].
  FrameResult solveCase(int caseIndex) {
    final c = model.cases[caseIndex];
    final rhs = Float64List(_neq);
    final nodal = List.generate(model.nodes.length, (_) => [0.0, 0.0, 0.0]);
    for (final p in c.nodal) {
      if (p.node < 0 || p.node >= model.nodes.length) continue;
      nodal[p.node][0] += p.fx;
      nodal[p.node][1] += p.fy;
      nodal[p.node][2] += p.mz;
    }
    for (var i = 0; i < model.nodes.length; i++) {
      for (var d = 0; d < 3; d++) {
        final q = _eq[i][d];
        if (q >= 0) rhs[q] += nodal[i][d];
      }
    }

    // Index member loads by element once (avoids an elements × loads scan).
    final distBy = <int, List<DistributedLoad>>{};
    for (final d in c.distributed) {
      (distBy[d.element] ??= []).add(d);
    }
    final pointBy = <int, List<MemberPointLoad>>{};
    for (final p in c.point) {
      (pointBy[p.element] ??= []).add(p);
    }
    final loads = <(List<_Segment>, List<_Point>)>[];
    final fEq = <List<double>>[];
    for (var i = 0; i < _elems.length; i++) {
      final el = _elems[i];
      final ll = _localLoads(
        c,
        i,
        distBy[i] ?? const [],
        pointBy[i] ?? const [],
      );
      loads.add(ll);
      final f = _equivalent(el, ll.$1, ll.$2);
      // Condense with the uncondensed stiffness so released ends carry
      // no moment.
      final kFull = _frameStiffness(el.ea, el.ei, el.l);
      _condense(kFull, f, el.releasedDofs());
      fEq.add(f);
      final g = _toGlobal(el, f);
      final d = _dofs(el.e);
      for (var k = 0; k < 6; k++) {
        if (d[k] >= 0) rhs[d[k]] += g[k];
      }
    }

    final sol = _k.solve(rhs);
    final disp = List.generate(
      model.nodes.length,
      (i) => [
        for (var d = 0; d < 3; d++) _eq[i][d] >= 0 ? sol[_eq[i][d]] : 0.0,
      ],
    );

    final nodeForces = List.generate(
      model.nodes.length,
      (_) => [0.0, 0.0, 0.0],
    );
    final members = <MemberResult>[];
    for (var i = 0; i < _elems.length; i++) {
      final el = _elems[i];
      final dg = [...disp[el.e.n1], ...disp[el.e.n2]];
      final dl = _toLocalVec(el, dg);
      final end = List<double>.filled(6, 0);
      for (var r = 0; r < 6; r++) {
        var v = -fEq[i][r];
        for (var k = 0; k < 6; k++) {
          v += el.kLocal[r][k] * dl[k];
        }
        end[r] = v;
      }
      for (final r in el.releasedDofs()) {
        end[r] = 0;
      }
      final g = _toGlobal(el, end);
      for (var k = 0; k < 3; k++) {
        nodeForces[el.e.n1][k] += g[k];
        nodeForces[el.e.n2][k] += g[3 + k];
      }
      members.add(
        MemberResult(end, _stations(el, i, end, dl, loads[i].$1, loads[i].$2)),
      );
    }

    final reactions = <int, List<double>>{};
    for (final entry in model.supports.entries) {
      if (entry.value.isEmpty) continue;
      final i = entry.key;
      reactions[i] = [
        for (var d = 0; d < 3; d++) nodeForces[i][d] - nodal[i][d],
      ];
      // A rotation fixed only because the node is pin-jointed carries no
      // moment.
      if (freeRotationNodes.contains(i) && !entry.value.rz) {
        reactions[i]![2] = 0;
      }
    }
    return FrameResult(disp, reactions, members);
  }

  List<double> _toGlobal(_Elem el, List<double> f) {
    final c = el.c, s = el.s;
    return [
      c * f[0] - s * f[1],
      s * f[0] + c * f[1],
      f[2],
      c * f[3] - s * f[4],
      s * f[3] + c * f[4],
      f[5],
    ];
  }

  List<double> _toLocalVec(_Elem el, List<double> g) {
    final c = el.c, s = el.s;
    return [
      c * g[0] + s * g[1],
      -s * g[0] + c * g[1],
      g[2],
      c * g[3] + s * g[4],
      -s * g[3] + c * g[4],
      g[5],
    ];
  }

  List<MemberStation> _stations(
    _Elem el,
    int index,
    List<double> end,
    List<double> dl,
    List<_Segment> segs,
    List<_Point> pts,
  ) {
    final n1 = end[0], v1 = end[1], m1 = end[2];

    // Exact internal forces at x from the start end forces and the loads.
    (double, double, double) forces(double x) {
      var p = 0.0, q = 0.0, mq = 0.0;
      for (final sg in segs) {
        final u = math.min(x, sg.b);
        if (u <= sg.a) continue;
        final t = u - sg.a;
        final len = sg.b - sg.a;
        final kp = (sg.px2 - sg.px1) / len, kq = (sg.qy2 - sg.qy1) / len;
        p += sg.px1 * t + kp * t * t / 2;
        final qi = sg.qy1 * t + kq * t * t / 2;
        q += qi;
        mq += (x - sg.a) * qi - (sg.qy1 * t * t / 2 + kq * t * t * t / 3);
      }
      for (final pt in pts) {
        if (pt.a < x || (pt.a == 0 && x == 0)) {
          p += pt.px;
          q += pt.qy;
          mq += (x - pt.a) * pt.qy;
        }
      }
      return (-n1 - p, v1 + q, -m1 + x * v1 + mq);
    }

    // Transverse deflection: integrate κ = M/EI twice on a fine grid
    // (κ is linear within each step to O(h²)), then fit the end
    // displacements w(0) = w1, w(L) = w2.
    final l = el.l;
    final xs = _stationX[index];
    const sub = 10; // integration steps between consecutive stations
    final values = [for (final x in xs) forces(x)];
    final deflAt = List<double>.filled(xs.length, 0);
    var slope = 0.0, defl = 0.0;
    var kPrev = values[0].$3 / el.ei;
    for (var s = 1; s < xs.length; s++) {
      final x0 = xs[s - 1], dx = (xs[s] - x0) / sub;
      for (var k = 1; k <= sub; k++) {
        final kap = (k == sub ? values[s].$3 : forces(x0 + k * dx).$3) / el.ei;
        defl += slope * dx + (2 * kPrev + kap) * dx * dx / 6;
        slope += 0.5 * (kPrev + kap) * dx;
        kPrev = kap;
      }
      deflAt[s] = defl;
    }
    final wl = dl[1], wr = dl[4];
    final theta = (wr - wl - defl) / l;
    return [
      for (var s = 0; s < xs.length; s++)
        MemberStation(
          xs[s],
          values[s].$1,
          values[s].$2,
          values[s].$3,
          dl[0] + (dl[3] - dl[0]) * xs[s] / l,
          wl + theta * xs[s] + deflAt[s],
        ),
    ];
  }

  /// Solves every load case.
  List<FrameResult> solveAll() => [
    for (var i = 0; i < model.cases.length; i++) solveCase(i),
  ];

  /// Number of equations (free degrees of freedom).
  int get equations => _neq;
}

/// Linear combination Σ factor·result of case results.
FrameResult combineResults(List<FrameResult> cases, Map<int, double> factors) {
  FrameResult? out;
  for (final e in factors.entries) {
    if (e.key < 0 || e.key >= cases.length || e.value == 0) continue;
    final part = cases[e.key].scaled(e.value);
    out = out == null ? part : out.plus(part);
  }
  return out ?? cases.first.scaled(0);
}
