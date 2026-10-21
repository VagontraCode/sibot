import 'dart:math' as math;

import 'core.dart';

/// Homogeneous slope facing +x: crest level H for x ≤ 0, face down to the
/// toe at x = H / tan β, level 0 beyond. Units m, kN, kPa, degrees.
class SlopeInput {
  final double height;
  final double angle;

  /// Unit weight (kN/m³), effective cohesion (kPa), friction angle (°).
  final double gamma;
  final double cohesion;
  final double phi;

  /// Pore pressure ratio ru = u / (γ h).
  final double ru;

  /// Uniform surcharge on the crest, kPa.
  final double surcharge;

  /// Deepest slip surface below the toe, m (null = H).
  final double? maxDepth;

  const SlopeInput({
    required this.height,
    required this.angle,
    required this.gamma,
    required this.cohesion,
    required this.phi,
    this.ru = 0,
    this.surcharge = 0,
    this.maxDepth,
  });

  double get toeX =>
      angle >= 89.999 ? 0 : height / math.tan(angle * math.pi / 180);

  double groundY(double x) {
    if (x <= 0) return height;
    final l = toeX;
    if (x >= l) return 0;
    return height * (1 - x / l);
  }
}

class SlipCircle {
  final double xc;
  final double yc;
  final double r;
  const SlipCircle(this.xc, this.yc, this.r);

  double baseY(double x) {
    final d = r * r - (x - xc) * (x - xc);
    return d <= 0 ? double.nan : yc - math.sqrt(d);
  }
}

class Slice {
  final double x;
  final double width;
  final double top;
  final double base;
  const Slice(this.x, this.width, this.top, this.base);
}

class SlopeResult {
  final SlopeInput input;
  final SlipCircle circle;
  final double factor;
  final List<Slice> slices;

  /// Factor of safety of the same circle with EN 1997-1 DA3 design
  /// parameters (tan φ' and c' / 1.25, variable surcharge × 1.3).
  final double factorEc7;

  /// Circles analysed during the search.
  final int circles;

  final List<Check> checks;
  bool get ok => checks.every((c) => c.ok);

  const SlopeResult({
    required this.input,
    required this.circle,
    required this.factor,
    required this.slices,
    required this.factorEc7,
    required this.circles,
    required this.checks,
  });
}

const _nSlices = 40;

/// Slices of the sliding mass for [c], or null when the circle does not
/// cut a meaningful mass.
List<Slice>? _slices(SlopeInput s, SlipCircle c) {
  const n = 240;
  final x0 = c.xc - c.r, x1 = c.xc + c.r;
  double? a, b;
  for (var k = 0; k <= n; k++) {
    final x = x0 + (x1 - x0) * k / n;
    final yb = c.baseY(x);
    if (yb.isNaN) continue;
    if (s.groundY(x) - yb > 1e-6) {
      a ??= x;
      b = x;
    }
  }
  if (a == null || b == null || b - a < 0.05 * s.height) return null;
  // Refine the entry and exit points by bisection.
  double edge(double inside, double outside) {
    for (var k = 0; k < 40; k++) {
      final m = (inside + outside) / 2;
      final yb = c.baseY(m);
      if (!yb.isNaN && s.groundY(m) - yb > 0) {
        inside = m;
      } else {
        outside = m;
      }
    }
    return inside;
  }

  final step = (x1 - x0) / n;
  a = edge(a, math.max(x0, a - step));
  b = edge(b, math.min(x1, b + step));
  final w = (b - a) / _nSlices;
  final out = <Slice>[];
  var maxH = 0.0;
  for (var k = 0; k < _nSlices; k++) {
    final x = a + (k + 0.5) * w;
    final top = s.groundY(x), base = c.baseY(x);
    if (base.isNaN || top <= base || top > c.yc) return null;
    maxH = math.max(maxH, top - base);
    out.add(Slice(x, w, top, base));
  }
  if (maxH < 0.05 * s.height) return null;
  return out;
}

