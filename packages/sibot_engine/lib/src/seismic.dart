import 'dart:math' as math;

import 'core.dart';

/// Ground types of EN 1998-1 Table 3.1.
enum GroundType { a, b, c, d, e }

/// Elastic spectrum parameters S, TB, TC, TD (Tables 3.2 and 3.3,
/// recommended values).
class SpectrumParams {
  final double s;
  final double tb;
  final double tc;
  final double td;
  const SpectrumParams(this.s, this.tb, this.tc, this.td);
}

SpectrumParams spectrumParams(GroundType g, {required bool type1}) => type1
    ? switch (g) {
        GroundType.a => const SpectrumParams(1.0, 0.15, 0.4, 2.0),
        GroundType.b => const SpectrumParams(1.2, 0.15, 0.5, 2.0),
        GroundType.c => const SpectrumParams(1.15, 0.20, 0.6, 2.0),
        GroundType.d => const SpectrumParams(1.35, 0.20, 0.8, 2.0),
        GroundType.e => const SpectrumParams(1.4, 0.15, 0.5, 2.0),
      }
    : switch (g) {
        GroundType.a => const SpectrumParams(1.0, 0.05, 0.25, 1.2),
        GroundType.b => const SpectrumParams(1.35, 0.05, 0.25, 1.2),
        GroundType.c => const SpectrumParams(1.5, 0.10, 0.25, 1.2),
        GroundType.d => const SpectrumParams(1.8, 0.10, 0.30, 1.2),
        GroundType.e => const SpectrumParams(1.6, 0.05, 0.25, 1.2),
      };

/// Design spectrum Sd(T), m/s² (3.13–3.16), β = 0.2.
double designSpectrum(double t, double ag, SpectrumParams p, double q) {
  const beta = 0.2;
  if (t <= p.tb) {
    return ag * p.s * (2 / 3 + t / p.tb * (2.5 / q - 2 / 3));
  }
  if (t <= p.tc) return ag * p.s * 2.5 / q;
  if (t <= p.td) {
    return math.max(ag * p.s * 2.5 / q * p.tc / t, beta * ag);
  }
  return math.max(ag * p.s * 2.5 / q * p.tc * p.td / (t * t), beta * ag);
}

/// Structural system for the approximate period T1 = Ct H^3/4 (4.6).
enum PeriodSystem {
  steelFrame(0.085),
  concreteFrame(0.075),
  other(0.050);

  final double ct;
  const PeriodSystem(this.ct);
}

/// Importance classes and γI (Table 4.3, recommended values).
const importanceFactors = {1: 0.8, 2: 1.0, 3: 1.2, 4: 1.4};

class SeismicInput {
  /// Reference peak ground acceleration on ground A, m/s².
  final double agR;
  final int importanceClass;
  final GroundType ground;

  /// Type 1 for high seismicity (Ms > 5.5), type 2 otherwise.
  final bool type1;
  final double q;
  final PeriodSystem system;

  /// Seismic masses (t) and heights above the base (m) of each floor,
  /// from the bottom up.
  final List<double> masses;
  final List<double> heights;

  /// Period override, s (null = Ct H^3/4).
  final double? period;

  const SeismicInput({
    required this.agR,
    required this.ground,
    required this.masses,
    required this.heights,
    this.importanceClass = 2,
    this.type1 = false,
    this.q = 1.5,
    this.system = PeriodSystem.concreteFrame,
    this.period,
  });
}

class StoreyForce {
  final double height;
  final double mass;
  final double force;
  final double shear;
  const StoreyForce(this.height, this.mass, this.force, this.shear);
}

class SeismicResult {
  final SpectrumParams spectrum;
  final double ag;
  final double t1;
  final double sd;
  final double lambda;
  final double totalMass;

  /// Base shear Fb, kN, and overturning moment at the base, kN·m.
  final double baseShear;
  final double overturning;
  final List<StoreyForce> storeys;

  /// T1 ≤ min(4 TC, 2 s) for the lateral force method (4.3.3.2.1).
  final bool periodInRange;

  /// Spectrum points (T, Sd) for plotting.
  final List<(double, double)> curve;

  const SeismicResult({
    required this.spectrum,
    required this.ag,
    required this.t1,
    required this.sd,
    required this.lambda,
    required this.totalMass,
    required this.baseShear,
    required this.overturning,
    required this.storeys,
    required this.periodInRange,
    required this.curve,
  });
}

