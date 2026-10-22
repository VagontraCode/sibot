// Free modelling in 3D: end releases, springs, plane frames, general
// member loads and the editing operations, against closed forms and the
// 2D solver.
import 'dart:math' as math;

import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  final sec = Section3D.rectangle(300, 500);
  final eiy = sec.youngModulus * 1e3 * sec.iy;

  Model3D beam({
    List<int> releases = const [],
    Map<int, Support3D>? supports,
    List<LoadCase3D>? cases,
    bool plane = false,
  }) => Model3D(
    nodes: const [Node3D(0, 0, 0), Node3D(6, 0, 0)],
    supports: supports ?? {0: Support3D.fixed, 1: Support3D.fixed},
    sections: [sec],
    elements: [Element3D(0, 1, 0, releases: releases)],
    cases:
        cases ??
        const [
          LoadCase3D(name: 'G', member: [MemberLoad3D(0, qz: -10)]),
        ],
    plane: plane,
  );

  group('end releases', () {
    test('My released at both ends of a fixed beam: simply supported', () {
      final r = Frame3DAnalysis(beam(releases: [4, 10])).solveCase(0);
      final st = r.members.single.stations;
      // Midspan qL²/8 = 45, ends 0; midspan deflection 5qL⁴/(384EI).
      expect(st.first.my, closeTo(0, 1e-6));
      expect(st.last.my, closeTo(0, 1e-6));
      final mid = st[st.length ~/ 2];
      expect(mid.x, closeTo(3, 1e-9));
      expect(mid.my, closeTo(45, 1e-6));
      expect(
        mid.disp[2],
        closeTo(-5 * 10 * math.pow(6, 4) / (384 * eiy), 1e-9),
      );
      // Reactions: no fixing moment.
      expect(r.reactions[0]![4], closeTo(0, 1e-6));
      expect(r.reactions[0]![2], closeTo(30, 1e-6));
    });

    test(
      'one released end: propped cantilever, M = qL²/8 at the fixed end',
      () {
        final r = Frame3DAnalysis(beam(releases: [10])).solveCase(0);
        final st = r.members.single.stations;
        expect(st.first.my, closeTo(-45, 1e-6));
        expect(st.last.my, closeTo(0, 1e-6));
        // Reaction at the pinned end 3qL/8.
        expect(r.reactions[1]![2], closeTo(3 * 10 * 6 / 8, 1e-6));
      },
    );

    test('pin-jointed plane truss: free node rotations are restrained', () {
      // Triangle, span 4 m, height 3 m, 30 kN down at the apex.
      final m = Model3D(
        nodes: const [Node3D(0, 0, 0), Node3D(4, 0, 0), Node3D(2, 0, 3)],
        supports: {
          0: Support3D.pinned,
          1: Support3D.of([false, false, true, false, false, false]),
        },
        sections: [sec],
        elements: const [
          Element3D(0, 1, 0, releases: Element3D.pinnedEnds),
          Element3D(0, 2, 0, releases: Element3D.pinnedEnds),
          Element3D(1, 2, 0, releases: Element3D.pinnedEnds),
        ],
        cases: const [
          LoadCase3D(name: 'P', nodal: [NodalLoad3D(2, fz: -30)]),
        ],
        plane: true,
      );
      final an = Frame3DAnalysis(m);
      expect(an.freeRotations, isNotEmpty);
      final r = an.solveCase(0);
      // Rafter force: 15 / sin θ, sin θ = 3 / √13 → compression 18.03 kN.
      final rafter = r.members[1].stations.first.n;
      expect(rafter, closeTo(-15 * math.sqrt(13) / 3, 1e-6));
      // Tie: 15 / tan θ = 10 kN tension.
      expect(r.members[0].stations.first.n, closeTo(10, 1e-6));
      for (final mem in r.members) {
        for (final s in mem.stations) {
          expect(s.my.abs() + s.mz.abs(), lessThan(1e-6));
        }
      }
    });

    test('Euler column pinned by releases: αcr = π²EI/L²', () {
      // Four members, base pinned (moments released at the base), top
      // held laterally, 1000 kN down.
      final nodes = [for (var k = 0; k <= 4; k++) Node3D(0, 0, k * 1.0)];
      final m = Model3D(
        nodes: nodes,
        supports: {
          0: Support3D.fixed,
          4: Support3D.of([true, true, false, true, false, false]),
        },
        sections: [Section3D.rectangle(300, 300)],
        elements: [
          for (var k = 0; k < 4; k++)
            Element3D(
              k,
              k + 1,
              0,
              releases: [
                if (k == 0) ...[4, 5],
                if (k == 3) ...[10, 11],
              ],
            ),
        ],
        cases: const [
          LoadCase3D(name: 'P', nodal: [NodalLoad3D(4, fz: -1000)]),
        ],
      );
      final s = m.sections.single;
      final ei = s.youngModulus * 1e3 * s.iy;
      final pcr = math.pi * math.pi * ei / 16;
      final (alpha, _) = Frame3DAnalysis(m).bucklingFactor(0)!;
      expect(alpha * 1000, closeTo(pcr, pcr * 0.01));
    });
  });

  test('elastic support: tip spring under a cantilever', () {
    // δ = P / (k + 3EI/L³); spring reaction k δ.
    const k = 5000.0;
    final m = beam(
      supports: {
        0: Support3D.fixed,
        1: Support3D.of(
          [false, false, false, false, false, false],
          [0, 0, k, 0, 0, 0],
        ),
      },
      cases: const [
        LoadCase3D(name: 'P', nodal: [NodalLoad3D(1, fz: -20)]),
      ],
    );
    final r = Frame3DAnalysis(m).solveCase(0);
    final d = 20 / (k + 3 * eiy / 216);
    expect(r.displacements[1][2], closeTo(-d, 1e-9));
    expect(r.reactions[1]![2], closeTo(k * d, 1e-6));
    expect(r.reactions[0]![2] + r.reactions[1]![2], closeTo(20, 1e-6));
  });

  group('general member loads', () {
    test('point load: M = Pab/L, deflection under the load', () {
      final m = beam(
        releases: [4, 10],
        cases: const [
          LoadCase3D(name: 'P', point: [PointLoad3D(0, 2, fz: -60)]),
        ],
      );
      final r = Frame3DAnalysis(m).solveCase(0);
      final st = r.members.single.stations;
      final at = st.firstWhere((s) => (s.x - 2).abs() < 1e-9);
      expect(at.my, closeTo(60 * 2 * 4 / 6, 1e-6));
      // Simply supported: δ = P a² b² / (3 EI L).
      expect(at.disp[2], closeTo(-60 * 4 * 16 / (3 * eiy * 6), 1e-9));
    });

    test('partial trapezoidal load: total reaction and lumped mass', () {
      const load = MemberLoad3D(0, qz: -5, start: 1, end: 5, end2: [0, 0, -15]);
      final m = beam(
        releases: [4, 10],
        cases: const [
          LoadCase3D(name: 'G', member: [load]),
        ],
      );
      final r = Frame3DAnalysis(m).solveCase(0);
      // Total 40 kN; centroid at 1 + 4 (5 + 30) / (3 × 20) = 3.333 m.
      expect(r.reactions[0]![2] + r.reactions[1]![2], closeTo(40, 1e-6));
      expect(r.reactions[1]![2], closeTo(40 * (10 / 3) / 6, 1e-6));
      final masses = lumpedMasses(
        m,
        Frame3DAnalysis(m),
        const ModalOptions(massCases: {0: 1}),
      );
      expect(masses[0] + masses[1], closeTo(40 / gravity, 1e-9));
      expect(masses[1], closeTo(40 * (10 / 3) / 6 / gravity, 1e-9));
    });
  });

  test('a 2D frame and its plane 3D model give the same results', () {
    // Portal 6 × 4 m, pinned base on the right, hinge at the beam's right
    // end, trapezoidal partial load, point load and a horizontal force.
    final m2 = Model2D(
      nodes: const [Node2D(0, 0), Node2D(0, 4), Node2D(6, 4), Node2D(6, 0)],
      supports: const {0: Support.fixed, 3: Support.pinned},
      sections: [FrameSection.rectangle(300, 500)],
      elements: const [
        Element2D(0, 1),
        Element2D(1, 2, hingeEnd: true),
        Element2D(3, 2),
      ],
      cases: const [
        LoadCase(
          name: 'G',
          selfWeight: true,
          nodal: [NodalLoad(1, fx: 12, mz: 5)],
          distributed: [
            DistributedLoad(1, -8, w2: -14, start: 1, end: 5),
            DistributedLoad(0, 3, axis: LoadAxis.localY),
          ],
          point: [MemberPointLoad(1, 2, -25)],
        ),
      ],
    );
    final m3 = planeModelFrom2D(m2);
    expect(m3.plane, isTrue);
    final r2 = FrameAnalysis(m2).solveCase(0);
    final r3 = Frame3DAnalysis(m3).solveCase(0);
    for (final n in [0, 3]) {
      expect(r3.reactions[n]![0], closeTo(r2.reactions[n]![0], 1e-6));
      expect(r3.reactions[n]![2], closeTo(r2.reactions[n]![1], 1e-6));
    }
    expect(r3.reactions[0]![4], closeTo(-r2.reactions[0]![2], 1e-6));
    for (var n = 0; n < 4; n++) {
      expect(r3.displacements[n][0], closeTo(r2.displacements[n][0], 1e-9));
      expect(r3.displacements[n][2], closeTo(r2.displacements[n][1], 1e-9));
    }
    // Beam moments and deflections agree at the load points and ends
    // (2D sagging + = 3D My +; 2D w across the member = 3D local z).
    for (final x in [0.0, 1.0, 2.0, 5.0, 6.0]) {
      final s2 = r2.members[1].stations.firstWhere(
        (s) => (s.x - x).abs() < 1e-6,
      );
      final s3 = r3.members[1].stations.firstWhere(
        (s) => (s.x - x).abs() < 1e-6,
      );
      expect(s3.my, closeTo(s2.m, 1e-4), reason: 'M at $x');
      expect(s3.vz, closeTo(s2.v, 1e-4), reason: 'V at $x');
      expect(s3.disp[2], closeTo(s2.w, 1e-7), reason: 'w at $x');
    }
  });

  group('editing', () {
    final base = Model3D(
      nodes: const [Node3D(0, 0, 0), Node3D(0, 0, 3)],
      supports: const {0: Support3D.fixed},
      sections: [sec],
      elements: const [
        Element3D(0, 1, 0, releases: [10]),
      ],
      cases: const [
        LoadCase3D(
          name: 'W',
          nodal: [NodalLoad3D(1, fx: 5)],
          member: [MemberLoad3D(0, qx: 2)],
          point: [PointLoad3D(0, 1.5, fy: 3)],
        ),
      ],
    );

    test('array copies members, supports and loads, sharing nodes', () {
      final c = base.copyItems(elems: {0}, dx: 5, dy: 0, dz: 0, count: 3);
      final m = c.model;
      expect(m.elements, hasLength(4));
      expect(m.nodes, hasLength(8));
      expect(c.elements, {1, 2, 3});
      expect(m.supports.keys, hasLength(4));
      expect(m.elements.last.releases, [10]);
      expect(m.cases.single.member, hasLength(4));
      expect(m.cases.single.point, hasLength(4));
      expect(m.cases.single.nodal, hasLength(4));
      expect(m.nodes.last.x, 15);
      // Copying onto itself again adds nothing.
      final again = m.copyItems(elems: {0}, dx: 5, dy: 0, dz: 0);
      expect(again.model.elements, hasLength(4));
    });

    test('a vertical array stacks a column with shared nodes', () {
      final c = base.copyItems(elems: {0}, dx: 0, dy: 0, dz: 3, count: 2);
      expect(c.model.nodes, hasLength(4));
      expect(c.model.elements, hasLength(3));
      // Only the base node is supported.
      expect(c.model.supports.keys, [0]);
    });

    test('mirror flips loads across the plane', () {
      final c = base.mirrorItems(elems: {0}, about: MirrorPlane.x, c: 2);
      final m = c.model;
      expect(m.nodes.last.x, 4);
      expect(m.cases.single.nodal.last.fx, -5);
      expect(m.cases.single.member.last.qx, -2);
      expect(m.cases.single.point.last.fy, 3);
    });

    test('bulk edits, deletion and selection helpers', () {
      final grid = base.copyItems(elems: {0}, dx: 5, dy: 0, dz: 0, count: 2);
      var m = grid.model;
      final (withBeam, beam) = m.addElement(1, 3, 0);
      m = withBeam;
      expect(m.kindOf(beam), MemberKind.beam);
      expect(m.elementsOfKind(MemberKind.column), {0, 1, 2});
      expect(m.levels(), [0, 3]);
      expect(m.elementsAtLevel(3), {0, 1, 2, 3});
      m = m.updateElements({0, 1}, section: 0, releases: [3, 9, 4]);
      // Torsion is kept at one end.
      expect(m.elements[0].releases, [3, 4]);
      m = m.deleteNodes({1, 3});
      expect(m.elements, hasLength(1));
      expect(m.cases.single.member.single.element, 0);
      expect(m.nodes, hasLength(4));
    });

    test('plane models keep nodes at Y = 0; JSON keeps the new fields', () {
      var m = Model3D.empty(plane: true);
      final (m1, a) = m.addNode(const Node3D(1, 7, 2));
      expect(m1.nodes[a].y, 0);
      m = m1.setSupport(
        a,
        Support3D.of(
          [true, false, true, false, false, false],
          [0, 0, 0, 0, 900, 0],
        ),
      );
      final (m2, b) = m.addNode(const Node3D(5, 0, 2));
      final (m3, e) = m2.addElement(a, b, 0, releases: [4]);
      final m4 = m3
          .setPointLoad(0, PointLoad3D(e, 2, fz: -10))
          .setMemberLoad(
            0,
            const MemberLoad3D(0, qz: -1, start: 1, end2: [0, 0, -3]),
          );
      final back = Model3D.fromJson(m4.toJson());
      expect(back.plane, isTrue);
      expect(back.supports[a]!.springs[4], 900);
      expect(back.elements.single.releases, [4]);
      expect(back.cases.first.point.single.a, 2);
      expect(back.cases.first.member.single.end2, [0, 0, -3]);
      expect(back.cases.first.member.single.start, 1);
    });
  });
}
