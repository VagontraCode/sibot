import 'dart:math' as math;

import 'core.dart';

/// Strength class of solid softwood (EN 338) or glued laminated timber
/// (EN 14080). Strengths and moduli in MPa, densities in kg/m³.
class TimberClass {
  final String name;
  final bool glulam;
  final double fmk;
  final double ft0k;
  final double fc0k;
  final double fvk;

  /// Compression perpendicular to the grain, MPa.
  final double fc90k;
  final double e0mean;
  final double e005;
  final double rhoK;

  const TimberClass(
    this.name, {
    required this.glulam,
    required this.fmk,
    required this.ft0k,
    required this.fc0k,
    required this.fvk,
    required this.fc90k,
    required this.e0mean,
    required this.e005,
    required this.rhoK,
  });

  /// Partial factor γM (EN 1995-1-1 Table 2.3).
  double get gammaM => glulam ? 1.25 : 1.3;
}

const timberClasses = <String, TimberClass>{
  'C16': TimberClass(
    'C16',
    glulam: false,
    fmk: 16,
    ft0k: 10,
    fc0k: 17,
    fvk: 3.2,
    fc90k: 2.2,
    e0mean: 8000,
    e005: 5400,
    rhoK: 310,
  ),
  'C18': TimberClass(
    'C18',
    glulam: false,
    fmk: 18,
    ft0k: 11,
    fc0k: 18,
    fvk: 3.4,
    fc90k: 2.2,
    e0mean: 9000,
    e005: 6000,
    rhoK: 320,
  ),
  'C24': TimberClass(
    'C24',
    glulam: false,
    fmk: 24,
    ft0k: 14,
    fc0k: 21,
    fvk: 4.0,
    fc90k: 2.5,
    e0mean: 11000,
    e005: 7400,
    rhoK: 350,
  ),
  'C30': TimberClass(
    'C30',
    glulam: false,
    fmk: 30,
    ft0k: 18,
    fc0k: 23,
    fvk: 4.0,
    fc90k: 2.7,
    e0mean: 12000,
    e005: 8000,
    rhoK: 380,
  ),
  'GL24h': TimberClass(
    'GL24h',
    glulam: true,
    fmk: 24,
    ft0k: 19.2,
    fc0k: 24,
    fvk: 3.5,
    fc90k: 2.5,
    e0mean: 11500,
    e005: 9600,
    rhoK: 385,
  ),
  'GL28h': TimberClass(
    'GL28h',
    glulam: true,
    fmk: 28,
    ft0k: 22.3,
    fc0k: 28,
    fvk: 3.5,
    fc90k: 2.5,
    e0mean: 12600,
    e005: 10500,
    rhoK: 425,
  ),
  'GL32h': TimberClass(
    'GL32h',
    glulam: true,
    fmk: 32,
    ft0k: 25.6,
    fc0k: 32,
    fvk: 3.5,
    fc90k: 2.5,
    e0mean: 14200,
    e005: 11800,
    rhoK: 440,
  ),
};

/// Load-duration class of the governing combination (EN 1995-1-1 2.3.1.2).
enum LoadDuration { permanent, longTerm, mediumTerm, shortTerm, instantaneous }

/// kmod for solid timber and glulam (Table 3.1); service class 1–3.
double timberKmod(LoadDuration d, int serviceClass) {
  const sc12 = [0.6, 0.7, 0.8, 0.9, 1.1];
  const sc3 = [0.5, 0.55, 0.65, 0.7, 0.9];
  return (serviceClass <= 2 ? sc12 : sc3)[d.index];
}

/// kdef for solid timber and glulam (Table 3.2).
double timberKdef(int serviceClass) => const [0.6, 0.8, 2.0][serviceClass - 1];

/// Rectangular timber member under axial force, major-axis bending and
/// shear, EN 1995-1-1. Optional deflection check for a simply supported
/// span under characteristic uniform loads.
class TimberMemberInput {
  final TimberClass timber;

  /// Width (minor axis) and depth (bending axis), mm.
  final double b;
  final double h;

