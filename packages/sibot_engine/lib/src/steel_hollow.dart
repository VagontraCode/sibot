import 'dart:math' as math;

import 'core.dart';
import 'steel_member.dart';
import 'steel_profiles.dart';
import 'steel_sections.dart';

/// EN 1993-1-1 checks of a hot-finished hollow section (CHS, RHS, SHS):
/// no lateral-torsional buckling (closed section), buckling curve a,
/// Annex B factors for members not susceptible to torsional deformation.
SteelMemberResult designHollowMember(SteelMemberInput i, HollowSection s) {
  requirePositive(i.length, 'length');
  requirePositive(i.ky, 'ky');
  requirePositive(i.kz, 'kz');
  if (i.myEd < 0) throw const InputError(InputProblem.notPositive, 'myEd');
  if (i.mzEd < 0) throw const InputError(InputProblem.notPositive, 'mzEd');
  if (i.vEd < 0) throw const InputError(InputProblem.notPositive, 'vEd');
  final grade = steelGrades[i.grade];
  if (grade == null) throw const InputError(InputProblem.outOfRange, 'grade');
  final fy = s.t <= 40 ? grade.$1 : grade.$2;
  final eps = math.sqrt(235 / fy);
  final nEd = i.nEd * 1e3, mEd = i.myEd * 1e6, mzEd = i.mzEd * 1e6;
  final vEd = i.vEd * 1e3;
  final compression = nEd > 0;

  // Classification (Table 5.2).
  int classOf(double r, double l1, double l2, double l3) =>
      r <= l1 ? 1 : (r <= l2 ? 2 : (r <= l3 ? 3 : 4));
  final int sectionClass, flangeClass, webClass;
  if (s.circular) {
    final r = s.h / s.t;
    sectionClass = classOf(r, 50 * eps * eps, 70 * eps * eps, 90 * eps * eps);
    flangeClass = sectionClass;
    webClass = sectionClass;
  } else {
    flangeClass = classOf((s.b - 3 * s.t) / s.t, 33 * eps, 38 * eps, 42 * eps);
    final web = (s.h - 3 * s.t) / s.t;
    webClass = compression
        ? classOf(web, 33 * eps, 38 * eps, 42 * eps)
        : classOf(web, 72 * eps, 83 * eps, 124 * eps);
    sectionClass = math.max(flangeClass, webClass);
  }
  if (sectionClass == 4) {
    throw const InputError(InputProblem.outOfRange, 'section');
  }
  final plastic = sectionClass <= 2;
  final wy = plastic ? s.wplY : s.welY;
  final wz = plastic ? s.wplZ : s.welZ;

  final nRk = s.area * fy;
  final nPlRd = nRk / i.gammaM0;
  final mcRd = wy * fy / i.gammaM0, mczRd = wz * fy / i.gammaM0;
  final vPlRd = s.avz * fy / math.sqrt(3) / i.gammaM0;
  var myRd = mcRd;
  if (vEd > 0.5 * vPlRd && vEd <= vPlRd) {
    myRd = mcRd * (1 - math.pow(2 * vEd / vPlRd - 1, 2));
  }

  // Bending and axial force (6.2.9.1, 6.41).
  final n = nEd.abs() / nPlRd;
  double crossRatio;
  var mNRd = myRd;
  if (plastic) {
    double mNz, ex;
    if (s.circular) {
      mNRd = myRd * (1 - math.pow(n, 1.7));
      mNz = mczRd * (1 - math.pow(n, 1.7));
      ex = 2;
    } else {
      final aw = math.min(0.5, (s.area - 2 * s.b * s.t) / s.area);
      final af = math.min(0.5, (s.area - 2 * s.h * s.t) / s.area);
      mNRd = math.min(myRd, myRd * (1 - n) / (1 - 0.5 * aw));
      mNz = math.min(mczRd, mczRd * (1 - n) / (1 - 0.5 * af));
      ex = math.min(6.0, 1.66 / (1 - 1.13 * n * n));
    }
    crossRatio = n >= 1
        ? n
        : (math.pow(mEd / math.max(mNRd, 1e-9), ex) +
                  math.pow(mzEd / math.max(mNz, 1e-9), ex))
              .toDouble();
    crossRatio = math.max(crossRatio, n);
  } else {
    crossRatio = n + mEd / myRd + mzEd / mczRd;
    mNRd = myRd * math.max(0, 1 - n);
  }

  // Flexural buckling, curve a (hot-finished).
  final lambda1 = math.pi * math.sqrt(steelE / fy);
  final lambdaY = i.ky * i.length * 1e3 / s.iRadiusY / lambda1;
  final lambdaZ = i.kz * i.length * 1e3 / s.iRadiusZ / lambda1;
  final chiY = bucklingChi(lambdaY, 0.21);
  final chiZ = bucklingChi(lambdaZ, 0.21);

  final cm = switch (i.shape) {
    MomentShape.uniform => 1.0,
    MomentShape.udl => 0.95,
    MomentShape.pointLoad => 0.90,
    MomentShape.linear => math.max(0.4, 0.6 + 0.4 * i.psi),
  };
  final nYRd = chiY * nRk / i.gammaM1, nZRd = chiZ * nRk / i.gammaM1;
  final nY = compression ? nEd / nYRd : 0.0;
  final nZ = compression ? nEd / nZRd : 0.0;
  // Annex B, Table B.1 (members not susceptible to torsional deformation).
  final double kyy, kzz, kyz, kzy;
  if (plastic) {
    kyy = cm * math.min(1 + (lambdaY - 0.2) * nY, 1 + 0.8 * nY);
    kzz = cm * math.min(1 + (lambdaZ - 0.2) * nZ, 1 + 0.8 * nZ);
    kyz = 0.6 * kzz;
    kzy = 0.6 * kyy;
  } else {
    kyy = cm * math.min(1 + 0.6 * lambdaY * nY, 1 + 0.6 * nY);
    kzz = cm * math.min(1 + 0.6 * lambdaZ * nZ, 1 + 0.6 * nZ);
    kyz = kzz;
    kzy = 0.8 * kyy;
  }
  final myRk1 = wy * fy / i.gammaM1, mzRk1 = wz * fy / i.gammaM1;

  const ref = 'EN 1993-1-1';
  final checks = <Check>[
    Check(
      kind: compression ? CheckKind.steelCompression : CheckKind.steelTension,
      demand: nEd.abs() / 1e3,
      capacity: nPlRd / 1e3,
      clause: compression ? '$ref 6.2.4' : '$ref 6.2.3',
      unit: 'kN',
    ),
    if (i.myEd > 0)
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
    if (i.vEd > 0)
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
      clause: plastic ? '$ref 6.2.9.1 (6.41)' : '$ref 6.2.9.2',
    ),
    if (compression) ...[
      Check(
        kind: CheckKind.flexuralBucklingY,
        demand: nEd / 1e3,
        capacity: nYRd / 1e3,
        clause: '$ref 6.3.1 (curve a)',
        unit: 'kN',
      ),
      Check(
        kind: CheckKind.flexuralBucklingZ,
        demand: nEd / 1e3,
        capacity: nZRd / 1e3,
        clause: '$ref 6.3.1 (curve a)',
        unit: 'kN',
      ),
    ],
    if (compression && (i.myEd > 0 || i.mzEd > 0)) ...[
      Check(
        kind: CheckKind.bucklingInteractionY,
        demand: nY + kyy * mEd / myRk1 + kyz * mzEd / mzRk1,
        capacity: 1,
        clause: '$ref 6.3.3 (6.61), Annex B',
      ),
      Check(
        kind: CheckKind.bucklingInteractionZ,
        demand: nZ + kzy * mEd / myRk1 + kzz * mzEd / mzRk1,
        capacity: 1,
        clause: '$ref 6.3.3 (6.62), Annex B',
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
    mCr: double.infinity,
    lambdaLT: 0,
    chiLT: 1,
    mbRd: mcRd / 1e6,
    kyy: kyy,
    kzy: kzy,
    checks: checks,
  );
}
