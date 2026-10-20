import 'dart:math';

/// Advanced structural analysis for complex scenarios
class AdvancedAnalysis {
  // ============ SEISMIC ANALYSIS (Eurocode 8) ============

  static Map<String, dynamic> calculateBaseShear({
    required double buildingMass, // tonnes
    required double peakGroundAcceleration, // ag in g
    required double soilFactor, // S (depends on soil type)
    required double damping, // typically 5%
  }) {
    const importanceFactor = 1.0; // Normal building
    const responseModificationFactor = 5.0; // RC moment frame

    // Seismic coefficient
    final c =
        peakGroundAcceleration *
        soilFactor *
        importanceFactor /
        responseModificationFactor;

    // Base shear (kN)
    final baseShear = (buildingMass * 9.81 * c) / 1000;

    return {
      'baseShear': baseShear,
      'seismicCoefficient': c,
      'responseModificationFactor': responseModificationFactor,
      'effectiveMass': buildingMass,
    };
  }

  /// Response spectrum analysis
  static Map<String, dynamic> responseSpectrumAnalysis({
    required double period, // seconds
    required double ag, // peak ground acceleration (g)
    required double soilType, // 1=A, 2=B, 3=C, 4=D, 5=E
    required double dampingRatio, // 5% default
  }) {
    const importanceFactor = 1.0;

    // Soil-dependent parameters
    final (sT, sB, sD) = _getSoilParameters(soilType);

    // Determine response spectrum ordinate
    double se;
    if (period <= sB) {
      se =
          ag *
          importanceFactor *
          (1 + (period / sB) * (2.5 / importanceFactor - 1));
    } else if (period <= sD) {
      se = ag * importanceFactor * 2.5;
    } else {
      se = ag * importanceFactor * 2.5 * pow(sD / period, 2).toDouble();
    }

    // Damping correction (for non-5%)
    final eta = sqrt(10 / (5 + dampingRatio));
    final correctedSe = se * eta;

    return {
      'spectralAcceleration': correctedSe,
      'period': period,
      'frequency': 1 / period,
      'dampingCorrection': eta,
      'soilCategory': _getSoilName(soilType),
    };
  }

  static (double, double, double) _getSoilParameters(double soilType) {
    // S=sT, Tb, Td
    switch (soilType.toInt()) {
      case 1: // A
        return (0.15, 0.20, 2.0);
      case 2: // B
        return (0.15, 0.35, 2.0);
      case 3: // C
        return (0.20, 0.60, 2.0);
      case 4: // D
        return (0.30, 0.80, 2.0);
      case 5: // E
        return (0.40, 1.50, 2.0);
      default:
        return (0.15, 0.35, 2.0);
    }
  }

  static String _getSoilName(double soilType) {
    switch (soilType.toInt()) {
      case 1:
        return 'Rock (A)';
      case 2:
        return 'Very stiff soil (B)';
      case 3:
        return 'Stiff soil (C)';
      case 4:
        return 'Medium-dense soil (D)';
      case 5:
        return 'Soft soil (E)';
      default:
        return 'Unknown';
    }
  }

  // ============ WIND LOAD ANALYSIS (Eurocode 1) ============

  static double calculateWindPressure({
    required double windSpeed, // m/s
    required double exposureCategory, // 1-4
    required double height, // m
  }) {
    // Base pressure: 0.5 * rho * v²
    const airDensity = 1.25; // kg/m³
    final basePressure = 0.5 * airDensity * windSpeed * windSpeed;

    // Exposure coefficient
    final ce = _getExposureCoefficient(exposureCategory, height);

    // Terrain coefficient
    const ct = 1.0;

    return (basePressure * ce * ct) / 1000; // Convert to kPa
  }

  static double _getExposureCoefficient(double category, double height) {
    // Simplified approach
    if (height < 5) return 0.5;
    if (height < 10) return 0.6;
    if (height < 25) return 0.75;
    return 1.0;
  }

  // ============ BEARING CAPACITY ANALYSIS ============

  /// Terzaghi bearing capacity formula
  static double calculateBearingCapacity({
    required double cohesion, // kPa
    required double internalFrictionAngle, // degrees
    required double unitWeight, // kN/m³
    required double footing, // m (width or diameter)
    required double depth, // m (depth of footing)
    String foundationType = 'strip', // strip, square, circular
  }) {
    final phi = internalFrictionAngle * pi / 180;
    final np = _calculateNp(phi);
    final nc = _calculateNc(phi);
    final nq = _calculateNq(phi);

    // Shape factors
    final (sc, sq, sg) = _getShapeFactors(foundationType, phi);

    // Depth factors
    final (kc, kq, kg) = _getDepthFactors(depth, footing, phi);

    // Inclination factors (assume vertical load)
    const ic = 1.0;
    const iq = 1.0;
    const ig = 1.0;

    // Bearing capacity
    final qc = cohesion * nc * sc * kc * ic;
    final qq = 0.5 * unitWeight * depth * nq * sq * kq * iq;
    final qg = 0.5 * unitWeight * footing * np * sg * kg * ig;

    return qc + qq + qg;
  }

