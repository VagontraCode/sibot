import 'dart:math';

class GeotechnicalAnalysis {
  static Map<String, dynamic> soilBearingCapacityAnalysis({
    required double soilCohesion, // kPa
    required double frictionAngle, // degrees
    required double unitWeight, // kN/m³
    required double footing, // m (width)
    required double depth, // m
    required double loadEccentricity, // m
    String foundationType = 'strip',
  }) {
    final phi = frictionAngle * pi / 180;

    // Bearing capacity factors
    final np = (tan(phi) - 1) * exp(pi * tan(phi));
    final nc = (cos(phi) / sin(phi)) * (exp(pi * tan(phi)) - 1);
    final nq = exp(pi * tan(phi)) * tan(45 * pi / 180 + phi / 2);

    // Inclination factors (assuming vertical load)
    const ic = 1.0;
    const iq = 1.0;
    const ig = 1.0;

    // Shape factors
    final sc = 1 + (nq / nc) * (footing / footing); // L=B for square
    final sq = 1 + (footing / footing) * tan(phi);
    final sg = 1 - 0.4 * (footing / footing);

    // Depth factors
    final kc = 1 + (depth / footing) * 0.4 * tan(phi);
    final kq = 1 + (depth / footing) * tan(phi);
    const kg = 1.0;

    // Calculate bearing capacity
    final qc = soilCohesion * nc * sc * kc * ic;
    final qq = 0.5 * unitWeight * depth * nq * sq * kq * iq;
    final qg = 0.5 * unitWeight * footing * np * sg * kg * ig; // put np was ng

    final qu = qc + qq + qg;

    // Apply eccentricity correction
    final effectiveLength = footing - 2 * loadEccentricity;
    final quEffective = qu * (effectiveLength / footing);

    return {
      'soilCohesion': soilCohesion,
      'frictionAngle': frictionAngle,
      'bearingCapacityUltimate': qu,
      'effectiveBearingCapacity': quEffective,
      'safetyFactor': qu / (quEffective * 1.5),
      'eccentricityEffect': effectiveLength / footing,
    };
  }

  static Map<String, dynamic> calculateSoilSettlement({
    required double appliedLoad, // kN
    required double footingArea, // m²
    required double elasticModulus, // MPa
    required double poissonsRatio,
    required double depthOfInfluence, // m
  }) {
    final pressure = appliedLoad / footingArea;
    final rigidity = elasticModulus / (1 - poissonsRatio * poissonsRatio);

    // Elastic settlement (Boussinesq)
    final elasticSettlement = (pressure * sqrt(footingArea)) / rigidity;

    // Consolidation settlement (approximate)
    final consolidationSettlement = elasticSettlement * 0.5;

    return {
      'pressure': pressure,
      'elasticSettlement': elasticSettlement,
      'consolidationSettlement': consolidationSettlement,
      'totalSettlement': elasticSettlement + consolidationSettlement,
      'allowableSettlement': 50, // mm (typical)
      'isSafe': (elasticSettlement + consolidationSettlement) < 50,
    };
  }
}
