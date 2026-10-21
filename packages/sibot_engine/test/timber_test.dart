// EN 1995-1-1 member checks against hand calculations.
import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

Check _check(TimberMemberResult r, CheckKind k) =>
    r.checks.firstWhere((c) => c.kind == k);

void main() {
  final c24 = timberClasses['C24']!;

  test('C24 75×200 beam, 4 m, medium term, service class 1', () {
    // fm,d = 0.8 × 24 / 1.3 = 14.77 MPa; W = 500 000 mm³.
    // σm,crit = 0.78 b² E0.05 / (h lef) = 40.58 MPa → λrel,m = 0.769,
    // kcrit = 1.56 − 0.75 λ = 0.983.
    // τ = 1.5 V / (kcr b h) = 1.49 MPa ≤ fv,d = 2.46 MPa.
    final r = designTimberMember(
      TimberMemberInput(
        timber: c24,
        b: 75,
        h: 200,
        length: 4,
        myEd: 6,
        vEd: 10,
      ),
    );
    expect(r.kmod, 0.8);
    expect(r.kh, 1.0);
    expect(r.fmd, closeTo(14.77, 0.01));
    expect(r.sigmaM, closeTo(12.0, 1e-9));
    expect(r.lambdaRelM, closeTo(0.769, 0.002));
    expect(r.kcrit, closeTo(0.983, 0.002));
    expect(r.tau, closeTo(1.4925, 0.001));
    expect(r.fvd, closeTo(2.4615, 0.001));
    expect(r.ok, isTrue);
  });

  test('depth factor for shallow solid timber is capped at 1.3', () {
    final r = designTimberMember(
      TimberMemberInput(timber: c24, b: 38, h: 89, length: 2, myEd: 0.5),
    );
    // (150/89)^0.2 = 1.110.
    expect(r.kh, closeTo(1.110, 0.001));
  });

  test('C24 100×100 column, 3 m: kc = 0.285, Nb ≈ 36.8 kN', () {
    // λ = 103.9, λrel = 1.762, k = 2.198, kc = 0.2847, fc,0,d = 12.92 MPa.
    final r = designTimberMember(
      TimberMemberInput(timber: c24, b: 100, h: 100, length: 3, nEd: 30),
    );
    expect(r.lambdaRelZ, closeTo(1.762, 0.003));
    expect(r.kcZ, closeTo(0.2847, 0.002));
    final c = _check(r, CheckKind.bucklingInteractionZ);
    // 30 kN / (0.2847 × 12.92 × 10 000 mm²) = 0.815.
    expect(c.demand, closeTo(0.815, 0.008));
    expect(c.ok, isTrue);
  });

  test('deflection: final deflection with creep exceeds L/250', () {
    // I = 5e7 mm⁴, E = 11 000 MPa: w(g = 1) = 6.06 mm, w(q = 1.5) = 9.09 mm.
    // wfin = 6.06 × 1.6 + 9.09 × (1 + 0.3 × 0.6) = 20.4 mm > 16 mm.
    final r = designTimberMember(
      TimberMemberInput(
        timber: c24,
        b: 75,
        h: 200,
        length: 4,
        myEd: 3,
        gk: 1,
        qk: 1.5,
      ),
    );
    expect(r.wInstQ, closeTo(9.09, 0.02));
    expect(r.wFin, closeTo(20.43, 0.05));
    expect(_check(r, CheckKind.deflectionInstant).ok, isTrue);
    expect(_check(r, CheckKind.deflectionFinal).ok, isFalse);
  });

  test('glulam uses γM = 1.25 and βc = 0.1', () {
    final gl = timberClasses['GL24h']!;
    final r = designTimberMember(
      TimberMemberInput(timber: gl, b: 140, h: 140, length: 3, nEd: 50),
    );
    expect(r.fc0d, closeTo(0.8 * 24 / 1.25, 1e-9));
    expect(r.kcZ, greaterThan(timberKc(r.lambdaRelZ, false)));
  });

  test('tension with bending uses the linear interaction', () {
    final r = designTimberMember(
      TimberMemberInput(
        timber: c24,
        b: 75,
        h: 200,
        length: 3,
        nEd: -20,
        myEd: 2,
      ),
    );
    expect(r.checks.any((c) => c.kind == CheckKind.combinedStress), isTrue);
    expect(
      r.checks.any((c) => c.kind == CheckKind.bucklingInteractionZ),
      isFalse,
    );
  });

  test('service class 3 and permanent load reduce kmod to 0.5', () {
    expect(timberKmod(LoadDuration.permanent, 3), 0.5);
    expect(timberKdef(3), 2.0);
  });

  test('rejects b larger than h', () {
    expect(
      () => designTimberMember(
        TimberMemberInput(timber: c24, b: 200, h: 100, length: 3),
      ),
      throwsA(isA<InputError>()),
    );
  });
}
