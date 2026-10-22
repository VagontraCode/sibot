import 'dart:math' as math;

import 'core.dart';

/// Masonry unit material and group (EN 1996-1-1 Table 3.3), with the K
/// constant for general purpose mortar and the final creep coefficient.
enum MasonryUnit {
  clayGroup1(0.55, 1.0),
  clayGroup2(0.45, 1.0),
  clayGroup3(0.35, 1.0),
  concreteGroup1(0.55, 1.0),
  concreteGroup2(0.52, 1.0),
  concreteGroup3(0.40, 1.0),
  calciumSilicateGroup1(0.55, 1.5),
  calciumSilicateGroup2(0.45, 1.5),
  aac(0.55, 1.0);

  final double k;
  final double creep;
  const MasonryUnit(this.k, this.creep);
}

/// Characteristic compressive strength, general purpose mortar (3.2).
double masonryFk(MasonryUnit unit, double fb, double fm) =>
    unit.k * math.pow(fb, 0.7) * math.pow(fm, 0.3);

/// Single-leaf wall under vertical load, EN 1996-1-1 6.1.2 and Annex G,
/// per metre length.
class MasonryWallInput {
  final MasonryUnit unit;

  /// Normalised unit strength and mortar strength, MPa.
  final double fb;
  final double fm;

  /// Wall thickness, mm, and clear storey height, m.
  final double t;
  final double height;

  /// Reduction factor ρn for the effective height (0.75 when both ends
  /// bear on concrete floors, 1.0 otherwise; lower with returns).
  final double rhoN;

  /// Design vertical load, kN/m.
  final double nEd;

  /// Load eccentricities at the top and the bottom of the wall from the
  /// floor loads, mm (same sign = single curvature).
  final double eTop;
  final double eBottom;

  final double gammaM;

  /// Cavity wall: thickness of the other (unloaded) leaf, mm (0 = single
  /// leaf). The loaded leaf is [t].
  final double otherLeaf;

  /// Lateral (wind) load on the wall, kPa, spanning vertically over the
  /// storey height.
  final double lateralLoad;

  /// Concentrated load (kN) on a bearing [bearingLength] × [bearingWidth]
  /// (mm) at [edgeDistance] (mm) from the end of the wall; 0 = none.
  final double concentratedLoad;
  final double bearingLength;
  final double bearingWidth;
  final double edgeDistance;

  const MasonryWallInput({
    required this.unit,
    required this.fb,
    required this.fm,
    required this.t,
    required this.height,
    required this.nEd,
    this.rhoN = 0.75,
    this.eTop = 0,
    this.eBottom = 0,
    this.gammaM = 2.5,
    this.otherLeaf = 0,
    this.lateralLoad = 0,
    this.concentratedLoad = 0,
    this.bearingLength = 0,
    this.bearingWidth = 0,
    this.edgeDistance = 0,
  });
}

class MasonryWallResult {
  final double fk;
  final double fd;
  final double hef;
  final double slenderness;
  final double eInit;

  /// Eccentricities at the ends and at mid-height (incl. creep), mm.
  final double eEnd;
  final double eMid;
  final double eCreep;

  final double phiEnd;
  final double phiMid;

  /// Design vertical resistance, kN/m.
  final double nRd;

  final List<Check> checks;
  bool get ok => checks.every((c) => c.ok);

  const MasonryWallResult({
    required this.fk,
    required this.fd,
    required this.hef,
    required this.slenderness,
    required this.eInit,
    required this.eEnd,
    required this.eMid,
    required this.eCreep,
    required this.phiEnd,
    required this.phiMid,
    required this.nRd,
    required this.checks,
  });
}

