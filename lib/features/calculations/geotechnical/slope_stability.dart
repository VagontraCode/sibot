import 'dart:math';

class SlopeStabilityAnalysis {
  /// Simple slope stability check (infinite slope method)
  static Map<String, dynamic> analyzeInfiniteSlope({
    required double slopeHeight, // m
    required double slopeAngle, // degrees
    required double cohesion, // kPa
    required double frictionAngle, // degrees
    required double unitWeight, // kN/m³
  }) {
    final theta = slopeAngle * pi / 180;
    final phi = frictionAngle * pi / 180;

    // Shear stress
    final tau = unitWeight * slopeHeight * sin(theta) * cos(theta);

    // Shear strength
    final sigma = unitWeight * slopeHeight * cos(theta) * cos(theta);
    final tf = cohesion + sigma * tan(phi);

    // Factor of safety
    final fs = tf / tau;

    return {
      'sloperHeight': slopeHeight,
      'slopeAngle': slopeAngle,
      'shearStress': tau,
      'shearStrength': tf,
      'factorOfSafety': fs,
      'isSafe': fs > 1.3, // Minimum FOS
      'criticalAngle': (frictionAngle * 180 / pi),
    };
  }

  /// Active earth pressure (Rankine)
  static Map<String, dynamic> calculateActiveEarthPressure({
    required double wallHeight, // m
    required double soilFrictionAngle, // degrees
    required double soilUnitWeight, // kN/m³
    required double soilCohesion, // kPa
    String state = 'active',
  }) {
    final phi = soilFrictionAngle * pi / 180;
    final ka = (1 - sin(phi)) / (1 + sin(phi));

    // Pressure at depth
    final pressureAtBase = soilUnitWeight * wallHeight * ka;

    // Total active force
    final totalForce = 0.5 * soilUnitWeight * wallHeight * wallHeight * ka;

    // Height of resultant
    final heightOfResultant = wallHeight / 3;

    return {
      'pressureAtBase': pressureAtBase,
      'totalActiveForce': totalForce,
      'heightOfResultant': heightOfResultant,
      'coefficientKa': ka,
      'state': state,
    };
  }
}
