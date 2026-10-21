// Rigid floor diaphragms, accidental torsion and the combination of
// directions, against closed-form results.
import 'dart:math' as math;

import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  // Four cantilever columns (no beams) tied by a rigid floor at the top:
  // at (±a, ±b), height L.
  const a = 3.0, b = 2.0, l = 3.5;
  const iy = 4e-4, iz = 2e-4, jt = 1e-4;
  const e = 30000e3, g = 12500e3;
  const sec = Section3D(
    name: 'C',
    area: 0.1,
    iy: iy,
    iz: iz,
    j: jt,
    youngModulus: 30000,
    shearModulus: 12500,
    unitWeight: 0,
  );
  const corners = [(-a, -b), (a, -b), (a, b), (-a, b)];

  Model3D floor({List<NodalLoad3D> loads = const []}) => Model3D(
    nodes: [
      for (final (x, y) in corners) Node3D(x, y, 0),
      for (final (x, y) in corners) Node3D(x, y, l),
    ],
    supports: {for (var i = 0; i < 4; i++) i: Support3D.fixed},
    sections: const [sec],
    elements: [for (var i = 0; i < 4; i++) Element3D(i, i + 4, 0)],
    cases: [
      LoadCase3D(name: 'L', nodal: loads),
      LoadCase3D(
        name: 'M',
        nodal: [for (var i = 4; i < 8; i++) NodalLoad3D(i, fz: -98.1)],
      ),
    ],
    diaphragms: const [
      [4, 5, 6, 7],
    ],
  );

  // Vertical columns: local z = global X, so X sway uses Iy, Y sway Iz.
  const kx = 3 * e * iy / (l * l * l), ky = 3 * e * iz / (l * l * l);
  const kTheta = 4 * (kx * b * b + ky * a * a) + 4 * g * jt / l;

  test('lateral load at one corner: equal X sway of all columns', () {
    // Load on the axis of symmetry would not twist; at a corner the floor
    // also rotates, but the X translation of the centre is F / 4kx.
    final r = Frame3DAnalysis(
      floor(loads: [const NodalLoad3D(4, fx: 40)]),
    ).solveCase(0);
    final mean =
        [
          for (var i = 4; i < 8; i++) r.displacements[i][0],
        ].reduce((p, q) => p + q) /
        4;
    expect(mean, closeTo(40 / (4 * kx), 1e-12));
    // Rotation from the eccentricity b: Mz = −F·(−b)… = F·b about Z.
    expect(r.displacements[4][5], closeTo(40 * b / kTheta, 1e-12));
    // All floor nodes share the rotation.
    for (var i = 5; i < 8; i++) {
      expect(r.displacements[i][5], closeTo(r.displacements[4][5], 1e-15));
    }
  });

  test('torque on the floor: rz = Mz / Σ(k r²) + column torsion', () {
    final r = Frame3DAnalysis(
      floor(loads: [const NodalLoad3D(6, mz: 100)]),
    ).solveCase(0);
    expect(r.displacements[5][5], closeTo(100 / kTheta, 1e-12));
    // Corner node (a, b) moves by rz × (−b, a).
    expect(r.displacements[6][0], closeTo(-b * 100 / kTheta, 1e-12));
    expect(r.displacements[6][1], closeTo(a * 100 / kTheta, 1e-12));
  });

  test('modes of a rigid floor on four columns', () {
    final modal = modalAnalysis(
      floor(),
      options: const ModalOptions(modes: 3, massCases: {1: 1}),
    );
    const m = 10.0; // t per corner
    final wY = math.sqrt(4 * ky / (4 * m));
    final wX = math.sqrt(4 * kx / (4 * m));
    final wT = math.sqrt(kTheta / (4 * m * (a * a + b * b)));
    final omegas = modal.modes.map((x) => x.omega).toList()..sort();
    final expected = [wY, wX, wT]..sort();
    for (var k = 0; k < 3; k++) {
      expect(omegas[k], closeTo(expected[k], expected[k] * 1e-6));
    }
    expect(modal.totalMass[0], closeTo(40, 1e-9));
    expect(modal.cumulativeRatio[0], closeTo(1, 1e-6));
  });

  test('accidental torsion: Ma = 0.05 L⊥ Fb on a single floor', () {
    final modal = modalAnalysis(
      floor(),
      options: const ModalOptions(modes: 3, massCases: {1: 1}),
    );
    final params = spectrumParams(GroundType.b, type1: false);
    final plain = responseSpectrum(
      modal,
      direction: 0,
      ag: 1.6,
      spectrum: params,
      q: 1.5,
    );
    final withTorsion = responseSpectrum(
      modal,
      direction: 0,
      ag: 1.6,
      spectrum: params,
      q: 1.5,
      accidentalTorsion: true,
    );
    // L⊥ for X excitation is the Y extent 2b.
    expect(
      withTorsion.torsionMoments.single,
      closeTo(0.05 * 2 * b * plain.baseShear, 1e-9),
    );
    // Torsion adds to the Y displacement of the corners.
    expect(
      withTorsion.combined.displacements[6][1],
      greaterThan(plain.combined.displacements[6][1]),
    );
  });

  test('EX + 0.3 EY: larger of the two directional sums', () {
    final r = Frame3DAnalysis(
      floor(loads: [const NodalLoad3D(4, fx: 10, fy: 5)]),
    ).solveCase(0);
    final ex = r.scaled(1), ey = r.scaled(2);
    final c = combineDirections(ex, ey);
    final ux = r.displacements[4][0].abs();
    expect(c.displacements[4][0], closeTo(math.max(1.6 * ux, 2.3 * ux), 1e-15));
  });

  test('generated buildings get one diaphragm per floor', () {
    final m = buildingFrame(
      BuildingParams(
        spansX: const [5, 5],
        spansY: const [4],
        storeyHeights: const [3, 3],
        column: Section3D.rectangle(300, 300),
        beam: Section3D.rectangle(250, 500),
      ),
    );
    expect(m.diaphragms, hasLength(2));
    expect(m.diaphragms.first, hasLength(6));
    // Rigid floors stiffen the frame laterally.
    final free = buildingFrame(
      BuildingParams(
        spansX: const [5, 5],
        spansY: const [4],
        storeyHeights: const [3, 3],
        column: Section3D.rectangle(300, 300),
        beam: Section3D.rectangle(250, 500),
        rigidFloors: false,
      ),
    );
    final t1 = modalAnalysis(
      m,
      options: const ModalOptions(modes: 1),
    ).modes[0].period;
    final t2 = modalAnalysis(
      free,
      options: const ModalOptions(modes: 1),
    ).modes[0].period;
    expect(t1, lessThanOrEqualTo(t2 * 1.0001));
  });
}