MasonryWallResult designMasonryWall(MasonryWallInput i) {
  requirePositive(i.fb, 'fb');
  requirePositive(i.fm, 'fm');
  requirePositive(i.t, 't');
  requirePositive(i.height, 'height');
  requirePositive(i.nEd, 'nEd');
  requireRange(i.rhoN, 0.3, 1.0, 'rhoN');
  requireRange(i.gammaM, 1.0, 3.5, 'gammaM');
  requireRange(i.fb, 0, 75, 'fb');
  // fm is limited to min(20 MPa, 2 fb) in (3.1).
  final fm = math.min(i.fm, math.min(20.0, 2 * i.fb));

  final fk = masonryFk(i.unit, i.fb, fm);
  final fd = fk / i.gammaM;
  final t = i.t;
  final hef = i.rhoN * i.height * 1e3;
  if (i.otherLeaf < 0) {
    throw const InputError(InputProblem.notPositive, 'otherLeaf');
  }
  if (i.lateralLoad < 0) {
    throw const InputError(InputProblem.notPositive, 'lateralLoad');
  }
  // Cavity walls: effective thickness (5.11) with ktef = 1.
  final tef = i.otherLeaf > 0
      ? math.pow(t * t * t + math.pow(i.otherLeaf, 3), 1 / 3).toDouble()
      : t;
  final slender = hef / tef;
  // Lateral load: mid-height moment of a vertical simple span (kN·m/m)
  // as an eccentricity ehm = M / N (6.1.2.2).
  final ehm = i.lateralLoad * i.height * i.height / 8 * 1e3 / i.nEd;
  final eInit = hef / 450;
  final eMin = 0.05 * t;

  // Ends (6.4, 6.5): Φi = 1 − 2 ei / t.
  final eEnd = math.max(math.max(i.eTop.abs(), i.eBottom.abs()) + eInit, eMin);
  final phiEnd = math.max(0.0, 1 - 2 * eEnd / t);

  // Mid-height: moment from the end eccentricities interpolated over the
  // middle fifth (≥ 0.4 of the larger end value), plus imperfection and
  // creep (6.6–6.8).
  final topLarger = i.eTop.abs() >= i.eBottom.abs();
  final e1 = topLarger ? i.eTop : i.eBottom;
  final e2 = topLarger ? i.eBottom : i.eTop;
  final eM0 = math.max((0.6 * e1 + 0.4 * e2).abs(), 0.4 * e1.abs());
  final em = eM0 + ehm + eInit;
  final eCreep = slender <= 15
      ? 0.0
      : 0.002 * i.unit.creep * slender * math.sqrt(tef * em);
  final eMid = math.max(em + eCreep, eMin);
  // Annex G with E = 1000 fk.
  final a1 = 1 - 2 * eMid / t;
  final lambda = slender * math.sqrt(1 / 1000);
  final u = (lambda - 0.063) / (0.73 - 1.17 * eMid / t);
  final phiMid = math.max(0.0, a1 * math.exp(-u * u / 2));

  final nRdEnd = phiEnd * t * fd;
  final nRdMid = phiMid * t * fd;
  final nRd = math.min(nRdEnd, nRdMid);

  const ref = 'EN 1996-1-1';

  // Concentrated load (6.1.3): NRdc = β Ab fd, the load spreading at 60°
  // to mid-height; Ab / Aef limited to 0.45.
  Check? concentrated;
  double? beta;
  if (i.concentratedLoad > 0) {
    requirePositive(i.bearingLength, 'bearingLength');
    requirePositive(i.bearingWidth, 'bearingWidth');
    if (i.bearingWidth > t) {
      throw const InputError(InputProblem.inconsistentGeometry, 'bearingWidth');
    }
    final hc = i.height * 1e3;
    final spread = hc / 2 / math.tan(math.pi / 3);
    final lefm = i.bearingLength + math.min(i.edgeDistance, spread) + spread;
    final ab = i.bearingLength * i.bearingWidth;
    final ratio = math.min(0.45, ab / (lefm * t));
    final b = (1 + 0.3 * i.edgeDistance / hc) * (1.5 - 1.1 * ratio);
    beta = b.clamp(1.0, math.min(1.25 + i.edgeDistance / (2 * hc), 1.5));
    concentrated = Check(
      kind: CheckKind.concentratedLoad,
      demand: i.concentratedLoad,
      capacity: beta * ab * fd / 1e3,
      clause: '$ref 6.1.3 (β = ${beta.toStringAsFixed(2)})',
      unit: 'kN',
    );
  }

  return MasonryWallResult(
    fk: fk,
    fd: fd,
    hef: hef / 1e3,
    slenderness: slender,
    eInit: eInit,
    eEnd: eEnd,
    eMid: eMid,
    eCreep: eCreep,
    phiEnd: phiEnd,
    phiMid: phiMid,
    nRd: nRd,
    checks: [
      Check(
        kind: CheckKind.slenderness,
        demand: slender,
        capacity: 27,
        clause: i.otherLeaf > 0 ? '$ref 5.5.1.4, tef 5.5.1.3' : '$ref 5.5.1.4',
      ),
      Check(
        kind: CheckKind.wallEnd,
        demand: i.nEd,
        capacity: nRdEnd,
        clause: '$ref 6.1.2.2 (6.4)',
        unit: 'kN/m',
      ),
      Check(
        kind: CheckKind.wallMid,
        demand: i.nEd,
        capacity: nRdMid,
        clause: '$ref 6.1.2.2, Annex G',
        unit: 'kN/m',
      ),
      ?concentrated,
    ],
  );
}
