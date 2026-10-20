class StructureAnalysisEngine {
  /// Frame analysis with nodal forces
  static Map<String, dynamic> analyzePortalFrame({
    required double height, // m
    required double span, // m
    required double distributedLoad, // kN/m
    required List<double> columnEI, // Stiffness
    required List<double> beamEI,
  }) {
    // Simplified portal frame analysis (2D)
    final w = distributedLoad;

    // Fixed end moments
    final fem = (w * span * span) / 12;

    // Moment distribution for symmetric loading
    final midSpanMoment = (w * span * span) / 8;
    final columnMoment = fem / 2;

    // Shear forces
    final beamShear = (w * span) / 2;
    final reactionForce = beamShear;

    return {
      'fixedEndMoments': fem,
      'midSpanMoment': midSpanMoment,
      'columnMoments': columnMoment,
      'beamShears': beamShear,
      'reactions': reactionForce,
      'deflection': _calculateFrameDeflection(
        distributedLoad,
        span,
        columnEI,
        height,
      ),
    };
  }

  static double _calculateFrameDeflection(
    double load,
    double span,
    List<double> ei,
    double height,
  ) {
    // Simplified beam deflection
    return (5 * load * span * span * span * span) / (384 * ei[0]);
  }

  /// Load distribution in multi-bay frames
  static Map<String, dynamic> distributeLoadMultiBay({
    required double totalLoad, // kN
    required int numberOfBays,
    required List<double> bayWidths, // m
    required List<double> columnStiffness,
  }) {
    final totalWidth = bayWidths.reduce((a, b) => a + b);
    final distribution = <String, dynamic>{};

    for (int i = 0; i < numberOfBays; i++) {
      final bayLoad = totalLoad * (bayWidths[i] / totalWidth);
      distribution['bay_${i + 1}'] = {
        'width': bayWidths[i],
        'load': bayLoad,
        'stiffnessContribution':
            columnStiffness[i] / columnStiffness.reduce((a, b) => a + b),
      };
    }

    return distribution;
  }
}
