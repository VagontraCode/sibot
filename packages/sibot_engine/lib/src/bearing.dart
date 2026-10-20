import 'dart:math' as math;

import 'core.dart';

/// Soil parameters for EN 1997-1 Annex D bearing resistance.
class Soil {
  /// Drained cohesion c′ (kPa) and friction angle φ′ (°).
  final double cohesion;
  final double phi;

  /// Unit weight γ (kN/m³).
  final double gamma;

  /// Undrained shear strength cu (kPa); when set, the undrained formula
  /// (D.3) is used instead of the drained one (D.4).
  final double? cu;

  const Soil({this.cohesion = 0, this.phi = 30, this.gamma = 18, this.cu});

  bool get undrained => cu != null;
}

/// Bearing capacity factors (EN 1997-1 D.4).
class BearingFactors {
  final double nq;
  final double nc;
  final double ngamma;
  const BearingFactors(this.nq, this.nc, this.ngamma);
}

BearingFactors bearingFactors(double phiDeg) {
  final phi = phiDeg * math.pi / 180;
  if (phiDeg == 0) return const BearingFactors(1, math.pi + 2, 0);
  final nq =
      math.exp(math.pi * math.tan(phi)) *
      math.pow(math.tan(math.pi / 4 + phi / 2), 2);
  final nc = (nq - 1) / math.tan(phi);
  final ng = 2 * (nq - 1) * math.tan(phi);
  return BearingFactors(nq, nc, ng);
}

/// Ultimate bearing pressure R/A′ (kPa) of a rectangular footing of
/// effective size B′ × L′ (m, B′ ≤ L′) founded at [depth] (m), vertical
/// load. Strip footings: pass a very long L′.
double ultimateBearingPressure(
  Soil s, {
  required double bEff,
  required double lEff,
  required double depth,
}) {
  requirePositive(bEff, 'bEff');
  requirePositive(lEff, 'lEff');
  final q = s.gamma * depth; // overburden at founding level
  final ratio = math.min(bEff / lEff, 1.0);
  if (s.undrained) {
    // D.3: (π + 2)·cu·sc + q, sc = 1 + 0.2·B′/L′.
    return (math.pi + 2) * s.cu! * (1 + 0.2 * ratio) + q;
  }
  requireRange(s.phi, 0, 45, 'phi');
  final f = bearingFactors(s.phi);
  final phi = s.phi * math.pi / 180;
  final sq = 1 + ratio * math.sin(phi);
  final sg = 1 - 0.3 * ratio;
  final sc = (sq * f.nq - 1) / (f.nq - 1);
  return s.cohesion * f.nc * sc +
      q * f.nq * sq +
      0.5 * s.gamma * bEff * f.ngamma * sg;
}

/// Partial factor on bearing resistance, design approach 2
/// (EN 1997-1 Table A.5, used in France by NF P94-261).
const gammaRv = 1.4;
