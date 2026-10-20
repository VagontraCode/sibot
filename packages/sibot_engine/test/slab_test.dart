// Slab design verified against hand calculations and BAEL Annexe E3.
import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  group('BAEL Annexe E3 panel coefficients (ULS, ν = 0)', () {
    test('square panel', () {
      final (mx, my) = baelPanelCoefficients(1.0);
      expect(mx, closeTo(0.0368, 1e-4));
      expect(my, closeTo(1.0, 1e-9));
    });
    test('α = 0.8', () {
      final (mx, my) = baelPanelCoefficients(0.8);
      expect(mx, closeTo(0.0561, 1e-4));
      expect(my, closeTo(0.6042, 1e-4));
    });
    test('My ≥ Mx/4 floor at α = 0.5', () {
      final (mx, my) = baelPanelCoefficients(0.5);
      expect(mx, closeTo(0.0962, 1e-4));
      expect(my, 0.25);
    });
  });

  group('EC2 one-way slab', () {
    // lx = 4 m, h = 180, cover 25, g = 2 + 4.5 (self-weight), q = 2.5.
    final r = designSlab(
      const SlabInput(
        code: DesignCode.ec2,
        lx: 4,
        h: 180,
        g: 2,
        q: 2.5,
        fck: 25,
        fyk: 500,
      ),
    );
    test('load and moment', () {
      expect(r.selfWeight, closeTo(4.5, 1e-9));
      expect(r.wUls, closeTo(12.525, 1e-9));
      expect(r.x.mSpan, closeTo(25.05, 1e-9));
      expect(r.x.d, 150);
    });
    test('main steel', () {
      // μ = 0.0668, z = 144.81 mm, As = 397.9 mm²/m
      expect(r.x.asSpan, closeTo(397.9, 0.5));
      expect(r.x.barsSpan.toString(), 'Ø8 @ 125');
    });
    test('distribution steel 20 %', () {
      expect(r.y.asSpan, closeTo(0.2 * r.x.asSpan, 1e-9));
    });
    test('all checks pass', () {
      expect(r.ok, isTrue, reason: r.checks.join('\n'));
    });
  });

  group('BAEL two-way continuous slab', () {
    final r = designSlab(
      const SlabInput(
        code: DesignCode.bael,
        lx: 4,
        ly: 5,
        h: 160,
        g: 1.5,
        q: 2.5,
        fck: 25,
        fyk: 500,
        support: SlabSupport.continuous,
      ),
    );
    test('panel moments', () {
      // α = 0.8 → μx = 0.0561, μy = 0.6042
      // w = 1.35 × (1.5 + 4.0) + 1.5 × 2.5 = 11.175 kN/m²
      // M0x = 0.0561 × 11.175 × 16 = 10.03; Mt = 0.75 M0x; Ma = 0.5 M0x
      final m0x = r.muX! * 11.175 * 16;
      expect(r.alpha, closeTo(0.8, 1e-12));
      expect(r.x.mSpan, closeTo(0.75 * m0x, 1e-9));
      expect(r.x.mSupport, closeTo(0.5 * m0x, 1e-9));
      expect(r.y.mSpan, closeTo(0.75 * r.muY! * m0x, 1e-9));
    });
    test('minimum steel ρ0 = 0.6 ‰ for FeE500', () {
      expect(r.x.asMin, closeTo(0.0006 * (3 - 0.8) / 2 * 1000 * 160, 1e-9));
      expect(r.y.asMin, closeTo(0.0006 * 1000 * 160, 1e-9));
    });
  });

  test('narrow panel falls back to one-way', () {
    final r = designSlab(
      const SlabInput(
        code: DesignCode.bael,
        lx: 3,
        ly: 9,
        h: 160,
        g: 1,
        q: 2,
        fck: 25,
        fyk: 500,
      ),
    );
    expect(r.notes, contains(SlabNote.treatedAsOneWay));
    expect(r.muX, isNull);
  });
}
