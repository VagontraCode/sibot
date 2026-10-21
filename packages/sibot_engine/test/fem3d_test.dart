// 3D frame solver against closed-form solutions and the 2D solver.
import 'dart:math' as math;

import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  // IPE 300-like section with round numbers.
  const sec = Section3D(
    name: 'S',
    area: 0.005,
    iy: 8e-5,
    iz: 6e-6,
    j: 2e-7,
    youngModulus: 210000,
    shearModulus: 81000,
  );
  const e = 210000e3, g = 81000e3;

  Model3D cantilever(NodalLoad3D load, {Node3D tip = const Node3D(4, 0, 0)}) =>
      Model3D(
        nodes: [const Node3D(0, 0, 0), tip],
        supports: {0: Support3D.fixed},
        sections: [sec],
        elements: [const Element3D(0, 1, 0)],
        cases: [
          LoadCase3D(name: 'P', nodal: [load]),
        ],
      );

  test('cantilever along X, vertical tip load: PL³/3EIy and M = PL', () {
    final r = Frame3DAnalysis(
      cantilever(const NodalLoad3D(1, fz: -10)),
    ).solveCase(0);
    expect(r.displacements[1][2], closeTo(-10 * 64 / (3 * e * 8e-5), 1e-12));
    // Hogging at the root: My = −PL.
    expect(r.members[0].stations.first.my, closeTo(-40, 1e-9));
    expect(r.members[0].stations.last.my, closeTo(0, 1e-9));
    expect(r.reactions[0]![2], closeTo(10, 1e-9));
    expect(r.reactions[0]![4], closeTo(-40, 1e-9)); // My reaction about Y
  });

  test('horizontal tip load bends about the minor axis (Iz)', () {
    final r = Frame3DAnalysis(
      cantilever(const NodalLoad3D(1, fy: 5)),
    ).solveCase(0);
    expect(r.displacements[1][1], closeTo(5 * 64 / (3 * e * 6e-6), 1e-12));
  });

  test('tip torque: θ = TL / GJ', () {
    final r = Frame3DAnalysis(
      cantilever(const NodalLoad3D(1, mx: 2)),
    ).solveCase(0);
    expect(r.displacements[1][3], closeTo(2 * 4 / (g * 2e-7), 1e-12));
    expect(r.members[0].stations.first.t, closeTo(2, 1e-9));
  });

  test('simply supported beam with UDL: wL²/8 and 5wL⁴/384EI', () {
    const m = Model3D(
      nodes: [Node3D(0, 0, 0), Node3D(6, 0, 0)],
      supports: {
        0: Support3D(ux: true, uy: true, uz: true, rx: true),
        1: Support3D(uy: true, uz: true),
      },
      sections: [sec],
      elements: [Element3D(0, 1, 0)],
      cases: [
        LoadCase3D(name: 'q', member: [MemberLoad3D(0, qz: -10)]),
      ],
    );
    final r = Frame3DAnalysis(m).solveCase(0);
    final mid = r.members[0].stations[5];
    expect(mid.my, closeTo(10 * 36 / 8, 1e-9));
    expect(mid.disp[2], closeTo(-5 * 10 * 1296 / (384 * e * 8e-5), 1e-12));
    expect(r.members[0].stations.first.vz, closeTo(30, 1e-9));
  });

  test('L-shaped grillage: bending of both legs plus torsion', () {
    // Leg a along X from the fixed support, leg b along Y, load P at the
    // tip: δ = P b³/3EI + P a³/3EI + P b² a / GJ.
    const a = 3.0, b = 2.0, p = 4.0;
    const m = Model3D(
      nodes: [Node3D(0, 0, 0), Node3D(a, 0, 0), Node3D(a, b, 0)],
      supports: {0: Support3D.fixed},
      sections: [sec],
      elements: [Element3D(0, 1, 0), Element3D(1, 2, 0)],
      cases: [
        LoadCase3D(
          name: 'P',
          nodal: [NodalLoad3D(2, fz: -p)],
        ),
      ],
    );
    final r = Frame3DAnalysis(m).solveCase(0);
    final ei = e * 8e-5, gj = g * 2e-7;
    final expected =
        p * b * b * b / (3 * ei) +
        p * a * a * a / (3 * ei) +
        p * b * b * a / gj;
    expect(r.displacements[2][2], closeTo(-expected, 1e-10));
    expect(r.members[0].stations.first.t.abs(), closeTo(p * b, 1e-9));
  });

  test('vertical cantilever: lateral X load bends about local y', () {
    final r = Frame3DAnalysis(
      cantilever(const NodalLoad3D(1, fx: 3), tip: const Node3D(0, 0, 4)),
    ).solveCase(0);
    expect(r.displacements[1][0], closeTo(3 * 64 / (3 * e * 8e-5), 1e-12));
  });

  test('roll of 90° swaps the bending axes', () {
    final m = Model3D(
      nodes: const [Node3D(0, 0, 0), Node3D(4, 0, 0)],
      supports: const {0: Support3D.fixed},
      sections: const [sec],
      elements: const [Element3D(0, 1, 0, roll: 90)],
      cases: const [
        LoadCase3D(name: 'P', nodal: [NodalLoad3D(1, fz: -10)]),
      ],
    );
    final r = Frame3DAnalysis(m).solveCase(0);
    expect(r.displacements[1][2], closeTo(-10 * 64 / (3 * e * 6e-6), 1e-12));
  });

  test('planar portal matches the 2D solver', () {
    // Fixed-base portal 6 m × 4 m, UDL 20 kN/m on the beam and 10 kN
    // horizontal at the top left.
    final s2 = FrameSection(
      name: 's',
      area: 0.005,
      inertia: 8e-5,
      youngModulus: 210000,
    );
    final m2 = Model2D(
      nodes: const [Node2D(0, 0), Node2D(0, 4), Node2D(6, 4), Node2D(6, 0)],
      supports: const {0: Support.fixed, 3: Support.fixed},
      sections: [s2],
      elements: const [Element2D(0, 1), Element2D(1, 2), Element2D(2, 3)],
      cases: const [
        LoadCase(
          name: 'L',
          nodal: [NodalLoad(1, fx: 10)],
          distributed: [DistributedLoad(1, -20)],
        ),
      ],
    );
    final r2 = FrameAnalysis(m2).solveCase(0);

    const m3 = Model3D(
      nodes: [
        Node3D(0, 0, 0),
        Node3D(0, 0, 4),
        Node3D(6, 0, 4),
        Node3D(6, 0, 0),
      ],
      supports: {0: Support3D.fixed, 3: Support3D.fixed},
      sections: [sec],
      elements: [Element3D(0, 1, 0), Element3D(1, 2, 0), Element3D(2, 3, 0)],
      cases: [
        LoadCase3D(
          name: 'L',
          nodal: [NodalLoad3D(1, fx: 10)],
          member: [MemberLoad3D(1, qz: -20)],
        ),
      ],
    );
    final r3 = Frame3DAnalysis(m3).solveCase(0);
    for (final n in [1, 2]) {
      expect(r3.displacements[n][0], closeTo(r2.displacements[n][0], 1e-9));
      expect(r3.displacements[n][2], closeTo(r2.displacements[n][1], 1e-9));
    }
    expect(r3.reactions[0]![2], closeTo(r2.reactions[0]![1], 1e-6));
    expect(r3.reactions[0]![0], closeTo(r2.reactions[0]![0], 1e-6));
    // Beam mid-span moment.
    final mid3 = r3.members[1].stations[5].my;
    final mid2 = r2.members[1].stations
        .reduce((a, b) => (a.x - 3).abs() < (b.x - 3).abs() ? a : b)
        .m;
    expect(mid3, closeTo(mid2, 1e-6));
  });

  test('self-weight in a space frame: total reaction equals weight', () {
    final nodes = <Node3D>[];
    for (final (x, y) in [(0.0, 0.0), (5.0, 0.0), (5.0, 4.0), (0.0, 4.0)]) {
      nodes.add(Node3D(x, y, 0));
      nodes.add(Node3D(x, y, 3));
    }
    final els = <Element3D>[
      for (var k = 0; k < 4; k++) Element3D(2 * k, 2 * k + 1, 0),
      for (var k = 0; k < 4; k++) Element3D(2 * k + 1, (2 * k + 3) % 8, 0),
    ];
    final m = Model3D(
      nodes: nodes,
      supports: {for (var k = 0; k < 4; k++) 2 * k: Support3D.fixed},
      sections: [Section3D.rectangle(300, 500)],
      elements: els,
      cases: const [LoadCase3D(name: 'G', selfWeight: true)],
    );
    final r = Frame3DAnalysis(m).solveCase(0);
    final total = r.reactions.values.fold(0.0, (s, v) => s + v[2]);
    final length = 4 * 3 + 2 * 5 + 2 * 4;
    expect(total, closeTo(25 * 0.15 * length, 1e-6));
  });

  test('unsupported structure is reported as unstable', () {
    const m = Model3D(
      nodes: [Node3D(0, 0, 0), Node3D(4, 0, 0)],
      supports: {},
      sections: [sec],
      elements: [Element3D(0, 1, 0)],
      cases: [LoadCase3D(name: 'P')],
    );
    expect(() => Frame3DAnalysis(m), throwsA(isA<ModelError>()));
  });

  test('rectangle torsion constant (Roark) for a square: 0.1406 a⁴', () {
    final s = Section3D.rectangle(400, 400);
    expect(s.j / math.pow(0.4, 4), closeTo(0.1406, 0.001));
  });
}
