// EN 1998-1 lateral force method against a hand calculation.
import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  const fourStoreys = SeismicInput(
    agR: 1.6,
    ground: GroundType.c,
    q: 1.5,
    masses: [300, 300, 300, 300],
    heights: [3, 6, 9, 12],
  );

  test('4-storey RC frame, agR = 1.6 m/s², ground C, type 2', () {
    // T1 = 0.075 × 12^0.75 = 0.4835 s (TC < T1 ≤ TD).
    // Sd = 1.6 × 1.5 × 2.5/1.5 × 0.25/0.4835 = 2.068 m/s².
    // λ = 0.85 (T1 ≤ 2 TC, > 2 storeys): Fb = 2.068 × 1200 × 0.85 = 2110 kN.
    final r = lateralForceMethod(fourStoreys);
    expect(r.t1, closeTo(0.4835, 1e-4));
    expect(r.sd, closeTo(2.068, 0.002));
    expect(r.lambda, 0.85);
    expect(r.baseShear, closeTo(2109.7, 2));
    // Top floor: Fb × 12/30.
    expect(r.storeys.last.force, closeTo(r.baseShear * 0.4, 1e-9));
    expect(r.storeys.first.shear, closeTo(r.baseShear, 1e-9));
    expect(r.periodInRange, isTrue);
  });

  test('design spectrum branches and the lower bound β ag', () {
    final p = spectrumParams(GroundType.a, type1: true);
    // Plateau: ag S 2.5/q.
    expect(designSpectrum(0.3, 2, p, 2), closeTo(2.5, 1e-12));
    // T = 0: ag S 2/3.
    expect(designSpectrum(0, 2, p, 2), closeTo(4 / 3, 1e-12));
    // Long period with large q: bounded by 0.2 ag.
    expect(designSpectrum(3.5, 2, p, 6), closeTo(0.4, 1e-12));
  });

  test('importance class III scales the base shear by 1.2', () {
    final r2 = lateralForceMethod(fourStoreys);
    final r3 = lateralForceMethod(
      const SeismicInput(
        agR: 1.6,
        ground: GroundType.c,
        q: 1.5,
        importanceClass: 3,
        masses: [300, 300, 300, 300],
        heights: [3, 6, 9, 12],
      ),
    );
    expect(r3.baseShear / r2.baseShear, closeTo(1.2, 1e-9));
  });

  test('rejects floors that are not in ascending order', () {
    expect(
      () => lateralForceMethod(
        const SeismicInput(
          agR: 1,
          ground: GroundType.b,
          masses: [100, 100],
          heights: [6, 3],
        ),
      ),
      throwsA(isA<InputError>()),
    );
  });
}
