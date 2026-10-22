import 'dart:math' as math;

import 'core.dart';

/// Soil below elevation [top] (m, toe level = 0) down to the next layer.
class SoilLayer {
  final double top;
  final double gamma;
  final double cohesion;
  final double phi;
  const SoilLayer({
    required this.top,
    required this.gamma,
    required this.cohesion,
    required this.phi,
  });
}

enum SlopeMethod { bishop, janbu }

/// Simple slope facing +x: crest level H for x ≤ 0, face down to the
/// toe at x = H / tan β, level 0 beyond. Units m, kN, kPa, degrees.
class SlopeInput {
  final double height;
  final double angle;

  /// Unit weight (kN/m³), effective cohesion (kPa) and friction angle (°)
  /// of the top soil, down to the first of [layers].
  final double gamma;
  final double cohesion;
  final double phi;

  /// Deeper layers, any order.
  final List<SoilLayer> layers;

  /// Pore pressure ratio ru = u / (γ h).
  final double ru;

  /// Horizontal water table elevation, m (null = none). Below it
  /// u = γw (zw − z); water above the ground acts as a weightless-strength
  /// material on the slices.
  final double? waterLevel;

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
    this.layers = const [],
    this.ru = 0,
    this.waterLevel,
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

  /// Length of the face along the profile.
  double get faceLength => math.sqrt(height * height + toeX * toeX);

  /// Point of the ground profile at distance [t] from the crest edge
  /// (negative on the crest).
  (double, double) profilePoint(double t) {
    if (t <= 0) return (t, height);
    final f = faceLength;
    if (t >= f) return (toeX + t - f, 0);
    return (toeX * t / f, height * (1 - t / f));
  }

  /// Layers from the surface down: (top, γ, c, φ).
  List<SoilLayer> get profile {
    final sorted = [...layers]..sort((a, b) => b.top.compareTo(a.top));
    return [
      SoilLayer(
        top: double.infinity,
        gamma: gamma,
        cohesion: cohesion,
        phi: phi,
      ),
      ...sorted,
    ];
  }
}

const gammaWater = 9.81;

/// Slip surface y = baseY(x) below the ground.
abstract interface class SlipSurface {
  double baseY(double x);

  /// Base inclination α (positive descending towards +x), radians.
  double alpha(double x);
}

class SlipCircle implements SlipSurface {
  final double xc;
  final double yc;
  final double r;
  const SlipCircle(this.xc, this.yc, this.r);

  @override
  double baseY(double x) {
    final d = r * r - (x - xc) * (x - xc);
    return d <= 0 ? double.nan : yc - math.sqrt(d);
  }

  @override
  double alpha(double x) => math.asin(((xc - x) / r).clamp(-1.0, 1.0));
}

/// Non-circular surface through ordered points (x strictly increasing).
class SlipPolyline implements SlipSurface {
  final List<(double, double)> points;
  const SlipPolyline(this.points);

  int _segment(double x) {
    for (var k = 0; k < points.length - 2; k++) {
      if (x <= points[k + 1].$1) return k;
    }
    return points.length - 2;
  }

  @override
  double baseY(double x) {
    if (x < points.first.$1 || x > points.last.$1) return double.nan;
    final k = _segment(x);
    final (x0, y0) = points[k];
    final (x1, y1) = points[k + 1];
    return y0 + (y1 - y0) * (x - x0) / (x1 - x0);
  }

  @override
  double alpha(double x) {
    final k = _segment(x);
    final (x0, y0) = points[k];
    final (x1, y1) = points[k + 1];
    return math.atan2(y0 - y1, x1 - x0);
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
  final SlopeMethod method;
  final SlipSurface surface;
  final double factor;
  final List<Slice> slices;

  /// Factor of safety of the same surface with EN 1997-1 DA3 design
  /// parameters (tan φ' and c' / 1.25, variable surcharge × 1.3).
  final double factorEc7;

  /// Janbu correction factor f0 (1 for Bishop).
  final double f0;

  /// Trial surfaces analysed during the search.
  final int circles;

  final List<Check> checks;
  bool get ok => checks.every((c) => c.ok);

  SlipCircle? get circle =>
      surface is SlipCircle ? surface as SlipCircle : null;

  const SlopeResult({
    required this.input,
    required this.method,
    required this.surface,
    required this.factor,
    required this.slices,
    required this.factorEc7,
    required this.circles,
    required this.checks,
    this.f0 = 1,
  });
}

const _nSlices = 40;

/// Slices of the sliding mass for the circle [c], or null when it does not
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
    // Slices above the centre would need a reversed base.
    if (base.isNaN || top <= base || top > c.yc) return null;
    maxH = math.max(maxH, top - base);
    out.add(Slice(x, w, top, base));
  }
  if (maxH < 0.05 * s.height) return null;
  return out;
}

