import 'dart:math' as math;
import 'dart:typed_data';

import '../fem/analysis.dart' show ModelError, ModelProblem;
import '../fem/banded.dart';
import 'model3d.dart';

/// Internal forces and displacement at a point along a member.
///
/// Sign conventions: N > 0 in tension; My > 0 when the local +z fibre is
/// in compression (sagging for a beam under gravity), Mz likewise for the
/// local +y fibre; Vy, Vz are the transverse shears; T the torque.
/// [disp] is the global displacement (m) of the point.
class Station3D {
  final double x;
  final double n, vy, vz, t, my, mz;
  final List<double> disp;
  const Station3D(
    this.x,
    this.n,
    this.vy,
    this.vz,
    this.t,
    this.my,
    this.mz,
    this.disp,
  );

  Station3D _comb(Station3D o, double a, double b) => Station3D(
    x,
    a * n + b * o.n,
    a * vy + b * o.vy,
    a * vz + b * o.vz,
    a * t + b * o.t,
    a * my + b * o.my,
    a * mz + b * o.mz,
    [for (var k = 0; k < 3; k++) a * disp[k] + b * o.disp[k]],
  );
}

class Member3DResult {
  /// End forces acting on the member in local axes (12 values).
  final List<double> endForces;
  final List<Station3D> stations;
  const Member3DResult(this.endForces, this.stations);

  double _max(double Function(Station3D) f) =>
      stations.map((s) => f(s).abs()).reduce(math.max);
  double get maxAbsMy => _max((s) => s.my);
  double get maxAbsMz => _max((s) => s.mz);
  double get maxAbsN => _max((s) => s.n);
}

class Frame3DResult {
  /// Displacements per node: ux, uy, uz (m), rx, ry, rz (rad).
  final List<List<double>> displacements;

  /// Reactions per supported node (kN, kN·m), global axes.
  final Map<int, List<double>> reactions;
  final List<Member3DResult> members;

  const Frame3DResult(this.displacements, this.reactions, this.members);

  Frame3DResult _combine(Frame3DResult o, double a, double b) => Frame3DResult(
    [
      for (var i = 0; i < displacements.length; i++)
        [
          for (var k = 0; k < 6; k++)
            a * displacements[i][k] + b * o.displacements[i][k],
        ],
    ],
    {
      for (final e in reactions.entries)
        e.key: [
          for (var k = 0; k < 6; k++)
            a * e.value[k] + b * o.reactions[e.key]![k],
        ],
    },
    [
      for (var i = 0; i < members.length; i++)
        Member3DResult(
          [
            for (var k = 0; k < 12; k++)
              a * members[i].endForces[k] + b * o.members[i].endForces[k],
          ],
          [
            for (var s = 0; s < members[i].stations.length; s++)
              members[i].stations[s]._comb(o.members[i].stations[s], a, b),
          ],
        ),
    ],
  );

  Frame3DResult scaled(double f) => _combine(this, f, 0);
  Frame3DResult plus(Frame3DResult o) => _combine(o, 1, 1);
}

class _Elem3 {
  final Element3D e;
  final double l;

  /// Rows: local x, y, z in global coordinates.
  final List<List<double>> r;
  final Float64List k; // 12 × 12 local stiffness, row-major

  /// [k] with the released DOFs condensed out (same as [k] when none).
  final Float64List kc;
  final List<int> rel;
  final double ea, eiy, eiz, gj;

  /// Station positions along the member, shared by every load case.
  List<double> xs = const [];

  _Elem3(
    this.e,
    this.l,
    this.r,
    this.k,
    this.kc,
    this.rel,
    this.ea,
    this.eiy,
    this.eiz,
    this.gj,
  );
}

/// Linearly varying load on [a, b] (local axes, kN/m).
class _Seg3 {
  final double a, b;
  final List<double> q1, q2;
  const _Seg3(this.a, this.b, this.q1, this.q2);

  List<double> at(double x) {
    final t = b > a ? (x - a) / (b - a) : 0.0;
    return [for (var k = 0; k < 3; k++) q1[k] + (q2[k] - q1[k]) * t];
  }
}

/// Concentrated force at [a] (local axes, kN).
class _Pt3 {
  final double a;
  final List<double> p;
  const _Pt3(this.a, this.p);
}

typedef _MemberLoads = (List<_Seg3>, List<_Pt3>);

const _gx = [
  -0.9061798459386640,
  -0.5384693101056831,
  0.0,
  0.5384693101056831,
  0.9061798459386640,
];
const _gw = [
  0.2369268850561891,
  0.4786286704993665,
  0.5688888888888889,
  0.4786286704993665,
  0.2369268850561891,
];

/// ∫ f over [a, b] by 5-point Gauss (exact for degree ≤ 9).
double _gauss(double a, double b, double Function(double) f) {
  if (b <= a) return 0;
  final h = (b - a) / 2, m = (a + b) / 2;
  var s = 0.0;
  for (var g = 0; g < 5; g++) {
    s += _gw[g] * f(m + h * _gx[g]);
  }
  return s * h;
}

/// Deflection at [x] of a fixed-fixed beam of length [l] under a unit
/// transverse force at [xi], times EI.
double _greenBending(double x, double xi, double l) {
  if (x <= xi) {
    final b = l - xi;
    return b * b * x * x * (3 * xi * l - x * (3 * xi + b)) / (6 * l * l * l);
  }
  final a = xi, b = l - xi, y = l - x;
  return a * a * y * y * (3 * b * l - y * (3 * b + a)) / (6 * l * l * l);
}

