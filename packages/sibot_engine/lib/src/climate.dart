import 'dart:math' as math;

import 'core.dart';

// ── Wind, EN 1991-1-4 ─────────────────────────────────────────────────

/// Terrain categories (Table 4.1): roughness length z0 and minimum
/// height zmin, m.
enum TerrainCategory {
  cat0(0.003, 1),
  catI(0.01, 1),
  catII(0.05, 2),
  catIII(0.3, 5),
  catIV(1.0, 10);

  final double z0;
  final double zMin;
  const TerrainCategory(this.z0, this.zMin);
}

/// Peak velocity pressure at height [z], kPa (4.5), flat terrain
/// (co = 1), ρ = 1.25 kg/m³, kI = 1.
class PeakPressure {
  final double vb;
  final double kr;
  final double cr;
  final double vm;
  final double iv;

  /// Exposure factor ce = qp / qb.
  final double ce;
  final double qb;
  final double qp;

  const PeakPressure({
    required this.vb,
    required this.kr,
    required this.cr,
    required this.vm,
    required this.iv,
    required this.ce,
    required this.qb,
    required this.qp,
  });
}

PeakPressure peakVelocityPressure({
  required double vb,
  required TerrainCategory terrain,
  required double z,

  /// Orography factor co(z) (4.3.3, Annex A.3); 1 on flat terrain.
  double co = 1,
}) {
  requirePositive(vb, 'vb');
  requireRange(co, 1, 2, 'co');
  requirePositive(z, 'z');
  requireRange(z, 0, 200, 'z');
  const rho = 1.25;
  final kr = 0.19 * math.pow(terrain.z0 / 0.05, 0.07);
  final zz = math.max(z, terrain.zMin);
  final ln = math.log(zz / terrain.z0);
  final cr = kr * ln;
  final vm = cr * co * vb;
  final iv = 1 / (co * ln);
  final qb = 0.5 * rho * vb * vb / 1e3;
  final qp = (1 + 7 * iv) * 0.5 * rho * vm * vm / 1e3;
  return PeakPressure(
    vb: vb,
    kr: kr.toDouble(),
    cr: cr.toDouble(),
    vm: vm.toDouble(),
    iv: iv,
    ce: qp / qb,
    qb: qb,
    qp: qp,
  );
}

/// External pressure zone with its coefficient cpe,10 and pressure.
class WindZone {
  final String zone;

  /// Extent of the zone along the wall or roof, m (null = remainder).
  final double? extent;
  final double cpe;

  /// we = qp · cpe, kPa.
  final double pressure;

  const WindZone(this.zone, this.extent, this.cpe, this.pressure);
}

class WindResult {
  final PeakPressure peak;

  /// e = min(b, 2h), m.
  final double e;
  final double hOverD;
  final List<WindZone> walls;
  final List<WindZone> roof;

  /// Lack-of-correlation factor and net windward + leeward pressure, kPa.
  final double correlation;
  final double netWall;

  const WindResult({
    required this.peak,
    required this.e,
    required this.hOverD,
    required this.walls,
    required this.roof,
    required this.correlation,
    required this.netWall,
  });
}

double _interp(double x, List<(double, double)> pts) {
  if (x <= pts.first.$1) return pts.first.$2;
  for (var k = 1; k < pts.length; k++) {
    if (x <= pts[k].$1) {
      final (x0, y0) = pts[k - 1];
      final (x1, y1) = pts[k];
      return y0 + (y1 - y0) * (x - x0) / (x1 - x0);
    }
  }
  return pts.last.$2;
}

