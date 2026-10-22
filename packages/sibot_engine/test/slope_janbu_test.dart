// Janbu non-circular surfaces, layered soils and water tables.
import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  test('vertical cut in clay: planar wedge at 45°, F = 4c / (γH) = 0.889', () {
    // c = 20, γ = 18, H = 5: Culmann wedge 4 × 20 / (18 × 5) = 0.889.
    final r = analyseSlope(
      const SlopeInput(height: 5, angle: 90, gamma: 18, cohesion: 20, phi: 0),
      method: SlopeMethod.janbu,
    );
    expect(r.factor, lessThanOrEqualTo(0.889 + 0.003));
    expect(r.factor, greaterThan(0.8));
    expect(r.surface, isA<SlipPolyline>());
    expect(r.circle, isNull);
  });

  // Force equilibrium only, on free non-circular surfaces: Janbu is
  // known to fall up to about 10–15 % below Bishop circles.
  test('Janbu on a 60° clay slope: below the Taylor circle (F = 1.456)', () {
    final r = analyseSlope(
      const SlopeInput(height: 6, angle: 60, gamma: 18, cohesion: 30, phi: 0),
      method: SlopeMethod.janbu,
    );
    expect(r.factor, lessThan(1.456 * 1.01));
    expect(r.factor, greaterThan(1.456 * 0.85));
    expect(r.f0, greaterThanOrEqualTo(1));
  });

  test('f0 = 1 + b1 (d/L − 1.4 (d/L)²)', () {
    const s = SlopeInput(height: 5, angle: 45, gamma: 18, cohesion: 20, phi: 0);
    // Chord (0,0)–(10,0), kink 2 m below: d/L = 0.2, b1 = 0.69 (c only).
    final p = SlipPolyline(const [(0, 0), (5, -2), (10, 0)]);
    expect(janbuF0(s, p), closeTo(1 + 0.69 * (0.2 - 1.4 * 0.04), 1e-12));
  });

  test('an identical layer changes nothing; a weak one governs', () {
    const base = SlopeInput(
      height: 8,
      angle: 33.7,
      gamma: 19,
      cohesion: 10,
      phi: 28,
    );
    final f = analyseSlope(base).factor;
    final same = analyseSlope(
      const SlopeInput(
        height: 8,
        angle: 33.7,
        gamma: 19,
        cohesion: 10,
        phi: 28,
        layers: [SoilLayer(top: 2, gamma: 19, cohesion: 10, phi: 28)],
      ),
    ).factor;
    expect(same, closeTo(f, 1e-9));
    for (final method in SlopeMethod.values) {
      final weak = analyseSlope(
        const SlopeInput(
          height: 8,
          angle: 33.7,
          gamma: 19,
          cohesion: 10,
          phi: 28,
          layers: [SoilLayer(top: 1, gamma: 18, cohesion: 2, phi: 12)],
        ),
        method: method,
      ).factor;
      expect(weak, lessThan(f * 0.8), reason: method.name);
    }
  });

  test('a water table at the toe reduces F; dry below the surface', () {
    const dry = SlopeInput(
      height: 8,
      angle: 33.7,
      gamma: 19,
      cohesion: 10,
      phi: 28,
      waterLevel: -20,
      maxDepth: 8,
    );
    const wet = SlopeInput(
      height: 8,
      angle: 33.7,
      gamma: 19,
      cohesion: 10,
      phi: 28,
      waterLevel: 4,
    );
    final f = analyseSlope(
      const SlopeInput(
        height: 8,
        angle: 33.7,
        gamma: 19,
        cohesion: 10,
        phi: 28,
      ),
    ).factor;
    expect(analyseSlope(dry).factor, closeTo(f, 1e-9));
    expect(analyseSlope(wet).factor, lessThan(f));
  });

  test('a pond in front of the toe is stabilising compared with the same '
      'water table under a drained toe', () {
    // Water at +2 m: ponded in front of the toe (weight on the slices) is
    // the physical case and must not crash.
    final r = analyseSlope(
      const SlopeInput(
        height: 8,
        angle: 33.7,
        gamma: 19,
        cohesion: 10,
        phi: 28,
        waterLevel: 2,
      ),
      method: SlopeMethod.janbu,
    );
    expect(r.factor, greaterThan(0.5));
    expect(r.factorEc7, lessThan(r.factor));
  });
}
