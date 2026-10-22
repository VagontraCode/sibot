import 'dart:math' as math;

import 'core.dart';
import 'materials.dart';
import 'rebar.dart';

/// Rigid pile cap under a centred rectangular column, designed with the
/// strut-and-tie (Blévot) model. Piles are equally spaced: in line (2),
/// at the corners of an equilateral triangle (3) or of a square (4).
class PileCapInput {
  final DesignCode code;

  /// Column design load at ULS, kN (cap self-weight is added).
  final double nEd;
  final int piles;

  /// Pile centre spacing, m, and pile diameter, mm.
  final double spacing;
  final double pileDiameter;

  /// Column side, mm, along the pile line (x), and across it (null =
  /// square).
  final double column;
  final double? columnB;

  /// ULS moments at the cap underside, kN·m: [mx] about x (varies the
  /// reactions along y), [my] about y (along x).
  final double mx;
  final double my;

  /// Design compressive resistance of one pile, kN (null = not checked).
  final double? pileCapacity;

  /// Cap depth, bottom cover to the ties and edge distance beyond the
  /// pile faces, mm.
  final double h;
  final double cover;
  final double edge;

  final double fck;
  final double fyk;

  const PileCapInput({
    required this.nEd,
    required this.piles,
    required this.spacing,
    required this.pileDiameter,
    required this.column,
    required this.h,
    this.columnB,
    this.mx = 0,
    this.my = 0,
    this.pileCapacity,
    this.code = DesignCode.ec2,
    this.cover = 50,
    this.edge = 150,
    this.fck = 25,
    this.fyk = 500,
  });
}

class PileCapResult {
  final double d;

  /// Plan dimensions (m) and self-weight (kN, characteristic).
  final double length;
  final double width;
  final double selfWeight;

  /// Mean pile reaction at ULS, kN, and the extreme ones under the
  /// moments (R = N/n ± M x / Σx²).
  final double reaction;
  final double maxReaction;
  final double minReaction;

  /// A pile is pulled (minimum reaction < 0).
  bool get tension => minReaction < -1e-9;

  /// Strut angle to the horizontal, degrees.
  final double theta;

  /// Force and steel of each tie (2 piles: 1 tie; 3: 3 side ties;
  /// 4: 4 side ties), kN and mm².
  final int ties;
  final double tieForce;
  final double asTie;
  final BarSet? bars;

  /// Node stresses and limits, MPa.
  final double sigmaColumn;
  final double sigmaPile;
  final double limitColumn;
  final double limitPile;

  /// Depth range giving 45° ≤ θ ≤ 55°, mm.
  final double hMin;
  final double hMax;

  final List<Check> checks;
  bool get ok => checks.every((c) => c.ok);

  const PileCapResult({
    required this.d,
    required this.length,
    required this.width,
    required this.selfWeight,
    required this.reaction,
    required this.maxReaction,
    required this.minReaction,
    required this.theta,
    required this.ties,
    required this.tieForce,
    required this.asTie,
    required this.bars,
    required this.sigmaColumn,
    required this.sigmaPile,
    required this.limitColumn,
    required this.limitPile,
    required this.hMin,
    required this.hMax,
    required this.checks,
  });
}

