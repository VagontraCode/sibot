import 'dart:math' as math;

import 'core.dart';
import 'materials.dart';
import 'rc_bending.dart';
import 'rebar.dart';

/// Cantilever retaining wall with a vertical back face, horizontal
/// backfill and a uniform surcharge. Stability uses Rankine active
/// pressure on the vertical plane through the heel and global factors
/// of safety of 1.5 (traditional method); the stem is designed at ULS.
class WallInput {
  final DesignCode code;

  /// Stem height above the base, base thickness, toe and heel lengths,
  /// stem thickness at top and bottom: all m.
  final double stemHeight;
  final double baseThickness;
  final double toe;
  final double heel;
  final double stemTop;
  final double stemBottom;

  /// Backfill unit weight (kN/m³), friction angle (°), surcharge (kPa).
  final double soilWeight;
  final double phi;
  final double surcharge;

  /// Base–soil friction angle (°); defaults to 2φ/3.
  final double? baseFriction;

  /// Allowable bearing pressure, kPa.
  final double qAllowable;

  final double fck;
  final double fyk;
  final double cover;

  const WallInput({
    required this.code,
    required this.stemHeight,
    required this.baseThickness,
    required this.toe,
    required this.heel,
    required this.stemTop,
    required this.stemBottom,
    required this.phi,
    required this.qAllowable,
    required this.fck,
    required this.fyk,
    this.soilWeight = 18,
    this.surcharge = 0,
    this.baseFriction,
    this.cover = 40,
  });

  double get baseWidth => toe + stemBottom + heel;
  double get totalHeight => stemHeight + baseThickness;
}

/// Pre-design of a cantilever wall for the stem height of [i].
///
/// Starts from typical proportions (base thickness and stem ≈ H/12, toe
/// ≈ B/4) and lengthens the heel in 50 mm steps until overturning,
/// sliding, eccentricity and bearing are satisfied, up to a base width of
/// 1.2 × the total height. Beyond that the last geometry is returned and
/// sliding usually needs a shear key.
WallInput presizeWall(WallInput i) {
  double up(double v) => (v * 20).ceil() / 20; // round up to 50 mm
  final h = i.stemHeight;
  final t = math.max(0.3, up(h / 12));
  final total = h + t;
  final stemBottom = math.max(0.25, up(h / 12));
  final toe = math.max(0.3, up(0.5 * total / 4));

  WallInput withHeel(double heel) => WallInput(
    code: i.code,
    stemHeight: h,
    baseThickness: t,
    toe: toe,
    heel: heel,
    stemTop: 0.2,
    stemBottom: stemBottom,
    phi: i.phi,
    // Bearing is only checked when an allowable pressure was given.
    qAllowable: i.qAllowable > 0 ? i.qAllowable : 1e9,
    fck: i.fck,
    fyk: i.fyk,
    soilWeight: i.soilWeight,
    surcharge: i.surcharge,
    baseFriction: i.baseFriction,
    cover: i.cover,
  );

  const stability = {
    CheckKind.overturning,
    CheckKind.sliding,
    CheckKind.baseEccentricity,
    CheckKind.bearingPressure,
  };
  var heel = math.max(0.3, up(0.5 * total - toe - stemBottom));
  while (true) {
    final trial = withHeel(heel);
    final stable = designWall(
      trial,
    ).checks.where((c) => stability.contains(c.kind)).every((c) => c.ok);
    if (stable || trial.baseWidth >= 1.2 * total) break;
    heel = ((heel + 0.05) * 20).round() / 20;
  }
  final result = withHeel(heel);
  return WallInput(
    code: result.code,
    stemHeight: result.stemHeight,
    baseThickness: result.baseThickness,
    toe: result.toe,
    heel: result.heel,
    stemTop: result.stemTop,
    stemBottom: result.stemBottom,
    phi: i.phi,
    qAllowable: i.qAllowable,
    fck: i.fck,
    fyk: i.fyk,
    soilWeight: i.soilWeight,
    surcharge: i.surcharge,
    baseFriction: i.baseFriction,
    cover: i.cover,
  );
}

