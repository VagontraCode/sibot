// 2D frame analysis checked against closed-form solutions.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

// Steel-like section: E = 200 000 MPa, I = 1e-4 m⁴, A = 0.01 m².
const _sec = FrameSection(
  name: 'S',
  area: 0.01,
  inertia: 1e-4,
  youngModulus: 200000,
  unitWeight: 78.5,
);
const _ei = 200000 * 1000 * 1e-4; // kN·m²

/// Beam along x with [spans] (m) and supports at the given nodes.
Model2D _beam(
  List<double> spans,
  Map<int, Support> supports, {
  List<LoadCase>? cases,
  Map<int, (bool, bool)> hinges = const {},
}) {
  final nodes = [const Node2D(0, 0)];
  var x = 0.0;
  for (final s in spans) {
    x += s;
    nodes.add(Node2D(x, 0));
  }
  return Model2D(
    nodes: nodes,
    supports: supports,
    sections: const [_sec],
    elements: [
      for (var i = 0; i < spans.length; i++)
        Element2D(
          i,
          i + 1,
          hingeStart: hinges[i]?.$1 ?? false,
          hingeEnd: hinges[i]?.$2 ?? false,
        ),
    ],
    cases: cases ?? const [],
  );
}

LoadCase _udl(int elements, double w) => LoadCase(
  name: 'G',
  distributed: [for (var i = 0; i < elements; i++) DistributedLoad(i, -w)],
);

MemberStation _at(MemberResult m, double x) =>
    m.stations.reduce((a, b) => (a.x - x).abs() < (b.x - x).abs() ? a : b);