/// Lateral force method of analysis, EN 1998-1 4.3.3.2, with the
/// height-proportional distribution (4.11).
SeismicResult lateralForceMethod(SeismicInput i) {
  requirePositive(i.agR, 'agR');
  requireRange(i.q, 1, 8, 'q');
  if (i.masses.isEmpty || i.masses.length != i.heights.length) {
    throw const InputError(InputProblem.inconsistentGeometry, 'masses');
  }
  for (final m in i.masses) {
    requirePositive(m, 'mass');
  }
  for (var k = 0; k < i.heights.length; k++) {
    requirePositive(i.heights[k], 'height');
    if (k > 0 && i.heights[k] <= i.heights[k - 1]) {
      throw const InputError(InputProblem.inconsistentGeometry, 'height');
    }
  }
  final gammaI = importanceFactors[i.importanceClass];
  if (gammaI == null) {
    throw const InputError(InputProblem.outOfRange, 'importanceClass');
  }
  if (i.period != null) requirePositive(i.period!, 'period');

  final p = spectrumParams(i.ground, type1: i.type1);
  final ag = gammaI * i.agR;
  final height = i.heights.last;
  final t1 = i.period ?? i.system.ct * math.pow(height, 0.75).toDouble();
  final sd = designSpectrum(t1, ag, p, i.q);
  final lambda = t1 <= 2 * p.tc && i.masses.length > 2 ? 0.85 : 1.0;
  final mass = i.masses.reduce((a, b) => a + b);
  final fb = sd * mass * lambda; // t · m/s² = kN

  var sumZm = 0.0;
  for (var k = 0; k < i.masses.length; k++) {
    sumZm += i.heights[k] * i.masses[k];
  }
  final forces = [
    for (var k = 0; k < i.masses.length; k++)
      fb * i.heights[k] * i.masses[k] / sumZm,
  ];
  final storeys = <StoreyForce>[];
  var shear = 0.0;
  for (var k = forces.length - 1; k >= 0; k--) {
    shear += forces[k];
    storeys.insert(0, StoreyForce(i.heights[k], i.masses[k], forces[k], shear));
  }
  var moment = 0.0;
  for (var k = 0; k < forces.length; k++) {
    moment += forces[k] * i.heights[k];
  }

  final curve = [
    for (var k = 0; k <= 80; k++)
      (k * 0.05, designSpectrum(math.max(k * 0.05, 1e-6), ag, p, i.q)),
  ];

  return SeismicResult(
    spectrum: p,
    ag: ag,
    t1: t1,
    sd: sd,
    lambda: lambda,
    totalMass: mass,
    baseShear: fb,
    overturning: moment,
    storeys: storeys,
    periodInRange: t1 <= math.min(4 * p.tc, 2.0),
    curve: curve,
  );
}

// ── PS92 (NF P 06-013) ────────────────────────────────────────────────

/// PS92 seismic zones (décret 91-461) and site classes.
enum Ps92Zone { ia, ib, ii, iii }

enum Ps92Site { s0, s1, s2, s3 }

/// Nominal acceleration aN (m/s²) by zone and building class B, C, D
/// (arrêté du 29 mai 1997).
double ps92NominalAcceleration(Ps92Zone zone, String buildingClass) {
  const table = {
    Ps92Zone.ia: {'B': 1.0, 'C': 1.5, 'D': 2.0},
    Ps92Zone.ib: {'B': 1.5, 'C': 2.0, 'D': 2.5},
    Ps92Zone.ii: {'B': 2.5, 'C': 3.0, 'D': 3.5},
    Ps92Zone.iii: {'B': 3.5, 'C': 4.0, 'D': 4.5},
  };
  final v = table[zone]![buildingClass];
  if (v == null) {
    throw const InputError(InputProblem.outOfRange, 'buildingClass');
  }
  return v;
}

/// Normalised design spectrum parameters of PS92 6.2.1.3: RA, RM, TB,
/// TC, TD for each site class (5 % damping).
(double, double, double, double, double) ps92SiteParams(Ps92Site s) =>
    switch (s) {
      Ps92Site.s0 => (1.0, 2.5, 0.15, 0.30, 2.67),
      Ps92Site.s1 => (1.0, 2.5, 0.20, 0.40, 3.20),
      Ps92Site.s2 => (0.9, 2.25, 0.30, 0.60, 3.85),
      Ps92Site.s3 => (0.8, 2.0, 0.45, 0.90, 4.44),
    };

/// Normalised spectrum R(T).
double ps92R(double t, Ps92Site site) {
  final (ra, rm, tb, tc, td) = ps92SiteParams(site);
  if (t <= tb) return ra + (rm - ra) * t / tb;
  if (t <= tc) return rm;
  if (t <= td) return rm * tc / t;
  return rm * tc * td / (t * t);
}

/// PS92 design acceleration aN · R(T) · ρ · τ / q (m/s²), with the
/// damping correction ρ = 1 (5 %) and the topographic factor τ.
double ps92Spectrum(
  double t,
  double aN,
  Ps92Site site,
  double q, {
  double tau = 1,
}) => aN * ps92R(t, site) * tau / q;
