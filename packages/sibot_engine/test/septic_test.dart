import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  test('10 users: 1 m³ settling + 0.8 m³ sludge', () {
    // 10 × 100 L × 1 day = 1.0 m³; 10 × 40 L × 2 years = 0.8 m³.
    final r = sizeSepticTank(const SepticInput(users: 10));
    expect(r.settlingVolume, closeTo(1.0, 1e-12));
    expect(r.sludgeVolume, closeTo(0.8, 1e-12));
    expect(r.volume, closeTo(1.8, 1e-12));
    expect(r.providedVolume, greaterThanOrEqualTo(r.volume));
    expect(r.length / r.width, closeTo(2, 0.2));
    expect(r.firstCompartment + r.secondCompartment, closeTo(r.length, 1e-9));
    expect(r.totalDepth, closeTo(1.8, 1e-12));
  });

  test('DTU 64.1 minimum governs small houses', () {
    // 7 main rooms: 3 + 2 = 5 m³ > 1.8 m³.
    final r = sizeSepticTank(const SepticInput(users: 10, rooms: 7));
    expect(r.dtuMinimum, 5);
    expect(r.volume, 5);
  });

  test('rejects zero users', () {
    expect(
      () => sizeSepticTank(const SepticInput(users: 0)),
      throwsA(isA<InputError>()),
    );
  });
}
