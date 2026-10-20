class LoadCalculator {
  /// EC1 Wind load calculation
  static Map<String, dynamic> calculateWindLoad({
    required double windSpeed, // m/s or km/h
    required double height, // m
    required double exposureCategory, // 1-4
    required double buildingWidth, // m
    required double buildingHeight, // m
    String standard = 'eurocode',
  }) {
    // Convert if needed (assuming m/s)
    final vb = windSpeed;

    // Exposure factors (simplified)
    final cz = _getExposureFactor(exposureCategory, height);

    // Turbulence factor
    const ct = 1.0;

    // Pressure coefficient (buildings typically -0.8 to +0.5)
    final cp = 0.8;

    // Peak velocity pressure
    final qb = 0.5 * 1.225 * vb * vb; // kPa (air density = 1.225 kg/m³)
    final qp = qb * cz * cz * ct;

    // Wind pressure
    final windPressure = qp * cp;

    // Total wind load on building
    final windLoadHorizontal = windPressure * buildingWidth * buildingHeight;

    return {
      'peakVelocity': vb,
      'peakPressure': qp,
      'windPressure': windPressure,
      'totalWindLoad': windLoadHorizontal,
      'exposureCategory': exposureCategory,
      'standard': standard,
    };
  }

  static double _getExposureFactor(double category, double height) {
    if (height < 5) return 0.5;
    if (height < 10) return 0.65;
    if (height < 20) return 0.8;
    return 1.0;
  }

  /// EC1 Snow load calculation
  static Map<String, dynamic> calculateSnowLoad({
    required double location, // altitude in m
    required double roofSlope, // degrees
    required double roofLength, // m
    required double roofWidth, // m
    String standard = 'eurocode',
  }) {
    // Ground snow load (example zones - should vary by region)
    final sk = _getGroundSnowLoad(location);

    // Roof shape coefficient
    final cs = _getRoofShapeCoefficient(roofSlope);

    // Exposure coefficient
    const ce = 1.0;

    // Thermal coefficient
    const ct = 1.0;

    // Design snow load
    final sd = sk * cs * ce * ct;

    // Total snow load on roof
    final totalSnowLoad = sd * roofLength * roofWidth / 1000;

    return {
      'groundSnowLoad': sk,
      'roofShapeCoefficient': cs,
      'designSnowLoad': sd,
      'totalSnowLoad': totalSnowLoad,
      'roofSlope': roofSlope,
      'location': location,
    };
  }

  static double _getGroundSnowLoad(double altitude) {
    // Simplified formula (varies by region)
    if (altitude < 100) return 0.5; // kPa
    if (altitude < 500) return 0.75;
    return 1.0 + (altitude - 500) / 1000 * 0.25;
  }

  static double _getRoofShapeCoefficient(double slope) {
    if (slope < 30) return 0.8;
    if (slope < 60) return 0.8 * (60 - slope) / 30;
    return 0;
  }
}
