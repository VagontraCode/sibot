// Modal analysis against closed-form frequencies.
import 'dart:math' as math;

import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  const sec = Section3D(
    name: 'S',
    area: 0.01,
    iy: 2e-4,
    iz: 5e-5,
    j: 1e-5,
    youngModulus: 30000,
    shearModulus: 12500,
    unitWeight: 0, // massless members: only the lumped tip mass vibrates
  );
  const e = 30000e3;

  test('cantilever column with a tip mass: ω = √(3EI / m L³), both axes', () {
    // Tip mass 10 t from a 98.1 kN gravity load; L = 4 m.
    const m = Model3D(
      nodes: [Node3D(0, 0, 0), Node3D(0, 0, 4)],
      supports: {0: Support3D.fixed},
      sections: [sec],
      elements: [Element3D(0, 1, 0)],
      cases: [
        LoadCase3D(name: 'G', nodal: [NodalLoad3D(1, fz: -98.1)]),
      ],
    );
    final r = modalAnalysis(
      m,
      options: const ModalOptions(modes: 3, massCases: {0: 1}),
    );
    // Vertical column: local z = global X, so X sway uses Iy, Y sway Iz.
    final wY = math.sqrt(3 * e * 5e-5 / (10 * 64));
    final wX = math.sqrt(3 * e * 2e-4 / (10 * 64));
    expect(r.modes[0].omega, closeTo(wY, wY * 1e-6));
    expect(r.modes[1].omega, closeTo(wX, wX * 1e-6));
    expect(r.modes[0].massRatio[1], closeTo(1, 1e-6));
    expect(r.modes[1].massRatio[0], closeTo(1, 1e-6));
    expect(r.totalMass[0], closeTo(10, 1e-9));
  });

  test('simply supported beam with distributed mass: (π/L)² √(EI/m̄)', () {
    // 24 elements, lumped masses: first frequency within 0.5 %.
    const n = 24, l = 10.0;
    final s = Section3D(
      name: 'B',
      area: 0.1,
      iy: 2e-3,
      iz: 1e-3,
      j: 1e-3,
      youngModulus: 30000,
      shearModulus: 12500,
      unitWeight: 25,
    );
    final model = Model3D(
      nodes: [for (var i = 0; i <= n; i++) Node3D(l * i / n, 0, 0)],
      supports: {
        0: const Support3D(ux: true, uy: true, uz: true, rx: true),
        n: const Support3D(uy: true, uz: true),
      },
      sections: [s],
      elements: [for (var i = 0; i < n; i++) Element3D(i, i + 1, 0)],
    );
    // Restrain horizontal Y sway at every node to keep only vertical modes.
    final m2 = Model3D(
      nodes: model.nodes,
      supports: {
        ...model.supports,
        for (var i = 1; i < n; i++) i: const Support3D(uy: true, ux: true),
      },
      sections: model.sections,
      elements: model.elements,
    );
    final r = modalAnalysis(m2, options: const ModalOptions(modes: 2));
    final mBar = 25 * 0.1 / gravity; // t/m
    final w1 = math.pow(math.pi / l, 2) * math.sqrt(e * 2e-3 / mBar);
    expect(r.modes[0].omega, closeTo(w1, w1 * 0.005));
    // Second mode: 4 ω1.
    expect(r.modes[1].omega, closeTo(4 * w1, 4 * w1 * 0.01));
  });

  test('two-storey shear frame: mass ratios add up to 100 %', () {
    // Rigid beams approximated by very stiff sections.
    const col = Section3D(
      name: 'C',
      area: 0.16,
      iy: 2.133e-3,
      iz: 2.133e-3,
      j: 3.6e-3,
      youngModulus: 30000,
      shearModulus: 12500,
      unitWeight: 0,
    );
    const beam = Section3D(
      name: 'R',
      area: 10,
      iy: 10,
      iz: 10,
      j: 10,
      youngModulus: 30000,
      shearModulus: 12500,
      unitWeight: 0,
    );
    final nodes = <Node3D>[];
    for (final z in [0.0, 3.0, 6.0]) {
      nodes.add(Node3D(0, 0, z));
      nodes.add(Node3D(5, 0, z));
    }
    final m = Model3D(
      nodes: nodes,
      supports: {0: Support3D.fixed, 1: Support3D.fixed},
      sections: const [col, beam],
      elements: const [
        Element3D(0, 2, 0),
        Element3D(1, 3, 0),
        Element3D(2, 4, 0),
        Element3D(3, 5, 0),
        Element3D(2, 3, 1),
        Element3D(4, 5, 1),
      ],
      cases: [
        LoadCase3D(
          name: 'M',
          nodal: [for (var i = 2; i < 6; i++) NodalLoad3D(i, fz: -100)],
        ),
      ],
    );
    final r = modalAnalysis(
      m,
      options: const ModalOptions(modes: 12, massCases: {0: 1}),
    );
    expect(r.cumulativeRatio[0], closeTo(1, 0.02));
    expect(r.cumulativeRatio[1], closeTo(1, 0.02));
    // Periods ascending.
    for (var k = 1; k < r.modes.length; k++) {
      expect(
        r.modes[k].period,
        lessThanOrEqualTo(r.modes[k - 1].period + 1e-9),
      );
    }
  });
}