/// Bishop's simplified factor of safety for a given circle, or null when
/// the circle is not admissible (mα too small, uplift or no driving).
double? bishopFactor(
  SlopeInput s,
  SlipCircle c, {
  List<Slice>? slices,
  double cDiv = 1,
  double tanDiv = 1,
  double qFactor = 1,
}) {
  final sl = slices ?? _slices(s, c);
  if (sl == null) return null;
  final tanPhi = math.tan(s.phi * math.pi / 180) / tanDiv;
  final coh = s.cohesion / cDiv;
  var drive = 0.0;
  final w = <double>[], sinA = <double>[], cosA = <double>[];
  for (final p in sl) {
    final q = p.x <= 0 ? s.surcharge * qFactor : 0.0;
    final wt = s.gamma * (p.top - p.base) * p.width + q * p.width;
    final sa = ((c.xc - p.x) / c.r).clamp(-1.0, 1.0);
    final ca = math.sqrt(1 - sa * sa);
    w.add(wt);
    sinA.add(sa);
    cosA.add(ca);
    drive += wt * sa;
  }
  if (drive <= 1e-9) return null;
  var f = 1.0;
  for (var it = 0; it < 100; it++) {
    var resist = 0.0;
    for (var k = 0; k < sl.length; k++) {
      final p = sl[k];
      final m = cosA[k] * (1 + sinA[k] / cosA[k] * tanPhi / f);
      if (m < 0.05) return null;
      final u = s.ru * s.gamma * (p.top - p.base);
      final eff = math.max(0.0, w[k] - u * p.width);
      resist += (coh * p.width + eff * tanPhi) / m;
    }
    final next = resist / drive;
    if ((next - f).abs() < 1e-7) return next;
    f = next;
  }
  return f;
}

/// Critical circle by a grid search of centres and tangent depths
/// followed by a pattern search, Bishop's simplified method.
SlopeResult analyseSlope(SlopeInput s, {double required = 1.5}) {
  requirePositive(s.height, 'height');
  // Steeper faces need slip circles centred below the crest, which
  // vertical slices cannot represent (F would be overestimated).
  requireRange(s.angle, 5, 75, 'angle');
  requirePositive(s.gamma, 'gamma');
  requireRange(s.phi, 0, 50, 'phi');
  requireRange(s.cohesion, 0, 1000, 'cohesion');
  requireRange(s.ru, 0, 0.6, 'ru');
  requireRange(s.surcharge, 0, 500, 'surcharge');
  if (s.cohesion == 0 && s.phi == 0) {
    throw const InputError(InputProblem.notPositive, 'cohesion');
  }
  final h = s.height, l = s.toeX;
  final depth = s.maxDepth ?? h;

  var count = 0;
  double? eval(double xc, double yc, double yt) {
    if (yt >= yc || yt < -depth - 1e-9 || yt > h) return null;
    count++;
    return bishopFactor(s, SlipCircle(xc, yc, yc - yt));
  }

  var best = double.infinity;
  var bx = 0.0, by = 0.0, bt = 0.0;
  const nx = 14, ny = 14, nt = 10;
  for (var i = 0; i <= nx; i++) {
    final xc = -h + (l + 2 * h) * i / nx;
    for (var j = 0; j <= ny; j++) {
      final yc = h * (0.6 + 2.4 * j / ny);
      for (var k = 0; k <= nt; k++) {
        final yt = -depth + (depth + 0.9 * h) * k / nt;
        final f = eval(xc, yc, yt);
        if (f != null && f < best) {
          best = f;
          bx = xc;
          by = yc;
          bt = yt;
        }
      }
    }
  }
  if (!best.isFinite) {
    throw const InputError(InputProblem.inconsistentGeometry, 'height');
  }

  // Pattern search refinement.
  var step = h * 0.25;
  while (step > h * 1e-3) {
    var improved = false;
    for (final d in const [
      (1, 0, 0),
      (-1, 0, 0),
      (0, 1, 0),
      (0, -1, 0),
      (0, 0, 1),
      (0, 0, -1),
    ]) {
      final f = eval(bx + d.$1 * step, by + d.$2 * step, bt + d.$3 * step);
      if (f != null && f < best - 1e-9) {
        best = f;
        bx += d.$1 * step;
        by += d.$2 * step;
        bt += d.$3 * step;
        improved = true;
      }
    }
    if (!improved) step /= 2;
  }

  final circle = SlipCircle(bx, by, by - bt);
  final slices = _slices(s, circle)!;
  final fd =
      bishopFactor(
        s,
        circle,
        slices: slices,
        cDiv: 1.25,
        tanDiv: 1.25,
        qFactor: 1.3,
      ) ??
      0;
  const ref = 'EN 1997-1 11.5.1';
  return SlopeResult(
    input: s,
    circle: circle,
    factor: best,
    slices: slices,
    factorEc7: fd,
    circles: count,
    checks: [
      Check(
        kind: CheckKind.slopeGlobal,
        demand: required,
        capacity: best,
        clause: 'Bishop',
      ),
      Check(
        kind: CheckKind.slopeEc7,
        demand: 1,
        capacity: fd,
        clause: '$ref (DA3)',
      ),
    ],
  );
}
