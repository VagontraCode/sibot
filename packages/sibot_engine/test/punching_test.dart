// Punching shear verified against hand calculations.
import 'dart:math' as math;

import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  group('EC2 interior column', () {
    // 400 × 400 column, VEd = 600 kN, d = 200 mm, ρ = 0.8 %, C30, β = 1.15
    final p = designPunching(
      code: DesignCode.ec2,
      c1: 400,
      c2: 400,
      vEd: 600,
      d: 200,
      h: 240,
      rhoL: 0.008,
      fck: 30,
      fyk: 500,
    );
    test('control perimeter and stress', () {
      // u1 = 1600 + 4π·200 = 4113.3 mm; vEd = 1.15 × 600e3/(4113.3 × 200)
      expect(p.u1, closeTo(1600 + 800 * math.pi, 1e-9));
      expect(p.demand, closeTo(1.15 * 600e3 / (p.u1 * 200), 1e-12));
    });
    test('concrete resistance', () {
      // k = 2.0; vRd,c = 0.12 × 2 × (100 × 0.008 × 30)^(1/3) = 0.6935 MPa
      expect(p.resistance, closeTo(0.12 * 2 * math.pow(24, 1 / 3), 1e-12));
    });
    test('reinforcement when vEd > vRd,c', () {
      // vEd = 0.8387 > 0.6935 → Asw = (vEd − 0.75 vRd,c)·u1/(1.5·fywd,ef)
      // fywd,ef = min(250 + 50, 434.8) = 300 MPa
      expect(p.needsReinforcement, isTrue);
      final expected = (p.demand - 0.75 * p.resistance) * p.u1 / (1.5 * 300);
      expect(p.aswPerPerimeter, closeTo(expected, 1e-9));
    });
    test('face stress below vRd,max = 0.4·ν·fcd', () {
      expect(p.faceLimit, closeTo(0.4 * 0.6 * (1 - 30 / 250) * 20, 1e-12));
      expect(p.checks.every((c) => c.ok), isTrue);
    });
  });

  test('BAEL A.5.2.42', () {
    // uc = 2(400 + 400 + 2 × 240) = 2560 mm
    // Qu,lim = 0.045 × 2560 × 240 × 25/1.5 = 460.8 kN < 600 kN
    final p = designPunching(
      code: DesignCode.bael,
      c1: 400,
      c2: 400,
      vEd: 600,
      d: 200,
      h: 240,
      rhoL: 0.008,
      fck: 25,
      fyk: 500,
    );
    expect(p.u1, 2560);
    expect(p.resistance, closeTo(460.8, 1e-9));
    expect(p.checks.single.ok, isFalse);
  });

  test('slab carries the punching check when a load is given', () {
    final r = designSlab(
      const SlabInput(
        code: DesignCode.ec2,
        lx: 5,
        ly: 6,
        h: 220,
        g: 2,
        q: 3,
        fck: 30,
        fyk: 500,
        punchLoad: 150,
        punchBeta: 1.0,
      ),
    );
    expect(r.punching, isNotNull);
    expect(r.checks.where((c) => c.kind == CheckKind.punching), isNotEmpty);
  });
}
