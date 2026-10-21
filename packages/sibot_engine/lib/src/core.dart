/// Shared types for design calculations.
///
/// Units used throughout the engine unless a name says otherwise:
///   forces kN, moments kN·m, distributed loads kN/m or kN/m²,
///   spans and plan dimensions m, section dimensions mm,
///   stresses MPa (= N/mm²), steel areas mm².
library;

enum DesignCode {
  /// EN 1992-1-1 with recommended values (αcc = 1.0, γc = 1.5, γs = 1.15).
  ec2,

  /// BAEL 91 révisé 99 (γb = 1.5, θ = 1, γs = 1.15).
  bael,
}

/// What a check verifies; the UI maps each kind to a translated label.
enum CheckKind {
  bendingSteel,
  minSteel,
  maxSteel,
  barSpacing,
  shearCrushing,
  shearLinks,
  linkSpacing,
  deflection,
  concreteStress,
  steelStress,
  crackWidth,
  slenderness,
  axialBending,
  bearingPressure,
  punching,
  overturning,
  sliding,
  baseEccentricity,
  steelTension,
  steelCompression,
  steelBending,
  steelShear,
  steelCombined,
  flexuralBucklingY,
  flexuralBucklingZ,
  lateralTorsional,
  bucklingInteractionY,
  bucklingInteractionZ,
  combinedStress,
  deflectionInstant,
  deflectionFinal,
}

/// One design check: [demand] must not exceed [capacity].
class Check {
  final CheckKind kind;
  final double demand;
  final double capacity;

  /// Clause reference in the selected code, e.g. "EN 1992-1-1 6.2.3".
  final String clause;

  /// Unit shared by demand and capacity (empty when dimensionless).
  final String unit;

  const Check({
    required this.kind,
    required this.demand,
    required this.capacity,
    required this.clause,
    this.unit = '',
  });

  double get ratio => capacity <= 0 ? double.infinity : demand / capacity;

  bool get ok => demand <= capacity * (1 + 1e-9);

  @override
  String toString() =>
      '$kind: ${demand.toStringAsFixed(3)} / ${capacity.toStringAsFixed(3)} $unit '
      '(${ok ? 'OK' : 'FAIL'}) [$clause]';
}

/// Thrown for inputs a calculation cannot accept. [field] names the input.
class InputError implements Exception {
  final InputProblem problem;
  final String field;
  const InputError(this.problem, this.field);

  @override
  String toString() => 'InputError($problem, $field)';
}

enum InputProblem {
  /// Value must be strictly positive.
  notPositive,

  /// Value is outside the range the method covers.
  outOfRange,

  /// Geometry is inconsistent (e.g. cover leaves no effective depth).
  inconsistentGeometry,
}

void requirePositive(double v, String field) {
  if (!(v > 0) || v.isInfinite) {
    throw InputError(InputProblem.notPositive, field);
  }
}

void requireRange(double v, double min, double max, String field) {
  if (v.isNaN || v < min || v > max) {
    throw InputError(InputProblem.outOfRange, field);
  }
}
