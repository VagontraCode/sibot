import 'dart:math';

/// Core structural calculation engine supporting Eurocode and BAEL 99
class CalculationEngine {
  // ============ FOOTING DESIGN ============

  /// Calculate required footing area (ISO/Eurocode method)
  static double calculateRequiredFootingArea({
    required double totalLoad, // kN
    required double soilBearingCapacity, // kPa
    required double safetyFactor, // typically 3.0
  }) {
    return (totalLoad * safetyFactor) / (soilBearingCapacity / 100);
  }

  /// Calculate footing dimensions for isolated rectangular footing
  static Map<String, double> calculateFootingDimensions({
    required double requiredArea, // m²
    required double lengthWidthRatio, // L/B ratio
  }) {
    final width = sqrt(requiredArea / lengthWidthRatio);
    final length = width * lengthWidthRatio;

    // Round to nearest 50mm
    final roundedWidth = (width * 20).ceilToDouble() / 20;
    final roundedLength = (length * 20).ceilToDouble() / 20;

    return {
      'width': roundedWidth,
      'length': roundedLength,
      'area': roundedWidth * roundedLength,
    };
  }

  /// Calculate footing depth for shear (Eurocode 2)
  static double calculateFootingDepthShear({
    required double shearForce, // kN
    required double effectiveWidth, // m
    required double concreteStrength, // MPa
    double vrdConstant = 0.5, // EC2: 0.5 for d ≤ 600mm
  }) {
    final vrd = vrdConstant * concreteStrength;
    return (shearForce * 1000) / (vrd * effectiveWidth * 1000);
  }

  /// Design reinforcement for footing (Eurocode 2)
  static Map<String, dynamic> designFootingReinforcement({
    required double bendingMoment, // kN.m
    required double concreteStrength, // fck in MPa
    required double steelStrength, // fy in MPa
    required double effectiveDepth, // mm
    required double width, // m
  }) {
    final d = effectiveDepth;
    final b = width * 1000; // convert to mm
    final m = bendingMoment * 1e6; // convert to N.mm

    // Lever arm (simplified approach)
    final la = 0.87 * steelStrength * d;
    final ast = m / la;

    // Percentage steel
    final pct = (ast / (b * d)) * 100;

    // Check minimum and maximum steel
    final minSteel = 0.12 * b * d / steelStrength;
    final maxSteel = 0.04 * b * d;

    return {
      'ast': max(ast, minSteel),
      'percentage': pct,
      'isValid': ast <= maxSteel,
      'barSize': _recommendBarSize(ast),
      'spacing': _calculateBarSpacing(b, ast),
    };
  }

  // ============ BEAM DESIGN ============

  /// Design beam flexural reinforcement (Eurocode 2)
  static Map<String, dynamic> designBeamFlexure({
    required double bendingMoment, // kN.m
    required double concreteStrength, // fck in MPa
    required double steelStrength, // fy in MPa
    required double effectiveDepth, // mm
    required double width, // mm
    double limitingRa = 0.48, // Limiting K value for EC2
  }) {
    final d = effectiveDepth;
    final b = width;
    final m = bendingMoment * 1e6; // N.mm

    // Calculate K
    final k = m / (b * d * d * concreteStrength);

    if (k > limitingRa) {
      return {
        'error': 'Section too small or moment too large',
        'k': k,
        'isValid': false,
      };
    }

    // Calculate lever arm
    final la = 0.5 + sqrt(0.25 - (k / 1.134));
    final z = min(0.95 * d, la * d);

    // Calculate steel area
    final ast = m / (0.87 * steelStrength * z);

    return {
      'ast': ast,
      'k': k,
      'z': z,
      'isValid': true,
      'barSize': _recommendBarSize(ast),
      'barNumber': _calculateBarNumber(ast),
    };
  }

  /// Design beam shear reinforcement
  static Map<String, dynamic> designBeamShear({
    required double shearForce, // kN
    required double concreteStrength, // fck in MPa
    required double steelStrength, // fy in MPa
    required double effectiveDepth, // mm
    required double width, // mm
  }) {
    final vc = 0.79 * sqrt(concreteStrength) * width * effectiveDepth / 1000;
    final vd = shearForce * 1000;

    final vsr = vd - vc;
    final asv = (vsr * 1000) / (0.87 * steelStrength * effectiveDepth);

    return {
      'vc': vc,
      'vd': vd,
      'vsr': vsr,
      'asv': asv,
      'needsShearLinks': vsr > 0,
      'stirrupSpacing': _calculateStirrupSpacing(asv, steelStrength),
    };
  }

