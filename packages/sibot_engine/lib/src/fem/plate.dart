import 'dart:math' as math;
import 'dart:typed_data';

import '../core.dart';
import '../materials.dart';
import '../rc_bending.dart';
import 'banded.dart';

/// Edge condition of a rectangular plate.
enum EdgeSupport { free, simple, fixed }

/// Concentrated load (kN, downward) at (x, y), m.
class PlatePointLoad {
  final double x;
  final double y;
  final double p;
  const PlatePointLoad(this.x, this.y, this.p);
}

/// Rectangular slab or raft Lx × Ly on a uniform mesh of ACM (Adini–
/// Clough–Melosh) Kirchhoff plate elements. z points down: w and loads
/// are positive downward, positive moments put the bottom in tension.
class PlateInput {
  final double lx;
  final double ly;

  /// Thickness, mm; Young's modulus, MPa; Poisson's ratio.
  final double t;
  final double e;
  final double nu;

  /// Mesh divisions along x and y.
  final int nx;
  final int ny;

  /// Edges x = 0, x = Lx, y = 0, y = Ly.
  final EdgeSupport left;
  final EdgeSupport right;
  final EdgeSupport bottom;
  final EdgeSupport top;

  /// Point supports (columns, piles): w = 0 at the nearest node.
  final List<(double, double)> columns;

  /// Uniform load, kPa (self-weight not included).
  final double q;
  final List<PlatePointLoad> pointLoads;

  /// Winkler subgrade modulus for rafts, kN/m³ (0 = none).
  final double subgrade;

  const PlateInput({
    required this.lx,
    required this.ly,
    required this.t,
    this.e = 31000,
    this.nu = 0.2,
    this.nx = 16,
    this.ny = 16,
    this.left = EdgeSupport.simple,
    this.right = EdgeSupport.simple,
    this.bottom = EdgeSupport.simple,
    this.top = EdgeSupport.simple,
    this.columns = const [],
    this.q = 0,
    this.pointLoads = const [],
    this.subgrade = 0,
  });

  PlateInput withLoads(double q, List<PlatePointLoad> points) => PlateInput(
    lx: lx,
    ly: ly,
    t: t,
    e: e,
    nu: nu,
    nx: nx,
    ny: ny,
    left: left,
    right: right,
    bottom: bottom,
    top: top,
    columns: columns,
    q: q,
    pointLoads: points,
    subgrade: subgrade,
  );

  /// Flexural rigidity D = E t³ / 12(1 − ν²), kN·m.
  double get rigidity => e * 1e3 * math.pow(t / 1e3, 3) / (12 * (1 - nu * nu));
}

class PlateResult {
  final int nx;
  final int ny;
  final double dx;
  final double dy;

  /// Per node (row-major, i along x fastest): deflection (m, down),
  /// moments (kN·m/m).
  final Float64List w;
  final Float64List mx;
  final Float64List my;
  final Float64List mxy;

  /// Sum of the support and soil reactions, kN (equals the total load).
  final double totalReaction;

  /// Reaction of each column, kN.
  final List<double> columnReactions;

  const PlateResult({
    required this.nx,
    required this.ny,
    required this.dx,
    required this.dy,
    required this.w,
    required this.mx,
    required this.my,
    required this.mxy,
    required this.totalReaction,
    required this.columnReactions,
  });

  int node(int i, int j) => j * (nx + 1) + i;
  int get nodeCount => (nx + 1) * (ny + 1);

  double maxOf(Float64List v) => v.reduce(math.max);
  double minOf(Float64List v) => v.reduce(math.min);

  /// Value at the node nearest to (x, y).
  double at(Float64List v, double x, double y) =>
      v[node((x / dx).round().clamp(0, nx), (y / dy).round().clamp(0, ny))];
}

// ── ACM element ───────────────────────────────────────────────────────

/// Polynomial basis of the ACM element and its derivatives at (x, y).
List<double> _p(double x, double y) => [
  1,
  x,
  y,
  x * x,
  x * y,
  y * y,
  x * x * x,
  x * x * y,
  x * y * y,
  y * y * y,
  x * x * x * y,
  x * y * y * y,
];
List<double> _px(double x, double y) => [
  0,
  1,
  0,
  2 * x,
  y,
  0,
  3 * x * x,
  2 * x * y,
  y * y,
  0,
  3 * x * x * y,
  y * y * y,
];
List<double> _py(double x, double y) => [
  0,
  0,
  1,
  0,
  x,
  2 * y,
  0,
  x * x,
  2 * x * y,
  3 * y * y,
  x * x * x,
  3 * x * y * y,
];

