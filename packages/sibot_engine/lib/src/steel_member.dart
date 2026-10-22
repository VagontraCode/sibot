import 'dart:math' as math;

import 'core.dart';
import 'steel_sections.dart';
import 'steel_hollow.dart';
import 'steel_profiles.dart';

/// Shape of the major-axis bending moment between restraints; sets C1
/// (elastic critical moment) and the equivalent uniform moment factors.
enum MomentShape {
  /// Constant moment.
  uniform,

  /// Simply supported span under uniform load.
  udl,

  /// Simply supported span under a central point load.
  pointLoad,

  /// Linear diagram with end moment ratio ψ (−1 ≤ ψ ≤ 1).
  linear,
}

/// Steel member under axial force and major-axis bending, EN 1993-1-1.
class SteelMemberInput {
  /// I or H section, or hot-finished hollow section.
  final SteelProfile section;

  /// Grade name from [steelGrades], e.g. 'S275'.
  final String grade;

  /// Member length between lateral restraints, m.
  final double length;

  /// Axial force, kN: compression positive, tension negative.
  final double nEd;

  /// Maximum major-axis moment (absolute), kN·m.
  final double myEd;

  /// Maximum minor-axis moment (absolute), kN·m.
  final double mzEd;

  /// Maximum shear force (absolute), kN.
  final double vEd;

  /// Buckling length factors (Lcr = k·L) about y, z and for
  /// lateral-torsional buckling.
  final double ky;
  final double kz;
  final double kLT;

  final MomentShape shape;

  /// End moment ratio for [MomentShape.linear].
  final double psi;

  final double gammaM0;
  final double gammaM1;

  const SteelMemberInput({
    required this.section,
    required this.length,
    this.grade = 'S275',
    this.nEd = 0,
    this.myEd = 0,
    this.mzEd = 0,
    this.vEd = 0,
    this.ky = 1,
    this.kz = 1,
    this.kLT = 1,
    this.shape = MomentShape.uniform,
    this.psi = 1,
    this.gammaM0 = 1.0,
    this.gammaM1 = 1.0,
  });
}

class SteelMemberResult {
  final double fy;
  final double epsilon;

  /// Cross-section class (1–4) under the design forces.
  final int sectionClass;
  final int flangeClass;
  final int webClass;

  /// Resistances, kN and kN·m.
  final double nPlRd;
  final double mcRd;
  final double vPlRd;

  /// Reduced moment resistance for shear and axial force, kN·m.
  final double mNRd;

  final double lambdaY;
  final double lambdaZ;
  final double chiY;
  final double chiZ;

  /// Elastic critical moment, kN·m, and LTB reduction.
  final double mCr;
  final double lambdaLT;
  final double chiLT;
  final double mbRd;

  final double kyy;
  final double kzy;

  final List<Check> checks;
  bool get ok => checks.every((c) => c.ok);

  const SteelMemberResult({
    required this.fy,
    required this.epsilon,
    required this.sectionClass,
    required this.flangeClass,
    required this.webClass,
    required this.nPlRd,
    required this.mcRd,
    required this.vPlRd,
    required this.mNRd,
    required this.lambdaY,
    required this.lambdaZ,
    required this.chiY,
    required this.chiZ,
    required this.mCr,
    required this.lambdaLT,
    required this.chiLT,
    required this.mbRd,
    required this.kyy,
    required this.kzy,
    required this.checks,
  });
}

const steelE = 210000.0;
const steelG = 81000.0;

/// Imperfection factor of buckling curves a0, a, b, c, d (Table 6.1).
const _alpha = {'a0': 0.13, 'a': 0.21, 'b': 0.34, 'c': 0.49, 'd': 0.76};

/// Reduction factor χ for flexural buckling (6.49).
double bucklingChi(double lambda, double alpha) {
  if (lambda <= 0.2) return 1;
  final phi = 0.5 * (1 + alpha * (lambda - 0.2) + lambda * lambda);
  return math.min(1, 1 / (phi + math.sqrt(phi * phi - lambda * lambda)));
}

/// C1 factor for the elastic critical moment (end restraint k = 1).
double momentC1(MomentShape shape, double psi) => switch (shape) {
  MomentShape.uniform => 1.0,
  MomentShape.udl => 1.127,
  MomentShape.pointLoad => 1.348,
  MomentShape.linear => math.min(2.7, 1.88 - 1.40 * psi + 0.52 * psi * psi),
};

/// Elastic critical moment, N·mm, for a doubly symmetric I section
/// loaded at the shear centre.
double criticalMoment(ISteelSection s, double lcr, double c1) {
  final ez = math.pi * math.pi * steelE * s.iz / (lcr * lcr);
  return c1 * ez * math.sqrt(s.iw / s.iz + steelG * s.it / ez);
}