  static double _calculateNc(double phi) {
    return (cos(phi) / sin(phi)) *
        (sin(45 * pi / 180 + phi / 2) / cos(45 * pi / 180 - phi / 2) - 1);
  }

  static double _calculateNq(double phi) {
    return sin(45 * pi / 180 + phi / 2) /
        cos(45 * pi / 180 - phi / 2) *
        exp(pi * tan(phi) * tan(45 * pi / 180 + phi / 2));
  }

  static double _calculateNp(double phi) {
    return (tan(phi) - 1) * exp(pi * tan(phi));
  }

  static (double, double, double) _getShapeFactors(String type, double phi) {
    switch (type) {
      case 'square':
        return (1.3, 1.0, 0.8);
      case 'circular':
        return (1.3, 1.0, 0.6);
      default: // strip
        return (1.0, 1.0, 1.0);
    }
  }

  static (double, double, double) _getDepthFactors(
    double d,
    double b,
    double phi,
  ) {
    final depthRatio = d / b;
    final kq = 1 + (depthRatio) * tan(phi);
    final kc = 1 + (depthRatio) * 0.4 * tan(phi);
    const kg = 1.0;

    return (kc.clamp(1.0, 2.0), kq.clamp(1.0, 2.0), kg);
  }

  // ============ SETTLEMENT CALCULATION ============

  static Map<String, dynamic> calculateSettlement({
    required double appliedPressure, // kPa
    required double footing, // m
    required double elasticModulus, // MPa
    required double poissonsRatio,
    required double depthOfLayer, // m
  }) {
    // Elastic settlement (immediate)
    final depthFactor = 1 - (0.5 * poissonsRatio);
    final immediateSettlement =
        (appliedPressure * footing * depthFactor) / elasticModulus;

    // Primary consolidation (simplified)
    final consolidationCoefficient = 0.5; // cm²/s (typical)
    final consolidationTime =
        (depthOfLayer * depthOfLayer) / consolidationCoefficient;

    return {
      'immediateSettlement': immediateSettlement,
      'consolidationTime': consolidationTime,
      'totalSettlement': immediateSettlement * 1.5, // Approximate
      'depthOfInfluence': depthOfLayer,
    };
  }

  // ============ LOAD COMBINATIONS ============

  /// Generate load combinations per Eurocode
  static List<Map<String, dynamic>> generateLoadCombinations({
    required double deadLoad, // kN
    required double liveLoad, // kN
    required double windLoad, // kN
    String code = 'eurocode',
  }) {
    final combinations = <Map<String, dynamic>>[];

    if (code == 'eurocode') {
      // ULS Combinations
      combinations.add({
        'name': 'EQU',
        'factored': (deadLoad * 0.9) + (windLoad * 1.5),
        'type': 'EQU',
        'description': '0.9G + 1.5W',
      });

      combinations.add({
        'name': 'STR A',
        'factored': (deadLoad * 1.35) + (liveLoad * 1.5),
        'type': 'STR',
        'description': '1.35G + 1.5Q',
      });

      combinations.add({
        'name': 'STR B',
        'factored': (deadLoad * 1.0) + (liveLoad * 1.5),
        'type': 'STR',
        'description': '1.0G + 1.5Q',
      });

      // SLS Combinations
      combinations.add({
        'name': 'SLS Frequent',
        'unfactored': deadLoad + (liveLoad * 0.4),
        'type': 'SLS',
        'description': 'G + 0.4Q',
      });
    } else if (code == 'bael99') {
      combinations.add({
        'name': 'BAEL ULS',
        'factored': (deadLoad * 1.35) + (liveLoad * 1.5),
        'type': 'ULS',
        'description': '1.35G + 1.5Q',
      });

      combinations.add({
        'name': 'BAEL SLS',
        'unfactored': deadLoad + liveLoad,
        'type': 'SLS',
        'description': 'G + Q',
      });
    }

    return combinations;
  }

  // ============ INTERACTION DIAGRAMS ============