/// Curvature rows [w,xx; w,yy; 2 w,xy] of the basis.
List<List<double>> _curv(double x, double y) => [
  [0, 0, 0, 2, 0, 0, 6 * x, 2 * y, 0, 0, 6 * x * y, 0],
  [0, 0, 0, 0, 0, 2, 0, 0, 2 * x, 6 * y, 0, 6 * x * y],
  [0, 0, 0, 0, 2, 0, 0, 4 * x, 4 * y, 0, 6 * x * x, 6 * y * y],
];

/// Inverse of a dense matrix (Gauss–Jordan with partial pivoting).
List<List<double>> _inverse(List<List<double>> a) {
  final n = a.length;
  final m = [
    for (var i = 0; i < n; i++)
      [...a[i], for (var j = 0; j < n; j++) i == j ? 1.0 : 0.0],
  ];
  for (var c = 0; c < n; c++) {
    var p = c;
    for (var r = c + 1; r < n; r++) {
      if (m[r][c].abs() > m[p][c].abs()) p = r;
    }
    final t = m[c];
    m[c] = m[p];
    m[p] = t;
    final d = m[c][c];
    for (var k = 0; k < 2 * n; k++) {
      m[c][k] /= d;
    }
    for (var r = 0; r < n; r++) {
      if (r == c) continue;
      final f = m[r][c];
      if (f == 0) continue;
      for (var k = 0; k < 2 * n; k++) {
        m[r][k] -= f * m[c][k];
      }
    }
  }
  return [for (final r in m) r.sublist(n)];
}

const _gauss4 = [
  (-0.8611363115940526, 0.3478548451374538),
  (-0.3399810435848563, 0.6521451548625461),
  (0.3399810435848563, 0.6521451548625461),
  (0.8611363115940526, 0.3478548451374538),
];

/// Element matrices for an a × b rectangle: stiffness (12 × 12), the
/// Winkler matrix per unit modulus, the load vector per unit pressure,
/// and C⁻¹ to recover curvatures. DOF order per node (corners in the
/// order (0,0), (a,0), (a,b), (0,b)): w, w,x, w,y.
class _AcmElement {
  final List<List<double>> k;
  final List<List<double>> kw;
  final List<double> f;
  final List<List<double>> cInv;
  final double a, b;

  factory _AcmElement(double a, double b, double d, double nu) {
    final corners = [(0.0, 0.0), (a, 0.0), (a, b), (0.0, b)];
    final c = <List<double>>[
      for (final (x, y) in corners) ...[_p(x, y), _px(x, y), _py(x, y)],
    ];
    final cInv = _inverse(c);
    final dm = [
      [d, d * nu, 0.0],
      [d * nu, d, 0.0],
      [0.0, 0.0, d * (1 - nu) / 2],
    ];
    // Integrals in coefficient space.
    final kc = List.generate(12, (_) => List.filled(12, 0.0));
    final wc = List.generate(12, (_) => List.filled(12, 0.0));
    final fc = List.filled(12, 0.0);
    for (final (gx, wx) in _gauss4) {
      for (final (gy, wy) in _gauss4) {
        final x = a * (gx + 1) / 2, y = b * (gy + 1) / 2;
        final wt = wx * wy * a * b / 4;
        final bm = _curv(x, y);
        final p = _p(x, y);
        for (var i = 0; i < 12; i++) {
          fc[i] += wt * p[i];
          for (var j = 0; j < 12; j++) {
            var s = 0.0;
            for (var r = 0; r < 3; r++) {
              for (var q = 0; q < 3; q++) {
                s += bm[r][i] * dm[r][q] * bm[q][j];
              }
            }
            kc[i][j] += wt * s;
            wc[i][j] += wt * p[i] * p[j];
          }
        }
      }
    }
    // Transform to nodal DOFs: K = C⁻ᵀ Kc C⁻¹.
    List<List<double>> congruent(List<List<double>> m) {
      final t = List.generate(12, (_) => List.filled(12, 0.0));
      for (var i = 0; i < 12; i++) {
        for (var j = 0; j < 12; j++) {
          var s = 0.0;
          for (var r = 0; r < 12; r++) {
            s += m[i][r] * cInv[r][j];
          }
          t[i][j] = s;
        }
      }
      final out = List.generate(12, (_) => List.filled(12, 0.0));
      for (var i = 0; i < 12; i++) {
        for (var j = 0; j < 12; j++) {
          var s = 0.0;
          for (var r = 0; r < 12; r++) {
            s += cInv[r][i] * t[r][j];
          }
          out[i][j] = s;
        }
      }
      return out;
    }

    final f = [
      for (var i = 0; i < 12; i++)
        () {
          var s = 0.0;
          for (var r = 0; r < 12; r++) {
            s += cInv[r][i] * fc[r];
          }
          return s;
        }(),
    ];
    return _AcmElement._(congruent(kc), congruent(wc), f, cInv, a, b);
  }

