import 'dart:math' as math;

import 'core.dart';
import 'materials.dart';
import 'rebar.dart';

/// Vertical two-leg links at a spacing.
class Links {
  final int diameter;
  final int legs;

  /// Spacing, mm.
  final int spacing;

  const Links(this.diameter, this.spacing, {this.legs = 2});

  /// Asw / s provided, mm²/mm.
  double get aswPerS => legs * barArea(diameter) / spacing;

  @override
  String toString() => '${legs}x Ø$diameter @ $spacing';
}

class ShearDesign {
  /// Shear resistance without links (EC2 VRd,c), kN. Null for BAEL.
  final double? vRdc;

  /// Crushing check: demand and capacity in kN (EC2: VEd vs VRd,max) or
  /// MPa (BAEL: τu vs τlim).
  final Check crushing;

  /// Required Asw/s, mm²/mm (already including the minimum).
  final double aswPerSRequired;

  /// Maximum link spacing, mm.
  final double maxSpacing;

  /// cot θ used (EC2 only).
  final double? cotTheta;

  final Links? links;

  const ShearDesign({
    required this.vRdc,
    required this.crushing,
    required this.aswPerSRequired,
    required this.maxSpacing,
    required this.cotTheta,
    required this.links,
  });
}

/// Designs vertical links for shear [vEd] (kN) on a b × d section (mm).
/// [rhoL] is the provided tension steel ratio As/(b·d).
ShearDesign designShear({
  required DesignCode code,
  required Concrete concrete,
  required RebarSteel steel,
  required double vEd,
  required double b,
  required double d,
  required double rhoL,
  int maxLinkDiameter = 12,
}) {
  requirePositive(b, 'b');
  requirePositive(d, 'd');
  final v = vEd.abs() * 1e3; // N
  final fyk = steel.fyk;
  final fywd = steel.fyd;

  late final double required;
  late final double sMax;
  late final Check crushing;
  double? vRdc;
  double? cotTheta;

  switch (code) {
    case DesignCode.ec2:
      // 6.2.2(1): members without shear reinforcement.
      final fck = concrete.fck;
      final k = math.min(1 + math.sqrt(200 / d), 2.0);
      final rho = math.min(rhoL, 0.02);
      const cRdc = 0.18 / Concrete.gammaC;
      final vMin = 0.035 * math.pow(k, 1.5) * math.sqrt(fck);
      final vc = math.max(cRdc * k * math.pow(100 * rho * fck, 1 / 3), vMin);
      vRdc = vc * b * d / 1e3;

      // 6.2.3: variable strut inclination, 1 ≤ cot θ ≤ 2.5.
      final z = 0.9 * d;
      final nu1 = 0.6 * (1 - fck / 250);
      final strut = b * z * nu1 * concrete.fcd; // N, times sinθ·cosθ
      double vRdMax(double cot) => strut / (cot + 1 / cot);
      if (v <= vRdMax(2.5)) {
        cotTheta = 2.5;
      } else {
        final s2t = 2 * v / strut; // sin 2θ
        cotTheta = s2t >= 1 ? 1.0 : 1 / math.tan(0.5 * math.asin(s2t));
        cotTheta = cotTheta.clamp(1.0, 2.5);
      }
      crushing = Check(
        kind: CheckKind.shearCrushing,
        demand: v / 1e3,
        capacity: vRdMax(cotTheta) / 1e3,
        clause: 'EN 1992-1-1 6.2.3(3)',
        unit: 'kN',
      );
      final forShear = v > vRdc * 1e3 ? v / (z * fywd * cotTheta) : 0.0;
      // 9.2.2(5): ρw,min = 0.08·√fck / fyk.
      final minimum = 0.08 * math.sqrt(fck) / fyk * b;
      required = math.max(forShear, minimum);
      sMax = 0.75 * d; // 9.2.2(6), vertical links
    case DesignCode.bael:
      // A.5.1.1 and A.5.1.211: straight links, fissuration peu préjudiciable.
      final tauU = v / (b * d);
      final tauLim = math.min(0.20 * concrete.fck / Concrete.gammaC, 5.0);
      crushing = Check(
        kind: CheckKind.shearCrushing,
        demand: tauU,
        capacity: tauLim,
        clause: 'BAEL A.5.1.211',
        unit: 'MPa',
      );
      // A.5.1.23 with k = 1, α = 90°.
      final ft28 = concrete.fctm;
      final forShear = math.max(
        0.0,
        b * RebarSteel.gammaS * (tauU - 0.3 * ft28) / (0.9 * fyk),
      );
      // A.5.1.22: At·fe / (b0·st) ≥ 0.4 MPa.
      final minimum = 0.4 * b / fyk;
      required = math.max(forShear, minimum);
      sMax = math.min(0.9 * d, 400); // A.5.1.22
  }

  return ShearDesign(
    vRdc: vRdc,
    crushing: crushing,
    aswPerSRequired: required,
    maxSpacing: sMax,
    cotTheta: cotTheta,
    links: chooseLinks(required, sMax, maxDiameter: maxLinkDiameter),
  );
}

/// Smallest two-leg link diameter whose spacing (multiple of 25 mm,
/// ≥ 75 mm) satisfies [aswPerS] and [maxSpacing].
Links? chooseLinks(double aswPerS, double maxSpacing, {int maxDiameter = 12}) {
  for (final d in const [6, 8, 10, 12]) {
    if (d > maxDiameter) break;
    final raw = 2 * barArea(d) / aswPerS;
    final s = (math.min(raw, maxSpacing) / 25).floor() * 25;
    if (s >= 75) return Links(d, s);
  }
  return null;
}