/// Axial displacement at [x] of a bar fixed at both ends under a unit
/// axial force at [xi], times EA.
double _greenAxial(double x, double xi, double l) =>
    x <= xi ? x * (l - xi) / l : xi * (l - x) / l;

/// Sequential static condensation of the DOFs [rel] of a 12 × 12 matrix
/// and, optionally, of a load vector (both copied).
(Float64List, List<double>?) _condense(
  Float64List k,
  List<int> rel, [
  List<double>? f,
]) {
  final c = Float64List.fromList(k);
  final g = f == null ? null : List<double>.of(f);
  for (final r in rel) {
    final krr = c[r * 12 + r];
    if (krr.abs() > 1e-30) {
      final col = [for (var i = 0; i < 12; i++) c[i * 12 + r]];
      final row = [for (var j = 0; j < 12; j++) c[r * 12 + j]];
      for (var i = 0; i < 12; i++) {
        if (col[i] == 0) continue;
        for (var j = 0; j < 12; j++) {
          c[i * 12 + j] -= col[i] * row[j] / krr;
        }
      }
      if (g != null) {
        final fr = g[r];
        for (var i = 0; i < 12; i++) {
          g[i] -= col[i] * fr / krr;
        }
      }
    }
    for (var i = 0; i < 12; i++) {
      c[i * 12 + r] = 0;
      c[r * 12 + i] = 0;
    }
    if (g != null) g[r] = 0;
  }
  return (c, g);
}

/// Member-end values of the released DOFs: k_bb u_b = f_b − k_ba u_a
/// (zero end action), written into [u].
void _recover(Float64List k, List<int> rel, List<double> u, List<double> f) {
  final m = rel.length;
  final a = [
    for (final i in rel) [for (final j in rel) k[i * 12 + j]],
  ];
  final rhs = [
    for (final i in rel)
      () {
        var s = f[i];
        for (var j = 0; j < 12; j++) {
          if (!rel.contains(j)) s -= k[i * 12 + j] * u[j];
        }
        return s;
      }(),
  ];
  // Tiny regularisation: a member free to spin (torsion released at both
  // ends) keeps a definite, force-free solution.
  var scale = 0.0;
  for (var i = 0; i < m; i++) {
    scale = math.max(scale, a[i][i].abs());
  }
  for (var i = 0; i < m; i++) {
    a[i][i] += 1e-12 * math.max(scale, 1e-30);
  }
  // Gaussian elimination with partial pivoting (m ≤ 6).
  for (var p = 0; p < m; p++) {
    var best = p;
    for (var r = p + 1; r < m; r++) {
      if (a[r][p].abs() > a[best][p].abs()) best = r;
    }
    if (best != p) {
      final t = a[p];
      a[p] = a[best];
      a[best] = t;
      final tr = rhs[p];
      rhs[p] = rhs[best];
      rhs[best] = tr;
    }
    final piv = a[p][p];
    if (piv.abs() < 1e-300) continue;
    for (var r = p + 1; r < m; r++) {
      final f = a[r][p] / piv;
      if (f == 0) continue;
      for (var c = p; c < m; c++) {
        a[r][c] -= f * a[p][c];
      }
      rhs[r] -= f * rhs[p];
    }
  }
  final x = List<double>.filled(m, 0);
  for (var p = m - 1; p >= 0; p--) {
    var s = rhs[p];
    for (var c = p + 1; c < m; c++) {
      s -= a[p][c] * x[c];
    }
    x[p] = a[p][p].abs() < 1e-300 ? 0 : s / a[p][p];
  }
  for (var i = 0; i < m; i++) {
    u[rel[i]] = x[i];
  }
}

/// Local axes of a member: x along it, z in the vertical plane pointing
/// up (global X for vertical members), then rotated by [rollDeg].
List<List<double>> memberAxes(Node3D a, Node3D b, double rollDeg) {
  final dx = b.x - a.x, dy = b.y - a.y, dz = b.z - a.z;
  final l = math.sqrt(dx * dx + dy * dy + dz * dz);
  final x = [dx / l, dy / l, dz / l];
  final ref = x[2].abs() > 0.999 ? [1.0, 0.0, 0.0] : [0.0, 0.0, 1.0];
  final dot = ref[0] * x[0] + ref[1] * x[1] + ref[2] * x[2];
  var z = [for (var k = 0; k < 3; k++) ref[k] - dot * x[k]];
  final zn = math.sqrt(z[0] * z[0] + z[1] * z[1] + z[2] * z[2]);
  z = [for (final v in z) v / zn];
  var y = [
    z[1] * x[2] - z[2] * x[1],
    z[2] * x[0] - z[0] * x[2],
    z[0] * x[1] - z[1] * x[0],
  ];
  if (rollDeg != 0) {
    final c = math.cos(rollDeg * math.pi / 180);
    final s = math.sin(rollDeg * math.pi / 180);
    final y2 = [for (var k = 0; k < 3; k++) c * y[k] + s * z[k]];
    final z2 = [for (var k = 0; k < 3; k++) -s * y[k] + c * z[k]];
    y = y2;
    z = z2;
  }
  return [x, y, z];
}