PileCapResult designPileCap(PileCapInput i) {
  if (i.piles < 2 || i.piles > 4) {
    throw const InputError(InputProblem.outOfRange, 'piles');
  }
  requirePositive(i.nEd, 'nEd');
  requirePositive(i.spacing, 'spacing');
  requirePositive(i.pileDiameter, 'pileDiameter');
  requirePositive(i.column, 'column');
  requirePositive(i.h, 'h');
  requirePositive(i.cover, 'cover');
  requireRange(i.edge, 0, 2000, 'edge');
  final concrete = Concrete(i.code, i.fck);
  final steel = RebarSteel(i.fyk);
  final e = i.spacing * 1e3, a = i.column, dp = i.pileDiameter;
  final b = i.columnB ?? a;
  requirePositive(b, 'columnB');
  if (i.pileCapacity != null) requirePositive(i.pileCapacity!, 'pileCapacity');
  if (e < 2 * dp) {
    // Piles closer than two diameters interact (EC7 / DTU 13.2 practice).
    throw const InputError(InputProblem.inconsistentGeometry, 'spacing');
  }
  if (a >= e || (i.piles > 2 && b >= e)) {
    throw const InputError(InputProblem.inconsistentGeometry, 'column');
  }
  final d = i.h - i.cover - 12;
  if (d <= 0) {
    throw const InputError(InputProblem.inconsistentGeometry, 'h');
  }

  // Plan dimensions and self-weight.
  final over = dp / 2 + i.edge;
  final double length, width, area;
  switch (i.piles) {
    case 2:
      length = e + 2 * over;
      width = 2 * over;
      area = length * width;
    case 3:
      // Equilateral triangle whose sides lie `over` outside the pile
      // centres (corners not cut: slightly conservative self-weight).
      final side = e + 2 * over * math.sqrt(3);
      length = side;
      width = side * math.sqrt(3) / 2;
      area = math.sqrt(3) / 4 * side * side;
    default:
      length = e + 2 * over;
      width = length;
      area = length * length;
  }
  final selfWeight = 25 * area * i.h * 1e-9;
  final nTotal = i.nEd + 1.35 * selfWeight;
  final r = nTotal / i.piles;

  // Pile coordinates (mm) and reactions under the moments.
  final piles = switch (i.piles) {
    2 => [(-e / 2, 0.0), (e / 2, 0.0)],
    3 => [
      (0.0, e / math.sqrt(3)),
      (-e / 2, -e / (2 * math.sqrt(3))),
      (e / 2, -e / (2 * math.sqrt(3))),
    ],
    _ => [(-e / 2, -e / 2), (e / 2, -e / 2), (-e / 2, e / 2), (e / 2, e / 2)],
  };
  final sxx = piles.fold<double>(0, (s, p) => s + p.$1 * p.$1);
  final syy = piles.fold<double>(0, (s, p) => s + p.$2 * p.$2);
  if (i.mx != 0 && syy < 1e-9) {
    // Piles in one line cannot carry a moment about that line.
    throw const InputError(InputProblem.inconsistentGeometry, 'mx');
  }
  final reactions = [
    for (final (x, y) in piles)
      r + i.my * 1e3 * x / sxx + (syy > 0 ? i.mx * 1e3 * y / syy : 0),
  ];
  final rMax = reactions.reduce(math.max);
  final rMin = reactions.reduce(math.min);

  // Horizontal distance from the column node to a pile, mm.
  final lx = e / 2 - a / 4, ly = e / 2 - b / 4;
  final l = switch (i.piles) {
    2 => lx,
    3 => e / math.sqrt(3) - 0.3 * math.sqrt(a * b),
    _ => math.sqrt(lx * lx + ly * ly),
  };
  final tanT = d / l;
  final theta = math.atan(tanT) * 180 / math.pi;
  final sin2 = tanT * tanT / (1 + tanT * tanT);

  // Tie forces, every tie designed for the largest reaction.
  final h = rMax * l / d; // horizontal strut component at a pile, kN
  final (ties, t) = switch (i.piles) {
    2 => (1, h),
    3 => (3, h / math.sqrt(3)),
    _ => (4, rMax * math.max(lx, ly) / d),
  };
  final asTie = t * 1e3 / steel.fyd;
  final bars = chooseBars(asTie, dp, maxCount: 10);

  // Node stresses (EN 1992-1-1 6.5.4): CCC under the column, CCT over
  // the piles.
  final nu = 1 - i.fck / 250;
  final limitColumn = 1.0 * nu * concrete.fcd;
  final limitPile = 0.85 * nu * concrete.fcd;
  final sigmaColumn = i.nEd * 1e3 / (a * b * sin2);
  final sigmaPile = rMax * 1e3 / (math.pi * dp * dp / 4 * sin2);

  // Depths for θ = 45° and 55°.
  final extra = i.cover + 12;
  final hMin = l + extra;
  final hMax = l * math.tan(55 * math.pi / 180) + extra;

  final ref = i.code == DesignCode.ec2 ? 'EN 1992-1-1' : 'BAEL';
  return PileCapResult(
    d: d,
    length: length / 1e3,
    width: width / 1e3,
    selfWeight: selfWeight,
    reaction: r,
    maxReaction: rMax,
    minReaction: rMin,
    theta: theta,
    ties: ties,
    tieForce: t,
    asTie: asTie,
    bars: bars,
    sigmaColumn: sigmaColumn,
    sigmaPile: sigmaPile,
    limitColumn: limitColumn,
    limitPile: limitPile,
    hMin: hMin,
    hMax: hMax,
    checks: [
      Check(
        kind: CheckKind.strutAngle,
        demand: 45,
        capacity: theta,
        clause: 'Blévot · θ ≥ 45°',
        unit: '°',
      ),
      Check(
        kind: CheckKind.strutAngle,
        demand: theta,
        capacity: 55,
        clause: 'Blévot · θ ≤ 55°',
        unit: '°',
      ),
      Check(
        kind: CheckKind.tieSteel,
        demand: asTie,
        capacity: bars?.area ?? 0,
        clause: '$ref 6.5.3',
        unit: 'mm²',
      ),
      Check(
        kind: CheckKind.nodeColumn,
        demand: sigmaColumn,
        capacity: limitColumn,
        clause: 'EN 1992-1-1 6.5.4 (6.60)',
        unit: 'MPa',
      ),
      Check(
        kind: CheckKind.nodePile,
        demand: sigmaPile,
        capacity: limitPile,
        clause: 'EN 1992-1-1 6.5.4 (6.61)',
        unit: 'MPa',
      ),
      if (i.pileCapacity != null)
        Check(
          kind: CheckKind.pileReaction,
          demand: rMax,
          capacity: i.pileCapacity!,
          clause: 'EN 1997-1 7.6.2',
          unit: 'kN',
        ),
    ],
  );
}