  // ============ COLUMN DESIGN ============

  /// Design column for axial load (Eurocode 2)
  static Map<String, dynamic> designColumn({
    required double axialLoad, // kN
    required double concreteStrength, // fck in MPa
    required double steelStrength, // fy in MPa
    required double height, // m
    required double assumedPercentSteel, // typically 1-3%
  }) {
    const safetyFactor = 1.5;
    final designLoad = axialLoad * safetyFactor;

    // Assume circular column initially
    final requiredArea =
        (designLoad * 1000) /
        (0.4 * concreteStrength + (assumedPercentSteel / 100) * steelStrength);

    final diameter = sqrt(requiredArea * 4 / pi);

    // Slenderness check
    final slenderness = height * 1000 / diameter;

    return {
      'diameter': (diameter / 50).ceilToDouble() * 50, // Round to 50mm
      'requiredArea': requiredArea,
      'slenderness': slenderness,
      'isSlender': slenderness > 15,
      'areaRequired': requiredArea,
      'steel_percentage': assumedPercentSteel,
    };
  }

  // ============ SLAB DESIGN ============

  /// Design one-way slab (Eurocode 2)
  static Map<String, dynamic> designOneWaySlab({
    required double span, // m
    required double loadPerM2, // kN/m²
    required double concreteStrength, // fck in MPa
    required double steelStrength, // fy in MPa
  }) {
    const safetyFactor = 1.5;
    final designLoad = loadPerM2 * safetyFactor;

    final bendingMoment = (designLoad * span * span) / 8;

    // Effective depth estimate
    final estimatedD = span * 1000 / 25;

    return {
      'span': span,
      'designLoad': designLoad,
      'bendingMoment': bendingMoment,
      'estimatedDepth': estimatedD,
      'recommendedDepth': (estimatedD / 25).ceilToDouble() * 25,
      'ast_per_m': _calculateSlabSteel(
        bendingMoment,
        estimatedD,
        steelStrength,
      ),
    };
  }

  // ============ RETAINING WALL ============

  /// Calculate earth pressure coefficient
  static double calculateEarthPressureCoefficient(
    double internalFrictionAngle, {
    bool isActive = true,
  }) {
    final angle = internalFrictionAngle * pi / 180;
    if (isActive) {
      return pow(tan(pi / 4 - angle / 2), 2).toDouble();
    } else {
      return pow(tan(pi / 4 + angle / 2), 2).toDouble();
    }
  }

  /// Check overturning stability
  static Map<String, dynamic> checkOverturnStability({
    required double resistingMoment, // about toe
    required double overturningMoment, // about toe
    double safetyFactorMin = 2.0,
  }) {
    final fos = resistingMoment / overturningMoment;
    return {
      'fos': fos,
      'isSafe': fos >= safetyFactorMin,
      'safetyMargin': fos - safetyFactorMin,
    };
  }

  /// Check sliding stability
  static Map<String, dynamic> checkSlidingStability({
    required double verticalLoad, // kN
    required double horizontalLoad, // kN
    required double frictionCoefficient,
    double safetyFactorMin = 1.5,
  }) {
    final frictionForce = verticalLoad * frictionCoefficient;
    final fos = frictionForce / horizontalLoad;
    return {
      'fos': fos,
      'isSafe': fos >= safetyFactorMin,
      'frictionForce': frictionForce,
      'safetyMargin': fos - safetyFactorMin,
    };
  }

  // ============ HELPER METHODS ============

  static String _recommendBarSize(double ast) {
    if (ast < 100) return '8mm';
    if (ast < 200) return '10mm';
    if (ast < 350) return '12mm';
    if (ast < 500) return '16mm';
    return '20mm';
  }

  static double _calculateBarSpacing(double width, double ast) {
    const barDiameter = 12.0;
    const barArea = (pi * barDiameter * barDiameter) / 4;
    final numberBars = (ast / barArea).ceil();
    return width / (numberBars + 1);
  }