/// Rectangular building with a flat roof (sharp eaves): wall zones
/// (Table 7.1) and roof zones (Table 7.2), cpe,10.
WindResult designWind({
  required double vb,
  required TerrainCategory terrain,
  required double h,
  required double b,
  required double d,
  double co = 1,
}) {
  requirePositive(h, 'h');
  requirePositive(b, 'b');
  requirePositive(d, 'd');
  final peak = peakVelocityPressure(vb: vb, terrain: terrain, z: h, co: co);
  final qp = peak.qp;
  final e = math.min(b, 2 * h);
  final hd = h / d;

  final cpeD = _interp(hd, const [(0.25, 0.7), (1, 0.8)]);
  final cpeE = _interp(hd, const [(0.25, -0.3), (1, -0.5), (5, -0.7)]);
  WindZone z(String n, double? ext, double c) => WindZone(n, ext, c, qp * c);

  final walls = <WindZone>[
    if (e < d) ...[
      z('A', e / 5, -1.2),
      z('B', e * 4 / 5, -0.8),
      z('C', d - e, -0.5),
    ] else if (e < 5 * d) ...[
      z('A', e / 5, -1.2),
      z('B', d - e / 5, -0.8),
    ] else
      z('A', d, -1.2),
    z('D', null, cpeD),
    z('E', null, cpeE),
  ];

  final roof = <WindZone>[
    z('F', e / 4, -1.8),
    z('G', b - e / 2, -1.2),
    z('H', e / 2 - e / 10, -0.7),
    z('I', null, -0.2),
    z('I+', null, 0.2),
  ];

  final correlation = _interp(hd, const [(1, 0.85), (5, 1.0)]);
  return WindResult(
    peak: peak,
    e: e,
    hOverD: hd,
    walls: walls,
    roof: roof,
    correlation: correlation,
    netWall: correlation * qp * (cpeD - cpeE),
  );
}

// ── Snow, EN 1991-1-3 ─────────────────────────────────────────────────

enum RoofShape { flat, monopitch, duopitch }

/// Shape coefficient μ1 (Table 5.2) for a pitch [alpha] in degrees.
double snowMu1(double alpha) {
  if (alpha <= 30) return 0.8;
  if (alpha < 60) return 0.8 * (60 - alpha) / 30;
  return 0;
}

class SnowLoad {
  /// Roof snow load on each slope, kN/m², for one load arrangement.
  final String arrangement;
  final double left;
  final double right;

  const SnowLoad(this.arrangement, this.left, this.right);
}

class SnowResult {
  final double sk;
  final double ce;
  final double ct;
  final double mu1Left;
  final double mu1Right;
  final List<SnowLoad> cases;

  const SnowResult({
    required this.sk,
    required this.ce,
    required this.ct,
    required this.mu1Left,
    required this.mu1Right,
    required this.cases,
  });

  double get max =>
      cases.map((c) => math.max(c.left, c.right)).reduce(math.max);
}

/// Snow load on a roof, s = μ1 Ce Ct sk (5.2). [sk] in kN/m²; pitches in
/// degrees. Duopitch roofs give the undrifted case and the two drifted
/// cases (Figure 5.3).
SnowResult designSnow({
  required double sk,
  required RoofShape shape,
  double alpha1 = 0,
  double alpha2 = 0,
  double ce = 1.0,
  double ct = 1.0,
}) {
  requirePositive(sk, 'sk');
  requireRange(alpha1, 0, 90, 'alpha1');
  requireRange(alpha2, 0, 90, 'alpha2');
  requireRange(ce, 0.5, 1.5, 'ce');
  requireRange(ct, 0.1, 1.0, 'ct');
  final base = ce * ct * sk;
  final m1 = snowMu1(shape == RoofShape.flat ? 0 : alpha1);
  final m2 = shape == RoofShape.duopitch ? snowMu1(alpha2) : m1;
  final cases = switch (shape) {
    RoofShape.flat ||
    RoofShape.monopitch => [SnowLoad('i', m1 * base, m1 * base)],
    RoofShape.duopitch => [
      SnowLoad('i', m1 * base, m2 * base),
      SnowLoad('ii', 0.5 * m1 * base, m2 * base),
      SnowLoad('iii', m1 * base, 0.5 * m2 * base),
    ],
  };
  return SnowResult(
    sk: sk,
    ce: ce,
    ct: ct,
    mu1Left: m1,
    mu1Right: m2,
    cases: cases,
  );
}

