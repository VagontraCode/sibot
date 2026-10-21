// Bishop's simplified method against Taylor's charts and the infinite
// slope solution.
import 'dart:math' as math;

import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  test('75° slope in clay (φ = 0): Taylor Ns = 4.57', () {
    // F = c Ns / (γ H) = 30 × 4.57 / (18 × 6) = 1.269.
    final r = analyseSlope(
      const SlopeInput(height: 6, angle: 75, gamma: 18, cohesion: 30, phi: 0),
    );
    expect(r.factor, closeTo(1.269, 1.269 * 0.03));
  });

  test('faces steeper than 75° are rejected', () {
    expect(
      () => analyseSlope(
        const SlopeInput(height: 5, angle: 90, gamma: 18, cohesion: 20, phi: 0),
      ),
      throwsA(isA<InputError>()),
    );
  });

  test('60° slope in clay (φ = 0): Taylor Ns = 5.24', () {
    // F = 30 × 5.24 / (18 × 6) = 1.456.
    final r = analyseSlope(
      const SlopeInput(height: 6, angle: 60, gamma: 18, cohesion: 30, phi: 0),
    );
    expect(r.factor, closeTo(1.456, 1.456 * 0.03));
  });

  test('cohesionless slope tends to the infinite slope tan φ / tan β', () {
    // 2:1 slope, φ = 30°: tan 30° / 0.5 = 1.155; shallow circles approach
    // it from above.
    final r = analyseSlope(
      SlopeInput(
        height: 5,
        angle: math.atan(0.5) * 180 / math.pi,
        gamma: 19,
        cohesion: 0,
        phi: 30,
      ),
    );
    expect(r.factor, greaterThan(1.155 * 0.99));
    expect(r.factor, lessThan(1.155 * 1.12));
  });

  test('pore pressure and surcharge reduce the factor of safety', () {
    const base = SlopeInput(
      height: 8,
      angle: 33.7,
      gamma: 19,
      cohesion: 10,
      phi: 28,
    );
    final dry = analyseSlope(base).factor;
    final wet = analyseSlope(
      const SlopeInput(
        height: 8,
        angle: 33.7,
        gamma: 19,
        cohesion: 10,
        phi: 28,
        ru: 0.3,
      ),
    ).factor;
    final loaded = analyseSlope(
      const SlopeInput(
        height: 8,
        angle: 33.7,
        gamma: 19,
        cohesion: 10,
        phi: 28,
        surcharge: 20,
      ),
    ).factor;
    expect(wet, lessThan(dry));
    expect(loaded, lessThan(dry));
  });

  test('EC7 DA3 factor is the unfactored one / 1.25 for a c-φ soil', () {
    final r = analyseSlope(
      const SlopeInput(
        height: 8,
        angle: 33.7,
        gamma: 19,
        cohesion: 10,
        phi: 28,
      ),
    );
    // Dividing c and tan φ by the same factor divides F by it exactly.
    expect(r.factorEc7, closeTo(r.factor / 1.25, 1e-4));
  });
}
