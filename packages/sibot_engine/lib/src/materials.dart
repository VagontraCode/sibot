import 'dart:math' as math;

import 'core.dart';

/// Concrete design values for the selected code.
class Concrete {
  final DesignCode code;

  /// Characteristic compressive strength (EC2 fck, BAEL fc28), MPa.
  final double fck;

  Concrete(this.code, this.fck) {
    // EC2 rectangular block with λ = 0.8, η = 1 holds up to C50/60; BAEL
    // formulas are calibrated for ordinary concretes up to 60 MPa.
    requireRange(fck, 12, code == DesignCode.ec2 ? 50 : 60, 'fck');
  }

  static const gammaC = 1.5;

  /// Design stress of the rectangular block over 0.8·x, MPa.
  /// EC2 3.1.6 / 3.1.7: η·fcd with αcc = 1.0. BAEL A.4.3.41: fbu.
  double get fBlock => switch (code) {
    DesignCode.ec2 => fcd,
    DesignCode.bael => 0.85 * fck / gammaC,
  };

  /// EC2 design compressive strength fcd = αcc·fck/γc, MPa.
  double get fcd => 1.0 * fck / gammaC;

  /// Mean tensile strength, MPa. EC2 Table 3.1 fctm; BAEL A.2.1.12 ft28.
  double get fctm => switch (code) {
    DesignCode.ec2 => 0.30 * math.pow(fck, 2 / 3).toDouble(),
    DesignCode.bael => 0.6 + 0.06 * fck,
  };

  /// Secant modulus, MPa. EC2 Table 3.1 Ecm; BAEL A.2.1.21 Eij.
  double get ecm => switch (code) {
    DesignCode.ec2 => 22000 * math.pow((fck + 8) / 10, 0.3).toDouble(),
    DesignCode.bael => 11000 * math.pow(fck, 1 / 3).toDouble(),
  };

  /// Ultimate compressive strain (both codes 3.5‰).
  static const epsCu = 0.0035;
}

/// Reinforcing steel.
class RebarSteel {
  /// Characteristic yield strength (EC2 fyk, BAEL fe), MPa.
  final double fyk;

  RebarSteel(this.fyk) {
    requireRange(fyk, 200, 600, 'fyk');
  }

  static const gammaS = 1.15;
  static const es = 200000.0;

  /// Design yield strength fyd (EC2) = fsu (BAEL), MPa.
  double get fyd => fyk / gammaS;

  /// Design yield strain.
  double get epsYd => fyd / es;
}

/// Unit weight of reinforced concrete, kN/m³ (EN 1991-1-1 Table A.1).
const reinforcedConcreteWeight = 25.0;