int _classOf(double ratio, double l1, double l2, double l3) =>
    ratio <= l1 ? 1 : (ratio <= l2 ? 2 : (ratio <= l3 ? 3 : 4));

SteelMemberResult designSteelMember(SteelMemberInput i) {
  final p = i.section;
  if (p is HollowSection) return designHollowMember(i, p);
  if (p is! ISteelSection) {
    throw const InputError(InputProblem.outOfRange, 'section');
  }
  final s = p;
  requirePositive(i.length, 'length');
  requirePositive(i.ky, 'ky');
  requirePositive(i.kz, 'kz');
  requirePositive(i.kLT, 'kLT');
  requireRange(i.psi, -1, 1, 'psi');
  if (i.myEd < 0) throw const InputError(InputProblem.notPositive, 'myEd');
  if (i.mzEd < 0) throw const InputError(InputProblem.notPositive, 'mzEd');
  if (i.vEd < 0) throw const InputError(InputProblem.notPositive, 'vEd');
  final grade = steelGrades[i.grade];
  if (grade == null) throw const InputError(InputProblem.outOfRange, 'grade');

  final tMax = math.max(s.tf, s.tw);
  final fy = tMax <= 40 ? grade.$1 : grade.$2;
  final eps = math.sqrt(235 / fy);
  final nEd = i.nEd * 1e3; // N, compression positive
  final mEd = i.myEd * 1e6; // N·mm
  final mzEd = i.mzEd * 1e6;
  final vEd = i.vEd * 1e3;
  final compression = nEd > 0;

  // ── Classification (Table 5.2) ──────────────────────────────────────
  final cf = (s.b - s.tw - 2 * s.r) / 2;
  final flangeClass = _classOf(cf / s.tf, 9 * eps, 10 * eps, 14 * eps);
  final cw = s.h - 2 * s.tf - 2 * s.r;
  final webRatio = cw / s.tw;
  int webClass;
  if (!compression) {
    webClass = _classOf(webRatio, 72 * eps, 83 * eps, 124 * eps);
  } else {
    // Plastic neutral axis position α and elastic stress ratio ψ.
    final alpha = (0.5 * (1 + nEd / (fy * s.tw * cw))).clamp(0.0, 1.0);
    double l1, l2;
    if (alpha > 0.5) {
      l1 = 396 * eps / (13 * alpha - 1);
      l2 = 456 * eps / (13 * alpha - 1);
    } else {
      l1 = 36 * eps / alpha;
      l2 = 41.5 * eps / alpha;
    }
    final sigN = nEd / s.area;
    final sigM = mEd / s.welY * cw / s.h;
    final psiW = sigN + sigM <= 0 ? 1.0 : (sigN - sigM) / (sigN + sigM);
    final l3 = psiW > -1
        ? 42 * eps / (0.67 + 0.33 * psiW)
        : 62 * eps * (1 - psiW) * math.sqrt(-psiW);
    webClass = _classOf(webRatio, l1, l2, l3);
  }
  final sectionClass = math.max(flangeClass, webClass);

  // Class 4 webs in compression: effective area (EN 1993-1-5 4.4, ψ = 1).
  var aEff = s.area;
  if (sectionClass == 4 && compression) {
    final lp = webRatio / (28.4 * eps * 2);
    final rho = lp > 0.673 ? math.min(1.0, (lp - 0.22) / (lp * lp)) : 1.0;
    aEff = s.area - (1 - rho) * cw * s.tw;
  }
  final plastic = sectionClass <= 2;
  final wy = plastic ? s.wplY : s.welY;
  final wz = plastic ? s.wplZ : s.welZ;

  // ── Cross-section resistances (6.2) ─────────────────────────────────
  final nRk = (compression ? aEff : s.area) * fy;
  final nPlRd = nRk / i.gammaM0;
  final mcRd = wy * fy / i.gammaM0;
  final mczRd = wz * fy / i.gammaM0;
  final vPlRd = s.avz * fy / math.sqrt(3) / i.gammaM0;

  // Shear interaction (6.2.8): reduced yield strength over the web.
  var mVRd = mcRd;
  if (vEd > 0.5 * vPlRd && vEd <= vPlRd) {
    final rho = math.pow(2 * vEd / vPlRd - 1, 2).toDouble();
    final aw = (s.h - 2 * s.tf) * s.tw;
    final w = plastic ? s.wplY - rho * aw * aw / (4 * s.tw) : wy * (1 - rho);
    mVRd = math.min(mcRd, w * fy / i.gammaM0);
  }

  // Axial interaction (6.2.9).
  final n = nEd.abs() / nPlRd;
  double crossRatio;
  var mNRd = mVRd;
  if (plastic) {
    final hwTw = (s.h - 2 * s.tf) * s.tw;
    final noReduction =
        nEd.abs() <= 0.25 * nPlRd && nEd.abs() <= 0.5 * hwTw * fy / i.gammaM0;
    if (!noReduction) {
      final a = math.min(0.5, (s.area - 2 * s.b * s.tf) / s.area);
      mNRd = math.min(mVRd, mVRd * (1 - n) / (1 - 0.5 * a));
    }
    // Minor axis (6.2.9.1(5)) and biaxial bending (6.41).
    final a = math.min(0.5, (s.area - 2 * s.b * s.tf) / s.area);
    final mNzRd = n <= a ? mczRd : mczRd * (1 - math.pow((n - a) / (1 - a), 2));
    final beta = math.max(1.0, 5 * n);
    crossRatio = n >= 1
        ? n
        : (math.pow(mEd / math.max(mNRd, 1e-9), 2) +
                  math.pow(mzEd / math.max(mNzRd, 1e-9), beta))
              .toDouble();
    crossRatio = math.max(crossRatio, n);
  } else {
    crossRatio = n + mEd / mVRd + mzEd / mczRd;
    mNRd = mVRd * math.max(0, 1 - n);
  }

  // ── Flexural buckling (6.3.1) ───────────────────────────────────────
  final lambda1 = math.pi * math.sqrt(steelE / fy);
  final aRatio = math.sqrt(nRk / (s.area * fy));
  final lambdaY = i.ky * i.length * 1e3 / s.iRadiusY / lambda1 * aRatio;
  final lambdaZ = i.kz * i.length * 1e3 / s.iRadiusZ / lambda1 * aRatio;
  final slender = s.h / s.b > 1.2;
  final curveY = slender ? (fy >= 460 ? 'a0' : 'a') : 'b';
  final curveZ = slender ? (fy >= 460 ? 'a0' : 'b') : 'c';
  final chiY = bucklingChi(lambdaY, _alpha[curveY]!);
  final chiZ = bucklingChi(lambdaZ, _alpha[curveZ]!);

  // ── Lateral-torsional buckling (6.3.2.3, rolled sections) ───────────
  final c1 = momentC1(i.shape, i.psi);
  final mCr = criticalMoment(s, i.kLT * i.length * 1e3, c1);
  final lambdaLT = math.sqrt(wy * fy / mCr);
  const beta = 0.75, lambdaLT0 = 0.4;
  final alphaLT = s.h / s.b <= 2 ? 0.34 : 0.49;
  var chiLT = 1.0;
  if (lambdaLT > lambdaLT0 && mEd / mCr > lambdaLT0 * lambdaLT0) {
    final phi =
        0.5 *
        (1 + alphaLT * (lambdaLT - lambdaLT0) + beta * lambdaLT * lambdaLT);
    chiLT = 1 / (phi + math.sqrt(phi * phi - beta * lambdaLT * lambdaLT));
    chiLT = math.min(chiLT, math.min(1, 1 / (lambdaLT * lambdaLT)));
    // Correction for the moment distribution (6.58, Table 6.6).
    final kc = switch (i.shape) {
      MomentShape.uniform => 1.0,
      MomentShape.udl => 0.94,
      MomentShape.pointLoad => 0.90,
      MomentShape.linear => 1 / (1.33 - 0.33 * i.psi),
    };
    final f = math.min(
      1.0,
      1 - 0.5 * (1 - kc) * (1 - 2 * math.pow(lambdaLT - 0.8, 2)),
    );
    chiLT = math.min(1.0, math.min(chiLT / f, 1 / (lambdaLT * lambdaLT)));
  }
  final mbRd = chiLT * wy * fy / i.gammaM1;

  // ── Interaction (6.3.3, Annex B, torsionally flexible members) ──────
  final cm = switch (i.shape) {
    MomentShape.uniform => 1.0,
    MomentShape.udl => 0.95,
    MomentShape.pointLoad => 0.90,
    MomentShape.linear => math.max(0.4, 0.6 + 0.4 * i.psi),
  };
  final nYRd = chiY * nRk / i.gammaM1;
  final nZRd = chiZ * nRk / i.gammaM1;
  final nY = compression ? nEd / nYRd : 0.0;
  final nZ = compression ? nEd / nZRd : 0.0;
  final double kyy, kzy, kzz, kyz;
  if (plastic) {
    kyy = cm * math.min(1 + (lambdaY - 0.2) * nY, 1 + 0.8 * nY);
    kzz = cm * math.min(1 + (2 * lambdaZ - 0.6) * nZ, 1 + 1.4 * nZ);
    kyz = 0.6 * kzz;
    if (lambdaZ < 0.4) {
      kzy = math.min(0.6 + lambdaZ, 1 - 0.1 * lambdaZ * nZ / (cm - 0.25));
    } else {
      kzy = math.max(
        1 - 0.1 * lambdaZ * nZ / (cm - 0.25),
        1 - 0.1 * nZ / (cm - 0.25),
      );
    }
  } else {
    kyy = cm * math.min(1 + 0.6 * lambdaY * nY, 1 + 0.6 * nY);
    kzz = cm * math.min(1 + 0.6 * lambdaZ * nZ, 1 + 0.6 * nZ);
    kyz = kzz;
    kzy = math.max(
      1 - 0.05 * lambdaZ * nZ / (cm - 0.25),
      1 - 0.05 * nZ / (cm - 0.25),
    );
  }

  const ref = 'EN 1993-1-1';
  final checks = <Check>[
    Check(
      kind: compression ? CheckKind.steelCompression : CheckKind.steelTension,
      demand: nEd.abs() / 1e3,
      capacity: nPlRd / 1e3,
      clause: compression ? '$ref 6.2.4' : '$ref 6.2.3',
      unit: 'kN',
    ),
    Check(
      kind: CheckKind.steelBending,
      demand: i.myEd,
      capacity: mcRd / 1e6,
      clause: '$ref 6.2.5',
      unit: 'kN·m',
    ),
    if (i.mzEd > 0)
      Check(
        kind: CheckKind.steelBendingZ,
        demand: i.mzEd,
        capacity: mczRd / 1e6,
        clause: '$ref 6.2.5',
        unit: 'kN·m',
      ),
    Check(
      kind: CheckKind.steelShear,
      demand: i.vEd,
      capacity: vPlRd / 1e3,
      clause: '$ref 6.2.6',
      unit: 'kN',
    ),
    Check(
      kind: CheckKind.steelCombined,
      demand: crossRatio,
      capacity: 1,
      clause: plastic ? '$ref 6.2.8, 6.2.9.1' : '$ref 6.2.9.2',
    ),
    if (compression) ...[
      Check(
        kind: CheckKind.flexuralBucklingY,
        demand: nEd / 1e3,
        capacity: nYRd / 1e3,
        clause: '$ref 6.3.1 (curve $curveY)',
        unit: 'kN',
      ),
      Check(
        kind: CheckKind.flexuralBucklingZ,
        demand: nEd / 1e3,
        capacity: nZRd / 1e3,
        clause: '$ref 6.3.1 (curve $curveZ)',
        unit: 'kN',
      ),
    ],
    if (i.myEd > 0)
      Check(
        kind: CheckKind.lateralTorsional,
        demand: i.myEd,
        capacity: mbRd / 1e6,
        clause: '$ref 6.3.2.3',
        unit: 'kN·m',
      ),
    if ((compression && (i.myEd > 0 || i.mzEd > 0)) ||
        (i.myEd > 0 && i.mzEd > 0)) ...[
      Check(
        kind: CheckKind.bucklingInteractionY,
        demand:
            nY +
            kyy * mEd / mbRd +
            kyz * mzEd / (mczRd * i.gammaM0 / i.gammaM1),
        capacity: 1,
        clause: '$ref 6.3.3 (6.61)',
      ),
      Check(
        kind: CheckKind.bucklingInteractionZ,
        demand:
            nZ +
            kzy * mEd / mbRd +
            kzz * mzEd / (mczRd * i.gammaM0 / i.gammaM1),
        capacity: 1,
        clause: '$ref 6.3.3 (6.62)',
      ),
    ],
  ];

  return SteelMemberResult(
    fy: fy,
    epsilon: eps,
    sectionClass: sectionClass,
    flangeClass: flangeClass,
    webClass: webClass,
    nPlRd: nPlRd / 1e3,
    mcRd: mcRd / 1e6,
    vPlRd: vPlRd / 1e3,
    mNRd: mNRd / 1e6,
    lambdaY: lambdaY,
    lambdaZ: lambdaZ,
    chiY: chiY,
    chiZ: chiZ,
    mCr: mCr / 1e6,
    lambdaLT: lambdaLT,
    chiLT: chiLT,
    mbRd: mbRd / 1e6,
    kyy: kyy,
    kzy: kzy,
    checks: checks,
  );
}

/// Lightest library profile of [series] ('IPE', 'HEA', 'HEB') that passes
/// every check, or null when none does.
SteelProfile? lightestSteelSection(
  String series,
  SteelMemberInput Function(SteelProfile) inputFor,
) {
  final candidates = [
    for (final n in profilesOfSeries(series))
      if (steelDesignable(steelProfiles[n]!)) steelProfiles[n]!,
  ]..sort((a, b) => a.area.compareTo(b.area));
  for (final s in candidates) {
    if (designSteelMember(inputFor(s)).ok) return s;
  }
  return null;
}
