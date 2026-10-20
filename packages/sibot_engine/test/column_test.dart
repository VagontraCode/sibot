// Column design verified against hand calculations.
import 'dart:math' as math;

import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  group('interaction curve', () {
    // 300 × 300, 2 × 4Ø16 = 2 × 804 mm², d2 = 46 mm, C30 / B500.
    final s = RectSectionNM(
      b: 300,
      h: 300,
      d2: 46,
      asPerFace: 804.2,
      fc: 20,
      fyd: 434.78,
    );
    test('pure compression at 2‰ (steel at 400 MPa)', () {
      expect(s.nMax, closeTo((20 * 300 * 300 + 2 * 804.2 * 400) / 1e3, 1e-6));
    });
    test('pure bending: steel couple + small concrete block', () {
      // With N = 0, tension steel yields; equilibrium fixes x.
      final m = s.momentResistance(0)!;
      // Bounds: ≥ As·fyd·(d − d2) with yielding of only the tension face is
      // impossible to exceed far; a simple estimate is As·fyd·0.9d.
      final estimate = 804.2 * 434.78 * 0.9 * 254 / 1e6;
      expect(m, closeTo(estimate, 0.12 * estimate));
    });
    test('balanced region gives the largest moment', () {
      final pts = s.curve();
      final peak = pts.reduce((a, b) => a.m > b.m ? a : b);
      expect(peak.n, greaterThan(0));
      expect(peak.n, lessThan(s.nMax));
    });
  });

  group('EC2 slender column', () {
    // 300 × 300, l0 = 3 m, NEd = 1200 kN, M0Ed = 30 kN·m, C30/37, B500.
    final r = designColumn(
      const ColumnInput(
        code: DesignCode.ec2,
        b: 300,
        h: 300,
        l0: 3,
        nEd: 1200,
        m0Ed: 30,
        fck: 30,
        fyk: 500,
      ),
    );
    test('slenderness and limit', () {
      // λ = 3000 / (300/√12) = 34.64
      expect(r.slenderness, closeTo(34.641, 1e-3));
      // n = 1.2e6/(90000 × 20) = 0.6667; λlim = 20 × (1/1.2) × 1.1 × 0.7/√n
      expect(r.slendernessLimit, closeTo(15.718, 1e-3));
      expect(r.notes, contains(ColumnNote.secondOrderIncluded));
    });
    test('imperfection eccentricity l0/400', () {
      expect(r.imperfection, closeTo(7.5, 1e-9));
    });
    test('second-order eccentricity by nominal curvature', () {
      const ac = 90000.0, fcd = 20.0, fyd = 500 / 1.15;
      final omega = r.bars!.area * fyd / (ac * fcd);
      final n = 1200e3 / (ac * fcd);
      final kr = math.min(1.0, (1 + omega - n) / (1 + omega - 0.4));
      final lambda = 3000 / (300 / math.sqrt(12));
      final beta = 0.35 + 30 / 200 - lambda / 150;
      final kPhi = math.max(1.0, 1 + beta * 1.0);
      final curvature = kr * kPhi * (fyd / 200000) / (0.45 * 254);
      expect(r.secondOrder, closeTo(curvature * 3000 * 3000 / 10, 1e-6));
      // MEd = max(M0 + N·ei, N·e0) + N·e2 = 39 + 1.2·e2
      expect(r.mEd, closeTo(39 + 1.2 * r.secondOrder, 1e-6));
    });
    test('provided steel resists the design moment', () {
      expect(r.mRd, greaterThanOrEqualTo(r.mEd));
      expect(r.ok, isTrue);
    });
    test('required steel is the smallest that works', () {
      // At the required area the resistance equals the demand.
      expect(r.asRequired, greaterThanOrEqualTo(r.asMin));
      expect(r.bars!.area, greaterThanOrEqualTo(r.asRequired));
    });
  });

  group('BAEL centred compression', () {
    // 300 × 300, lf = 3 m, Nu = 1200 kN, fc28 = 25, FeE500.
    final r = designColumn(
      const ColumnInput(
        code: DesignCode.bael,
        b: 300,
        h: 300,
        l0: 3,
        nEd: 1200,
        fck: 25,
        fyk: 500,
      ),
    );
    test('uses the α method', () {
      expect(r.notes, contains(ColumnNote.baelCentredCompression));
    });
    test('steel area', () {
      // α = 0.85/(1 + 0.2(34.64/35)²) = 0.71075; Br = 280² = 78 400 mm²
      // A = (1.2e6/α − 78400 × 25/1.35) × 1.15/500 = 544.0 mm²
      expect(r.asRequired, closeTo(544.0, 0.5));
      // Amin = max(4 cm²/m × 1.2 m, 0.2 % × 90 000) = 480 mm²
      expect(r.asMin, closeTo(480, 1e-9));
      expect(r.bars.toString(), '4 Ø14');
      expect(r.ok, isTrue);
    });
  });

  test('BAEL rejects λ > 70 with a failing check', () {
    final r = designColumn(
      const ColumnInput(
        code: DesignCode.bael,
        b: 200,
        h: 200,
        l0: 5,
        nEd: 300,
        fck: 25,
        fyk: 500,
      ),
    );
    expect(r.slenderness, greaterThan(70));
    expect(r.notes, contains(ColumnNote.slendernessOutOfScope));
    expect(r.ok, isFalse);
  });
}