void main() {
  group('banded Cholesky', () {
    test('solves a small SPD system', () {
      // [4 1 0; 1 3 1; 0 1 2] x = [1 2 3]
      final k = BandedMatrix(3, 1)
        ..add(0, 0, 4)
        ..add(0, 1, 1)
        ..add(1, 1, 3)
        ..add(1, 2, 1)
        ..add(2, 2, 2);
      k.factorize();
      final x = k.solve(Float64ListLike.of([1, 2, 3]));
      expect(4 * x[0] + x[1], closeTo(1, 1e-12));
      expect(x[0] + 3 * x[1] + x[2], closeTo(2, 1e-12));
      expect(x[1] + 2 * x[2], closeTo(3, 1e-12));
    });
    test('RCM gives a permutation', () {
      final p = reverseCuthillMcKee(5, [(0, 4), (4, 1), (1, 3), (3, 2)]);
      expect(p.toSet(), {0, 1, 2, 3, 4});
    });
  });

  test('cantilever with a tip load: PL³/3EI', () {
    final m = _beam(
      [4],
      {0: Support.fixed},
      cases: const [
        LoadCase(name: 'P', nodal: [NodalLoad(1, fy: -10)]),
      ],
    );
    final r = FrameAnalysis(m).solveCase(0);
    expect(r.displacements[1][1], closeTo(-10 * 64 / (3 * _ei), 1e-12));
    expect(r.displacements[1][2], closeTo(-10 * 16 / (2 * _ei), 1e-12));
    expect(r.reactions[0]![1], closeTo(10, 1e-9));
    expect(r.reactions[0]![2], closeTo(40, 1e-9));
    // Hogging moment −PL at the root, zero at the tip.
    expect(r.members[0].stations.first.m, closeTo(-40, 1e-9));
    expect(r.members[0].stations.last.m, closeTo(0, 1e-9));
  });

  test('simply supported beam, UDL: wL²/8 and 5wL⁴/384EI', () {
    final m = _beam(
      [6],
      {0: Support.pinned, 1: Support.rollerX},
      cases: [_udl(1, 10)],
    );
    final r = FrameAnalysis(m).solveCase(0);
    final mid = _at(r.members[0], 3);
    expect(mid.m, closeTo(45, 1e-9));
    expect(mid.w, closeTo(-5 * 10 * math.pow(6, 4) / (384 * _ei), 1e-7));
    expect(r.reactions[0]![1], closeTo(30, 1e-9));
    expect(r.reactions[1]![1], closeTo(30, 1e-9));
    expect(r.members[0].stations.first.v, closeTo(30, 1e-9));
  });

  test('fixed-fixed beam, UDL: wL²/12 at the ends, wL²/24 at mid-span', () {
    final m = _beam(
      [6],
      {0: Support.fixed, 1: Support.fixed},
      cases: [_udl(1, 10)],
    );
    final r = FrameAnalysis(m).solveCase(0);
    expect(r.members[0].stations.first.m, closeTo(-30, 1e-9));
    expect(_at(r.members[0], 3).m, closeTo(15, 1e-9));
    expect(r.reactions[0]![2], closeTo(30, 1e-9));
  });

  test('two equal spans, UDL: 3/8, 10/8, 3/8 wL and −wL²/8', () {
    final m = _beam(
      [5, 5],
      {0: Support.pinned, 1: Support.rollerX, 2: Support.rollerX},
      cases: [_udl(2, 10)],
    );
    final r = FrameAnalysis(m).solveCase(0);
    expect(r.reactions[0]![1], closeTo(18.75, 1e-9));
    expect(r.reactions[1]![1], closeTo(62.5, 1e-9));
    expect(r.reactions[2]![1], closeTo(18.75, 1e-9));
    expect(r.members[0].stations.last.m, closeTo(-31.25, 1e-9));
  });

  test('propped cantilever, central point load: prop reaction 5P/16', () {
    final m = Model2D(
      nodes: const [Node2D(0, 0), Node2D(8, 0)],
      supports: const {0: Support.fixed, 1: Support.rollerX},
      sections: const [_sec],
      elements: const [Element2D(0, 1)],
      cases: const [
        LoadCase(name: 'P', point: [MemberPointLoad(0, 4, -16)]),
      ],
    );
    final r = FrameAnalysis(m).solveCase(0);
    expect(r.reactions[1]![1], closeTo(5 * 16 / 16, 1e-9));
    expect(r.reactions[0]![2], closeTo(3 * 16 * 8 / 16, 1e-9));
    // Jump in shear across the load equals P.
    final before = r.members[0].stations.lastWhere((s) => s.x < 4);
    final after = r.members[0].stations.firstWhere((s) => s.x > 4);
    expect(before.v - after.v, closeTo(16, 1e-6));
  });

  test('trapezoidal load is equivalent to its resultant reactions', () {
    // Simply supported L = 6, load 0 → 12 kN/m: R1 = wL/6, R2 = wL/3.
    final m = _beam(
      [6],
      {0: Support.pinned, 1: Support.rollerX},
      cases: const [
        LoadCase(name: 'T', distributed: [DistributedLoad(0, 0, w2: -12)]),
      ],
    );
    final r = FrameAnalysis(m).solveCase(0);
    expect(r.reactions[0]![1], closeTo(12 * 6 / 6, 1e-9));
    expect(r.reactions[1]![1], closeTo(12 * 6 / 3, 1e-9));
    // Maximum moment wL²/(9√3) at x = L/√3.
    final mMax = r.members[0].maxMoment;
    expect(mMax, closeTo(12 * 36 / (9 * math.sqrt(3)), 0.05));
  });

  test('portal frame under a horizontal load (Kleinlogel)', () {
    // Fixed bases, h = 4, L = 6, equal I; k = (Ib/L)/(Ic/h)... here
    // k = Ib·h/(Ic·L) = 4/6. M_base = Hh(3k+1)/(2(6k+1)),
    // M_top = Hh·3k/(2(6k+1)). Large A suppresses axial shortening.
    const stiff = FrameSection(
      name: 'P',
      area: 10,
      inertia: 1e-4,
      youngModulus: 200000,
    );
    const m = Model2D(
      nodes: [Node2D(0, 0), Node2D(0, 4), Node2D(6, 4), Node2D(6, 0)],
      supports: {0: Support.fixed, 3: Support.fixed},
      sections: [stiff],
      elements: [Element2D(0, 1), Element2D(1, 2), Element2D(2, 3)],
      cases: [
        LoadCase(name: 'H', nodal: [NodalLoad(1, fx: 20)]),
      ],
    );
    final r = FrameAnalysis(m).solveCase(0);
    const k = 4 / 6, h = 4.0, hh = 20.0;
    final mBase = hh * h * (3 * k + 1) / (2 * (6 * k + 1));
    final mTop = hh * h * 3 * k / (2 * (6 * k + 1));
    expect(r.reactions[0]![0], closeTo(-10, 1e-3));
    expect(r.reactions[3]![0], closeTo(-10, 1e-3));
    expect(r.reactions[0]![2].abs(), closeTo(mBase, 1e-3));
    expect(r.members[1].stations.first.m.abs(), closeTo(mTop, 1e-3));
  });

  test('triangular truss: N = −P/(2 sin α)', () {
    // Apex at (2, 2): members at 45°. Load P = 20 down at the apex.
    const m = Model2D(
      nodes: [Node2D(0, 0), Node2D(4, 0), Node2D(2, 2)],
      supports: {0: Support.pinned, 1: Support.rollerX},
      sections: [_sec],
      elements: [
        Element2D(0, 2, kind: ElementKind.truss),
        Element2D(2, 1, kind: ElementKind.truss),
        Element2D(0, 1, kind: ElementKind.truss),
      ],
      cases: [
        LoadCase(name: 'P', nodal: [NodalLoad(2, fy: -20)]),
      ],
    );
    final a = FrameAnalysis(m);
    final r = a.solveCase(0);
    final n = -20 / (2 * math.sin(math.pi / 4));
    expect(r.members[0].stations.first.n, closeTo(n, 1e-9));
    expect(r.members[1].stations.first.n, closeTo(n, 1e-9));
    // Tie: tension P/(2 tan α) = 10 kN.
    expect(r.members[2].stations.first.n, closeTo(10, 1e-9));
    expect(r.members[0].maxMoment.abs(), lessThan(1e-9));
    expect(a.freeRotationNodes, containsAll([0, 1, 2]));
  });

  test('internal hinge carries no moment', () {
    // Two cantilevers meeting at a central hinge, UDL: by symmetry the
    // hinge transfers no shear; root moment −w(L/2)²/2.
    final m = _beam(
      [3, 3],
      {0: Support.fixed, 2: Support.fixed},
      cases: [_udl(2, 10)],
      hinges: {0: (false, true)},
    );
    final r = FrameAnalysis(m).solveCase(0);
    expect(r.members[0].stations.last.m, closeTo(0, 1e-9));
    expect(r.members[0].stations.first.m, closeTo(-45, 1e-9));
  });

  test('spring support settles by R/k', () {
    final m = _beam(
      [6],
      {0: Support.pinned, 1: const Support(ky: 5000)},
      cases: [_udl(1, 10)],
    );
    final r = FrameAnalysis(m).solveCase(0);
    expect(r.reactions[1]![1], closeTo(30, 1e-9));
    expect(r.displacements[1][1], closeTo(-30 / 5000, 1e-12));
  });

  test('inclined rafter with load per horizontal projection', () {
    // Run 4 m, rise 3 m; w = 5 kN/m on plan → vertical reactions 10 kN.
    const m = Model2D(
      nodes: [Node2D(0, 0), Node2D(4, 3)],
      supports: {0: Support.pinned, 1: Support.rollerX},
      sections: [_sec],
      elements: [Element2D(0, 1)],
      cases: [
        LoadCase(
          name: 'S',
          distributed: [DistributedLoad(0, -5, projected: true)],
        ),
      ],
    );
    final r = FrameAnalysis(m).solveCase(0);
    expect(r.reactions[0]![1] + r.reactions[1]![1], closeTo(20, 1e-9));
    expect(r.reactions[1]![1], closeTo(10, 1e-9));
    // Max moment = w·run²/8 = 10 kN·m.
    expect(r.members[0].maxMoment, closeTo(10, 1e-6));
  });

  test('self-weight and global equilibrium of a two-bay frame', () {
    const m = Model2D(
      nodes: [
        Node2D(0, 0),
        Node2D(0, 3),
        Node2D(5, 3),
        Node2D(5, 0),
        Node2D(10, 3),
        Node2D(10, 0),
      ],
      supports: {0: Support.fixed, 3: Support.pinned, 5: Support.fixed},
      sections: [_sec],
      elements: [
        Element2D(0, 1),
        Element2D(1, 2),
        Element2D(2, 3),
        Element2D(2, 4),
        Element2D(4, 5),
      ],
      cases: [
        LoadCase(
          name: 'G',
          selfWeight: true,
          distributed: [DistributedLoad(1, -12), DistributedLoad(3, -8)],
          nodal: [NodalLoad(4, fx: 6)],
        ),
      ],
    );
    final r = FrameAnalysis(m).solveCase(0);
    final totalLength = 3 + 5 + 3 + 5 + 3;
    final sw = 78.5 * 0.01 * totalLength;
    final sumY = r.reactions.values.fold(0.0, (s, v) => s + v[1]);
    final sumX = r.reactions.values.fold(0.0, (s, v) => s + v[0]);
    expect(sumY, closeTo(12 * 5 + 8 * 5 + sw, 1e-8));
    expect(sumX, closeTo(-6, 1e-8));
  });

  test('unstable model is reported', () {
    final m = _beam([4], {0: Support.pinned}, cases: [_udl(1, 1)]);
    expect(() => FrameAnalysis(m), throwsA(isA<ModelError>()));
  });

  group('combinations', () {
    final cases = const [
      LoadCase(name: 'G', type: LoadType.permanent),
      LoadCase(name: 'Q', type: LoadType.imposed),
      LoadCase(name: 'W', type: LoadType.wind),
    ];
    test('EC2: each variable action leads', () {
      final c = generateCombinations(cases, DesignCode.ec2);
      final q = c.firstWhere((x) => x.name.contains('1.5 Q'));
      expect(q.factors, {0: 1.35, 1: 1.5, 2: 1.5 * 0.6});
      final w = c.firstWhere((x) => x.name.contains('1.35G + 1.5 W'));
      expect(w.factors, {0: 1.35, 2: 1.5, 1: 1.5 * 0.7});
      final up = c.firstWhere((x) => x.name == 'ULS G + 1.5 W');
      expect(up.factors, {0: 1.0, 2: 1.5});
      final qp = c.firstWhere(
        (x) => x.kind == CombinationKind.slsQuasiPermanent,
      );
      expect(qp.factors, {0: 1.0, 1: 0.3});
    });
    test('BAEL: 1.35G + 1.5Q + W', () {
      final c = generateCombinations(cases, DesignCode.bael);
      final q = c.firstWhere((x) => x.name.contains('1.5 Q'));
      expect(q.factors[2], closeTo(1.0, 0.002));
    });
    test('results combine linearly', () {
      final m = _beam(
        [6],
        {0: Support.pinned, 1: Support.rollerX},
        cases: [_udl(1, 10), _udl(1, 4)],
      );
      final a = FrameAnalysis(m);
      final all = a.solveAll();
      final comb = combineResults(all, {0: 1.35, 1: 1.5});
      expect(_at(comb.members[0], 3).m, closeTo(1.35 * 45 + 1.5 * 18, 1e-9));
    });
  });

  test('model JSON round trip', () {
    final m = _beam(
      [5, 5],
      {0: Support.pinned, 2: Support.rollerX},
      cases: [_udl(2, 10)],
      hinges: {1: (true, false)},
    );
    final back = Model2D.fromJson(m.toJson());
    expect(back.toJson(), m.toJson());
  });
}

/// Small helper to build a Float64List in tests.
extension Float64ListLike on List<double> {
  static Float64List of(List<double> v) => Float64List.fromList(v);
}