  /// Calculate column interaction diagram points
  static List<Map<String, double>> calculateInteractionDiagram({
    required double columnWidth, // mm
    required double columnDepth, // mm
    required double concreteStrength, // MPa
    required double steelStrength, // MPa
    required double steelPercentage, // %
  }) {
    final points = <Map<String, double>>[];
    final fc = concreteStrength;
    final fy = steelStrength;

    // Gross area
    final ag = columnWidth * columnDepth;
    final as = (steelPercentage / 100) * ag;
    const ec = 0.003; // Concrete strain at failure

    // Pure compression point
    final pn0 = 0.85 * fc * (ag - as) + fy * as;
    points.add({'eccentricity': 0, 'axialLoad': pn0 / 1000});

    // Generate interaction points
    for (int i = 1; i <= 9; i++) {
      final c = (columnDepth / 10) * i; // Neutral axis depth
      final strain = ec * (c - columnDepth / 2) / c;
      final fs = min(fy, strain * 200000); // Stress in steel

      final cc = 0.85 * fc * columnWidth * c;
      final cs = fs * as;
      final pni = cc + cs;

      final m = pni * (columnDepth / 2 - c) / 1e6; // Convert to kN.m

      points.add({'eccentricity': m / (pni / 1000), 'axialLoad': pni / 1000});
    }

    // Pure bending point
    final mb = steelStrength * as * (0.87 * columnDepth) / 1e6;
    points.add({'eccentricity': mb / 0.001, 'axialLoad': 0});

    return points;
  }

  // ============ MATERIAL TAKEOFF ============

  static Map<String, dynamic> calculateMaterialTakeoff({
    required double concreteVolume, // m³
    required double concreteStrength, // fck MPa
    required double steelQuantity, // tonnes
    required double steelGrade, // 250, 500, etc
    required double formworkArea, // m²
  }) {
    // Concrete composition (per m³)
    final cement = concreteVolume * 360; // kg (for fck 30)
    final sand = concreteVolume * 570; // kg
    final aggregate = concreteVolume * 1200; // kg
    final water = concreteVolume * 180; // liters

    return {
      'concrete': {
        'volume': concreteVolume,
        'strength': concreteStrength,
        'cement': cement,
        'sand': sand,
        'aggregate': aggregate,
        'water': water,
      },
      'steel': {
        'quantity': steelQuantity,
        'grade': steelGrade,
        'cost': steelQuantity * 50000, // Approximate
      },
      'formwork': {
        'area': formworkArea,
        'quantity': (formworkArea / 2.4).ceil(), // 2.4m² per sheet
      },
      'labor': {
        'concreteHours': concreteVolume * 8,
        'steelHours': steelQuantity * 20,
        'formworkHours': formworkArea * 1.5,
      },
    };
  }
}

/// Unit conversion utilities
class UnitConverter {
  static const kpaToBar = 0.01;
  static const kpaToAtm = 0.0098692;
  static const mpaToMpg = 145.038;
  static const knToLbf = 224.809;

  static double convertPressure(double value, String from, String to) {
    final inKpa = _toPressure(value, from);
    return _fromPressure(inKpa, to);
  }

  static double _toPressure(double value, String unit) {
    switch (unit.toLowerCase()) {
      case 'kpa':
        return value;
      case 'bar':
        return value / kpaToBar;
      case 'atm':
        return value / kpaToAtm;
      case 'mpa':
        return value * 1000;
      default:
        return value;
    }
  }

  static double _fromPressure(double kpa, String unit) {
    switch (unit.toLowerCase()) {
      case 'kpa':
        return kpa;
      case 'bar':
        return kpa * kpaToBar;
      case 'atm':
        return kpa * kpaToAtm;
      case 'mpa':
        return kpa / 1000;
      default:
        return kpa;
    }
  }

  static double convertLength(double value, String from, String to) {
    final inMeter = _toLength(value, from);
    return _fromLength(inMeter, to);
  }

  static double _toLength(double value, String unit) {
    switch (unit.toLowerCase()) {
      case 'mm':
        return value / 1000;
      case 'cm':
        return value / 100;
      case 'm':
        return value;
      case 'km':
        return value * 1000;
      case 'ft':
        return value * 0.3048;
      case 'in':
        return value * 0.0254;
      default:
        return value;
    }
  }

  static double _fromLength(double meter, String unit) {
    switch (unit.toLowerCase()) {
      case 'mm':
        return meter * 1000;
      case 'cm':
        return meter * 100;
      case 'm':
        return meter;
      case 'km':
        return meter / 1000;
      case 'ft':
        return meter / 0.3048;
      case 'in':
        return meter / 0.0254;
      default:
        return meter;
    }
  }

  static double convertForce(double value, String from, String to) {
    final inKn = _toForce(value, from);
    return _fromForce(inKn, to);
  }

  static double _toForce(double value, String unit) {
    switch (unit.toLowerCase()) {
      case 'kn':
        return value;
      case 'n':
        return value / 1000;
      case 'lbf':
        return value / knToLbf;
      case 'tonf':
        return value * 9.81;
      case 'kgf':
        return value * 0.00981;
      default:
        return value;
    }
  }

  static double _fromForce(double kn, String unit) {
    switch (unit.toLowerCase()) {
      case 'kn':
        return kn;
      case 'n':
        return kn * 1000;
      case 'lbf':
        return kn * knToLbf;
      case 'tonf':
        return kn / 9.81;
      case 'kgf':
        return kn / 0.00981;
      default:
        return kn;
    }
  }
}
