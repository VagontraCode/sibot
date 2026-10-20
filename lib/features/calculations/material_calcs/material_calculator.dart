import 'dart:math';

class MaterialCalculator {
  static Map<String, dynamic> calculateConcreteVolume({
    required double length, // m
    required double width, // m
    required double height, // m
    String shape = 'rectangular',
  }) {
    double volume = 0;

    if (shape == 'rectangular') {
      volume = length * width * height;
    } else if (shape == 'circular') {
      final radius = length / 2; // diameter = length
      volume = pi * radius * radius * height;
    }

    // Material composition per m³
    const cement = 360; // kg
    const sand = 570; // kg
    const aggregate = 1200; // kg
    const water = 180; // liters

    return {
      'volume': volume,
      'cement': volume * cement,
      'sand': volume * sand,
      'aggregate': volume * aggregate,
      'water': volume * water,
      'totalWeight': volume * (cement + sand + aggregate) / 1000,
    };
  }

  static Map<String, dynamic> calculateRebarWeight({
    required int numberOfBars,
    required double barDiameter, // mm
    required double barLength, // m
    required String barGrade, // 250, 500, etc
  }) {
    // Standard density of reinforcing steel: 7850 kg/m³
    const double steelDensity = 7850.0;

    // Convert diameter to meters for consistent SI calculations
    final double diameterInMeters = barDiameter / 1000;

    // Cross-sectional area (A = πd²/4) in m²
    final double barArea = (pi * pow(diameterInMeters, 2)) / 4;

    // Weight of a single bar (W = Volume * Density = Area * Length * Density) in kg
    final double weightPerBar = barArea * barLength * steelDensity;

    final double totalWeight = numberOfBars * weightPerBar;
    final double weightPerMeter = weightPerBar / barLength;

    return {
      'numberOfBars': numberOfBars,
      'diameter': barDiameter,
      'length': barLength,
      'weightPerBar': weightPerBar,
      'totalWeight': totalWeight,
      'weightPerMeter': weightPerMeter,
      'grade': barGrade,
    };
  }

  static double calculateRebarWeightStandard(
    double diameter, // mm
    double length, // m
  ) {
    // Standard formula: weight = (D² × L) / 162
    // where D is diameter in mm, L is length in m
    return (diameter * diameter * length) / 162;
  }
}