/// Slices between the ends of a polyline lying on the ground.
List<Slice>? _polySlices(SlopeInput s, SlipPolyline p) {
  final a = p.points.first.$1, b = p.points.last.$1;
  if (b - a < 0.05 * s.height) return null;
  final w = (b - a) / _nSlices;
  final out = <Slice>[];
  var maxH = 0.0;
  for (var k = 0; k < _nSlices; k++) {
    final x = a + (k + 0.5) * w;
    final top = s.groundY(x), base = p.baseY(x);
    if (top <= base) return null;
    maxH = math.max(maxH, top - base);
    out.add(Slice(x, w, top, base));
  }
  if (maxH < 0.05 * s.height) return null;
  return out;
}

/// Weight, base strength and pore pressure of one slice.
class _SliceData {
  final double w;
  final double c;
  final double tanPhi;
  final double u;
  final double alpha;
  const _SliceData(this.w, this.c, this.tanPhi, this.u, this.alpha);
}

List<_SliceData> _sliceData(
  SlopeInput s,
  SlipSurface surface,
  List<Slice> sl, {
  required double cDiv,
  required double tanDiv,
  required double qFactor,
}) {
  final prof = s.profile;
  final zw = s.waterLevel;
  final out = <_SliceData>[];
  for (final p in sl) {
    // Weight of the soil column, layer by layer.
    var weight = 0.0;
    for (var k = 0; k < prof.length; k++) {
      final hi = math.min(p.top, prof[k].top);
      final lo = math.max(
        p.base,
        k + 1 < prof.length ? prof[k + 1].top : p.base,
      );
      if (hi > lo) weight += prof[k].gamma * (hi - lo);
    }
    if (zw != null && zw > p.top) weight += gammaWater * (zw - p.top);
    final q = p.x <= 0 ? s.surcharge * qFactor : 0.0;
    final soil = prof.lastWhere((l) => l.top >= p.base, orElse: () => prof[0]);
    var u = s.ru * weight;
    if (zw != null && zw > p.base) u += gammaWater * (zw - p.base);
    out.add(
      _SliceData(
        (weight + q) * p.width,
        soil.cohesion / cDiv,
        math.tan(soil.phi * math.pi / 180) / tanDiv,
        u,
        surface.alpha(p.x),
      ),
    );
  }
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
  final d = _sliceData(s, c, sl, cDiv: cDiv, tanDiv: tanDiv, qFactor: qFactor);
  var drive = 0.0;
  for (final x in d) {
    drive += x.w * math.sin(x.alpha);
  }
  if (drive <= 1e-9) return null;
  var f = 1.0;
  for (var it = 0; it < 100; it++) {
    var resist = 0.0;
    for (var k = 0; k < sl.length; k++) {
      final x = d[k];
      final ca = math.cos(x.alpha), sa = math.sin(x.alpha);
      final m = ca + sa * x.tanPhi / f;
      if (m < 0.05) return null;
      final eff = math.max(0.0, x.w - x.u * sl[k].width);
      resist += (x.c * sl[k].width + eff * x.tanPhi) / m;
    }
    final next = resist / drive;
    if ((next - f).abs() < 1e-7) return next;
    f = next;
  }
  return f;
}

/// Janbu correction factor f0 = 1 + b1 (d/L − 1.4 (d/L)²) for a surface
/// of chord length L and depth d below the chord.
double janbuF0(SlopeInput s, SlipPolyline p) {
  final (xa, ya) = p.points.first;
  final (xc, yc) = p.points.last;
  final l = math.sqrt((xc - xa) * (xc - xa) + (yc - ya) * (yc - ya));
  var d = 0.0;
  for (final (x, y) in p.points) {
    // Distance below the chord.
    final dist = ((xc - xa) * (ya - y) - (xa - x) * (yc - ya)).abs() / l;
    d = math.max(d, dist);
  }
  final soils = s.profile;
  final anyC = soils.any((l) => l.cohesion > 0);
  final anyPhi = soils.any((l) => l.phi > 0);
  final b1 = anyC && !anyPhi
      ? 0.69
      : anyPhi && !anyC
      ? 0.31
      : 0.5;
  // The correction curves stop at their maximum, d/L ≈ 0.36.
  final r = math.min(d / l, 1 / 2.8);
  return 1 + b1 * (r - 1.4 * r * r);
}

