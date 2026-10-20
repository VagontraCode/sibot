import 'dart:math' as math;

import 'core.dart';
import 'materials.dart';

/// Punching of a slab under an interior column or a concentrated load
/// on a c1 × c2 area (mm).
class PunchingDesign {
  /// Basic control perimeter (EC2: at 2d; BAEL: at h/2), mm.
  final double u1;

  /// Shear stress at the control perimeter, MPa (EC2) / load, kN (BAEL).
  final double demand;

  /// Resistance without punching reinforcement, same unit as [demand].
  final double resistance;

  /// EC2: stress at the loaded face and its limit vRd,max (MPa).
  final double? faceStress;
  final double? faceLimit;

  /// EC2: punching reinforcement per perimeter (mm²) with radial
  /// spacing 0.75·d, when needed (null if not needed or not possible).
  final double? aswPerPerimeter;

  final List<Check> checks;

  const PunchingDesign({
    required this.u1,
    required this.demand,
    required this.resistance,
    required this.faceStress,
    required this.faceLimit,
    required this.aswPerPerimeter,
    required this.checks,
  });

  bool get needsReinforcement => demand > resistance;
}

/// Punching of a footing under a c1 × c2 column carrying [nEd] (kN, ULS)
/// with a uniform net soil pressure [sigma] (kPa) that relieves the load
/// inside the control perimeter.
Check footingPunching({
  required DesignCode code,
  required double c1,
  required double c2,
  required double nEd,
  required double sigma,
  required double d,
  required double h,
  required double rhoL,
  required double fck,
}) {
  final s = sigma / 1e3; // N/mm²
  switch (code) {
    case DesignCode.ec2:
      // 6.4.4(2): perimeters within 2d; check a = d and a = 2d.
      final k = math.min(1 + math.sqrt(200 / d), 2.0);
      final rho = math.min(rhoL, 0.02);
      final vMin = 0.035 * math.pow(k, 1.5) * math.sqrt(fck);
      final vc = math.max(0.12 * k * math.pow(100 * rho * fck, 1 / 3), vMin);
      var worst = -1.0;
      var demand = 0.0, capacity = 1.0;
      for (final a in [d, 2 * d]) {
        final inside = c1 * c2 + 2 * a * (c1 + c2) + math.pi * a * a;
        final vRed = nEd * 1e3 - s * inside;
        final u = 2 * (c1 + c2) + 2 * math.pi * a;
        final vEd = vRed / (u * d);
        final vRd = vc * 2 * d / a;
        if (vEd / vRd > worst) {
          worst = vEd / vRd;
          demand = vEd;
          capacity = vRd;
        }
      }
      return Check(
        kind: CheckKind.punching,
        demand: demand,
        capacity: capacity,
        clause: 'EN 1992-1-1 6.4.4',
        unit: 'MPa',
      );
    case DesignCode.bael:
      final uc = 2 * (c1 + c2 + 2 * h);
      final inside = (c1 + h) * (c2 + h);
      final qu = nEd * 1e3 - s * inside;
      return Check(
        kind: CheckKind.punching,
        demand: qu / 1e3,
        capacity: 0.045 * uc * h * fck / Concrete.gammaC / 1e3,
        clause: 'BAEL A.5.2.42',
        unit: 'kN',
      );
  }
}

/// [vEd] ULS load (kN); [d] mean effective depth and [h] thickness (mm);
/// [rhoL] mean tension steel ratio √(ρx·ρy); [beta] EC2 eccentricity
/// factor (1.15 for an interior column, 1.0 for a centred load).
PunchingDesign designPunching({
  required DesignCode code,
  required double c1,
  required double c2,
  required double vEd,
  required double d,
  required double h,
  required double rhoL,
  required double fck,
  required double fyk,
  double beta = 1.15,
}) {
  requirePositive(c1, 'c1');
  requirePositive(c2, 'c2');
  requirePositive(vEd, 'vEd');
  final concrete = Concrete(code, fck);
  final v = vEd * 1e3;

  switch (code) {
    case DesignCode.ec2:
      // 6.4.2: basic control perimeter at 2d.
      final u1 = 2 * (c1 + c2) + 4 * math.pi * d;
      final u0 = 2 * (c1 + c2);
      final vEd1 = beta * v / (u1 * d); // 6.4.3(3)
      final k = math.min(1 + math.sqrt(200 / d), 2.0);
      final rho = math.min(rhoL, 0.02);
      final vMin = 0.035 * math.pow(k, 1.5) * math.sqrt(fck);
      final vRdc = math.max(0.12 * k * math.pow(100 * rho * fck, 1 / 3), vMin);
      // 6.4.5(3) as amended (A1:2014): vRd,max = 0.4·ν·fcd.
      final nu = 0.6 * (1 - fck / 250);
      final vRdMax = 0.4 * nu * concrete.fcd;
      final vEd0 = beta * v / (u0 * d);
      double? asw;
      if (vEd1 > vRdc && vEd0 <= vRdMax) {
        // 6.4.5(1) eq. 6.52 with sr = 0.75d, vertical links.
        final fywdEf = math.min(250 + 0.25 * d, fyk / RebarSteel.gammaS);
        asw = (vEd1 - 0.75 * vRdc) * u1 / (1.5 * fywdEf);
      }
      return PunchingDesign(
        u1: u1,
        demand: vEd1,
        resistance: vRdc,
        faceStress: vEd0,
        faceLimit: vRdMax,
        aswPerPerimeter: asw,
        checks: [
          Check(
            kind: CheckKind.punching,
            demand: vEd0,
            capacity: vRdMax,
            clause: 'EN 1992-1-1 6.4.5(3)',
            unit: 'MPa',
          ),
          if (asw == null)
            Check(
              kind: CheckKind.punching,
              demand: vEd1,
              capacity: vRdc,
              clause: 'EN 1992-1-1 6.4.4',
              unit: 'MPa',
            ),
        ],
      );
    case DesignCode.bael:
      // A.5.2.42: Qu ≤ 0.045·uc·h·fc28/γb, uc at h/2 from the loaded area.
      final uc = 2 * (c1 + c2 + 2 * h);
      final resistance = 0.045 * uc * h * fck / Concrete.gammaC / 1e3;
      return PunchingDesign(
        u1: uc,
        demand: vEd,
        resistance: resistance,
        faceStress: null,
        faceLimit: null,
        aswPerPerimeter: null,
        checks: [
          Check(
            kind: CheckKind.punching,
            demand: vEd,
            capacity: resistance,
            clause: 'BAEL A.5.2.42',
            unit: 'kN',
          ),
        ],
      );
  }
}
