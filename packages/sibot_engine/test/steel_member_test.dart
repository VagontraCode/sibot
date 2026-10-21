// EN 1993-1-1 member checks against hand calculations.
import 'dart:math' as math;

import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

Check _check(SteelMemberResult r, CheckKind k) =>
    r.checks.firstWhere((c) => c.kind == k);

void main() {
  final ipe300 = steelSections['IPE 300']!;
  final heb200 = steelSections['HEB 200']!;

  test('IPE 300 torsion and warping constants', () {
    // Tables: It = 20.12 cm⁴, Iw = 125.9e3 cm⁶.
    expect(ipe300.it / 1e4, closeTo(20.12, 0.4));
    expect(ipe300.iw / 1e9, closeTo(125.9, 1.5));
  });

  test('IPE 300 S235 restrained beam: class 1, Mpl and Vpl', () {
    final r = designSteelMember(
      SteelMemberInput(
        section: ipe300,
        grade: 'S235',
        length: 6,
        myEd: 100,
        vEd: 80,
        kLT: 0.01, // continuously restrained
      ),
    );
    expect(r.sectionClass, 1);
    expect(r.mcRd, closeTo(147.7, 0.8));
    expect(r.vPlRd, closeTo(348.4, 1.5));
    expect(r.chiLT, 1.0);
    expect(r.ok, isTrue);
  });

  test('IPE 300 S235, L = 6 m, uniform moment: Mcr and Mb,Rd', () {
    // Mcr = π²EIz/L² · √(Iw/Iz + L²GIt/(π²EIz)) ≈ 90.2 kN·m,
    // λLT = 1.280, curve b, χLT = 0.534, Mb,Rd ≈ 78.9 kN·m.
    final r = designSteelMember(
      SteelMemberInput(section: ipe300, grade: 'S235', length: 6, myEd: 70),
    );
    expect(r.mCr, closeTo(90.2, 1.5));
    expect(r.lambdaLT, closeTo(1.28, 0.015));
    expect(r.chiLT, closeTo(0.534, 0.008));
    expect(r.mbRd, closeTo(78.9, 1.2));
    expect(_check(r, CheckKind.lateralTorsional).ok, isTrue);
  });

  test('a UDL moment diagram raises the LTB resistance', () {
    SteelMemberResult run(MomentShape s) => designSteelMember(
      SteelMemberInput(
        section: ipe300,
        grade: 'S235',
        length: 6,
        myEd: 70,
        shape: s,
      ),
    );
    expect(
      run(MomentShape.udl).mbRd,
      greaterThan(run(MomentShape.uniform).mbRd),
    );
  });

  test('HEB 200 S235 column, L = 4 m: χz = 0.637, Nb,z,Rd ≈ 1169 kN', () {
    final r = designSteelMember(
      SteelMemberInput(section: heb200, grade: 'S235', length: 4, nEd: 1000),
    );
    expect(r.lambdaZ, closeTo(0.840, 0.006));
    expect(r.chiZ, closeTo(0.637, 0.005));
    final c = _check(r, CheckKind.flexuralBucklingZ);
    expect(c.capacity, closeTo(1169, 12));
    expect(c.ok, isTrue);
    expect(
      _check(r, CheckKind.flexuralBucklingY).capacity,
      greaterThan(c.capacity),
    );
  });

  test('beam-column interaction governs over the separate checks', () {
    final r = designSteelMember(
      SteelMemberInput(
        section: heb200,
        grade: 'S275',
        length: 4,
        nEd: 600,
        myEd: 60,
        shape: MomentShape.linear,
        psi: 0,
      ),
    );
    final iy = _check(r, CheckKind.bucklingInteractionY);
    final iz = _check(r, CheckKind.bucklingInteractionZ);
    final nz = _check(r, CheckKind.flexuralBucklingZ);
    expect(iz.ratio, greaterThan(nz.ratio));
    expect(iy.ratio, greaterThan(0));
    expect(r.kyy, inInclusiveRange(0.4, 1.8));
  });

  test('tension member has no buckling checks', () {
    final r = designSteelMember(
      SteelMemberInput(section: ipe300, length: 5, nEd: -500),
    );
    expect(r.checks.any((c) => c.kind == CheckKind.steelTension), isTrue);
    expect(r.checks.any((c) => c.kind == CheckKind.flexuralBucklingZ), isFalse);
  });

  test('IPE 600 S355 in pure compression is class 4 with reduced area', () {
    final s = steelSections['IPE 600']!;
    final r = designSteelMember(
      SteelMemberInput(section: s, grade: 'S355', length: 3, nEd: 2000),
    );
    expect(r.sectionClass, 4);
    expect(r.nPlRd, lessThan(s.area * 355 / 1e3));
  });

  test('lightest IPE for a 6 m restrained beam with 100 kN·m', () {
    final s = lightestSteelSection(
      'IPE',
      (s) => SteelMemberInput(
        section: s,
        grade: 'S235',
        length: 6,
        myEd: 100,
        kLT: 0.01,
      ),
    );
    // Wpl,req = 100e6 / 235 = 425.5 cm³ → IPE 270 (484 cm³).
    expect(s?.name, 'IPE 270');
  });

  test('minor-axis bending: Mpl,z = Wpl,z fy and biaxial interaction', () {
    // HEB 200 S235: Wpl,z = 306.1 cm³ → Mpl,z = 71.9 kN·m.
    final r = designSteelMember(
      SteelMemberInput(
        section: heb200,
        grade: 'S235',
        length: 3,
        mzEd: 30,
        kLT: 0.01,
      ),
    );
    final bz = _check(r, CheckKind.steelBendingZ);
    expect(bz.capacity, closeTo(71.9, 0.8));
    // Biaxial (6.41) with n = 0: (My/Mpl,y)² + Mz/Mpl,z.
    final both = designSteelMember(
      SteelMemberInput(
        section: heb200,
        grade: 'S235',
        length: 3,
        myEd: 80,
        mzEd: 30,
        kLT: 0.01,
      ),
    );
    final c = _check(both, CheckKind.steelCombined);
    final mply = heb200.wplY * 235 / 1e6;
    expect(c.demand, closeTo(math.pow(80 / mply, 2) + 30 / bz.capacity, 1e-6));
    expect(
      both.checks.any((k) => k.kind == CheckKind.bucklingInteractionZ),
      isTrue,
    );
  });

  test('rejects an unknown grade', () {
    expect(
      () => designSteelMember(
        SteelMemberInput(section: ipe300, length: 3, grade: 'S999'),
      ),
      throwsA(isA<InputError>()),
    );
  });
}