  _AcmElement._(this.k, this.kw, this.f, this.cInv, this.a, this.b);

  /// Moments [Mx, My, Mxy] at local (x, y) for nodal DOFs [d].
  List<double> moments(
    List<double> d,
    double dRig,
    double nu,
    double x,
    double y,
  ) {
    final alpha = [
      for (var r = 0; r < 12; r++)
        () {
          var s = 0.0;
          for (var j = 0; j < 12; j++) {
            s += cInv[r][j] * d[j];
          }
          return s;
        }(),
    ];
    final bm = _curv(x, y);
    final kxx = _dot(bm[0], alpha), kyy = _dot(bm[1], alpha);
    final kxy2 = _dot(bm[2], alpha);
    return [
      -dRig * (kxx + nu * kyy),
      -dRig * (kyy + nu * kxx),
      -dRig * (1 - nu) / 2 * kxy2,
    ];
  }

  static double _dot(List<double> a, List<double> b) {
    var s = 0.0;
    for (var i = 0; i < a.length; i++) {
      s += a[i] * b[i];
    }
    return s;
  }
}

/// Linear analysis of a rectangular plate (Kirchhoff, ACM elements).
PlateResult analysePlate(PlateInput p) =>
    analysePlateCases(p, [(p.q, p.pointLoads)]).first;

/// Analyses several load sets (uniform load, point loads) on one
/// factorisation of the stiffness; [p]'s own loads are ignored.
List<PlateResult> analysePlateCases(
  PlateInput p,
  List<(double, List<PlatePointLoad>)> loads,
) {
  requirePositive(p.lx, 'lx');
  requirePositive(p.ly, 'ly');
  requirePositive(p.t, 't');
  requirePositive(p.e, 'e');
  requireRange(p.nu, 0, 0.49, 'nu');
  requireRange(p.nx.toDouble(), 2, 80, 'nx');
  requireRange(p.ny.toDouble(), 2, 80, 'ny');
  if (p.subgrade < 0) {
    throw const InputError(InputProblem.notPositive, 'subgrade');
  }
  final nx = p.nx, ny = p.ny;
  final dx = p.lx / nx, dy = p.ly / ny;
  final dRig = p.rigidity;
  final el = _AcmElement(dx, dy, dRig, p.nu);
  final nodes = (nx + 1) * (ny + 1);
  int node(int i, int j) => j * (nx + 1) + i;

  // Restraints.
  final fixed = List.generate(nodes, (_) => [false, false, false]);
  void edge(EdgeSupport s, bool alongX, int Function(int) nodeAt, int n) {
    if (s == EdgeSupport.free) return;
    for (var k = 0; k <= n; k++) {
      final f = fixed[nodeAt(k)];
      f[0] = true;
      // Tangential slope: w,x along a y-edge... the edge runs along x
      // when [alongX], so its tangential derivative is w,x.
      if (alongX) {
        f[1] = true;
      } else {
        f[2] = true;
      }
      if (s == EdgeSupport.fixed) {
        f[1] = true;
        f[2] = true;
      }
    }
  }

  edge(p.left, false, (k) => node(0, k), ny);
  edge(p.right, false, (k) => node(nx, k), ny);
  edge(p.bottom, true, (k) => node(k, 0), nx);
  edge(p.top, true, (k) => node(k, ny), nx);
  final columnNodes = <int>[];
  for (final (x, y) in p.columns) {
    final i = (x / dx).round().clamp(0, nx), j = (y / dy).round().clamp(0, ny);
    final n = node(i, j);
    columnNodes.add(n);
    fixed[n][0] = true;
  }

  // Numbering: nodes row by row along the shorter side keeps the band
  // narrow.
  final byX = nx <= ny;
  final order = <int>[
    if (byX)
      for (var j = 0; j <= ny; j++)
        for (var i = 0; i <= nx; i++) node(i, j)
    else
      for (var i = 0; i <= nx; i++)
        for (var j = 0; j <= ny; j++) node(i, j),
  ];
  final eq = List.generate(nodes, (_) => List.filled(3, -1));
  var neq = 0;
  for (final n in order) {
    for (var d = 0; d < 3; d++) {
      if (!fixed[n][d]) eq[n][d] = neq++;
    }
  }
  if (neq == 0) throw const InputError(InputProblem.outOfRange, 'support');

  List<int> elementNodes(int i, int j) => [
    node(i, j),
    node(i + 1, j),
    node(i + 1, j + 1),
    node(i, j + 1),
  ];
  var band = 0;
  for (var j = 0; j < ny; j++) {
    for (var i = 0; i < nx; i++) {
      final e = [
        for (final n in elementNodes(i, j))
          for (var d = 0; d < 3; d++)
            if (eq[n][d] >= 0) eq[n][d],
      ];
      if (e.isEmpty) continue;
      band = math.max(band, e.reduce(math.max) - e.reduce(math.min));
    }
  }

  final k = BandedMatrix(neq, band);
  final ks = p.subgrade;
  for (var j = 0; j < ny; j++) {
    for (var i = 0; i < nx; i++) {
      final en = elementNodes(i, j);
      final dofs = [
        for (final n in en)
          for (var d = 0; d < 3; d++) eq[n][d],
      ];
      for (var a = 0; a < 12; a++) {
        if (dofs[a] < 0) continue;
        for (var b = 0; b < 12; b++) {
          if (dofs[b] < dofs[a]) continue;
          final v = el.k[a][b] + ks * el.kw[a][b];
          if (v != 0) k.add(dofs[a], dofs[b], v);
        }
      }
    }
  }
  try {
    k.factorize();
  } on SingularStiffness {
    throw const InputError(InputProblem.inconsistentGeometry, 'support');
  }

  // One factorisation, one solve per load set.
  return [
    for (final (q, points) in loads)
      _solvePlate(
        p,
        k,
        el,
        eq,
        columnNodes,
        q,
        points,
        dx: dx,
        dy: dy,
        dRig: dRig,
      ),
  ];
}

