import 'dart:math' as math;

import 'bearing.dart';
import 'core.dart';

/// Bearing resistance and settlement of a rectangular shallow footing
/// B × L (m, B ≤ L) under a centred vertical load.
class ShallowFoundationInput {
  final double b;
  final double l;
  final double depth;

  /// Characteristic permanent and variable vertical loads (kN), including
  /// the footing and backfill.
  final double g;
  final double q;

  final Soil soil;

  /// Soil Young's modulus (MPa) and Poisson's ratio for settlement.
  final double youngModulus;
  final double poisson;

  const ShallowFoundationInput({
    required this.b,
    required this.l,
    required this.depth,
    required this.g,
    required this.q,
    required this.soil,
    this.youngModulus = 20,
    this.poisson = 0.3,
  });
}

class ShallowFoundationDesign {
  final ShallowFoundationInput input;
  final BearingFactors? factors;

  /// Ultimate bearing pressure (kPa), design resistance pressure
  /// qult/γR,v (kPa) and design pressure Vd/A (kPa).
  final double qUlt;
  final double qRd;
  final double qEd;

  /// Mean SLS pressure (kPa) and elastic settlement estimate (mm).
  final double qSls;
  final double settlement;

  final List<Check> checks;

  const ShallowFoundationDesign({
    required this.input,
    required this.factors,
    required this.qUlt,
    required this.qRd,
    required this.qEd,
    required this.qSls,
    required this.settlement,
    required this.checks,
  });

  bool get ok => checks.every((c) => c.ok);
}

ShallowFoundationDesign designShallowFoundation(ShallowFoundationInput i) {
  requirePositive(i.b, 'b');
  requirePositive(i.l, 'l');
  requireRange(i.depth, 0, 20, 'depth');
  requirePositive(i.g + i.q, 'g');
  requirePositive(i.youngModulus, 'youngModulus');
  requireRange(i.poisson, 0, 0.5, 'poisson');
  final b = math.min(i.b, i.l), l = math.max(i.b, i.l);
  final qUlt = ultimateBearingPressure(
    i.soil,
    bEff: b,
    lEff: l,
    depth: i.depth,
  );
  final qRd = qUlt / gammaRv;
  final area = b * l;
  final qEd = (1.35 * i.g + 1.5 * i.q) / area;
  final qSls = (i.g + i.q) / area;

  // Rigid footing on an elastic half-space, equivalent circle of the same
  // area: s = (π/2)·q·a·(1 − ν²)/E (EN 1997-1 Annex F.2 adjusted
  // elasticity method; an estimate only).
  final a = math.sqrt(area / math.pi);
  final settlement =
      math.pi /
      2 *
      qSls *
      a *
      (1 - i.poisson * i.poisson) /
      (i.youngModulus * 1e3);

  return ShallowFoundationDesign(
    input: i,
    factors: i.soil.undrained ? null : bearingFactors(i.soil.phi),
    qUlt: qUlt,
    qRd: qRd,
    qEd: qEd,
    qSls: qSls,
    settlement: settlement * 1000,
    checks: [
      Check(
        kind: CheckKind.bearingPressure,
        demand: qEd,
        capacity: qRd,
        clause: 'EN 1997-1 Annex D, DA2',
        unit: 'kPa',
      ),
    ],
  );
}
