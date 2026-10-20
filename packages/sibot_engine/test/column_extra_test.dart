// Biaxial bending and circular columns.
import 'dart:math' as math;

import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  group('circle geometry', () {
    const c = CircleShape(400);
    test('half-depth segment is a half disc', () {
      final (a, y) = c.compressed(200);
      expect(a, closeTo(math.pi * 200 * 200 / 2, 1e-6));
      // Centroid of a half disc: 4R/(3π) from the diameter.
      expect(y, closeTo(200 - 4 * 200 / (3 * math.pi), 1e-9));
    });
    test('full depth', () {
      final (a, y) = c.compressed(400);
      expect(a, closeTo(c.area, 1e-9));
      expect(y, 200);
    });
  });

  test('biaxial exponent of EN 1992-1-1 5.8.9(4)', () {
    expect(biaxialExponent(0.05), 1.0);
    expect(biaxialExponent(0.1), 1.0);
    expect(biaxialExponent(0.4), closeTo(1.25, 1e-12));
    expect(biaxialExponent(0.7), closeTo(1.5, 1e-12));
    expect(biaxialExponent(1.0), closeTo(2.0, 1e-12));
  });

  group('rectangular column, moments in both directions', () {
    ColumnDesign run({double mh = 0, double mb = 0}) => designColumn(
      ColumnInput(
        code: DesignCode.ec2,
        b: 400,
        h: 400,
        l0: 3,
        nEd: 1500,
        m0Ed: mh,
        m0EdB: mb,
        fck: 30,
        fyk: 500,
      ),
    );

    test('a square column is symmetric', () {
      expect(run(mh: 150).asRequired, closeTo(run(mb: 150).asRequired, 1));
      expect(run(mh: 150).asRequired, greaterThan(run(mh: 150).asMin));
    });
    test('adding a second moment needs more steel', () {
      final uni = run(mh: 150);
      final bi = run(mh: 150, mb: 150);
      expect(bi.notes, contains(ColumnNote.biaxial));
      expect(bi.asRequired, greaterThan(uni.asRequired));
      expect(bi.ok, isTrue, reason: bi.checks.join('\n'));
      final biaxial = bi.checks.firstWhere((c) => c.clause.contains('5.8.9'));
      expect(biaxial.demand, lessThanOrEqualTo(1));
    });
    test('both directions report resistances', () {
      final r = run(mh: 60, mb: 30);
      expect(r.dirB, isNotNull);
      expect(r.dirH.mRd, greaterThanOrEqualTo(r.dirH.mEd));
      expect(r.dirB!.mRd, greaterThanOrEqualTo(r.dirB!.mEd));
    });
  });

  group('circular column', () {
    ColumnDesign run(DesignCode code, {double mh = 0, double mb = 0}) =>
        designColumn(
          ColumnInput(
            code: code,
            shape: ColumnShape.circular,
            b: 400,
            l0: 3,
            nEd: 1500,
            m0Ed: mh,
            m0EdB: mb,
            fck: code == DesignCode.ec2 ? 30 : 25,
            fyk: 500,
          ),
        );

    test('slenderness uses i = D/4', () {
      expect(run(DesignCode.ec2, mh: 40).slenderness, closeTo(30, 1e-9));
    });
    test('moments combine vectorially', () {
      final a = run(DesignCode.ec2, mh: 30, mb: 40);
      final b = run(DesignCode.ec2, mh: 50);
      expect(a.asRequired, closeTo(b.asRequired, 1e-6));
    });
    test('at least six bars and the moment is resisted', () {
      final r = run(DesignCode.ec2, mh: 60);
      expect(r.bars!.count, greaterThanOrEqualTo(6));
      expect(r.mRd, greaterThanOrEqualTo(r.mEd));
      expect(r.ok, isTrue);
    });
    test('BAEL centred compression on a circle', () {
      // λ = 30, α = 0.85/(1 + 0.2(30/35)²) = 0.74111
      // Br = π·380²/4; concrete alone carries Nu/α → minimum steel governs:
      // Amin = max(4 cm²/m × π × 0.4 m, 0.2 % B) = 502.7 mm²
      final r = run(DesignCode.bael);
      expect(r.centred, isTrue);
      expect(r.asRequired, closeTo(400 * math.pi * 0.4, 1e-6));
      expect(r.bars.toString(), '6 Ø12');
    });
  });
}