PlateResult _solvePlate(
  PlateInput p,
  BandedMatrix k,
  _AcmElement el,
  List<List<int>> eq,
  List<int> columnNodes,
  double q,
  List<PlatePointLoad> pointLoads, {
  required double dx,
  required double dy,
  required double dRig,
}) {
  final nx = p.nx, ny = p.ny;
  final nodes = (nx + 1) * (ny + 1);
  final ks = p.subgrade;
  int node(int i, int j) => j * (nx + 1) + i;
  List<int> elementNodes(int i, int j) => [
    node(i, j),
    node(i + 1, j),
    node(i + 1, j + 1),
    node(i, j + 1),
  ];
  final f = Float64List(k.n);
  for (var j = 0; j < ny; j++) {
    for (var i = 0; i < nx; i++) {
      final en = elementNodes(i, j);
      for (var a = 0; a < 12; a++) {
        final e = eq[en[a ~/ 3]][a % 3];
        if (e >= 0) f[e] += q * el.f[a];
      }
    }
  }
  for (final pl in pointLoads) {
    final i = (pl.x / dx).round().clamp(0, nx);
    final j = (pl.y / dy).round().clamp(0, ny);
    final e = eq[node(i, j)][0];
    if (e >= 0) f[e] += pl.p;
  }
  final x = k.solve(f);

  final w = Float64List(nodes);
  final wx = Float64List(nodes), wy = Float64List(nodes);
  for (var n = 0; n < nodes; n++) {
    if (eq[n][0] >= 0) w[n] = x[eq[n][0]];
    if (eq[n][1] >= 0) wx[n] = x[eq[n][1]];
    if (eq[n][2] >= 0) wy[n] = x[eq[n][2]];
  }

  // Nodal moments: average of the adjacent elements' corner values.
  final mx = Float64List(nodes), my = Float64List(nodes);
  final mxy = Float64List(nodes), count = Float64List(nodes);
  const corners = [(0, 0), (1, 0), (1, 1), (0, 1)];
  for (var j = 0; j < ny; j++) {
    for (var i = 0; i < nx; i++) {
      final en = elementNodes(i, j);
      final d = [
        for (final n in en) ...[w[n], wx[n], wy[n]],
      ];
      for (var c = 0; c < 4; c++) {
        final (cx, cy) = corners[c];
        final m = el.moments(d, dRig, p.nu, cx * dx, cy * dy);
        mx[en[c]] += m[0];
        my[en[c]] += m[1];
        mxy[en[c]] += m[2];
        count[en[c]] += 1;
      }
    }
  }
  for (var n = 0; n < nodes; n++) {
    mx[n] /= count[n];
    my[n] /= count[n];
    mxy[n] /= count[n];
  }

  // Column reactions (upward) from the residual K·u − f at the column
  // nodes, assembled element by element.
  final residual = Float64List(nodes);
  for (var j = 0; j < ny; j++) {
    for (var i = 0; i < nx; i++) {
      final en = elementNodes(i, j);
      final d = [
        for (final n in en) ...[w[n], wx[n], wy[n]],
      ];
      for (var a = 0; a < 12; a += 3) {
        var s = 0.0;
        for (var b = 0; b < 12; b++) {
          s += (el.k[a][b] + ks * el.kw[a][b]) * d[b];
        }
        residual[en[a ~/ 3]] += s - q * el.f[a];
      }
    }
  }
  // K·u − f is the reaction in the downward-positive convention.
  final columnReactions = [
    for (final n in columnNodes)
      -residual[n] +
          pointLoads
              .where(
                (pl) =>
                    node(
                      (pl.x / dx).round().clamp(0, nx),
                      (pl.y / dy).round().clamp(0, ny),
                    ) ==
                    n,
              )
              .fold(0.0, (s, pl) => s + pl.p),
  ];
  final total = q * p.lx * p.ly + pointLoads.fold(0.0, (s, pl) => s + pl.p);

  return PlateResult(
    nx: nx,
    ny: ny,
    dx: dx,
    dy: dy,
    w: w,
    mx: mx,
    my: my,
    mxy: mxy,
    totalReaction: total,
    columnReactions: columnReactions,
  );
}