// ── Duopitch roofs (EN 1991-1-4 Table 7.4a, θ = 0°) ───────────────────

/// cpe,10 of the zones F, G, H (windward slope), I, J (leeward) for the
/// two load cases of the table: [suction] (negative values) and
/// [pressure] (positive values), at pitches 5°–75°.
final _duopitch = <int, (List<double>, List<double>)>{
  5: ([-1.7, -1.2, -0.6, -0.6, 0.2], [0.0, 0.0, 0.0, -0.6, -0.6]),
  15: ([-0.9, -0.8, -0.3, -0.4, -1.0], [0.2, 0.2, 0.2, 0.0, 0.0]),
  30: ([-0.5, -0.5, -0.2, -0.4, -0.5], [0.7, 0.7, 0.4, 0.0, 0.0]),
  45: ([0.0, 0.0, 0.0, -0.2, -0.3], [0.7, 0.7, 0.6, 0.0, 0.0]),
  60: ([0.7, 0.7, 0.7, -0.2, -0.3], [0.7, 0.7, 0.7, -0.2, -0.3]),
  75: ([0.8, 0.8, 0.8, -0.2, -0.3], [0.8, 0.8, 0.8, -0.2, -0.3]),
};

/// Zone coefficients of a duopitch roof at [pitch] (°, 5–75), linear
/// interpolation between the tabulated pitches: (suction case,
/// pressure case), each for F, G, H, I, J.
(List<double>, List<double>) duopitchCpe(double pitch) {
  requireRange(pitch, 5, 75, 'pitch');
  final keys = _duopitch.keys.toList();
  var k = 0;
  while (k < keys.length - 2 && pitch > keys[k + 1]) {
    k++;
  }
  final a = keys[k], b = keys[k + 1];
  final t = (pitch - a) / (b - a);
  List<double> lerp(List<double> x, List<double> y) => [
    for (var i = 0; i < 5; i++) x[i] + (y[i] - x[i]) * t,
  ];
  return (
    lerp(_duopitch[a]!.$1, _duopitch[b]!.$1),
    lerp(_duopitch[a]!.$2, _duopitch[b]!.$2),
  );
}

// ── French National Annex regions ─────────────────────────────────────

/// Basic wind velocity vb,0 of the mainland wind regions 1–4 (NF EN
/// 1991-1-4/NA), m/s.
const frenchWindRegions = {1: 22.0, 2: 24.0, 3: 26.0, 4: 28.0};

/// Ground snow load at 200 m of the snow regions (NF EN 1991-1-3/NA),
/// kN/m².
const frenchSnowRegions = {
  'A1': 0.45,
  'A2': 0.45,
  'B1': 0.55,
  'B2': 0.55,
  'C1': 0.65,
  'C2': 0.65,
  'D': 0.90,
  'E': 1.40,
};

/// Characteristic ground snow load at altitude [altitude] (m) of a
/// French snow region: sk,200 + Δs. Regions A1–D up to 2000 m; region E
/// up to 1000 m (beyond, enter sk from the National Annex).
double frenchSnowLoad(String region, double altitude) {
  final s0 = frenchSnowRegions[region];
  if (s0 == null) throw const InputError(InputProblem.outOfRange, 'region');
  requireRange(altitude, 0, 2000, 'altitude');
  final a = altitude;
  if (region == 'E') {
    if (a > 1000) throw const InputError(InputProblem.outOfRange, 'altitude');
    if (a <= 200) return s0;
    if (a <= 500) return s0 + 1.5 * (a - 200) / 1000;
    return s0 + 3.5 * a / 1000 - 1.30;
  }
  if (a <= 200) return s0;
  if (a <= 500) return s0 + (a - 200) / 1000;
  if (a <= 1000) return s0 + 1.5 * a / 1000 - 0.45;
  return s0 + 3.5 * a / 1000 - 2.45;
}