class WallDesign {
  final WallInput input;
  final double ka;

  /// Horizontal thrusts from soil and surcharge, kN/m.
  final double thrustSoil;
  final double thrustSurcharge;

  /// Total vertical load for stability (no surcharge), kN/m.
  final double vertical;

  /// Overturning and resisting moments about the toe, kN·m/m.
  final double overturningMoment;
  final double resistingMoment;

  final double fsOverturning;
  final double fsSliding;

  /// Base eccentricity (m) and bearing pressure used in the check (kPa).
  final double eccentricity;
  final double pressure;
  final double pressureMax;
  final double pressureMin;

  /// Stem base: ULS moment, shear, effective depth, steel.
  final double stemMoment;
  final double stemShear;
  final double stemD;
  final double stemAs;
  final BarSpacing? stemBars;

  final List<Check> checks;

  const WallDesign({
    required this.input,
    required this.ka,
    required this.thrustSoil,
    required this.thrustSurcharge,
    required this.vertical,
    required this.overturningMoment,
    required this.resistingMoment,
    required this.fsOverturning,
    required this.fsSliding,
    required this.eccentricity,
    required this.pressure,
    required this.pressureMax,
    required this.pressureMin,
    required this.stemMoment,
    required this.stemShear,
    required this.stemD,
    required this.stemAs,
    required this.stemBars,
    required this.checks,
  });

  bool get ok => checks.every((c) => c.ok);
}

double _rad(double deg) => deg * math.pi / 180;

/// Required global factor of safety against overturning and sliding.
const wallSafetyFactor = 1.5;

