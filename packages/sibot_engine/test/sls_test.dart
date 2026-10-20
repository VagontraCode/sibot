// Serviceability: cracked section, stress limits and crack width.
import 'dart:math' as math;

import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  group('cracked section', () {
    final cs = crackedSection(b: 300, d: 554, as: 1206.4, n: 15);
    test('neutral axis balances first moments', () {
      // b·x²/2 = n·As·(d − x)
      expect(300 * cs.x * cs.x / 2, closeTo(15 * 1206.4 * (554 - cs.x), 1e-3));
    });
    test('stresses follow σ = M·y/I', () {
      final m = 150.0;
      expect(cs.concreteStress(m), closeTo(m * 1e6 * cs.x / cs.inertia, 1e-9));
      expect(
        cs.steelStress(m),
        closeTo(15 * m * 1e6 * (554 - cs.x) / cs.inertia, 1e-9),
      );
    });
    test('compression steel raises the neutral axis less than it stiffens', () {
      final withTop = crackedSection(
        b: 300,
        d: 554,
        as: 1206.4,
        n: 15,
        as2: 402,
        d2: 44,
      );
      expect(withTop.x, lessThan(cs.x));
      expect(withTop.inertia, greaterThan(cs.inertia * 0.95));
    });
  });

  group('BAEL steel stress limits (FeE500, fc28 = 25)', () {
    // ft28 = 2.1; 110·√(1.6 × 2.1) = 201.6 → max(250, 201.6) = 250
    test('fissuration préjudiciable', () {
      expect(
        baelSteelStressLimit(BaelCracking.harmful, 500, 2.1),
        closeTo(250, 1e-9),
      );
    });
    test('fissuration très préjudiciable', () {
      expect(
        baelSteelStressLimit(BaelCracking.veryHarmful, 500, 2.1),
        closeTo(200, 1e-9),
      );
    });
    test('fissuration peu préjudiciable has no limit', () {
      expect(baelSteelStressLimit(BaelCracking.slight, 500, 2.1), isNull);
    });
  });

  group('EC2 beam crack width', () {
    // Beam of beam_test.dart: 300 × 600, 6Ø16, G = 24.5, Q = 15, ψ2 = 0.3.
    final r = designBeam(
      const BeamInput(
        code: DesignCode.ec2,
        span: 6,
        b: 300,
        h: 600,
        g: 20,
        q: 15,
        fck: 30,
        fyk: 500,
      ),
    );
    final s = r.sls!;
    test('quasi-permanent and characteristic moments', () {
      expect(s.mQp, closeTo((24.5 + 0.3 * 15) * 36 / 8, 1e-9));
      expect(s.mChar, closeTo((24.5 + 15) * 36 / 8, 1e-9));
    });
    test('crack width from eq. 7.8 – 7.11', () {
      final c = Concrete(DesignCode.ec2, 30);
      final sigma = s.section.steelStress(s.mQp);
      final x = s.section.x;
      final hc = math.min(2.5 * (600 - 554), math.min((600 - x) / 3, 300.0));
      final rho = r.tensionBars!.area / (300 * hc);
      final ae = 200000 / c.ecm;
      final strain = math.max(
        (sigma - 0.4 * c.fctm / rho * (1 + ae * rho)) / 200000,
        0.6 * sigma / 200000,
      );
      final sr = 3.4 * 38 + 0.425 * 0.8 * 0.5 * 16 / rho;
      expect(s.crack!.wk, closeTo(sr * strain, 1e-9));
      expect(s.crack!.wk, lessThan(0.3));
    });
  });

  test('BAEL harmful cracking adds a steel stress check', () {
    final r = designBeam(
      const BeamInput(
        code: DesignCode.bael,
        span: 6,
        b: 300,
        h: 600,
        g: 20,
        q: 15,
        fck: 25,
        fyk: 500,
        baelCracking: BaelCracking.harmful,
      ),
    );
    final c = r.checks.firstWhere((c) => c.kind == CheckKind.steelStress);
    expect(c.capacity, closeTo(250, 1e-9));
    expect(c.demand, closeTo(r.sls!.sigmaS, 1e-9));
  });
}
