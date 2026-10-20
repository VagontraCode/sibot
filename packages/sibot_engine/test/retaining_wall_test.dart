// Cantilever wall verified against a hand calculation.
//
// Stem 3.0 m, base 0.4 m, toe 0.6, heel 1.2, stem 0.2 → 0.3 m (B = 2.1 m).
// γ = 18, φ = 30° (Ka = 1/3), q = 10 kPa, δ = 20°.
//   Pa = ½ × ⅓ × 18 × 3.4² = 34.68 kN/m;  Pq = ⅓ × 10 × 3.4 = 11.333
//   Mo = 34.68 × 3.4/3 + 11.333 × 1.7 = 58.571 kN·m/m
//   Weights: stem 15 @ 0.8, batter 3.75 @ 0.6667, base 21 @ 1.05,
//            soil 64.8 @ 1.5 → V = 104.55, Mr = 133.75
import 'dart:math' as math;

import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

const _wall = WallInput(
  code: DesignCode.bael,
  stemHeight: 3,
  baseThickness: 0.4,
  toe: 0.6,
  heel: 1.2,
  stemTop: 0.2,
  stemBottom: 0.3,
  phi: 30,
  surcharge: 10,
  qAllowable: 200,
  fck: 25,
  fyk: 500,
);

void main() {
  final r = designWall(_wall);

  test('Rankine coefficient and thrusts', () {
    expect(r.ka, closeTo(1 / 3, 1e-12));
    expect(r.thrustSoil, closeTo(34.68, 1e-9));
    expect(r.thrustSurcharge, closeTo(11.3333, 1e-4));
    expect(r.overturningMoment, closeTo(58.5707, 1e-3));
  });

  test('weights and resisting moment', () {
    expect(r.vertical, closeTo(104.55, 1e-9));
    expect(r.resistingMoment, closeTo(133.75, 1e-9));
  });

  test('overturning passes, sliding needs a shear key', () {
    expect(r.fsOverturning, closeTo(2.2836, 1e-4));
    // 104.55 × tan 20° / 46.013 = 0.827
    expect(
      r.fsSliding,
      closeTo(104.55 * math.tan(20 * math.pi / 180) / 46.0133, 1e-4),
    );
    expect(r.checks.firstWhere((c) => c.kind == CheckKind.sliding).ok, isFalse);
  });

  test('bearing pressure at 3/4 width (BAEL)', () {
    // V' = 116.55, x = (151.75 − 58.571)/116.55 = 0.79947, e = 0.25053
    expect(r.eccentricity, closeTo(0.25053, 1e-4));
    expect(r.pressure, closeTo(116.55 / 2.1 * (1 + 3 * 0.25053 / 2.1), 0.02));
  });

  test('stem moment at ULS', () {
    // 1.35 × ⅓ × 18 × 27/6 + 1.5 × ⅓ × 10 × 9/2 = 36.45 + 22.5
    expect(r.stemMoment, closeTo(58.95, 1e-9));
  });

  test('pre-design lengthens the heel until the wall is stable', () {
    final p = presizeWall(_wall);
    expect(p.stemBottom, greaterThanOrEqualTo(p.stemTop));
    expect(p.baseWidth, lessThanOrEqualTo(1.2 * p.totalHeight + 1e-9));
    final d = designWall(p);
    expect(d.fsOverturning, greaterThanOrEqualTo(1.5));
    expect(d.fsSliding, greaterThanOrEqualTo(1.5));
    expect(d.eccentricity.abs(), lessThanOrEqualTo(p.baseWidth / 6));
    // The heel is the shortest (50 mm steps) that satisfies sliding.
    final shorter = WallInput(
      code: p.code,
      stemHeight: p.stemHeight,
      baseThickness: p.baseThickness,
      toe: p.toe,
      heel: p.heel - 0.05,
      stemTop: p.stemTop,
      stemBottom: p.stemBottom,
      phi: p.phi,
      surcharge: p.surcharge,
      qAllowable: p.qAllowable,
      fck: p.fck,
      fyk: p.fyk,
    );
    expect(designWall(shorter).ok, isFalse);
  });

  group('toe and heel at ULS', () {
    test('toe moment matches the trapezoid closed form', () {
      // Linear pressure from σ0 (toe end) to σt (stem face), minus the
      // factored base weight 1.35 × 25 × 0.4 = 13.5 kPa.
      final b = _wall.baseWidth;
      final s0 = r.ulsPressureToe;
      final st = s0 + (r.ulsPressureHeel - s0) * _wall.toe / b;
      const t = 0.6;
      final expected = t * t / 6 * (2 * s0 + st) - 13.5 * t * t / 2;
      expect(r.toeMoment, closeTo(expected, 1e-3));
    });
    test('heel is loaded downwards', () {
      expect(r.heelMoment, greaterThan(0));
      expect(r.heelBars, isNotNull);
    });
    test('ULS pressures balance the factored vertical load', () {
      // Mean of the end pressures × B = Vu (pressure within the kern).
      final vu = 1.35 * r.vertical + 1.5 * 10 * 1.2;
      expect(
        (r.ulsPressureToe + r.ulsPressureHeel) / 2 * _wall.baseWidth,
        closeTo(vu, 1e-9),
      );
    });
  });

  group('EC7 stability (EC2 code)', () {
    final e = designWall(
      const WallInput(
        code: DesignCode.ec2,
        stemHeight: 3,
        baseThickness: 0.4,
        toe: 0.6,
        heel: 1.2,
        stemTop: 0.2,
        stemBottom: 0.3,
        phi: 30,
        surcharge: 10,
        qAllowable: 200,
        fck: 25,
        fyk: 500,
      ),
    );
    test('EQU overturning with φ′ reduced by 1.25', () {
      final phiD = math.atan(math.tan(30 * math.pi / 180) / 1.25);
      final kaD = math.pow(math.tan(math.pi / 4 - phiD / 2), 2);
      final dst =
          1.1 * 0.5 * kaD * 18 * math.pow(3.4, 3) / 3 +
          1.5 * kaD * 10 * 3.4 * 3.4 / 2;
      expect(e.equDestabilising, closeTo(dst, 1e-9));
      expect(e.equStabilising, closeTo(0.9 * 133.75, 1e-9));
    });
    test('DA2 sliding', () {
      expect(e.slidingAction, closeTo(1.35 * 34.68 + 1.5 * 11.3333, 1e-3));
      expect(
        e.slidingResistance,
        closeTo(104.55 * math.tan(20 * math.pi / 180) / 1.1, 1e-9),
      );
    });
  });
}
