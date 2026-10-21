// EN 1996-1-1 wall checks against hand calculations.
import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  test('fk = K fb^0.7 fm^0.3', () {
    // 0.55 × 20^0.7 × 10^0.3 = 8.934 MPa.
    expect(masonryFk(MasonryUnit.clayGroup1, 20, 10), closeTo(8.934, 0.005));
  });

  test('200 mm clay wall, 2.7 m, centric load: NRd ≈ 598 kN/m', () {
    // hef = 2.025 m, hef/t = 10.1, einit = 4.5 mm, emin = 10 mm.
    // Ends: Φ = 0.9. Mid: λ = 0.320, u = 0.383, Φm = 0.9 e^(−u²/2) = 0.836.
    // NRd = 0.836 × 200 × 8.934 / 2.5 = 597.8 kN/m.
    final r = designMasonryWall(
      const MasonryWallInput(
        unit: MasonryUnit.clayGroup1,
        fb: 20,
        fm: 10,
        t: 200,
        height: 2.7,
        nEd: 300,
      ),
    );
    expect(r.hef, closeTo(2.025, 1e-9));
    expect(r.eInit, closeTo(4.5, 1e-9));
    expect(r.phiEnd, closeTo(0.9, 1e-9));
    expect(r.phiMid, closeTo(0.8364, 0.001));
    expect(r.nRd, closeTo(597.8, 1.0));
    expect(r.ok, isTrue);
  });

  test('eccentric floor load reduces the end and mid-height capacity', () {
    MasonryWallResult run(double e) => designMasonryWall(
      MasonryWallInput(
        unit: MasonryUnit.clayGroup1,
        fb: 20,
        fm: 10,
        t: 200,
        height: 2.7,
        nEd: 300,
        eTop: e,
      ),
    );
    final centric = run(0), eccentric = run(30);
    // Ends: ei = 30 + 4.5 = 34.5 mm → Φ = 0.655.
    expect(eccentric.phiEnd, closeTo(0.655, 1e-3));
    expect(eccentric.phiMid, lessThan(centric.phiMid));
  });

  test('slender walls include creep eccentricity and fail beyond 27', () {
    final r = designMasonryWall(
      const MasonryWallInput(
        unit: MasonryUnit.calciumSilicateGroup1,
        fb: 12,
        fm: 5,
        t: 100,
        height: 3,
        rhoN: 1.0,
        nEd: 50,
      ),
    );
    expect(r.slenderness, closeTo(30, 1e-9));
    expect(r.eCreep, greaterThan(0));
    expect(r.checks.first.ok, isFalse);
  });

  test('mortar strength is capped at 2 fb', () {
    final a = designMasonryWall(
      const MasonryWallInput(
        unit: MasonryUnit.aac,
        fb: 4,
        fm: 10,
        t: 250,
        height: 2.5,
        nEd: 50,
      ),
    );
    expect(a.fk, closeTo(masonryFk(MasonryUnit.aac, 4, 8), 1e-9));
  });
}
