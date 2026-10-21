// Computed profile properties against tabulated values (Euronorm 19-57 /
// EN 10365 tables): A (cm²), Iy (cm⁴), Wpl,y (cm³).
import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  const table = {
    'IPE 200': (28.5, 1943.0, 220.6),
    'IPE 300': (53.8, 8356.0, 628.4),
    'IPE 400': (84.5, 23130.0, 1307.0),
    'IPE 600': (156.0, 92080.0, 3512.0),
    'HEA 200': (53.8, 3692.0, 429.5),
    'HEA 300': (112.5, 18260.0, 1383.0),
    'HEB 200': (78.1, 5696.0, 642.5),
    'HEB 300': (149.1, 25170.0, 1869.0),
    'HEB 400': (197.8, 57680.0, 3232.0),
  };
  for (final e in table.entries) {
    test('${e.key} matches the tables within 1 %', () {
      final s = steelSections[e.key]!;
      final (a, iy, wpl) = e.value;
      expect(s.area / 100, closeTo(a, a * 0.01));
      expect(s.iy / 1e4, closeTo(iy, iy * 0.01));
      expect(s.wplY / 1e3, closeTo(wpl, wpl * 0.01));
    });
  }

  test('IPE 300 shear area 25.68 cm² and iz 3.35 cm', () {
    final s = steelSections['IPE 300']!;
    expect(s.avz / 100, closeTo(25.68, 0.05));
    expect(s.iRadiusZ / 10, closeTo(3.35, 0.03));
  });

  test('every library profile has positive properties', () {
    for (final s in steelSections.values) {
      expect(s.area, greaterThan(0), reason: s.name);
      expect(s.iy, greaterThan(s.iz), reason: s.name);
      expect(s.wplY, greaterThan(s.welY), reason: s.name);
    }
  });
}