Float64List _localStiffness(
  double l,
  double ea,
  double eiy,
  double eiz,
  double gj,
) {
  final k = Float64List(144);
  void set(int i, int j, double v) {
    k[i * 12 + j] = v;
    k[j * 12 + i] = v;
  }

  final l2 = l * l, l3 = l2 * l;
  set(0, 0, ea / l);
  set(0, 6, -ea / l);
  set(6, 6, ea / l);
  set(3, 3, gj / l);
  set(3, 9, -gj / l);
  set(9, 9, gj / l);
  // Bending in the local x–y plane (v, θz): Iz.
  set(1, 1, 12 * eiz / l3);
  set(1, 5, 6 * eiz / l2);
  set(1, 7, -12 * eiz / l3);
  set(1, 11, 6 * eiz / l2);
  set(5, 5, 4 * eiz / l);
  set(5, 7, -6 * eiz / l2);
  set(5, 11, 2 * eiz / l);
  set(7, 7, 12 * eiz / l3);
  set(7, 11, -6 * eiz / l2);
  set(11, 11, 4 * eiz / l);
  // Bending in the local x–z plane (w, θy): Iy.
  set(2, 2, 12 * eiy / l3);
  set(2, 4, -6 * eiy / l2);
  set(2, 8, -12 * eiy / l3);
  set(2, 10, -6 * eiy / l2);
  set(4, 4, 4 * eiy / l);
  set(4, 8, 6 * eiy / l2);
  set(4, 10, 2 * eiy / l);
  set(8, 8, 12 * eiy / l3);
  set(8, 10, 6 * eiy / l2);
  set(10, 10, 4 * eiy / l);
  return k;
}

/// Linear static analysis of a space frame by the direct stiffness
/// method (Euler–Bernoulli members, end releases by static condensation,
/// elastic supports).
class Frame3DAnalysis {
  final Model3D model;
  final List<_Elem3> _elems = [];
  late final List<List<int>> _eq;
  late final int _neq;
  late final BandedMatrix _k;
  late final Float64List _kDiag;

  /// Stations per member for the result diagrams.
  static const stationCount = 11;

  Frame3DAnalysis(this.model) {
    _validate();
    _prepare();
    _number();
    _assemble();
  }

  int get equations => _neq;

  /// Equation number of a node DOF (−1 when restrained).
  int equationOf(int node, int dof) => _eq[node][dof];

  /// Diagonal of the stiffness matrix before factorisation.
  Float64List get stiffnessDiagonal => _kDiag;

  /// Solves K·x = rhs with the factorised stiffness.
  Float64List solveVector(Float64List rhs) =>
      _neq == 0 ? Float64List(0) : _k.solve(rhs);

