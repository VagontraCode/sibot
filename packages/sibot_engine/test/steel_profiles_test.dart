import 'dart:math' as math;

import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  test('HEM areas match the tables within 1 %', () {
    // HEM 200: 131.3 cm²; HEM 300: 303.1 cm²; HEM 400: 325.8 cm².
    for (final (n, a) in [
      ('HEM 200', 131.3),
      ('HEM 300', 303.1),
      ('HEM 400', 325.8),
    ]) {
      expect(steelSections[n]!.area / 100, closeTo(a, a * 0.01), reason: n);
    }
  });

  test('CHS 168.3×8: A = 40.3 cm², I = 1297 cm⁴', () {
    final s = hollowSections['CHS 168.3×8']!;
    expect(s.area / 100, closeTo(40.29, 0.05));
    expect(s.iy / 1e4, closeTo(1297, 2));
    expect(s.it, closeTo(2 * s.iy, 1e-6));
  });

  test('SHS 100×5 (hot-finished): A = 18.7 cm², I ≈ 280 cm⁴', () {
    // Sharp corners: (100⁴ − 90⁴)/12 = 286.6 cm⁴; the rounded corners
    // (r = 7.5 and 5 mm) remove 27 mm² about 47 mm from the axis: −6 cm⁴.
    // (271 cm⁴ is the cold-formed EN 10219 value, r = 10 mm.)
    final s = hollowSections['SHS 100×5']!;
    expect(s.area / 100, closeTo(18.7, 0.1));
    expect(s.iy / 1e4, closeTo(280.6, 1.5));
    expect(s.iz, closeTo(s.iy, 1e-6 * s.iy));
    // Rounded-corner section is smaller than the sharp-corner one.
    final sharp = (math.pow(100, 4) - math.pow(90, 4)) / 12;
    expect(s.iy, lessThan(sharp));
  });

  test('RHS major axis is stiffer than minor', () {
    final s = hollowSections['RHS 200×100×8']!;
    expect(s.iy, greaterThan(3 * s.iz));
    expect(s.wplY, greaterThan(s.welY));
  });

  test('CHS 168.3×8 S355 column, 4 m: χ = 0.719 (curve a), Nb ≈ 1028 kN', () {
    final r = designSteelMember(
      SteelMemberInput(
        section: hollowSections['CHS 168.3×8']!,
        grade: 'S355',
        length: 4,
        nEd: 800,
      ),
    );
    expect(r.lambdaY, closeTo(0.9226, 0.003));
    expect(r.chiY, closeTo(0.719, 0.003));
    final nb = r.checks.firstWhere(
      (c) => c.kind == CheckKind.flexuralBucklingY,
    );
    expect(nb.capacity, closeTo(1028, 6));
    expect(r.checks.any((c) => c.kind == CheckKind.lateralTorsional), isFalse);
    expect(r.ok, isTrue);
  });

  test('channels and angles are for analysis only', () {
    final u = steelProfiles['UPN 200']!;
    expect(u.area / 100, closeTo(32.2, 32.2 * 0.03));
    expect(u.iy / 1e4, closeTo(1910, 1910 * 0.02));
    expect(steelDesignable(u), isFalse);
    final l = steelProfiles['L 100×100×10']!;
    // Table: A = 19.2 cm² (with root fillet), I = 177 cm⁴.
    expect(l.area / 100, closeTo(19.2, 19.2 * 0.03));
    expect(l.iy / 1e4, closeTo(177, 177 * 0.05));
    expect(
      () => designSteelMember(SteelMemberInput(section: u, length: 3)),
      throwsA(isA<InputError>()),
    );
  });

  test('lightest SHS for a 4 m column carrying 400 kN', () {
    final s = lightestSteelSection(
      'SHS',
      (p) => SteelMemberInput(section: p, grade: 'S355', length: 4, nEd: 400),
    );
    expect(s, isNotNull);
    expect(s!.name, startsWith('SHS'));
  });

  test('series listing', () {
    expect(profilesOfSeries('HEM').first, 'HEM 100');
    expect(profilesOfSeries('CHS'), hasLength(10));
  });
}