  /// Member length, m.
  final double length;

  /// Axial force, kN: compression positive, tension negative.
  final double nEd;

  /// Major-axis moment and shear (absolute), kN·m and kN.
  final double myEd;
  final double vEd;

  /// Buckling length factors about y, z and the lateral-torsional
  /// effective length factor (lef = kLT·L).
  final double ky;
  final double kz;
  final double kLT;

  final LoadDuration duration;
  final int serviceClass;

  /// Characteristic permanent and variable uniform loads for the
  /// deflection check, kN/m (0 skips it), and ψ2 of the variable load.
  final double gk;
  final double qk;
  final double psi2;

  /// Deflection limits as span ratios: instantaneous (variable load)
  /// and final.
  final double limitInst;
  final double limitFin;

  /// End support: bearing length (mm, 0 = not checked) and reaction
  /// (kN, defaults to [vEd]).
  final double bearingLength;
  final double? reaction;

  /// Notch on the underside at the support: remaining depth hef (mm,
  /// 0 = no notch) and distance from the reaction to the notch corner.
  final double notchDepth;
  final double notchX;

  const TimberMemberInput({
    required this.timber,
    required this.b,
    required this.h,
    required this.length,
    this.nEd = 0,
    this.myEd = 0,
    this.vEd = 0,
    this.ky = 1,
    this.kz = 1,
    this.kLT = 1,
    this.duration = LoadDuration.mediumTerm,
    this.serviceClass = 1,
    this.gk = 0,
    this.qk = 0,
    this.psi2 = 0.3,
    this.limitInst = 300,
    this.limitFin = 250,
    this.bearingLength = 0,
    this.reaction,
    this.notchDepth = 0,
    this.notchX = 0,
  });
}

class TimberMemberResult {
  final double kmod;
  final double kh;

  /// Design strengths, MPa.
  final double fmd;
  final double fc0d;
  final double ft0d;
  final double fvd;

  /// Stresses, MPa.
  final double sigmaM;
  final double sigmaN;
  final double tau;

  final double lambdaRelY;
  final double lambdaRelZ;
  final double kcY;
  final double kcZ;
  final double lambdaRelM;
  final double kcrit;

  /// Deflections, mm (null when no loads were given).
  final double? wInstQ;
  final double? wFin;

  final List<Check> checks;
  bool get ok => checks.every((c) => c.ok);

  const TimberMemberResult({
    required this.kmod,
    required this.kh,
    required this.fmd,
    required this.fc0d,
    required this.ft0d,
    required this.fvd,
    required this.sigmaM,
    required this.sigmaN,
    required this.tau,
    required this.lambdaRelY,
    required this.lambdaRelZ,
    required this.kcY,
    required this.kcZ,
    required this.lambdaRelM,
    required this.kcrit,
    required this.wInstQ,
    required this.wFin,
    required this.checks,
  });
}

/// Instability factor kc (6.25–6.29).
double timberKc(double lambdaRel, bool glulam) {
  if (lambdaRel <= 0.3) return 1;
  final beta = glulam ? 0.1 : 0.2;
  final k = 0.5 * (1 + beta * (lambdaRel - 0.3) + lambdaRel * lambdaRel);
  return 1 / (k + math.sqrt(k * k - lambdaRel * lambdaRel));
}

/// Lateral-torsional factor kcrit (6.34).
double timberKcrit(double lambdaRelM) {
  if (lambdaRelM <= 0.75) return 1;
  if (lambdaRelM <= 1.4) return 1.56 - 0.75 * lambdaRelM;
  return 1 / (lambdaRelM * lambdaRelM);
}

