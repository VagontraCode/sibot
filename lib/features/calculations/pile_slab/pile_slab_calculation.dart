import 'dart:math';

class PileSlabCalculation {
  static Map<String, dynamic> designPileSlab({
    required double slabLoad, // kN/m²
    required double pileCapacity, // kN per pile
    required double pileSpacing, // m
    required double slabThickness, // mm
    required double concreteStrength, // MPa
  }) {
    // Calculate number of piles required
    final areaPerPile = pileSpacing * pileSpacing;
    final loadPerPile = slabLoad * areaPerPile;
    final pilesRequired = (loadPerPile / pileCapacity).ceil();

    // Design pile cap thickness
    final capThickness = _calculateCapThickness(pileSpacing, loadPerPile);

    // Punching shear check
    final punchingShearCheck = _checkPunchingShear(
      loadPerPile,
      pileSpacing,
      capThickness,
      concreteStrength,
    );

    // Moment distribution (simplified)
    final moment = (slabLoad * pileSpacing * pileSpacing) / 8;

    return {
      'pilesRequired': pilesRequired,
      'areaPerPile': areaPerPile,
      'loadPerPile': loadPerPile,
      'capThickness': capThickness,
      'punchingShearSafe': punchingShearCheck['isSafe'],
      'criticalMoment': moment,
      'reinforcementRequired': _calculateReinforcementForPileSlab(
        moment,
        concreteStrength,
      ),
    };
  }

  static double _calculateCapThickness(double spacing, double load) {
    // Empirical formula for pile cap thickness
    final baseThickness = spacing * 0.4;
    return (baseThickness / 50).ceilToDouble() * 50; // Round to 50mm
  }

  static Map<String, dynamic> _checkPunchingShear(
    double load,
    double pileSpacing,
    double thickness,
    double fc,
  ) {
    final perimeter = 4 * sqrt(load / (fc / 10));
    final vd = load * 1000;
    final vc = 0.79 * sqrt(fc) * perimeter * thickness;

    return {'isSafe': vd < vc, 'vd': vd, 'vc': vc, 'utilizationRatio': vd / vc};
  }

  static double _calculateReinforcementForPileSlab(
    double moment,
    double concreteStrength,
  ) {
    // Simplified steel area calculation
    return (moment * 1e6) / (0.87 * 500 * 400);
  }
}
