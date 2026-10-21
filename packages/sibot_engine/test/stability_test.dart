// Linear buckling and P-Δ against Euler loads.
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
    youngModulus: 210000,
    shearModulus: 81000,
    unitWeight: 0,
  );
  const ei = 210000e3 * 5e-5; // minor axis governs
  const l = 5.0, segments = 8;

  Model3D column({
    required Support3D base,
    required Support3D top,
    double p = 100,
    double h = 0,
  }) => Model3D(
    nodes: [for (var i = 0; i <= segments; i++) Node3D(0, 0, l * i / segments)],
    supports: {0: base, if (top.dofs.any((d) => d)) segments: top},
    sections: const [sec],
    elements: [for (var i = 0; i < segments; i++) Element3D(i, i + 1, 0)],
    cases: [
      LoadCase3D(
        name: 'P',
        nodal: [NodalLoad3D(segments, fz: -p, fy: h)],
      ),
    ],
  );

  test('cantilever column: αcr = π²EI / (4L² P)', () {
    final m = column(base: Support3D.fixed, top: const Support3D());
    final (alpha, shape) = Frame3DAnalysis(m).bucklingFactor(0)!;
    final euler = math.pi * math.pi * ei / (4 * l * l) / 100;
    expect(alpha, closeTo(euler, euler * 0.002));
    expect(shape.last[1].abs(), closeTo(1, 1e-6)); // sways in Y (minor axis)
  });

  test('pinned-pinned column: αcr = π²EI / (L² P)', () {
    final m = column(
      base: const Support3D(ux: true, uy: true, uz: true, rz: true),
      top: const Support3D(ux: true, uy: true),
    );
    final (alpha, _) = Frame3DAnalysis(m).bucklingFactor(0)!;
    final euler = math.pi * math.pi * ei / (l * l) / 100;
    expect(alpha, closeTo(euler, euler * 0.002));
  });

  test('tension only: no buckling factor', () {
    final m = column(base: Support3D.fixed, top: const Support3D(), p: -100);
    expect(Frame3DAnalysis(m).bucklingFactor(0), isNull);
  });

  test('P-Δ amplifies the sway by about 1 / (1 − P/Pcr)', () {
    // Cantilever, P = 40 % of Pcr, lateral load H at the top.
    final pcr = math.pi * math.pi * ei / (4 * l * l);
    final m = column(
      base: Support3D.fixed,
      top: const Support3D(),
      p: 0.4 * pcr,
      h: 5,
    );
    final an = Frame3DAnalysis(m);
    final first = an.solveCase(0).displacements[segments][1];
    final second = an.pDeltaCase(0).displacements[segments][1];
    final amplification = second / first;
    // The amplification estimate 1 / (1 − P/Pcr) gives 1.667 at 0.4 Pcr;
    // the exact cantilever value is within a few per cent of it.
    expect(amplification, closeTo(1 / (1 - 0.4), 0.05));
    // Base moment grows from H L to H L + P δ.
    final base = an.pDeltaCase(0).reactions[0]!;
    expect(base[3].abs(), closeTo(5 * l + 0.4 * pcr * second, 0.05 * 5 * l));
  });
}