// ── Wood–Armer and reinforcement ──────────────────────────────────────

/// Wood–Armer design moments (kN·m/m): bottom (positive, sagging) and
/// top (negative, returned as magnitudes) in x and y.
({double bx, double by, double tx, double ty}) woodArmer(
  double mx,
  double my,
  double mxy,
) {
  final a = mxy.abs();
  // Bottom.
  var bx = mx + a, by = my + a;
  if (bx < 0) {
    bx = 0;
    by = mx == 0 ? 0 : my + (mxy * mxy / mx).abs();
  } else if (by < 0) {
    by = 0;
    bx = my == 0 ? 0 : mx + (mxy * mxy / my).abs();
  }
  // Top.
  var tx = mx - a, ty = my - a;
  if (tx > 0) {
    tx = 0;
    ty = mx == 0 ? 0 : my - (mxy * mxy / mx).abs();
  } else if (ty > 0) {
    ty = 0;
    tx = my == 0 ? 0 : mx - (mxy * mxy / my).abs();
  }
  return (
    bx: math.max(0, bx),
    by: math.max(0, by),
    tx: math.max(0, -tx),
    ty: math.max(0, -ty),
  );
}

/// Required reinforcement (mm²/m) per node and layer from Wood–Armer
/// moments of a ULS result, with the minimum steel.
class PlateReinforcement {
  final Float64List bottomX;
  final Float64List bottomY;
  final Float64List topX;
  final Float64List topY;

  /// Minimum steel per layer, mm²/m.
  final double minimum;

  const PlateReinforcement({
    required this.bottomX,
    required this.bottomY,
    required this.topX,
    required this.topY,
    required this.minimum,
  });
}

PlateReinforcement plateReinforcement(
  PlateResult r, {
  required DesignCode code,
  required double t,
  required double fck,
  required double fyk,
  double cover = 25,
  double bar = 12,
}) {
  final concrete = Concrete(code, fck);
  final steel = RebarSteel(fyk);
  // x bars in the outer layer, y bars inside them (both faces).
  final dX = t - cover - bar / 2, dY = t - cover - 1.5 * bar;
  if (dY <= 0) throw const InputError(InputProblem.inconsistentGeometry, 't');
  double as(double m, double d) => m <= 0
      ? 0
      : designRectangularBending(
          code: code,
          concrete: concrete,
          steel: steel,
          mEd: m,
          b: 1000,
          d: d,
        ).asTension;
  final n = r.nodeCount;
  final bx = Float64List(n), by = Float64List(n);
  final tx = Float64List(n), ty = Float64List(n);
  for (var i = 0; i < n; i++) {
    final wa = woodArmer(r.mx[i], r.my[i], r.mxy[i]);
    bx[i] = as(wa.bx, dX);
    by[i] = as(wa.by, dY);
    tx[i] = as(wa.tx, dX);
    ty[i] = as(wa.ty, dY);
  }
  return PlateReinforcement(
    bottomX: bx,
    bottomY: by,
    topX: tx,
    topY: ty,
    minimum: minTensionSteel(
      code: code,
      concrete: concrete,
      steel: steel,
      b: 1000,
      d: dY,
    ),
  );
}