  /// Member lengths, m.
  List<double> get lengths => [for (final e in _elems) e.l];

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
          e.n2 >= model.nodes.length ||
          e.n1 == e.n2) {
        throw ModelError(ModelProblem.badNodeIndex, i);
      }
      if (e.section < 0 || e.section >= model.sections.length) {
        throw ModelError(ModelProblem.badSectionIndex, i);
      }
    }
    for (var i = 0; i < model.sections.length; i++) {
      final s = model.sections[i];
      if (!(s.area > 0 &&
          s.iy > 0 &&
          s.iz > 0 &&
          s.j > 0 &&
          s.youngModulus > 0 &&
          s.shearModulus > 0)) {
        throw ModelError(ModelProblem.badSection, i);
      }
    }
  }

  void _prepare() {
    for (var i = 0; i < model.elements.length; i++) {
      final e = model.elements[i];
      final a = model.nodes[e.n1], b = model.nodes[e.n2];
      final l = math.sqrt(
        math.pow(b.x - a.x, 2) +
            math.pow(b.y - a.y, 2) +
            math.pow(b.z - a.z, 2),
      );
      if (l < 1e-9) throw ModelError(ModelProblem.zeroLength, i);
      final s = model.sections[e.section];
      final ek = s.youngModulus * 1e3, gk = s.shearModulus * 1e3;
      final ea = ek * s.area, eiy = ek * s.iy, eiz = ek * s.iz;
      final gj = gk * s.j;
      final k = _localStiffness(l, ea, eiy, eiz, gj);
      final rel = [
        for (final d in Element3D.releasable)
          if (e.releases.contains(d)) d,
      ];
      _elems.add(
        _Elem3(
          e,
          l,
          memberAxes(a, b, e.roll),
          k,
          rel.isEmpty ? k : _condense(k, rel).$1,
          rel,
          ea,
          eiy,
          eiz,
          gj,
        ),
      );
    }
    _prepareStations();
  }

  /// Station positions: eleven equal steps plus every load boundary and
  /// point load of every case.
  void _prepareStations() {
    for (var i = 0; i < _elems.length; i++) {
      final l = _elems[i].l;
      final xs = <double>[
        for (var s = 0; s < stationCount; s++) l * s / (stationCount - 1),
      ];
      for (final c in model.cases) {
        for (final q in c.member) {
          if (q.element != i || q.uniform) continue;
          xs.add(q.start.clamp(0.0, l));
          xs.add((q.end ?? l).clamp(0.0, l));
        }
        for (final p in c.point) {
          if (p.element == i) xs.add(p.a.clamp(0.0, l));
        }
      }
      xs.sort();
      final out = <double>[];
      for (final x in xs) {
        if (out.isEmpty || x - out.last > 1e-9 * l) out.add(x);
      }
      _elems[i].xs = out;
    }
  }

  /// Nodes whose rotation about a global axis had no stiffness (all
  /// members released there) and was restrained, with the DOF (3–5).
  final Set<(int, int)> freeRotations = {};

  /// Rigid diaphragm slaves: node → (master, dx, dy) with dx, dy the
  /// slave's offset from the master in plan.
  final Map<int, (int, double, double)> _slaves = {};

  /// Per node and DOF: equation terms (equation, coefficient).
  late final List<List<List<(int, double)>>> _map;

  void _number() {
    final n = model.nodes.length;
    final used = List.filled(n, false);
    for (final el in _elems) {
      used[el.e.n1] = true;
      used[el.e.n2] = true;
    }
    // Rigid floors: the first node free in ux, uy, rz is the master; the
    // others follow its in-plane motion (nodes supported in those DOFs
    // stay independent).
    for (final group in model.diaphragms) {
      bool free(int i) {
        final s = model.supports[i];
        return s == null || !(s.ux || s.uy || s.rz);
      }

      final members = [
        for (final i in group)
          if (i >= 0 && i < n && used[i] && free(i)) i,
      ];
      if (members.length < 2) continue;
      final m = members.first;
      for (final s in members.skip(1)) {
        _slaves[s] = (
          m,
          model.nodes[s].x - model.nodes[m].x,
          model.nodes[s].y - model.nodes[m].y,
        );
      }
    }
    final order = reverseCuthillMcKee(n, [
      for (final el in _elems) (el.e.n1, el.e.n2),
      for (final e in _slaves.entries) (e.key, e.value.$1),
    ]);
    final byNew = List.filled(n, 0);
    for (var i = 0; i < n; i++) {
      byNew[order[i]] = i;
    }
    // Rotations that no member or spring resists (every member released
    // there) are restrained, like the pins of a truss.
    final rotDiag = List.generate(n, (_) => [0.0, 0.0, 0.0]);
    var maxRot = 0.0;
    for (final el in _elems) {
      if (el.rel.isEmpty) continue;
      final g = _globalOf(el, el.kc);
      for (var i = 0; i < 3; i++) {
        rotDiag[el.e.n1][i] += g[(3 + i) * 12 + 3 + i];
        rotDiag[el.e.n2][i] += g[(9 + i) * 12 + 9 + i];
      }
    }
    final hasReleases = _elems.any((el) => el.rel.isNotEmpty);
    if (hasReleases) {
      for (final el in _elems) {
        if (el.rel.isNotEmpty) continue;
        final g = _globalOf(el, el.kc);
        for (var i = 0; i < 3; i++) {
          rotDiag[el.e.n1][i] += g[(3 + i) * 12 + 3 + i];
          rotDiag[el.e.n2][i] += g[(9 + i) * 12 + 9 + i];
        }
      }
      for (final r in rotDiag) {
        for (final v in r) {
          maxRot = math.max(maxRot, v);
        }
      }
    }
    final masters = {for (final s in _slaves.values) s.$1};

    _eq = List.generate(n, (_) => List.filled(6, -1));
    var next = 0;
    for (var k = 0; k < n; k++) {
      final node = byNew[k];
      if (!used[node]) continue;
      final sup = model.supports[node] ?? const Support3D();
      final fixed = [...sup.dofs];
      if (model.plane) {
        fixed[1] = fixed[3] = fixed[5] = true;
      }
      if (hasReleases) {
        for (var i = 0; i < 3; i++) {
          final d = 3 + i;
          if (fixed[d] || sup.springs[d] > 0) continue;
          if (d == 5 && (masters.contains(node) || _slaves.containsKey(node))) {
            continue;
          }
          if (rotDiag[node][i] <= 1e-9 * maxRot) {
            fixed[d] = true;
            freeRotations.add((node, d));
          }
        }
      }
      final slave = _slaves.containsKey(node);
      for (var d = 0; d < 6; d++) {
        if (slave && (d == 0 || d == 1 || d == 5)) continue;
        if (!fixed[d]) _eq[node][d] = next++;
      }
    }
    _neq = next;
    _map = [
      for (var node = 0; node < n; node++)
        [for (var d = 0; d < 6; d++) _termsFor(node, d)],
    ];
  }

  List<(int, double)> _termsFor(int node, int d) {
    final s = _slaves[node];
    if (s == null || d == 2 || d == 3 || d == 4) {
      final eq = _eq[node][d];
      return eq >= 0 ? [(eq, 1.0)] : const [];
    }
    final (m, dx, dy) = s;
    final rz = _eq[m][5];
    final out = <(int, double)>[];
    void add(int eq, double c) {
      if (eq >= 0 && c != 0) out.add((eq, c));
    }

    switch (d) {
      case 0:
        add(_eq[m][0], 1);
        add(rz, -dy);
      case 1:
        add(_eq[m][1], 1);
        add(rz, dx);
      default:
        add(rz, 1);
    }
    return out;
  }

  /// Equation terms (equation, coefficient) of a node DOF: one term for
  /// a free DOF, none when restrained, the master's terms on a rigid
  /// floor.
  List<(int, double)> termsOf(int node, int dof) => _map[node][dof];

  /// Displacement of a node DOF from the equation vector.
  double _value(Float64List x, int node, int d) {
    var s = 0.0;
    for (final (eq, c) in _map[node][d]) {
      s += c * x[eq];
    }
    return s;
  }

  List<List<(int, double)>> _dofs(Element3D e) => [
    ..._map[e.n1],
    ..._map[e.n2],
  ];

  /// Global form Tᵀ k T of a local element matrix.
  List<double> _globalOf(_Elem3 el, Float64List k) {
    final r = el.r;
    final out = List<double>.filled(144, 0);
    // (Tᵀ k T)[i][j] = Σ_ab T[a][i] k[a][b] T[b][j], T block-diagonal.
    for (var bi = 0; bi < 4; bi++) {
      for (var bj = 0; bj < 4; bj++) {
        for (var i = 0; i < 3; i++) {
          for (var j = 0; j < 3; j++) {
            var s = 0.0;
            for (var a = 0; a < 3; a++) {
              final ra = r[a][i];
              if (ra == 0) continue;
              for (var b = 0; b < 3; b++) {
                s += ra * k[(bi * 3 + a) * 12 + bj * 3 + b] * r[b][j];
              }
            }
            out[(bi * 3 + i) * 12 + bj * 3 + j] = s;
          }
        }
      }
    }
    return out;
  }

  void _assemble() {
    _k = _build(null, keepDiagonal: true);
  }

  /// Assembles and factorises K (+ the local matrices [extra], e.g.
  /// geometric stiffness, element by element).
  BandedMatrix _build(List<Float64List>? extra, {bool keepDiagonal = false}) {
    var band = 0;
    for (final el in _elems) {
      final d = [
        for (final t in _dofs(el.e))
          for (final (eq, _) in t) eq,
      ];
      if (d.isEmpty) continue;
      band = math.max(band, d.reduce(math.max) - d.reduce(math.min));
    }
    final k = BandedMatrix(math.max(_neq, 1), band);
    for (var e = 0; e < _elems.length; e++) {
      final el = _elems[e];
      final local = extra == null ? el.kc : _withExtra(el, extra[e]);
      final g = _globalOf(el, local);
      final d = _dofs(el.e);
      // K_ab = Σ_ij c_ia c_jb g_ij over the constraint terms; each pair
      // of equations is stored once in the upper triangle.
      for (var i = 0; i < 12; i++) {
        if (d[i].isEmpty) continue;
        for (var j = 0; j < 12; j++) {
          if (d[j].isEmpty) continue;
          final gij = g[i * 12 + j];
          if (gij == 0) continue;
          for (final (a, ca) in d[i]) {
            for (final (b, cb) in d[j]) {
              if (b >= a) k.add(a, b, ca * cb * gij);
            }
          }
        }
      }
    }
    // Elastic supports on free DOFs.
    for (final entry in model.supports.entries) {
      final node = entry.key;
      if (node < 0 || node >= model.nodes.length) continue;
      final springs = entry.value.springs;
      for (var d = 0; d < 6; d++) {
        final ks = springs[d];
        if (ks <= 0) continue;
        final t = _map[node][d];
        for (final (a, ca) in t) {
          for (final (b, cb) in t) {
            if (b >= a) k.add(a, b, ca * cb * ks);
          }
        }
      }
    }
    if (keepDiagonal) {
      _kDiag = Float64List.fromList([
        for (var i = 0; i < _neq; i++) k.get(i, i),
      ]);
    }
    if (_neq == 0) return k;
    try {
      k.factorize();
    } on SingularStiffness catch (s) {
      int? node;
      for (var i = 0; i < _eq.length && node == null; i++) {
        if (_eq[i].contains(s.equation)) node = i;
      }
      throw ModelError(ModelProblem.unstable, node);
    }
    return k;
  }

  List<double> _toLocal(_Elem3 el, List<double> g) => [
    for (var b = 0; b < g.length ~/ 3; b++)
      for (var a = 0; a < 3; a++)
        el.r[a][0] * g[b * 3] +
            el.r[a][1] * g[b * 3 + 1] +
            el.r[a][2] * g[b * 3 + 2],
  ];

  List<double> _toGlobal(_Elem3 el, List<double> l) => [
    for (var b = 0; b < l.length ~/ 3; b++)
      for (var i = 0; i < 3; i++)
        el.r[0][i] * l[b * 3] +
            el.r[1][i] * l[b * 3 + 1] +
            el.r[2][i] * l[b * 3 + 2],
  ];

  /// Local stiffness plus [extra] (e.g. geometric), condensed when the
  /// member has releases.
  Float64List _withExtra(_Elem3 el, Float64List extra) {
    final sum = Float64List.fromList([
      for (var i = 0; i < 144; i++) el.k[i] + extra[i],
    ]);
    return el.rel.isEmpty ? sum : _condense(sum, el.rel).$1;
  }

  /// Member loads of a case in local axes: linear segments and point
  /// forces, per element.
  List<_MemberLoads> _memberLoads(LoadCase3D c) {
    final out = [for (var i = 0; i < _elems.length; i++) (<_Seg3>[], <_Pt3>[])];
    List<double> local(int i, List<double> g, bool isLocal) =>
        isLocal ? g : _toLocal(_elems[i], g);

    if (c.selfWeight) {
      for (var i = 0; i < _elems.length; i++) {
        final s = model.sections[_elems[i].e.section];
        final q = local(i, [0, 0, -s.unitWeight * s.area], false);
        out[i].$1.add(_Seg3(0, _elems[i].l, q, q));
      }
    }
    for (final m in c.member) {
      if (m.element < 0 || m.element >= _elems.length) continue;
      final l = _elems[m.element].l;
      final a = m.start.clamp(0.0, l), b = (m.end ?? l).clamp(0.0, l);
      if (b <= a) continue;
      out[m.element].$1.add(
        _Seg3(
          a,
          b,
          local(m.element, m.q1, m.local),
          local(m.element, m.q2, m.local),
        ),
      );
    }
    for (final p in c.point) {
      if (p.element < 0 || p.element >= _elems.length) continue;
      final l = _elems[p.element].l;
      out[p.element].$2.add(
        _Pt3(p.a.clamp(0.0, l), local(p.element, p.vector, p.local)),
      );
    }
    return out;
  }

  /// Consistent nodal loads (local, uncondensed): the loads weighted by
  /// the shape functions.
  static List<double> _equivalent(double l, _MemberLoads loads) {
    final f = List<double>.filled(12, 0);
    void at(double x, List<double> q, double w) {
      final xi = x / l;
      final n1 = 1 - 3 * xi * xi + 2 * xi * xi * xi;
      final n2 = l * (xi - 2 * xi * xi + xi * xi * xi);
      final n3 = 3 * xi * xi - 2 * xi * xi * xi;
      final n4 = l * (-xi * xi + xi * xi * xi);
      f[0] += (1 - xi) * q[0] * w;
      f[6] += xi * q[0] * w;
      f[1] += n1 * q[1] * w;
      f[5] += n2 * q[1] * w;
      f[7] += n3 * q[1] * w;
      f[11] += n4 * q[1] * w;
      f[2] += n1 * q[2] * w;
      f[4] -= n2 * q[2] * w;
      f[8] += n3 * q[2] * w;
      f[10] -= n4 * q[2] * w;
    }

    for (final s in loads.$1) {
      final h = (s.b - s.a) / 2, m = (s.a + s.b) / 2;
      for (var g = 0; g < 5; g++) {
        final x = m + h * _gx[g];
        at(x, s.at(x), _gw[g] * h);
      }
    }
    for (final p in loads.$2) {
      at(p.a, p.p, 1);
    }
    return f;
  }

  Frame3DResult solveCase(int index) {
    final (f, applied, feq, q) = _loads(index);
    final x = _neq == 0 ? Float64List(1) : _k.solve(f);
    return _result(x, applied, feq, q);
  }

  (Float64List, List<List<double>>, List<List<double>>, List<_MemberLoads>)
  _loads(int index, {List<Float64List>? extra}) {
    final c = model.cases[index];
    final f = Float64List(math.max(_neq, 1));
    final applied = List.generate(
      model.nodes.length,
      (_) => List.filled(6, 0.0),
    );
    for (final p in c.nodal) {
      if (p.node < 0 || p.node >= model.nodes.length) continue;
      final v = p.vector;
      for (var d = 0; d < 6; d++) {
        applied[p.node][d] += v[d];
        for (final (eq, c) in _map[p.node][d]) {
          f[eq] += c * v[d];
        }
      }
    }
    final q = _memberLoads(c);
    final feq = <List<double>>[];
    for (var i = 0; i < _elems.length; i++) {
      final el = _elems[i];
      final loc = _equivalent(el.l, q[i]);
      feq.add(loc);
      // Released ends carry no action: the load is condensed with them.
      final condensed = el.rel.isEmpty
          ? loc
          : _condense(
              extra == null
                  ? el.k
                  : Float64List.fromList([
                      for (var k = 0; k < 144; k++) el.k[k] + extra[i][k],
                    ]),
              el.rel,
              loc,
            ).$2!;
      final g = _toGlobal(el, condensed);
      final d = _dofs(el.e);
      for (var k = 0; k < 12; k++) {
        for (final (eq, c) in d[k]) {
          f[eq] += c * g[k];
        }
      }
    }
    return (f, applied, feq, q);
  }

  static final _zero12 = List<double>.filled(12, 0);

  List<_MemberLoads> get _noLoads => [
    for (var i = 0; i < _elems.length; i++) (const <_Seg3>[], const <_Pt3>[]),
  ];

  /// Static solution for nodal loads only (no load case).
  Frame3DResult solveNodal(List<NodalLoad3D> loads) {
    final f = Float64List(math.max(_neq, 1));
    final applied = List.generate(
      model.nodes.length,
      (_) => List.filled(6, 0.0),
    );
    for (final p in loads) {
      if (p.node < 0 || p.node >= model.nodes.length) continue;
      final v = p.vector;
      for (var d = 0; d < 6; d++) {
        applied[p.node][d] += v[d];
        for (final (eq, c) in _map[p.node][d]) {
          f[eq] += c * v[d];
        }
      }
    }
    final x = _neq == 0 ? Float64List(1) : _k.solve(f);
    return _result(
      x,
      applied,
      List.generate(_elems.length, (_) => List.filled(12, 0.0)),
      _noLoads,
    );
  }

  /// Member forces and reactions from a displacement vector over the
  /// equations, with no member loads (used for modal responses).
  Frame3DResult resultFromDisplacements(Float64List x) => _result(
    x,
    List.generate(model.nodes.length, (_) => List.filled(6, 0.0)),
    List.generate(_elems.length, (_) => List.filled(12, 0.0)),
    _noLoads,
  );

  /// Local end displacements of a member, with the released DOFs taken
  /// from the member's own equilibrium.
  List<double> _memberDisplacements(
    _Elem3 el,
    List<double> ug,
    List<double> feq,
    Float64List? extra,
  ) {
    final ul = _toLocal(el, ug);
    if (el.rel.isNotEmpty) {
      final k = extra == null
          ? el.k
          : Float64List.fromList([
              for (var i = 0; i < 144; i++) el.k[i] + extra[i],
            ]);
      _recover(k, el.rel, ul, feq);
    }
    return ul;
  }

  Frame3DResult _result(
    Float64List x,
    List<List<double>> applied,
    List<List<double>> feq,
    List<_MemberLoads> q, {
    List<Float64List>? extra,
  }) {
    final disp = [
      for (var n = 0; n < model.nodes.length; n++)
        [for (var d = 0; d < 6; d++) _value(x, n, d)],
    ];

    final members = <Member3DResult>[];
    final nodeForces = List.generate(
      model.nodes.length,
      (_) => List.filled(6, 0.0),
    );
    for (var i = 0; i < _elems.length; i++) {
      final el = _elems[i];
      final ug = [...disp[el.e.n1], ...disp[el.e.n2]];
      final ul = _memberDisplacements(el, ug, feq[i], extra?[i]);
      final fe = List<double>.filled(12, 0);
      for (var a = 0; a < 12; a++) {
        var s = -feq[i][a];
        for (var b = 0; b < 12; b++) {
          s += (el.k[a * 12 + b] + (extra?[i][a * 12 + b] ?? 0)) * ul[b];
        }
        fe[a] = s;
      }
      for (final r in el.rel) {
        fe[r] = 0; // exactly, up to round-off
      }
      final fg = _toGlobal(el, fe);
      for (var k = 0; k < 6; k++) {
        nodeForces[el.e.n1][k] += fg[k];
        nodeForces[el.e.n2][k] += fg[6 + k];
      }
      members.add(
        Member3DResult(
          fe,
          _stations(el, fe, ul, q[i], secondOrder: extra != null),
        ),
      );
    }

    final reactions = <int, List<double>>{
      for (final n in model.supports.keys)
        if (n >= 0 && n < model.nodes.length)
          n: [for (var k = 0; k < 6; k++) nodeForces[n][k] - applied[n][k]],
    };
    return Frame3DResult(disp, reactions, members);
  }

  List<Station3D> _stations(
    _Elem3 el,
    List<double> f,
    List<double> u,
    _MemberLoads loads, {
    bool secondOrder = false,
  }) {
    final l = el.l;
    final (segs, pts) = loads;
    final out = <Station3D>[];
    for (final x in el.xs) {
      final xi = x / l;
      // Load integrals from the start: P(x) = ∫q, M(x) = ∫(x − ξ) q.
      final p = [0.0, 0.0, 0.0], mq = [0.0, 0.0, 0.0];
      for (final s in segs) {
        final b = math.min(x, s.b);
        if (b <= s.a) continue;
        for (var k = 0; k < 3; k++) {
          p[k] += _gauss(s.a, b, (t) => s.at(t)[k]);
          mq[k] += _gauss(s.a, b, (t) => (x - t) * s.at(t)[k]);
        }
      }
      for (final pt in pts) {
        if (pt.a < x || (pt.a == 0 && x == 0)) {
          for (var k = 0; k < 3; k++) {
            p[k] += pt.p[k];
            mq[k] += (x - pt.a) * pt.p[k];
          }
        }
      }
      // Fixed-fixed particular displacements (Green's functions), added
      // to the Hermite interpolation of the member-end displacements.
      final part = [0.0, 0.0, 0.0];
      for (final s in segs) {
        for (final (a, b) in [
          (s.a, math.min(x, s.b)),
          (math.max(x, s.a), s.b),
        ]) {
          if (b <= a) continue;
          part[0] += _gauss(a, b, (t) => _greenAxial(x, t, l) * s.at(t)[0]);
          part[1] += _gauss(a, b, (t) => _greenBending(x, t, l) * s.at(t)[1]);
          part[2] += _gauss(a, b, (t) => _greenBending(x, t, l) * s.at(t)[2]);
        }
      }
      for (final pt in pts) {
        part[0] += _greenAxial(x, pt.a, l) * pt.p[0];
        part[1] += _greenBending(x, pt.a, l) * pt.p[1];
        part[2] += _greenBending(x, pt.a, l) * pt.p[2];
      }
      // Hermite shape functions.
      final n1 = 1 - 3 * xi * xi + 2 * xi * xi * xi;
      final n2 = l * (xi - 2 * xi * xi + xi * xi * xi);
      final n3 = 3 * xi * xi - 2 * xi * xi * xi;
      final n4 = l * (-xi * xi + xi * xi * xi);
      final ua = u[0] * (1 - xi) + u[6] * xi + part[0] / el.ea;
      final v =
          n1 * u[1] + n2 * u[5] + n3 * u[7] + n4 * u[11] + part[1] / el.eiz;
      final w =
          n1 * u[2] - n2 * u[4] + n3 * u[8] - n4 * u[10] + part[2] / el.eiy;
      final n = -(f[0] + p[0]);
      // Second-order runs: moments integrated from the start node include
      // the axial force acting on the deflection relative to that node
      // (chord rotation and P-δ).
      final dv = secondOrder ? v - u[1] : 0.0;
      final dw = secondOrder ? w - u[2] : 0.0;
      out.add(
        Station3D(
          x,
          n,
          f[1] + p[1],
          f[2] + p[2],
          -f[3],
          f[4] + x * f[2] + mq[2] + n * dw,
          -(f[5] - x * f[1] - mq[1]) + n * dv,
          _toGlobal(el, [ua, v, w]),
        ),
      );
    }
    return out;
  }

  /// Consistent geometric stiffness (local) of a member under axial
  /// force [n] (kN, tension positive).
  Float64List geometricStiffness(int element, double n) {
    final el = _elems[element];
    final l = el.l;
    final s = model.sections[el.e.section];
    final k = Float64List(144);
    void set(int i, int j, double v) {
      k[i * 12 + j] = v;
      k[j * 12 + i] = v;
    }

    final c = n / (30 * l);
    // Lateral displacement v (with θz) and w (with θy).
    set(1, 1, 36 * c);
    set(1, 5, 3 * l * c);
    set(1, 7, -36 * c);
    set(1, 11, 3 * l * c);
    set(5, 5, 4 * l * l * c);
    set(5, 7, -3 * l * c);
    set(5, 11, -l * l * c);
    set(7, 7, 36 * c);
    set(7, 11, -3 * l * c);
    set(11, 11, 4 * l * l * c);
    set(2, 2, 36 * c);
    set(2, 4, -3 * l * c);
    set(2, 8, -36 * c);
    set(2, 10, -3 * l * c);
    set(4, 4, 4 * l * l * c);
    set(4, 8, 3 * l * c);
    set(4, 10, -l * l * c);
    set(8, 8, 36 * c);
    set(8, 10, 3 * l * c);
    set(10, 10, 4 * l * l * c);
    // Torsion (Wagner term with the polar radius of gyration).
    final ip = n * (s.iy + s.iz) / (s.area * l);
    set(3, 3, ip);
    set(3, 9, -ip);
    set(9, 9, ip);
    return k;
  }

  /// Mean axial force of each member in a result.
  List<double> _axial(Frame3DResult r) => [
    for (final m in r.members)
      m.stations.fold(0.0, (s, st) => s + st.n) / m.stations.length,
  ];

  /// Second-order (P-Δ) analysis of a load case: K + Kg(N) iterated
  /// until the axial forces converge. Effects within members (P-δ) on
  /// the moment diagrams are not included.
  Frame3DResult pDeltaCase(int index, {int maxIterations = 20}) {
    final hasReleases = _elems.any((el) => el.rel.isNotEmpty);
    var (f, applied, feq, q) = _loads(index);
    var r = solveCase(index);
    var n = _axial(r);
    for (var it = 0; it < maxIterations; it++) {
      final kg = [
        for (var e = 0; e < _elems.length; e++) geometricStiffness(e, n[e]),
      ];
      final kt = _build(kg);
      // Loads on released members are condensed with K + Kg.
      if (hasReleases) (f, applied, feq, q) = _loads(index, extra: kg);
      final x = _neq == 0 ? Float64List(1) : kt.solve(f);
      r = _result(x, applied, feq, q, extra: kg);
      final n2 = _axial(r);
      var change = 0.0, scale = 1e-9;
      for (var e = 0; e < n.length; e++) {
        change = math.max(change, (n2[e] - n[e]).abs());
        scale = math.max(scale, n2[e].abs());
      }
      n = n2;
      if (change <= 1e-6 * scale) break;
    }
    return r;
  }

  /// Elastic critical load factor αcr of a load case (linear buckling,
  /// K φ = α (−Kg) φ) by inverse power iteration, with the buckled shape
  /// per node (largest translation scaled to 1). Null when the case puts
  /// no member in compression.
  (double, List<List<double>>)? bucklingFactor(int index) =>
      bucklingFactorOf(solveCase(index));

  /// Critical load factor of the axial forces of a result (e.g. a
  /// combination), reusing the factorised stiffness.
  (double, List<List<double>>)? bucklingFactorOf(Frame3DResult result) {
    if (_neq == 0) return null;
    final n = _axial(result);
    if (!n.any((v) => v < 0)) return null;
    final kg = [
      for (var e = 0; e < _elems.length; e++) geometricStiffness(e, n[e]),
    ];
    // y = −Kg x, assembled element by element.
    Float64List minusKg(Float64List x) {
      final y = Float64List(_neq);
      for (var e = 0; e < _elems.length; e++) {
        final el = _elems[e];
        final d = _dofs(el.e);
        final ug = [
          for (final t in d) t.fold(0.0, (s, term) => s + term.$2 * x[term.$1]),
        ];
        // Released ends follow the member (no load on it).
        final ul = _memberDisplacements(el, ug, _zero12, null);
        final fl = [
          for (var a = 0; a < 12; a++)
            () {
              var s = 0.0;
              for (var b = 0; b < 12; b++) {
                s -= kg[e][a * 12 + b] * ul[b];
              }
              return s;
            }(),
        ];
        // Consistent with the condensed K: Tᵀ Kg T, T the recovery map.
        final fc = el.rel.isEmpty ? fl : _condense(el.k, el.rel, fl).$2!;
        final fg = _toGlobal(el, fc);
        for (var k = 0; k < 12; k++) {
          for (final (eq, c) in d[k]) {
            y[eq] += c * fg[k];
          }
        }
      }
      return y;
    }

    var x = Float64List(_neq);
    for (var i = 0; i < _neq; i++) {
      x[i] = 1 + 0.1 * math.sin(i + 1.0);
    }
    var mu = 0.0;
    // −Kg·x is carried from one step to the next: one product per step.
    var gx = minusKg(x);
    for (var it = 0; it < 500; it++) {
      final z = _k.solve(gx);
      // Rayleigh quotient μ = zᵀ(−Kg)z / zᵀK z ≈ 1/α (K z = −Kg x).
      final gz = minusKg(z);
      var num = 0.0, den = 0.0, norm = 0.0;
      for (var i = 0; i < _neq; i++) {
        num += z[i] * gz[i];
        den += z[i] * gx[i];
        norm = math.max(norm, z[i].abs());
      }
      final next = den == 0 ? 0.0 : num / den;
      for (var i = 0; i < _neq; i++) {
        x[i] = z[i] / norm;
        gz[i] /= norm;
      }
      gx = gz;
      // αcr is needed to a few significant digits.
      if (it > 3 && (next - mu).abs() <= 1e-7 * next.abs()) {
        mu = next;
        break;
      }
      mu = next;
    }
    if (mu <= 0) return null;
    final shape = [
      for (var node = 0; node < model.nodes.length; node++)
        [for (var d = 0; d < 6; d++) _value(x, node, d)],
    ];
    var maxT = 0.0;
    for (final s in shape) {
      for (var d = 0; d < 3; d++) {
        maxT = math.max(maxT, s[d].abs());
      }
    }
    if (maxT > 0) {
      for (final s in shape) {
        for (var d = 0; d < 6; d++) {
          s[d] /= maxT;
        }
      }
    }
    return (1 / mu, shape);
  }

  List<Frame3DResult> solveAll() => [
    for (var i = 0; i < model.cases.length; i++) solveCase(i),
  ];
}
