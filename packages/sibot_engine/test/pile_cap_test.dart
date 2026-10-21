// Strut-and-tie pile caps against hand calculations.
import 'dart:math' as math;

import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  test('2-pile cap: θ, tie force and node stresses', () {
    // e = 1.5 m, D = 500, a = 400, h = 900, cover 50 → d = 838 mm.
    // Plan 2.3 × 0.8 m: G = 25 × 2.3 × 0.8 × 0.9 = 41.4 kN.
    // R = (1500 + 1.35 × 41.4) / 2 = 777.9 kN; l = 750 − 100 = 650 mm.
    // θ = atan(838/650) = 52.2°; T = R l / d = 603.4 kN;
    // As = 603.4e3 / 434.8 = 1388 mm².
    final r = designPileCap(
      const PileCapInput(
        nEd: 1500,
        piles: 2,
        spacing: 1.5,
        pileDiameter: 500,
        column: 400,
        h: 900,
        fck: 30,
      ),
    );
    expect(r.d, 838);
    expect(r.selfWeight, closeTo(41.4, 1e-9));
    expect(r.reaction, closeTo(777.9, 0.05));
    expect(r.theta, closeTo(52.2, 0.1));
    expect(r.tieForce, closeTo(603.4, 0.3));
    expect(r.asTie, closeTo(1387.8, 1));
    // σ column = 1.5e6 / (400² × sin²θ) = 15.02 MPa ≤ 0.88 × 20 = 17.6.
    expect(r.sigmaColumn, closeTo(15.02, 0.05));
    expect(r.limitColumn, closeTo(17.6, 1e-9));
    expect(r.ok, isTrue);
  });

  test('4-pile cap: side tie = N (2e − a) / (16 d) without self-weight', () {
    final r = designPileCap(
      const PileCapInput(
        nEd: 3000,
        piles: 4,
        spacing: 1.6,
        pileDiameter: 500,
        column: 500,
        h: 1100,
        edge: 0,
        cover: 50,
      ),
    );
    final d = r.d;
    final nTotal = r.reaction * 4;
    expect(r.tieForce, closeTo(nTotal * (2 * 1600 - 500) / (16 * d), 1e-6));
    expect(r.ties, 4);
  });

  test('3-pile cap: tie = R (e/√3 − 0.3a) / (√3 d)', () {
    final r = designPileCap(
      const PileCapInput(
        nEd: 2000,
        piles: 3,
        spacing: 1.5,
        pileDiameter: 400,
        column: 400,
        h: 900,
      ),
    );
    final l = 1500 / math.sqrt(3) - 120;
    expect(r.tieForce, closeTo(r.reaction * l / (math.sqrt(3) * r.d), 1e-6));
    expect(r.ties, 3);
  });

  test('shallow cap fails the strut angle and suggests a depth range', () {
    final r = designPileCap(
      const PileCapInput(
        nEd: 1500,
        piles: 2,
        spacing: 1.5,
        pileDiameter: 500,
        column: 400,
        h: 600,
      ),
    );
    expect(r.theta, lessThan(45));
    expect(r.ok, isFalse);
    expect(r.hMin, closeTo(650 + 62, 1e-9));
    expect(r.hMax, greaterThan(r.hMin));
  });

  test('piles closer than two diameters are rejected', () {
    expect(
      () => designPileCap(
        const PileCapInput(
          nEd: 1000,
          piles: 2,
          spacing: 0.9,
          pileDiameter: 500,
          column: 300,
          h: 800,
        ),
      ),
      throwsA(isA<InputError>()),
    );
  });
}