TimberMemberResult designTimberMember(TimberMemberInput i) {
  final t = i.timber;
  requirePositive(i.b, 'b');
  requirePositive(i.h, 'h');
  requirePositive(i.length, 'length');
  requirePositive(i.ky, 'ky');
  requirePositive(i.kz, 'kz');
  requirePositive(i.kLT, 'kLT');
  requireRange(i.serviceClass.toDouble(), 1, 3, 'serviceClass');
  requireRange(i.psi2, 0, 1, 'psi2');
  if (i.myEd < 0) throw const InputError(InputProblem.notPositive, 'myEd');
  if (i.vEd < 0) throw const InputError(InputProblem.notPositive, 'vEd');
  if (i.gk < 0) throw const InputError(InputProblem.notPositive, 'gk');
  if (i.qk < 0) throw const InputError(InputProblem.notPositive, 'qk');
  if (i.b > i.h) {
    throw const InputError(InputProblem.inconsistentGeometry, 'b');
  }

  final kmod = timberKmod(i.duration, i.serviceClass);
  // Depth factor (3.2, 3.3) for bending and tension.
  final kh = t.glulam
      ? (i.h < 600 ? math.min(1.1, math.pow(600 / i.h, 0.1).toDouble()) : 1.0)
      : (i.h < 150 ? math.min(1.3, math.pow(150 / i.h, 0.2).toDouble()) : 1.0);
  final fmd = kmod * kh * t.fmk / t.gammaM;
  final ft0d = kmod * kh * t.ft0k / t.gammaM;
  final fc0d = kmod * t.fc0k / t.gammaM;
  final fvd = kmod * t.fvk / t.gammaM;

  final area = i.b * i.h;
  final w = i.b * i.h * i.h / 6;
  final sigmaM = i.myEd * 1e6 / w;
  final sigmaN = i.nEd.abs() * 1e3 / area;
  final compression = i.nEd > 0;
  const kcr = 0.67;
  final tau = 1.5 * i.vEd * 1e3 / (kcr * area);

  // Column buckling (6.3.2).
  final l = i.length * 1e3;
  double lambdaRel(double lcr, double d) =>
      lcr / (d / math.sqrt(12)) / math.pi * math.sqrt(t.fc0k / t.e005);
  final lambdaRelY = lambdaRel(i.ky * l, i.h);
  final lambdaRelZ = lambdaRel(i.kz * l, i.b);
  final kcY = timberKc(lambdaRelY, t.glulam);
  final kcZ = timberKc(lambdaRelZ, t.glulam);

  // Lateral-torsional buckling (6.3.3), rectangular softwood section.
  final lef = i.kLT * l;
  final sigmaMcrit = 0.78 * i.b * i.b * t.e005 / (i.h * lef);
  final lambdaRelM = math.sqrt(t.fmk / sigmaMcrit);
  final kcrit = timberKcrit(lambdaRelM);

  const ref = 'EN 1995-1-1';
  const km = 0.7;
  final checks = <Check>[
    if (i.nEd != 0)
      Check(
        kind: compression ? CheckKind.steelCompression : CheckKind.steelTension,
        demand: sigmaN,
        capacity: compression ? fc0d : ft0d,
        clause: compression ? '$ref 6.1.4' : '$ref 6.1.2',
        unit: 'MPa',
      ),
    if (i.myEd > 0)
      Check(
        kind: CheckKind.steelBending,
        demand: sigmaM,
        capacity: fmd,
        clause: '$ref 6.1.6',
        unit: 'MPa',
      ),
    if (i.vEd > 0)
      Check(
        kind: CheckKind.steelShear,
        demand: tau,
        capacity: fvd,
        clause: '$ref 6.1.7',
        unit: 'MPa',
      ),
    if (i.nEd < 0 && i.myEd > 0)
      Check(
        kind: CheckKind.combinedStress,
        demand: sigmaN / ft0d + sigmaM / fmd,
        capacity: 1,
        clause: '$ref 6.2.3 (6.17)',
      ),
    if (compression) ...[
      Check(
        kind: CheckKind.bucklingInteractionY,
        demand: sigmaN / (kcY * fc0d) + sigmaM / fmd,
        capacity: 1,
        clause: '$ref 6.3.2 (6.23)',
      ),
      Check(
        kind: CheckKind.bucklingInteractionZ,
        demand: sigmaN / (kcZ * fc0d) + km * sigmaM / fmd,
        capacity: 1,
        clause: '$ref 6.3.2 (6.24)',
      ),
    ],
    if (i.myEd > 0)
      Check(
        kind: CheckKind.lateralTorsional,
        demand: compression
            ? math.pow(sigmaM / (kcrit * fmd), 2) + sigmaN / (kcZ * fc0d)
            : sigmaM / (kcrit * fmd),
        capacity: 1,
        clause: compression ? '$ref 6.3.3 (6.35)' : '$ref 6.3.3 (6.33)',
      ),
  ];

  // Bearing at an end support (6.1.5): effective length l + 30 mm,
  // kc,90 = 1.5 (solid softwood) or 1.75 (glulam, l ≤ 400 mm) for
  // discrete supports.
  final reaction = i.reaction ?? i.vEd;
  if (i.bearingLength > 0 && reaction > 0) {
    final lef = i.bearingLength + 30;
    final kc90 = t.glulam ? (i.bearingLength <= 400 ? 1.75 : 1.0) : 1.5;
    final fc90d = kmod * t.fc90k / t.gammaM;
    checks.add(
      Check(
        kind: CheckKind.timberBearing,
        demand: reaction * 1e3 / (i.b * lef),
        capacity: kc90 * fc90d,
        clause: '$ref 6.1.5 (kc,90 = ${kc90.toStringAsFixed(2)})',
        unit: 'MPa',
      ),
    );
  }

  // Notch on the loaded side's underside at the support (6.5.2).
  if (i.notchDepth > 0) {
    if (i.notchDepth >= i.h) {
      throw const InputError(InputProblem.inconsistentGeometry, 'notchDepth');
    }
    final h = i.h, alpha = i.notchDepth / h;
    final kn = t.glulam ? 6.5 : 5.0;
    final kv = math.min(
      1.0,
      kn /
          (math.sqrt(h) *
              (math.sqrt(alpha * (1 - alpha)) +
                  0.8 * i.notchX / h * math.sqrt(1 / alpha - alpha * alpha))),
    );
    checks.add(
      Check(
        kind: CheckKind.timberNotch,
        demand: 1.5 * reaction * 1e3 / (kcr * i.b * i.notchDepth),
        capacity: kv * fvd,
        clause: '$ref 6.5.2 (kv = ${kv.toStringAsFixed(2)})',
        unit: 'MPa',
      ),
    );
  }

  // Deflection of a simply supported span (2.2.3, 7.2).
  double? wInstQ, wFin;
  if (i.gk > 0 || i.qk > 0) {
    final ei = t.e0mean * i.b * math.pow(i.h, 3) / 12;
    double defl(double q) => 5 * q * math.pow(l, 4) / (384 * ei);
    final wG = defl(i.gk), wQ = defl(i.qk);
    final kdef = timberKdef(i.serviceClass);
    wInstQ = wQ;
    wFin = wG * (1 + kdef) + wQ * (1 + i.psi2 * kdef);
    checks.addAll([
      Check(
        kind: CheckKind.deflectionInstant,
        demand: wQ,
        capacity: l / i.limitInst,
        clause: '$ref 7.2 (L/${i.limitInst.round()})',
        unit: 'mm',
      ),
      Check(
        kind: CheckKind.deflectionFinal,
        demand: wFin,
        capacity: l / i.limitFin,
        clause: '$ref 2.2.3, 7.2 (L/${i.limitFin.round()})',
        unit: 'mm',
      ),
    ]);
  }

  return TimberMemberResult(
    kmod: kmod,
    kh: kh,
    fmd: fmd,
    fc0d: fc0d,
    ft0d: ft0d,
    fvd: fvd,
    sigmaM: sigmaM,
    sigmaN: sigmaN,
    tau: tau,
    lambdaRelY: lambdaRelY,
    lambdaRelZ: lambdaRelZ,
    kcY: kcY,
    kcZ: kcZ,
    lambdaRelM: lambdaRelM,
    kcrit: kcrit,
    wInstQ: wInstQ,
    wFin: wFin,
    checks: checks,
  );
}
