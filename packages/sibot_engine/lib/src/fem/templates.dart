import 'model.dart';

/// Continuous beam over [spans] (m). End supports pinned (or fixed when
/// [fixedEnds]); intermediate supports are rollers. [g] and [q] are
/// characteristic line loads (kN/m, downwards positive) on every span.
Model2D continuousBeam({
  required List<double> spans,
  required FrameSection section,
  double g = 0,
  double q = 0,
  bool fixedEnds = false,
  bool selfWeight = true,
}) {
  final nodes = [const Node2D(0, 0)];
  var x = 0.0;
  for (final s in spans) {
    x += s;
    nodes.add(Node2D(x, 0));
  }
  final end = fixedEnds ? Support.fixed : Support.pinned;
  return Model2D(
    nodes: nodes,
    supports: {
      0: end,
      for (var i = 1; i < spans.length; i++) i: Support.rollerX,
      spans.length: fixedEnds ? Support.fixed : Support.rollerX,
    },
    sections: [section],
    elements: [for (var i = 0; i < spans.length; i++) Element2D(i, i + 1)],
    cases: [
      LoadCase(
        name: 'G',
        selfWeight: selfWeight,
        distributed: [
          if (g != 0)
            for (var i = 0; i < spans.length; i++) DistributedLoad(i, -g),
        ],
      ),
      if (q != 0)
        LoadCase(
          name: 'Q',
          type: LoadType.imposed,
          distributed: [
            for (var i = 0; i < spans.length; i++) DistributedLoad(i, -q),
          ],
        ),
    ],
  );
}

/// Multi-bay, multi-storey frame with fixed bases. Section 0 = columns,
/// 1 = beams. Beam loads g, q (kN/m downwards); [wind] is a horizontal
/// force (kN) at each floor on the left column line.
Model2D portalFrame({
  required int bays,
  required double bayWidth,
  required int storeys,
  required double storeyHeight,
  required FrameSection column,
  required FrameSection beam,
  double g = 0,
  double q = 0,
  double wind = 0,
  bool selfWeight = true,
}) {
  final nodes = <Node2D>[];
  for (var j = 0; j <= storeys; j++) {
    for (var i = 0; i <= bays; i++) {
      nodes.add(Node2D(i * bayWidth, j * storeyHeight));
    }
  }
  int id(int i, int j) => j * (bays + 1) + i;
  final elements = <Element2D>[];
  for (var j = 0; j < storeys; j++) {
    for (var i = 0; i <= bays; i++) {
      elements.add(Element2D(id(i, j), id(i, j + 1)));
    }
  }
  final firstBeam = elements.length;
  for (var j = 1; j <= storeys; j++) {
    for (var i = 0; i < bays; i++) {
      elements.add(Element2D(id(i, j), id(i + 1, j), section: 1));
    }
  }
  final beams = [for (var k = firstBeam; k < elements.length; k++) k];
  return Model2D(
    nodes: nodes,
    supports: {for (var i = 0; i <= bays; i++) id(i, 0): Support.fixed},
    sections: [column, beam],
    elements: elements,
    cases: [
      LoadCase(
        name: 'G',
        selfWeight: selfWeight,
        distributed: [
          if (g != 0)
            for (final k in beams) DistributedLoad(k, -g),
        ],
      ),
      if (q != 0)
        LoadCase(
          name: 'Q',
          type: LoadType.imposed,
          distributed: [for (final k in beams) DistributedLoad(k, -q)],
        ),
      if (wind != 0)
        LoadCase(
          name: 'W',
          type: LoadType.wind,
          nodal: [
            for (var j = 1; j <= storeys; j++) NodalLoad(id(0, j), fx: wind),
          ],
        ),
    ],
  );
}

enum TrussType { pratt, howe, warren }

/// Flat truss of [span] × [height] (m) with [panels] panels, pinned at
/// the left and on a roller at the right. Nodal loads [g], [q] (kN,
/// downwards) at every top-chord node.
Model2D flatTruss({
  required double span,
  required double height,
  required int panels,
  required FrameSection section,
  TrussType type = TrussType.pratt,
  double g = 0,
  double q = 0,
  bool selfWeight = true,
}) {
  final p = panels;
  final dx = span / p;
  // Bottom nodes 0..p, top nodes p+1..2p+1.
  final nodes = <Node2D>[
    for (var i = 0; i <= p; i++) Node2D(i * dx, 0),
    for (var i = 0; i <= p; i++) Node2D(i * dx, height),
  ];
  int b(int i) => i;
  int t(int i) => p + 1 + i;
  final elements = <Element2D>[];
  void add(int a, int c) =>
      elements.add(Element2D(a, c, kind: ElementKind.truss));
  for (var i = 0; i < p; i++) {
    add(b(i), b(i + 1)); // bottom chord
    add(t(i), t(i + 1)); // top chord
  }
  for (var i = 0; i <= p; i++) {
    // Verticals at every panel point (a Warren truss on this grid also
    // needs them: its top nodes would otherwise sit on collinear chords).
    add(b(i), t(i));
  }
  for (var i = 0; i < p; i++) {
    final leftHalf = i < p / 2;
    switch (type) {
      case TrussType.pratt:
        // Diagonals slope down towards mid-span (tension under gravity).
        leftHalf ? add(t(i), b(i + 1)) : add(b(i), t(i + 1));
      case TrussType.howe:
        leftHalf ? add(b(i), t(i + 1)) : add(t(i), b(i + 1));
      case TrussType.warren:
        i.isEven ? add(b(i), t(i + 1)) : add(t(i), b(i + 1));
    }
  }
  final top = [for (var i = 0; i <= p; i++) t(i)];
  return Model2D(
    nodes: nodes,
    supports: {b(0): Support.pinned, b(p): Support.rollerX},
    sections: [section],
    elements: elements,
    cases: [
      LoadCase(
        name: 'G',
        selfWeight: selfWeight,
        nodal: [
          if (g != 0)
            for (final n in top) NodalLoad(n, fy: -g),
        ],
      ),
      if (q != 0)
        LoadCase(
          name: 'Q',
          type: LoadType.imposed,
          nodal: [for (final n in top) NodalLoad(n, fy: -q)],
        ),
    ],
  );
}
