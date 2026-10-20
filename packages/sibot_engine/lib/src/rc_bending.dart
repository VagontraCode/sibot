import 'dart:math' as math;

import 'core.dart';
import 'materials.dart';

/// ULS bending design of a rectangular section using the rectangular
/// stress block over 0.8·x (EC2 3.1.7(3) with λ = 0.8, η = 1;
/// BAEL A.4.3.42 diagramme rectangulaire simplifié).
class BendingDesign {
  /// Reduced moment μ = M / (b·d²·fc).
  final double mu;

  /// Limit reduced moment beyond which compression steel is needed.
  final double muLim;

  /// Relative neutral-axis depth x/d (capped at the limit when
  /// compression steel is used).
  final double alpha;

  /// Lever arm, mm.
  final double z;

  /// Tension steel required, mm².
  final double asTension;

  /// Compression steel required, mm² (0 when μ ≤ μlim).
  final double asCompression;

  /// Stress in the compression steel, MPa.
  final double sigmaCompression;

  const BendingDesign({
    required this.mu,
    required this.muLim,
    required this.alpha,
    required this.z,
    required this.asTension,
    required this.asCompression,
    required this.sigmaCompression,
  });

  bool get needsCompressionSteel => asCompression > 0;
}

/// Limit relative neutral-axis depth for each code.
///
/// EC2: x/d ≤ 0.45 for fck ≤ 50 MPa (5.6.3(2), ductility without
/// redistribution). BAEL: αl = 3.5 / (3.5 + 1000·εl) so the tension steel
/// still yields (A.4.3.3, pivot B limit).
double alphaLimit(DesignCode code, RebarSteel steel) => switch (code) {
  DesignCode.ec2 => 0.45,
  DesignCode.bael => 3.5 / (3.5 + 1000 * steel.epsYd),
};

double _muFromAlpha(double a) => 0.8 * a * (1 - 0.4 * a);

/// Designs a rectangular section b × h with effective depth d and
/// compression-steel depth d2 (mm) for moment [mEd] (kN·m, ≥ 0).
BendingDesign designRectangularBending({
  required DesignCode code,
  required Concrete concrete,
  required RebarSteel steel,
  required double mEd,
  required double b,
  required double d,
  double d2 = 50,
}) {
  requirePositive(b, 'b');
  requirePositive(d, 'd');
  if (mEd < 0) throw const InputError(InputProblem.outOfRange, 'mEd');

  final fc = concrete.fBlock;
  final fyd = steel.fyd;
  final m = mEd * 1e6; // N·mm
  final mu = m / (b * d * d * fc);
  final aLim = alphaLimit(code, steel);
  final muLim = _muFromAlpha(aLim);

  if (mu <= muLim) {
    final alpha = 1.25 * (1 - math.sqrt(1 - 2 * mu));
    final z = d * (1 - 0.4 * alpha);
    return BendingDesign(
      mu: mu,
      muLim: muLim,
      alpha: alpha,
      z: z,
      asTension: m == 0 ? 0 : m / (z * fyd),
      asCompression: 0,
      sigmaCompression: 0,
    );
  }

  // Compression steel: the concrete carries the limit moment, the couple
  // As2 / extra As carries the rest.
  final x = aLim * d;
  final zLim = d * (1 - 0.4 * aLim);
  final mLim = muLim * b * d * d * fc;
  final epsSc = Concrete.epsCu * (x - d2) / x;
  final sigmaSc = math.min(fyd, RebarSteel.es * math.max(epsSc, 0));
  if (sigmaSc <= 0 || d2 >= d) {
    throw const InputError(InputProblem.inconsistentGeometry, 'd2');
  }
  final as2 = (m - mLim) / ((d - d2) * sigmaSc);
  final as1 = mLim / (zLim * fyd) + as2 * sigmaSc / fyd;
  return BendingDesign(
    mu: mu,
    muLim: muLim,
    alpha: aLim,
    z: zLim,
    asTension: as1,
    asCompression: as2,
    sigmaCompression: sigmaSc,
  );
}

/// Minimum tension reinforcement, mm².
/// EC2 9.2.1.1(1): max(0.26·fctm/fyk, 0.0013)·b·d.
/// BAEL A.4.2.1 (condition de non-fragilité): 0.23·b·d·ft28/fe.
double minTensionSteel({
  required DesignCode code,
  required Concrete concrete,
  required RebarSteel steel,
  required double b,
  required double d,
}) => switch (code) {
  DesignCode.ec2 => math.max(0.26 * concrete.fctm / steel.fyk, 0.0013) * b * d,
  DesignCode.bael => 0.23 * b * d * concrete.fctm / steel.fyk,
};

String bendingClause(DesignCode code) => switch (code) {
  DesignCode.ec2 => 'EN 1992-1-1 6.1',
  DesignCode.bael => 'BAEL A.4.3',
};

String minSteelClause(DesignCode code) => switch (code) {
  DesignCode.ec2 => 'EN 1992-1-1 9.2.1.1',
  DesignCode.bael => 'BAEL A.4.2',
};