/// Janbu's simplified factor of safety (force equilibrium) for a
/// non-circular surface, corrected by f0.
double? janbuFactor(
  SlopeInput s,
  SlipPolyline p, {
  List<Slice>? slices,
  double cDiv = 1,
  double tanDiv = 1,
  double qFactor = 1,
}) {
  final sl = slices ?? _polySlices(s, p);
  if (sl == null) return null;
  final d = _sliceData(s, p, sl, cDiv: cDiv, tanDiv: tanDiv, qFactor: qFactor);
  var drive = 0.0;
  for (final x in d) {
    drive += x.w * math.tan(x.alpha);
  }
  if (drive <= 1e-9) return null;
  final f0 = janbuF0(s, p);
  var f = 1.0;
  for (var it = 0; it < 100; it++) {
    var resist = 0.0;
    for (var k = 0; k < sl.length; k++) {
      final x = d[k];
      final ca = math.cos(x.alpha);
      final m = ca * (1 + math.tan(x.alpha) * x.tanPhi / f);
      if (m < 0.05) return null;
      final eff = math.max(0.0, x.w - x.u * sl[k].width);
      resist += (x.c * sl[k].width + eff * x.tanPhi) / (ca * m);
    }
    final next = f0 * resist / drive;
    if ((next - f).abs() < 1e-7) return next;
    f = next;
  }
  return f;
}

void _validate(SlopeInput s, SlopeMethod method) {
  requirePositive(s.height, 'height');
  // Circles on steeper faces would be centred below the crest, which
  // vertical slices cannot represent (F would be overestimated).
  requireRange(s.angle, 5, method == SlopeMethod.bishop ? 75 : 90, 'angle');
  requirePositive(s.gamma, 'gamma');
  requireRange(s.phi, 0, 50, 'phi');
  requireRange(s.cohesion, 0, 1000, 'cohesion');
  requireRange(s.ru, 0, 0.6, 'ru');
  requireRange(s.surcharge, 0, 500, 'surcharge');
  if (s.cohesion == 0 && s.phi == 0) {
    throw const InputError(InputProblem.notPositive, 'cohesion');
  }
  for (final l in s.layers) {
    requirePositive(l.gamma, 'layers');
    requireRange(l.phi, 0, 50, 'layers');
    requireRange(l.cohesion, 0, 1000, 'layers');
    if (l.cohesion == 0 && l.phi == 0) {
      throw const InputError(InputProblem.notPositive, 'layers');
    }
    if (l.top >= s.height) {
      throw const InputError(InputProblem.inconsistentGeometry, 'layers');
    }
  }
  final zw = s.waterLevel;
  if (zw != null) {
    if (zw > s.height) {
      throw const InputError(InputProblem.outOfRange, 'waterLevel');
    }
  }
}

/// Critical slip surface: circles by a grid search of centres and tangent
/// depths (Bishop's simplified method), or polylines through the crest
/// and the toe region (Janbu's simplified method), refined by a pattern
/// search.
SlopeResult analyseSlope(
  SlopeInput s, {
  double required = 1.5,
  SlopeMethod method = SlopeMethod.bishop,
}) {
  _validate(s, method);
  return method == SlopeMethod.bishop
      ? _bishopSearch(s, required)
      : _janbuSearch(s, required);
}

List<Check> _checks(double required, double f, double fd, String method) {
  const ref = 'EN 1997-1 11.5.1';
  return [
    Check(
      kind: CheckKind.slopeGlobal,
      demand: required,
      capacity: f,
      clause: method,
    ),
    Check(
      kind: CheckKind.slopeEc7,
      demand: 1,
      capacity: fd,
      clause: '$ref (DA3)',
    ),
  ];
}

SlopeResult _bishopSearch(SlopeInput s, double required) {
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
  return SlopeResult(
    input: s,
    method: SlopeMethod.bishop,
    surface: circle,
    factor: best,
    slices: slices,
    factorEc7: fd,
    circles: count,
    checks: _checks(required, best, fd, 'Bishop'),
  );
}

