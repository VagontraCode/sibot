// Strip and combined footings, EC7 bearing resistance.
import 'dart:math' as math;

import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  group('EN 1997-1 Annex D', () {
    test('bearing factors at φ′ = 30°', () {
      final f = bearingFactors(30);
      expect(f.nq, closeTo(18.40, 0.01));
      expect(f.nc, closeTo(30.14, 0.01));
      expect(f.ngamma, closeTo(20.09, 0.01));
    });
    test('undrained factor π + 2', () {
      expect(bearingFactors(0).nc, closeTo(math.pi + 2, 1e-12));
    });
    test('drained strip, c′ = 0', () {
      // q = 18 × 1 = 18 kPa; 18 × 18.40 + 0.5 × 18 × 1.5 × 20.09 = 602.4
      final q = ultimateBearingPressure(
        const Soil(phi: 30, gamma: 18),
        bEff: 1.5,
        lEff: 1e6,
        depth: 1,
      );
      expect(q, closeTo(602.4, 0.3));
    });
    test('undrained square footing', () {
      // (π + 2) × 50 × 1.2 + 18 = 326.5 kPa
      final q = ultimateBearingPressure(
        const Soil(gamma: 18, cu: 50),
        bEff: 2,
        lEff: 2,
        depth: 1,
      );
      expect(q, closeTo((math.pi + 2) * 50 * 1.2 + 18, 1e-9));
    });
  });

  group('strip footing (BAEL)', () {
    // Wall 200 mm, G = 150, Q = 50 kN/m, q_adm = 200 kPa, D = 1 m.
    // h = 300: 20.1 kPa own weight → B ≥ 200/179.9 = 1.112 → 1.15 m
    // d ≥ (1150 − 200)/4 = 237.5 → h = 300, d = 244
    final r = designStripFooting(
      const StripFootingInput(
        code: DesignCode.bael,
        wall: 200,
        g: 150,
        q: 50,
        qAllowable: 200,
        fck: 25,
        fyk: 500,
      ),
    );
    test('width and thickness', () {
      expect(r.width, closeTo(1.15, 1e-9));
      expect(r.h, 300);
      expect(r.d, 244);
    });
    test('pressure', () {
      expect(r.pressure, closeTo((200 + 1.15 * 20.1) / 1.15, 1e-6));
    });
    test('transverse steel by struts and ties', () {
      // Nu = 277.5 kN/m → 277.5e3 × 950/(8 × 244 × 434.78) = 310.6 mm²/m
      expect(r.asMain, closeTo(310.6, 0.2));
      expect(r.asDistribution, closeTo(r.asMain / 4, 1e-9));
      expect(r.ok, isTrue);
    });
  });

  test('strip footing with soil parameters (EC7 DA2)', () {
    final r = designStripFooting(
      const StripFootingInput(
        code: DesignCode.ec2,
        wall: 200,
        g: 150,
        q: 50,
        soil: Soil(phi: 30, gamma: 18),
        fck: 25,
        fyk: 500,
      ),
    );
    expect(r.pressure, lessThanOrEqualTo(r.bearingLimit));
    expect(r.ok, isTrue, reason: r.checks.join('\n'));
  });

  group('combined footing, two equal columns', () {
    // 400 × 400 columns 4 m apart, G = 600, Q = 200 each.
    // Resultant at 2 m → L = 2 × (2 + 0.5) = 5 m, overhang 0.5 m.
    // ULS: P = 1110 kN each, q = 2220/5 = 444 kN/m.
    final r = designCombinedFooting(
      const CombinedFootingInput(
        code: DesignCode.ec2,
        a1: 400,
        b1: 400,
        a2: 400,
        b2: 400,
        spacing: 4,
        g1: 600,
        q1: 200,
        g2: 600,
        q2: 200,
        qAllowable: 200,
        fck: 30,
        fyk: 500,
      ),
    );
    test('length and overhang', () {
      expect(r.length, closeTo(5.0, 1e-9));
      expect(r.overhang1, closeTo(0.5, 1e-9));
    });
    test('moments', () {
      // Under a column: 444 × 0.5²/2 = 55.5 kN·m (bottom tension)
      // Mid-span: 444 × 2.5²/2 − 1110 × 2 = −832.5 kN·m (top tension)
      expect(r.mBottom, closeTo(55.5, 0.1));
      expect(r.mTop, closeTo(832.5, 0.1));
    });
    test('diagram closes at both ends', () {
      expect(r.diagram.first.m, closeTo(0, 1e-9));
      expect(r.diagram.last.m, closeTo(0, 1e-6));
      expect(r.diagram.last.v, closeTo(0, 1e-6));
    });
    test('all checks pass after thickening', () {
      expect(r.ok, isTrue, reason: r.checks.join('\n'));
    });
  });

  test('unequal columns put the resultant at mid-length', () {
    final r = designCombinedFooting(
      const CombinedFootingInput(
        code: DesignCode.bael,
        a1: 300,
        b1: 300,
        a2: 400,
        b2: 400,
        spacing: 3.5,
        g1: 300,
        q1: 100,
        g2: 600,
        q2: 250,
        qAllowable: 250,
        fck: 25,
        fyk: 500,
      ),
    );
    final xBar = 850 * 3.5 / 1250;
    expect(r.overhang1 + xBar, closeTo(r.length / 2, 1e-9));
    expect(r.ok, isTrue, reason: r.checks.join('\n'));
  });
}