WallDesign designWall(WallInput i) {
  requirePositive(i.stemHeight, 'stemHeight');
  requirePositive(i.baseThickness, 'baseThickness');
  requirePositive(i.stemBottom, 'stemBottom');
  requirePositive(i.stemTop, 'stemTop');
  requirePositive(i.qAllowable, 'qAllowable');
  requireRange(i.phi, 15, 45, 'phi');
  if (i.toe < 0) throw const InputError(InputProblem.outOfRange, 'toe');
  if (i.heel < 0) throw const InputError(InputProblem.outOfRange, 'heel');
  if (i.stemTop > i.stemBottom) {
    throw const InputError(InputProblem.inconsistentGeometry, 'stemTop');
  }
  final concrete = Concrete(i.code, i.fck);
  final steel = RebarSteel(i.fyk);

  final ka = math.pow(math.tan(_rad(45 - i.phi / 2)), 2).toDouble();
  final hTot = i.totalHeight;
  final b = i.baseWidth;
  final g = i.soilWeight;
  const gc = reinforcedConcreteWeight;

  // Horizontal thrusts per metre and their moments about the toe.
  final pa = 0.5 * ka * g * hTot * hTot;
  final pq = ka * i.surcharge * hTot;
  final mo = pa * hTot / 3 + pq * hTot / 2;

  // Stabilising weights (back face vertical, front face battered).
  final h = i.stemHeight;
  final tb = i.stemBottom, tt = i.stemTop;
  final parts = <(double, double)>[
    (tt * h * gc, i.toe + tb - tt / 2), // stem, rectangular part
    (0.5 * (tb - tt) * h * gc, i.toe + 2 / 3 * (tb - tt)), // stem, batter
    (b * i.baseThickness * gc, b / 2), // base
    (i.heel * h * g, i.toe + tb + i.heel / 2), // soil over the heel
  ];
  final v = parts.fold(0.0, (s, p) => s + p.$1);
  final mr = parts.fold(0.0, (s, p) => s + p.$1 * p.$2);

  final fsO = mr / mo;
  final delta = i.baseFriction ?? 2 / 3 * i.phi;
  final fsS = v * math.tan(_rad(delta)) / (pa + pq);

  // Bearing: the surcharge over the heel adds load.
  final qHeel = i.surcharge * i.heel;
  final vb = v + qHeel;
  final mb = mr + qHeel * (i.toe + tb + i.heel / 2);
  final xR = (mb - mo) / vb;
  final e = b / 2 - xR;
  final sMax = e.abs() <= b / 6 ? vb / b * (1 + 6 * e / b) : 2 * vb / (3 * xR);
  final sMin = e.abs() <= b / 6 ? vb / b * (1 - 6 * e / b) : 0.0;
  final sigma = switch (i.code) {
    DesignCode.bael => vb / b * (1 + 3 * e / b), // σ at 3/4 width
    DesignCode.ec2 => vb / (b - 2 * e), // effective width
  };

  // Stem at its base: ULS 1.35 × earth + 1.5 × surcharge.
  final mStem =
      1.35 * ka * g * h * h * h / 6 + 1.5 * ka * i.surcharge * h * h / 2;
  final vStem = 1.35 * 0.5 * ka * g * h * h + 1.5 * ka * i.surcharge * h;
  final d = tb * 1000 - i.cover - 6;
  final asReq = math.max(
    designRectangularBending(
      code: i.code,
      concrete: concrete,
      steel: steel,
      mEd: mStem,
      b: 1000,
      d: d,
    ).asTension,
    minTensionSteel(
      code: i.code,
      concrete: concrete,
      steel: steel,
      b: 1000,
      d: d,
    ),
  );
  final bars = chooseSpacing(asReq, math.min(3 * tb * 1000, 300));

  final shearCapacity = switch (i.code) {
    DesignCode.ec2 => () {
      final k = math.min(1 + math.sqrt(200 / d), 2.0);
      final rho = math.min((bars?.areaPerMetre ?? asReq) / (1000 * d), 0.02);
      final vMin = 0.035 * math.pow(k, 1.5) * math.sqrt(i.fck);
      final vc = math.max(0.12 * k * math.pow(100 * rho * i.fck, 1 / 3), vMin);
      return vc * 1000 * d / 1e3;
    }(),
    DesignCode.bael => 0.07 * i.fck / Concrete.gammaC * 1000 * d / 1e3,
  };

  const global = 'FS ≥ 1.5';
  final checks = <Check>[
    Check(
      kind: CheckKind.overturning,
      demand: wallSafetyFactor,
      capacity: fsO,
      clause: global,
    ),
    Check(
      kind: CheckKind.sliding,
      demand: wallSafetyFactor,
      capacity: fsS,
      clause: global,
    ),
    Check(
      kind: CheckKind.baseEccentricity,
      demand: e.abs(),
      capacity: b / 6,
      clause: i.code == DesignCode.bael ? 'DTU 13.12' : 'EN 1997-1 6.5.4',
      unit: 'm',
    ),
    Check(
      kind: CheckKind.bearingPressure,
      demand: sigma,
      capacity: i.qAllowable,
      clause: i.code == DesignCode.bael ? 'DTU 13.12' : 'EN 1997-1 6.5.2',
      unit: 'kPa',
    ),
    Check(
      kind: CheckKind.bendingSteel,
      demand: asReq,
      capacity: bars?.areaPerMetre ?? 0,
      clause: bendingClause(i.code),
      unit: 'mm²/m',
    ),
    Check(
      kind: CheckKind.shearCrushing,
      demand: vStem,
      capacity: shearCapacity,
      clause: i.code == DesignCode.ec2 ? 'EN 1992-1-1 6.2.2' : 'BAEL A.5.2.2',
      unit: 'kN/m',
    ),
  ];

  return WallDesign(
    input: i,
    ka: ka,
    thrustSoil: pa,
    thrustSurcharge: pq,
    vertical: v,
    overturningMoment: mo,
    resistingMoment: mr,
    fsOverturning: fsO,
    fsSliding: fsS,
    eccentricity: e,
    pressure: sigma,
    pressureMax: sMax,
    pressureMin: sMin,
    stemMoment: mStem,
    stemShear: vStem,
    stemD: d,
    stemAs: asReq,
    stemBars: bars,
    checks: checks,
  );
}
