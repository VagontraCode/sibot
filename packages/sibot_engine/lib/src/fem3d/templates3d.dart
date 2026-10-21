import 'dart:math' as math;

import '../fem/model.dart' show LoadType;
import 'model3d.dart';

/// Parameters of a regular building frame: a grid of columns with beams
/// in both directions at every floor. Floor loads (kN/m²) go to the
/// beams through 45° yield lines as moment-equivalent uniform loads.
class BuildingParams {
  final List<double> spansX;
  final List<double> spansY;
  final List<double> storeyHeights;
  final Section3D column;
  final Section3D beam;

  /// Floor finishes and slab (permanent) and imposed loads, kN/m²,
  /// applied at every level including the roof.
  final double g;
  final double q;

  /// Facade line load on perimeter beams, kN/m (permanent).
  final double facade;

  const BuildingParams({
    required this.spansX,
    required this.spansY,
    required this.storeyHeights,
    required this.column,
    required this.beam,
    this.g = 5,
    this.q = 2.5,
    this.facade = 0,
  });

  Map<String, dynamic> toJson() => {
    'sx': spansX,
    'sy': spansY,
    'h': storeyHeights,
    'col': column.toJson(),
    'beam': beam.toJson(),
    'g': g,
    'q': q,
    'facade': facade,
  };
  factory BuildingParams.fromJson(Map<String, dynamic> j) {
    List<double> list(String k) =>
        (j[k] as List).map((e) => (e as num).toDouble()).toList();
    return BuildingParams(
      spansX: list('sx'),
      spansY: list('sy'),
      storeyHeights: list('h'),
      column: Section3D.fromJson(Map<String, dynamic>.from(j['col'] as Map)),
      beam: Section3D.fromJson(Map<String, dynamic>.from(j['beam'] as Map)),
      g: (j['g'] as num).toDouble(),
      q: (j['q'] as num).toDouble(),
      facade: (j['facade'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Moment-equivalent uniform load on a beam of length [l] from a slab
/// panel whose other side is [other], per unit area load (45° lines):
/// triangle q·l/3 on the short side, trapezoid q·a/2·(1 − a²/(3b²)) on
/// the long side (a the short span, b the long one).
double panelLineLoad(double l, double other) {
  final a = math.min(l, other), b = math.max(l, other);
  if (l <= other) return a / 3;
  return a / 2 * (1 - a * a / (3 * b * b));
}

Model3D buildingFrame(BuildingParams p) {
  final xs = [0.0];
  for (final s in p.spansX) {
    xs.add(xs.last + s);
  }
  final ys = [0.0];
  for (final s in p.spansY) {
    ys.add(ys.last + s);
  }
  final zs = [0.0];
  for (final h in p.storeyHeights) {
    zs.add(zs.last + h);
  }
  final nx = xs.length, ny = ys.length;
  int node(int i, int j, int k) => k * nx * ny + j * nx + i;

  final nodes = <Node3D>[
    for (final z in zs)
      for (final y in ys)
        for (final x in xs) Node3D(x, y, z),
  ];
  final supports = {
    for (var j = 0; j < ny; j++)
      for (var i = 0; i < nx; i++) node(i, j, 0): Support3D.fixed,
  };

  final elements = <Element3D>[];
  final gLoads = <MemberLoad3D>[];
  final qLoads = <MemberLoad3D>[];
  for (var k = 1; k < zs.length; k++) {
    for (var j = 0; j < ny; j++) {
      for (var i = 0; i < nx; i++) {
        elements.add(Element3D(node(i, j, k - 1), node(i, j, k), 0));
      }
    }
    // Beams along X with the panels on either side (in Y).
    for (var j = 0; j < ny; j++) {
      for (var i = 0; i < nx - 1; i++) {
        final l = p.spansX[i];
        var w = 0.0;
        if (j > 0) w += panelLineLoad(l, p.spansY[j - 1]);
        if (j < ny - 1) w += panelLineLoad(l, p.spansY[j]);
        final perimeter = j == 0 || j == ny - 1;
        elements.add(Element3D(node(i, j, k), node(i + 1, j, k), 1));
        final e = elements.length - 1;
        gLoads.add(
          MemberLoad3D(e, qz: -(p.g * w + (perimeter ? p.facade : 0))),
        );
        qLoads.add(MemberLoad3D(e, qz: -p.q * w));
      }
    }
    // Beams along Y.
    for (var i = 0; i < nx; i++) {
      for (var j = 0; j < ny - 1; j++) {
        final l = p.spansY[j];
        var w = 0.0;
        if (i > 0) w += panelLineLoad(l, p.spansX[i - 1]);
        if (i < nx - 1) w += panelLineLoad(l, p.spansX[i]);
        final perimeter = i == 0 || i == nx - 1;
        elements.add(Element3D(node(i, j, k), node(i, j + 1, k), 1));
        final e = elements.length - 1;
        gLoads.add(
          MemberLoad3D(e, qz: -(p.g * w + (perimeter ? p.facade : 0))),
        );
        qLoads.add(MemberLoad3D(e, qz: -p.q * w));
      }
    }
  }

  return Model3D(
    nodes: nodes,
    supports: supports,
    sections: [p.column, p.beam],
    elements: elements,
    cases: [
      LoadCase3D(name: 'G', selfWeight: true, member: gLoads),
      LoadCase3D(name: 'Q', type: LoadType.imposed, member: qLoads),
    ],
  );
}

/// A single load case equal to Σ factor × case (self-weight becomes
/// member loads), for second-order and buckling analyses of a
/// combination.
LoadCase3D combinedCase(
  Model3D m,
  Map<int, double> factors, {
  String name = 'Combination',
}) {
  final nodal = <NodalLoad3D>[];
  final member = <MemberLoad3D>[];
  for (final e in factors.entries) {
    if (e.key < 0 || e.key >= m.cases.length) continue;
    final c = m.cases[e.key];
    final f = e.value;
    for (final p in c.nodal) {
      nodal.add(
        NodalLoad3D(
          p.node,
          fx: f * p.fx,
          fy: f * p.fy,
          fz: f * p.fz,
          mx: f * p.mx,
          my: f * p.my,
          mz: f * p.mz,
        ),
      );
    }
    for (final q in c.member) {
      member.add(
        MemberLoad3D(
          q.element,
          qx: f * q.qx,
          qy: f * q.qy,
          qz: f * q.qz,
          local: q.local,
        ),
      );
    }
    if (c.selfWeight) {
      for (var i = 0; i < m.elements.length; i++) {
        final s = m.sections[m.elements[i].section];
        member.add(MemberLoad3D(i, qz: -f * s.unitWeight * s.area));
      }
    }
  }
  return LoadCase3D(name: name, nodal: nodal, member: member);
}

/// [m] with [extra] appended to its load cases.
Model3D withCase(Model3D m, LoadCase3D extra) => Model3D(
  nodes: m.nodes,
  supports: m.supports,
  sections: m.sections,
  elements: m.elements,
  cases: [...m.cases, extra],
);