  static int _calculateBarNumber(double ast) {
    const standardBars = {
      '8mm': 50.27,
      '10mm': 78.54,
      '12mm': 113.10,
      '16mm': 201.06,
      '20mm': 314.16,
    };

    for (final entry in standardBars.entries) {
      final barArea = entry.value;
      final numberBars = (ast / barArea).ceil();
      if (numberBars <= 10) return numberBars;
    }
    return 0;
  }

  static double _calculateStirrupSpacing(double asv, double steelStrength) {
    return (0.87 * steelStrength * asv * 226) / 1000; // 8mm diameter assumed
  }

  static double _calculateSlabSteel(double moment, double d, double fy) {
    final la = 0.87 * fy * d;
    return (moment * 1e6) / la;
  }
}

/// Design suggestion engine
class SuggestionEngine {
  static Map<String, dynamic> suggestFooting({
    required double load, // kN
    required double soilBearing, // kPa
    String code = 'eurocode',
  }) {
    final safetyFactor = code == 'eurocode' ? 3.0 : 2.5;
    final area = CalculationEngine.calculateRequiredFootingArea(
      totalLoad: load,
      soilBearingCapacity: soilBearing,
      safetyFactor: safetyFactor,
    );

    return {
      'recommendedArea': area,
      'suggestedLength': (area * 1.5).toStringAsFixed(2),
      'suggestedWidth': (area / 1.5).toStringAsFixed(2),
      'depthEstimate': (sqrt(area) * 0.4).toStringAsFixed(2),
      'reasoning':
          'Based on soil bearing capacity with $safetyFactor safety factor',
      'standardDimensions': _standardFootingDimensions(area),
    };
  }

  static Map<String, dynamic> suggestBeam({
    required double span, // m
    required double load, // kN/m
    String code = 'eurocode',
  }) {
    final depthEstimate = span * 1000 / 12; // Common rule of thumb
    final widthEstimate = depthEstimate / 2;

    return {
      'estimatedDepth': depthEstimate.toStringAsFixed(0),
      'estimatedWidth': widthEstimate.toStringAsFixed(0),
      'spanDepthRatio': (span * 1000 / depthEstimate).toStringAsFixed(1),
      'reasoning': 'Based on span-to-depth ratio of 1:12',
      'standardSections': _standardBeamSections(depthEstimate),
    };
  }

  static List<Map<String, dynamic>> _standardFootingDimensions(double area) {
    return [
      {'length': 1.0, 'width': (area / 1.0).toStringAsFixed(2)},
      {'length': 1.5, 'width': (area / 1.5).toStringAsFixed(2)},
      {'length': 2.0, 'width': (area / 2.0).toStringAsFixed(2)},
    ];
  }

  static List<String> _standardBeamSections(double depth) {
    final sections = [200, 250, 300, 350, 400, 450, 500];
    return sections
        .where((d) => d >= depth * 0.9)
        .map((d) => '${d}x${(d ~/ 2)}')
        .toList();
  }

  static Map<String, dynamic> suggestRetainingWall(double height) {
    return {
      'cantilever': {
        'baseWidth': height * 0.6,
        'stemThickness': max(200.0, height * 1000 / 12), // mm
        'toeWidth': height * 0.2,
        'heelWidth': height * 0.4,
        'footingThickness': max(300.0, height * 1000 / 10), // mm
      },
      'alternatives': [
        {
          'type': 'Gabion Wall',
          'description': 'Stone-filled wire baskets. Flexible and permeable.',
          'recommendedBase': height * 0.7,
          'pros': 'Excellent drainage, easy to build, tolerates settlement.',
          'cons': 'Requires large excavation, wire mesh can corrode over time.',
        },
        {
          'type': 'Stone Masonry',
          'description': 'Traditional gravity wall using natural stone.',
          'recommendedBase': height * 0.5,
          'pros': 'Highly durable, aesthetic, local materials.',
          'cons': 'Labor intensive, requires skilled masonry.',
        },
        {
          'type': 'Reinforced Hollow Blocks',
          'description': 'Cement blocks with vertical rebar and concrete infill.',
          'recommendedBase': height * 0.45,
          'pros': 'Faster than traditional masonry, consistent quality.',
          'cons': 'Height limited (usually < 3m), requires precise rebar placement.',
        },
      ],
    };
  }
}