SlopeResult _janbuSearch(SlopeInput s, double required) {
  final h = s.height;
  final depth = s.maxDepth ?? h;
  final face = s.faceLength;

  var count = 0;
  // Surface from the profile at tA through the inner points to tC.
  SlipPolyline? build(double ta, double tc, List<(double, double)> inner) {
    if (ta >= tc) return null;
    final a = s.profilePoint(ta), c = s.profilePoint(tc);
    final pts = [a, ...inner, c];
    for (var k = 1; k < pts.length; k++) {
      if (pts[k].$1 - pts[k - 1].$1 < 1e-3 * h) return null;
    }
    for (final (x, y) in inner) {
      if (y < -depth - 1e-9 || y >= s.groundY(x)) return null;
    }
    return SlipPolyline(pts);
  }

  double? eval(SlipPolyline? p) {
    if (p == null) return null;
    count++;
    return janbuFactor(s, p);
  }

  // Grid of three-point surfaces: entry on the crest or the face, exit on
  // the face or beyond the toe, one kink below the chord.
  var best = double.infinity;
  var bta = 0.0, btc = 0.0;
  var bInner = <(double, double)>[];
  const na = 12;
  // Exits on the face, exactly at the toe and beyond it.
  final exits = [
    for (final f in const [0.4, 0.6, 0.8, 1.0]) f * face,
    for (final f in const [0.1, 0.25, 0.45, 0.7, 1.0]) face + f * h,
  ];
  const fracs = [0.3, 0.45, 0.6, 0.75];
  const depths = [0.0, 0.1, 0.2, 0.35, 0.5, 0.7, 0.9];
  for (var i = 0; i <= na; i++) {
    final ta = -1.5 * h + (1.5 * h + 0.5 * face) * i / na;
    for (final tc in exits) {
      if (tc <= ta) continue;
      final a = s.profilePoint(ta), c = s.profilePoint(tc);
      for (final fr in fracs) {
        final x = a.$1 + (c.$1 - a.$1) * fr;
        final chord = a.$2 + (c.$2 - a.$2) * fr;
        for (final dp in depths) {
          final y = chord - dp * (chord + depth);
          final f = eval(build(ta, tc, [(x, y)]));
          if (f != null && f < best) {
            best = f;
            bta = ta;
            btc = tc;
            bInner = [(x, y)];
          }
        }
      }
    }
  }
  if (!best.isFinite) {
    throw const InputError(InputProblem.inconsistentGeometry, 'height');
  }

  // Pattern search over the end positions and the inner points.
  void refine() {
    var step = h * 0.2;
    while (step > h * 1e-3) {
      var improved = false;
      final nVar = 2 + 2 * bInner.length;
      for (var v = 0; v < nVar; v++) {
        for (final sign in const [1.0, -1.0]) {
          var ta = bta, tc = btc;
          final inner = [...bInner];
          if (v == 0) {
            ta += sign * step;
          } else if (v == 1) {
            tc += sign * step;
          } else {
            final k = (v - 2) ~/ 2;
            final (x, y) = inner[k];
            inner[k] = v.isEven ? (x + sign * step, y) : (x, y + sign * step);
          }
          final f = eval(build(ta, tc, inner));
          if (f != null && f < best - 1e-9) {
            best = f;
            bta = ta;
            btc = tc;
            bInner = inner;
            improved = true;
          }
        }
      }
      if (!improved) step /= 2;
    }
  }

  refine();
  // Second kink between the first one and the exit.
  final c = s.profilePoint(btc);
  final k1 = bInner.first;
  bInner = [k1, ((k1.$1 + c.$1) / 2, (k1.$2 + c.$2) / 2)];
  refine();

  final surface = build(bta, btc, bInner)!;
  final slices = _polySlices(s, surface)!;
  final fd =
      janbuFactor(
        s,
        surface,
        slices: slices,
        cDiv: 1.25,
        tanDiv: 1.25,
        qFactor: 1.3,
      ) ??
      0;
  return SlopeResult(
    input: s,
    method: SlopeMethod.janbu,
    surface: surface,
    factor: best,
    slices: slices,
    factorEc7: fd,
    f0: janbuF0(s, surface),
    circles: count,
    checks: _checks(required, best, fd, 'Janbu'),
  );
}
