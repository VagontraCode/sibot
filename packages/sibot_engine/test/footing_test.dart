// Pad footing verified against hand calculations.
//
// Column 300 × 300, G = 400 kN, Q = 150 kN, q_adm = 200 kPa, depth 1.0 m,
// γ soil = 18 kN/m³. With h = 450 mm the footing + backfill weigh
// 0.45 × 25 + 0.55 × 18 = 21.15 kPa, so A² ≥ 550/(200 − 21.15) → A = 1.80 m
// (steps of 50 mm) and d ≥ (1800 − 300)/4 = 375 → h = 450 mm, d = 394 mm.
import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

FootingInput _input(DesignCode code) => FootingInput(
  code: code,
  a: 300,
  b: 300,
  g: 400,
  q: 150,
  qAllowable: 200,
  fck: 25,
  fyk: 500,
);

void main() {
  group('BAEL footing (méthode des bielles)', () {
    final r = designFooting(_input(DesignCode.bael));
    test('size and thickness', () {
      expect(r.lengthA, closeTo(1.80, 1e-9));
      expect(r.widthB, closeTo(1.80, 1e-9));
      expect(r.h, 450);
      expect(r.d, 394);
    });
    test('bearing pressure', () {
      // (550 + 3.24 × 21.15) / 3.24 = 190.9 kPa
      expect(r.pressure, closeTo(190.9, 0.05));
    });
    test('steel by struts and ties', () {
      // Nu = 765 kN; Ax = 765e3 × 1500 / (8 × 394 × 434.78) = 837.3 mm²
      expect(r.nUls, closeTo(765, 1e-9));
      expect(r.asA, closeTo(837.3, 0.3));
      // Ay with d = 382 mm: 863.6 mm²
      expect(r.asB, closeTo(863.6, 0.3));
    });
    test('punching', () {
      // Qu = 765 × (1 − 750²/1800²) = 632.2 kN ≤ 0.045 × 3000 × 450 × 25/1.5
      final p = r.checks.firstWhere((c) => c.kind == CheckKind.punching);
      expect(p.demand, closeTo(632.2, 0.1));
      expect(p.capacity, closeTo(1012.5, 1e-6));
    });
    test('all checks pass', () => expect(r.ok, isTrue));
  });

  group('EC2 footing', () {
    final r = designFooting(_input(DesignCode.ec2));
    test('same size (centred load)', () {
      expect(r.lengthA, closeTo(1.80, 1e-9));
      expect(r.h, 450);
    });
    test('cantilever bending at 0.15a inside the face', () {
      // σ = 765/3.24 = 236.1 kPa, c = 750 + 45 = 795 mm
      // M = 236.1 × 1.8 × 0.795²/2 = 134.3 kN·m → As = 795.7 mm²
      expect(r.asA, closeTo(795.7, 0.5));
      // Minimum 0.26 fctm/fyk b d = 945.9 mm² governs.
      expect(r.asMinA, closeTo(945.9, 0.5));
    });
    test('all checks pass', () => expect(r.ok, isTrue));
  });

  test('eccentric load enlarges the footing', () {
    final centred = designFooting(_input(DesignCode.bael));
    final eccentric = designFooting(
      FootingInput(
        code: DesignCode.bael,
        a: 300,
        b: 300,
        g: 400,
        q: 150,
        mg: 40,
        qAllowable: 200,
        fck: 25,
        fyk: 500,
      ),
    );
    expect(eccentric.area, greaterThan(centred.area));
    expect(eccentric.eccentricity, lessThan(eccentric.lengthA / 6));
  });
}
