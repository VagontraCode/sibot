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

  test('bearing at the support: σc,90 ≤ kc,90 fc,90,d with l + 30 mm', () {
    // 10 kN on 75 mm wide, 60 mm bearing: σ = 10e3 / (75 × 90) = 1.48 MPa;
    // fc,90,d = 0.8 × 2.5 / 1.3 = 1.538, × 1.5 = 2.31 MPa.
    final r = designTimberMember(
      TimberMemberInput(
        timber: c24,
        b: 75,
        h: 200,
        length: 4,
        vEd: 10,
        bearingLength: 60,
      ),
    );
    final c = r.checks.firstWhere((x) => x.kind == CheckKind.timberBearing);
    expect(c.demand, closeTo(1.4815, 1e-3));
    expect(c.capacity, closeTo(2.3077, 1e-3));
  });

  test('notched end: kv from 6.62', () {
    // h = 200, hef = 150 (α = 0.75), x = 50: kv = 5 / (√200 (√0.1875
    // + 0.8·0.25·√(1.333 − 0.5625))) = 5 / (14.142 × (0.4330 + 0.1756))
    // = 0.581.
    final r = designTimberMember(
      TimberMemberInput(
        timber: c24,
        b: 75,
        h: 200,
        length: 4,
        vEd: 6,
        notchDepth: 150,
        notchX: 50,
      ),
    );
    final c = r.checks.firstWhere((x) => x.kind == CheckKind.timberNotch);
    expect(c.capacity, closeTo(0.581 * 2.4615, 0.01));
    expect(c.demand, closeTo(1.5 * 6000 / (0.67 * 75 * 150), 1e-6));
  });

  test('dowel connection: Johansen mode c governs for equal members', () {
    // C24 (ρk = 350), d = 12 mm, fu = 400, t1 = t2 = 45 mm:
    // fh = 25.26 MPa, My = 76 750 N·mm, mode (c) = 5 650 N.
    final r = designDowelConnection(
      DowelConnectionInput(timber: c24, d: 12, t1: 45, t2: 45, fEd: 5),
    );
    expect(r.fh1, closeTo(25.26, 0.01));
    expect(r.myRk, closeTo(76750, 150));
    expect(r.governing, 2);
    expect(r.fvRk, closeTo(5650, 10));
    expect(r.fvRd, closeTo(0.8 * 5650 / 1.3, 10));
  });

  test('rows of bolts: nef = n^0.9 (a1 / 13d)^0.25', () {
    final r = designDowelConnection(
      DowelConnectionInput(
        timber: c24,
        d: 12,
        t1: 45,
        t2: 45,
        fEd: 5,
        perRow: 4,
        a1: 84,
      ),
    );
    // 4^0.9 × (84 / 156)^0.25 = 3.482 × 0.8566 = 2.983.
    expect(r.nef, closeTo(2.983, 0.005));
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
