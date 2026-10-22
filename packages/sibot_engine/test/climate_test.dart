// EN 1991-1-4 and EN 1991-1-3 against hand calculations.
import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  test('qp at 10 m, terrain II, vb = 26 m/s: ce = 2.35, qp ≈ 0.99 kPa', () {
    // kr = 0.19, cr = 0.19 ln(200) = 1.0067, Iv = 1/ln(200) = 0.1887.
    // qp = (1 + 7 Iv) · ½ ρ vm² = 2.321 × 0.5 × 1.25 × 26.17² = 993.6 Pa.
    final p = peakVelocityPressure(
      vb: 26,
      terrain: TerrainCategory.catII,
      z: 10,
    );
    expect(p.kr, closeTo(0.19, 1e-9));
    expect(p.cr, closeTo(1.0067, 1e-4));
    expect(p.ce, closeTo(2.35, 0.01));
    expect(p.qp, closeTo(0.9936, 0.002));
  });

  test('below zmin the pressure is constant', () {
    final a = peakVelocityPressure(
      vb: 24,
      terrain: TerrainCategory.catIV,
      z: 4,
    );
    final b = peakVelocityPressure(
      vb: 24,
      terrain: TerrainCategory.catIV,
      z: 10,
    );
    expect(a.qp, closeTo(b.qp, 1e-12));
  });

  test('wall zones for a 10 m high, 20 × 10 m building', () {
    // e = min(20, 20) = 20 ≥ d = 10 → zones A (4 m) and B (6 m).
    // h/d = 1: D = +0.8, E = −0.5, correlation 0.85.
    final w = designWind(
      vb: 26,
      terrain: TerrainCategory.catII,
      h: 10,
      b: 20,
      d: 10,
    );
    expect(w.e, 20);
    expect(w.walls.map((z) => z.zone), ['A', 'B', 'D', 'E']);
    expect(w.walls[0].extent, 4);
    expect(w.walls[1].extent, 6);
    final dz = w.walls.firstWhere((z) => z.zone == 'D');
    final ez = w.walls.firstWhere((z) => z.zone == 'E');
    expect(dz.cpe, closeTo(0.8, 1e-9));
    expect(ez.cpe, closeTo(-0.5, 1e-9));
    expect(w.netWall, closeTo(0.85 * w.peak.qp * 1.3, 1e-9));
    expect(w.roof.first.cpe, -1.8);
  });

  test('low building: h/d = 0.25 gives D = +0.7 and E = −0.3', () {
    final w = designWind(
      vb: 26,
      terrain: TerrainCategory.catIII,
      h: 5,
      b: 30,
      d: 20,
    );
    expect(w.walls.map((z) => z.zone), ['A', 'B', 'C', 'D', 'E']);
    expect(w.walls.last.cpe, closeTo(-0.3, 1e-9));
    expect(w.correlation, 0.85);
  });

  test('snow on a duopitch roof: μ1 and the drifted cases', () {
    // α = 40° → μ1 = 0.8 × 20/30 = 0.533; α = 20° → 0.8. sk = 0.65.
    final s = designSnow(
      sk: 0.65,
      shape: RoofShape.duopitch,
      alpha1: 40,
      alpha2: 20,
    );
    expect(s.mu1Left, closeTo(0.5333, 1e-4));
    expect(s.mu1Right, 0.8);
    expect(s.cases, hasLength(3));
    expect(s.cases[1].left, closeTo(0.5 * 0.5333 * 0.65, 1e-4));
    expect(s.max, closeTo(0.52, 1e-9));
  });

  test('orography factor scales qp by co² at the mean wind part', () {
    final flat = peakVelocityPressure(
      vb: 26,
      terrain: TerrainCategory.catII,
      z: 10,
    );
    final hill = peakVelocityPressure(
      vb: 26,
      terrain: TerrainCategory.catII,
      z: 10,
      co: 1.2,
    );
    // qp = (1 + 7 kI / (co ln)) · ½ρ (co cr vb)²: (co² + 7 co Iv0)/(1 + 7 Iv0).
    final iv0 = flat.iv;
    expect(
      hill.qp / flat.qp,
      closeTo((1.44 + 7 * 1.2 * iv0) / (1 + 7 * iv0), 1e-9),
    );
  });

  test('duopitch roof coefficients: table values and interpolation', () {
    final (s15, p15) = duopitchCpe(15);
    expect(s15, [-0.9, -0.8, -0.3, -0.4, -1.0]);
    expect(p15[0], 0.2);
    final (s225, _) = duopitchCpe(22.5);
    expect(s225[0], closeTo(-0.7, 1e-12));
  });

  test('French snow regions with altitude', () {
    expect(frenchSnowLoad('A2', 150), 0.45);
    expect(frenchSnowLoad('C1', 400), closeTo(0.85, 1e-12));
    // Continuity at 500 m and 1000 m.
    expect(frenchSnowLoad('B1', 500), closeTo(0.85, 1e-12));
    expect(frenchSnowLoad('B1', 1000), closeTo(0.55 + 1.05, 1e-12));
    expect(frenchSnowLoad('E', 500), closeTo(1.85, 1e-12));
    expect(() => frenchSnowLoad('E', 1200), throwsA(isA<InputError>()));
    expect(frenchWindRegions[3], 26);
  });

  test('flat roof: s = 0.8 Ce Ct sk', () {
    final s = designSnow(sk: 0.45, shape: RoofShape.flat, ce: 1.2);
    expect(s.max, closeTo(0.8 * 1.2 * 0.45, 1e-12));
  });
}
