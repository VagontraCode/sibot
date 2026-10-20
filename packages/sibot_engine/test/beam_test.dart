// Beam design verified against hand calculations.
//
// Example: b × h = 300 × 600 mm, cover 30 mm, Ø8 links, simple span 6 m,
// g = 20 kN/m (+ self-weight 25 × 0.3 × 0.6 = 4.5), q = 15 kN/m.
//   w = 1.35 × 24.5 + 1.5 × 15 = 55.575 kN/m
//   MEd = 55.575 × 6² / 8 = 250.09 kN·m,  VEd = 166.73 kN
//   d = 600 − 30 − 8 − 16/2 = 554 mm
import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

const _input = BeamInput(
  code: DesignCode.ec2,
  span: 6,
  b: 300,
  h: 600,
  g: 20,
  q: 15,
  fck: 30,
  fyk: 500,
);

BeamInput _with(DesignCode code, {double fck = 30, double h = 600}) =>
    BeamInput(
      code: code,
      span: 6,
      b: 300,
      h: h,
      g: 20,
      q: 15,
      fck: fck,
      fyk: 500,
    );

void main() {
  group('loads', () {
    final r = designBeam(_input);
    test('self-weight and ULS load', () {
      expect(r.selfWeight, closeTo(4.5, 1e-9));
      expect(r.wUls, closeTo(55.575, 1e-9));
    });
    test('design forces', () {
      expect(r.mEd, closeTo(250.0875, 1e-6));
      expect(r.vEd, closeTo(166.725, 1e-6));
      expect(r.d, closeTo(554, 1e-9));
    });
  });

  group('EC2 bending', () {
    final r = designBeam(_input);
    // fcd = 30/1.5 = 20; μ = 250.09e6 / (300 × 554² × 20) = 0.13581
    // α = 1.25(1 − √(1 − 2μ)) = 0.18319; z = d(1 − 0.4α) = 513.4 mm
    // As = MEd / (z · fyd) = 250.09e6 / (513.4 × 434.78) = 1120.4 mm²
    test('reduced moment and lever arm', () {
      expect(r.bending.mu, closeTo(0.13581, 1e-4));
      expect(r.bending.alpha, closeTo(0.18319, 1e-4));
      expect(r.bending.z, closeTo(513.4, 0.2));
    });
    test('tension steel', () {
      expect(r.bending.asTension, closeTo(1120.4, 0.5));
      expect(r.bending.needsCompressionSteel, isFalse);
      expect(r.bending.muLim, closeTo(0.2952, 1e-4));
    });
    test('bars: least area that fits one layer', () {
      // Inner width 224 mm: 6Ø16 = 1206 mm² (clear 25.6 mm) beats 4Ø20.
      expect(r.tensionBars.toString(), '6 Ø16');
      expect(r.tensionBars!.area, closeTo(1206.4, 0.1));
    });
    test('minimum steel', () {
      // fctm = 0.30 × 30^(2/3) = 2.896; 0.26 × 2.896/500 = 0.001506
      expect(r.asMin, closeTo(0.0015061 * 300 * 554, 0.5));
    });
  });

  group('EC2 shear', () {
    final s = designBeam(_input).shear;
    // ρl = 1206.4/(300×554) = 0.007259; k = 1.6008
    // vRd,c = 0.12 × 1.6008 × (100 × 0.007259 × 30)^(1/3) = 0.5365 MPa
    // VRd,c = 0.5365 × 300 × 554 = 89.2 kN < VEd → links required
    test('concrete resistance', () {
      expect(s.vRdc, closeTo(89.2, 0.2));
    });
    test('strut and links', () {
      // VRd,max (cot θ = 2.5) = 300 × 498.6 × 0.528 × 20 / 2.9 = 544.7 kN
      expect(s.cotTheta, 2.5);
      expect(s.crushing.capacity, closeTo(544.7, 0.3));
      // Asw/s = 166725 / (498.6 × 434.78 × 2.5) = 0.3076 mm²/mm
      expect(s.aswPerSRequired, closeTo(0.3076, 2e-4));
      expect(s.links.toString(), '2x Ø6 @ 175');
    });
  });

  group('EC2 deflection', () {
    final r = designBeam(_input);
    // ρ0 = 0.005477, ρ = 1120.4/166200 = 0.006741 > ρ0
    // l/d = 11 + 1.5√30 × ρ0/ρ = 17.675; × 1206.4/1120.4 = 19.03
    test('span/depth limit', () {
      expect(r.spanDepthLimit, closeTo(19.03, 0.03));
      expect(r.spanDepthActual, closeTo(10.83, 0.01));
      expect(r.checks.every((c) => c.ok), isTrue);
    });
  });

  group('BAEL bending', () {
    final r = designBeam(_with(DesignCode.bael, fck: 25));
    // fbu = 0.85 × 25 / 1.5 = 14.167; μ = 0.19173
    // αl = 3.5/(3.5 + 2.1739) = 0.61686, μl = 0.37172
    // α = 0.26850, z = 494.5 mm, As = 1163.2 mm²
    test('limit moment', () {
      expect(r.bending.muLim, closeTo(0.37172, 1e-4));
    });
    test('tension steel', () {
      expect(r.bending.mu, closeTo(0.19173, 1e-4));
      expect(r.bending.z, closeTo(494.5, 0.2));
      expect(r.bending.asTension, closeTo(1163.2, 0.6));
    });
    test('shear stress and links', () {
      // τu = 166725/(300×554) = 1.0032 MPa ≤ min(0.2×25/1.5, 5) = 3.333
      expect(r.shear.crushing.demand, closeTo(1.0032, 1e-3));
      expect(r.shear.crushing.capacity, closeTo(3.3333, 1e-3));
      // At/st = 300 × 1.15 × (1.0032 − 0.3 × 2.1)/(0.9 × 500) = 0.2859
      expect(r.shear.aswPerSRequired, closeTo(0.2859, 5e-4));
    });
    test('deflection exemption for a simple span', () {
      // h/l = 0.1 = 1/10 → just satisfies Mt/(10·M0).
      final defl = r.checks.where((c) => c.kind == CheckKind.deflection);
      expect(defl.first.capacity, closeTo(0.1, 1e-9));
      expect(defl.first.ok, isTrue);
    });
  });

  group('compression steel', () {
    // A shallow section forces μ > μlim.
    final r = designBeam(_with(DesignCode.ec2, h: 400));
    test('is required and keeps x/d at the limit', () {
      expect(r.bending.needsCompressionSteel, isTrue);
      expect(r.bending.alpha, 0.45);
      expect(r.notes, contains(BeamNote.compressionSteelRequired));
    });
    test('equilibrium of the steel couple', () {
      final b = r.bending;
      // Moment from concrete at the limit plus the steel couple = MEd.
      final fc = 20.0;
      final mLim = b.muLim * 300 * r.d * r.d * fc;
      final d2 = 30 + 8 + 6;
      final mCouple = b.asCompression * b.sigmaCompression * (r.d - d2);
      expect((mLim + mCouple) / 1e6, closeTo(r.mEd, 1e-6));
    });
  });

  group('input validation', () {
    test('rejects zero span', () {
      expect(
        () => designBeam(
          const BeamInput(
            code: DesignCode.ec2,
            span: 0,
            b: 300,
            h: 600,
            g: 10,
            q: 5,
            fck: 30,
            fyk: 500,
          ),
        ),
        throwsA(isA<InputError>()),
      );
    });
    test('rejects EC2 concrete above C50', () {
      expect(
        () => designBeam(_with(DesignCode.ec2, fck: 60)),
        throwsA(isA<InputError>()),
      );
    });
  });
}
