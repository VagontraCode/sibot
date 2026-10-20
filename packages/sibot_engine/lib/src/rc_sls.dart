import 'dart:math' as math;

import 'core.dart';
import 'materials.dart';

/// Cracked elastic rectangular section (concrete in tension ignored).
class CrackedSection {
  /// Neutral-axis depth, mm.
  final double x;

  /// Second moment of area of the cracked section in concrete units, mm⁴.
  final double inertia;

  /// Modular ratio used.
  final double n;

  final double d;

  const CrackedSection({
    required this.x,
    required this.inertia,
    required this.n,
    required this.d,
  });

  /// Concrete stress at the compressed face for moment [m] (kN·m), MPa.
  double concreteStress(double m) => m * 1e6 * x / inertia;

  /// Tension steel stress for moment [m] (kN·m), MPa.
  double steelStress(double m) => n * m * 1e6 * (d - x) / inertia;
}

/// Cracked section b × d with tension steel [as] and compression steel
/// [as2] at depth [d2] (mm, mm²), modular ratio [n].
CrackedSection crackedSection({
  required double b,
  required double d,
  required double as,
  required double n,
  double as2 = 0,
  double d2 = 50,
}) {
  // b·x²/2 + n·As2·(x − d2) − n·As·(d − x) = 0
  final qa = b / 2;
  final qb = n * (as + as2);
  final qc = -n * (as * d + as2 * d2);
  final x = (-qb + math.sqrt(qb * qb - 4 * qa * qc)) / (2 * qa);
  final inertia =
      b * x * x * x / 3 +
      n * as * math.pow(d - x, 2) +
      n * as2 * math.pow(x - d2, 2);
  return CrackedSection(x: x, inertia: inertia, n: n, d: d);
}

/// Long-term modular ratio for EC2 stress calculations with an
/// effective modulus Ecm/(1 + φ), φ = 2 (EN 1992-1-1 7.1(2), 5.8.6).
double ec2ModularRatio(Concrete c) => RebarSteel.es * (1 + 2.0) / c.ecm;

/// BAEL modular ratio n = 15 (A.4.5.1).
const baelModularRatio = 15.0;

/// BAEL cracking classes (A.4.5.3).
enum BaelCracking {
  /// Fissuration peu préjudiciable: no steel stress limit at SLS.
  slight,

  /// Fissuration préjudiciable.
  harmful,

  /// Fissuration très préjudiciable.
  veryHarmful,
}

/// BAEL limit on the SLS steel stress σs (MPa); null when not limited.
/// A.4.5.33: σs ≤ min(2fe/3, max(fe/2, 110√(η·ft28))), η = 1.6 for
/// high-bond bars; A.4.5.34: 0.8 × that value.
double? baelSteelStressLimit(BaelCracking c, double fe, double ft28) {
  final harmful = math.min(
    2 * fe / 3,
    math.max(fe / 2, 110 * math.sqrt(1.6 * ft28)),
  );
  return switch (c) {
    BaelCracking.slight => null,
    BaelCracking.harmful => harmful,
    BaelCracking.veryHarmful => 0.8 * harmful,
  };
}

/// EC2 calculated crack width (7.3.4) for a rectangular section in
/// bending. [cover] is the clear cover to the longitudinal bars (mm),
/// [spacing] their centre-to-centre spacing.
class CrackWidth {
  final double srMax;
  final double strain;
  final double wk;
  const CrackWidth(this.srMax, this.strain, this.wk);
}

CrackWidth ec2CrackWidth({
  required Concrete concrete,
  required double sigmaS,
  required double b,
  required double h,
  required double d,
  required double x,
  required double as,
  required int barDiameter,
  required double cover,
  required double spacing,
}) {
  // 7.3.2(3): effective tension area.
  final hcEff = math.min(2.5 * (h - d), math.min((h - x) / 3, h / 2));
  final rho = as / (b * hcEff);
  final alphaE = RebarSteel.es / concrete.ecm;
  const kt = 0.4; // long-term loading
  final fct = concrete.fctm;
  // 7.3.4(2) eq. 7.9.
  final strain = math.max(
    (sigmaS - kt * fct / rho * (1 + alphaE * rho)) / RebarSteel.es,
    0.6 * sigmaS / RebarSteel.es,
  );
  // 7.3.4(3) eq. 7.11 with k1 = 0.8 (high bond), k2 = 0.5 (bending);
  // eq. 7.14 when the bars are widely spaced.
  final srMax = spacing <= 5 * (cover + barDiameter / 2)
      ? 3.4 * cover + 0.425 * 0.8 * 0.5 * barDiameter / rho
      : 1.3 * (h - x);
  return CrackWidth(srMax, strain, srMax * strain);
}

void requireCrackLimit(double w) => requireRange(w, 0.1, 0.5, 'crackLimit');
