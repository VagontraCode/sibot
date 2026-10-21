// ACM plate elements against Timoshenko's plate solutions.
import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  // Square 4 m, 200 mm, E = 30 GPa, ν = 0.3, q = 10 kPa.
  const a = 4.0, q = 10.0;
  PlateInput square(EdgeSupport s, {int n = 16}) => PlateInput(
    lx: a,
    ly: a,
    t: 200,
    e: 30000,
    nu: 0.3,
    nx: n,
    ny: n,
    left: s,
    right: s,
    bottom: s,
    top: s,
    q: q,
  );

  test('simply supported square: w = 0.00406 qa⁴/D, M = 0.0479 qa²', () {
    final input = square(EdgeSupport.simple);
    final r = analysePlate(input);
    final d = input.rigidity;
    final wc = r.at(r.w, a / 2, a / 2);
    expect(
      wc,
      closeTo(0.00406 * q * a * a * a * a / d, 0.00406 * q * 256 / d * 0.01),
    );
    final mc = r.at(r.mx, a / 2, a / 2);
    expect(mc, closeTo(0.0479 * q * a * a, 0.0479 * q * 16 * 0.02));
    expect(r.at(r.my, a / 2, a / 2), closeTo(mc, 1e-9));
  });

  test(
    'clamped square: w = 0.00126 qa⁴/D, centre 0.0231 qa², edge −0.0513 qa²',
    () {
      final input = square(EdgeSupport.fixed, n: 20);
      final r = analysePlate(input);
      final d = input.rigidity;
      expect(
        r.at(r.w, a / 2, a / 2),
        closeTo(0.00126 * q * 256 / d, 0.00126 * q * 256 / d * 0.02),
      );
      expect(
        r.at(r.mx, a / 2, a / 2),
        closeTo(0.0231 * q * 16, 0.0231 * q * 16 * 0.04),
      );
      expect(
        r.at(r.mx, 0, a / 2),
        closeTo(-0.0513 * q * 16, 0.0513 * q * 16 * 0.06),
      );
    },
  );

  test('raft on Winkler springs under uniform load settles uniformly', () {
    const input = PlateInput(
      lx: 10,
      ly: 8,
      t: 500,
      nx: 10,
      ny: 8,
      left: EdgeSupport.free,
      right: EdgeSupport.free,
      bottom: EdgeSupport.free,
      top: EdgeSupport.free,
      q: 50,
      subgrade: 20000,
    );
    final r = analysePlate(input);
    for (final v in r.w) {
      expect(v, closeTo(50 / 20000, 1e-9));
    }
    expect(r.maxOf(r.mx).abs(), lessThan(1e-6));
  });

  test('flat slab on four columns: column reactions carry the load', () {
    const input = PlateInput(
      lx: 6,
      ly: 6,
      t: 250,
      nx: 12,
      ny: 12,
      left: EdgeSupport.free,
      right: EdgeSupport.free,
      bottom: EdgeSupport.free,
      top: EdgeSupport.free,
      columns: [(1, 1), (5, 1), (5, 5), (1, 5)],
      q: 8,
    );
    final r = analysePlate(input);
    final sum = r.columnReactions.reduce((x, y) => x + y);
    expect(sum, closeTo(8 * 36, 1e-6));
    for (final c in r.columnReactions) {
      expect(c, closeTo(72, 1e-6));
    }
    // Hogging over the columns.
    expect(r.at(r.mx, 1, 1), lessThan(0));
  });

  test('Wood–Armer moments', () {
    // Pure twist: both faces need |Mxy| in both directions.
    final t = woodArmer(0, 0, 5);
    expect([t.bx, t.by, t.tx, t.ty], [5, 5, 5, 5]);
    // Mx = 10, My = 2, Mxy = 4: bottom 14 and 6, no top steel... the top
    // check gives Mx − 4 = 6 > 0 → 0 and My − 16/10 = 0.4 > 0 → 0.
    final b = woodArmer(10, 2, 4);
    expect(b.bx, 14);
    expect(b.by, 6);
    expect(b.tx, 0);
    expect(b.ty, 0);
    // Mx = 10, My = −3, Mxy = 4: My + 4 = 1 ≥ 0 → bottom 14, 1.
    final c = woodArmer(10, -3, 4);
    expect(c.bx, 14);
    expect(c.by, 1);
  });

  test('reinforcement of the simply supported square', () {
    final r = analysePlate(square(EdgeSupport.simple));
    final as = plateReinforcement(
      r,
      code: DesignCode.ec2,
      t: 200,
      fck: 25,
      fyk: 500,
    );
    final centre = r.node(8, 8);
    // M ≈ 7.7 + |Mxy| ≈ 7.7 kN·m/m at the centre (Mxy = 0 there).
    expect(as.bottomX[centre], greaterThan(0));
    expect(as.bottomX[centre], lessThan(200));
    // Corners need top steel for the twisting moments.
    expect(as.topX[r.node(0, 0)] + as.topX[r.node(1, 1)], greaterThan(0));
    expect(as.minimum, greaterThan(0));
  });
}
