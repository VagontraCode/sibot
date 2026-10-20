import 'dart:math' as math;

import 'core.dart';
import 'materials.dart';
import 'rc_interaction.dart';
import 'rebar.dart';

enum ColumnShape { rectangular, circular }

enum ColumnNote {
  /// λ > λlim in at least one direction: second-order moment included.
  secondOrderIncluded,

  /// BAEL: centred compression formula (B.8.4) used.
  baelCentredCompression,

  /// Slenderness beyond the method's range; a buckling analysis is needed.
  slendernessOutOfScope,

  /// No bar arrangement up to the maximum ratio is sufficient.
  sectionTooSmall,

  /// Moments act in both directions: biaxial check EN 1992-1-1 5.8.9(4).
  biaxial,
}

class ColumnInput {
  final DesignCode code;
  final ColumnShape shape;

  /// Rectangular section b × h (mm); for a circular section [b] is the
  /// diameter and [h] is ignored.
  final double b;
  final double h;
  final double cover;
  final int linkDiameter;

  /// Effective (buckling) length l0 / lf, same in both directions, m.
  final double l0;

  /// Design axial load (compression), kN.
  final double nEd;

  /// First-order design moments, kN·m: [m0Ed] bends the section in the
  /// h direction (about the axis parallel to b), [m0EdB] in the b
  /// direction. For a circular section they are combined vectorially.
  final double m0Ed;
  final double m0EdB;

  final double fck;
  final double fyk;

  /// EC2 effective creep ratio φef (5.8.4).
  final double creepRatio;

  const ColumnInput({
    required this.code,
    required this.b,
    required this.l0,
    required this.nEd,
    required this.fck,
    required this.fyk,
    this.h = 0,
    this.shape = ColumnShape.rectangular,
    this.m0Ed = 0,
    this.m0EdB = 0,
    this.cover = 30,
    this.linkDiameter = 8,
    this.creepRatio = 1.0,
  });

  bool get circular => shape == ColumnShape.circular;
}

/// Bar arrangement. Rectangular: [perFaceB] bars on each face of width b
/// (corners included) and [perFaceH] on each face of width h. Circular:
/// [count] bars on a circle.
class ColumnBars {
  final int diameter;
  final int count;
  final int perFaceB;
  final int perFaceH;

  const ColumnBars.rect(this.diameter, this.perFaceB, this.perFaceH)
    : count = 2 * perFaceB + 2 * perFaceH - 4;

  const ColumnBars.circle(this.diameter, this.count)
    : perFaceB = 0,
      perFaceH = 0;

  double get area => count * barArea(diameter);
  BarSet get set => BarSet(count, diameter);

  @override
  String toString() => set.toString();
}

/// Results for one bending direction.
class ColumnDirection {
  final double slenderness;
  final double slendernessLimit;
  final double imperfection;
  final double secondOrder;

  /// Largest design moment over the imperfection cases, kN·m.
  final double mEd;

  /// Moment resistance at NEd with the chosen bars, kN·m.
  final double? mRd;

  final List<NMPoint> interaction;

  const ColumnDirection({
    required this.slenderness,
    required this.slendernessLimit,
    required this.imperfection,
    required this.secondOrder,
    required this.mEd,
    required this.mRd,
    required this.interaction,
  });
}

class ColumnDesign {
  final ColumnInput input;

  /// Direction h (or the single direction of a circular column).
  final ColumnDirection dirH;

  /// Direction b (rectangular columns only).
  final ColumnDirection? dirB;

  final double asRequired;
  final double asMin;
  final double asMax;
  final ColumnBars? bars;
  final int linkDiameter;
  final int linkSpacing;

  /// Axial resistance with the chosen bars, kN.
  final double nRd;

  /// True when the BAEL centred-compression method was used.
  final bool centred;

  final List<Check> checks;
  final List<ColumnNote> notes;

  const ColumnDesign({
    required this.input,
    required this.dirH,
    required this.dirB,
    required this.asRequired,
    required this.asMin,
    required this.asMax,
    required this.bars,
    required this.linkDiameter,
    required this.linkSpacing,
    required this.nRd,
    required this.centred,
    required this.checks,
    required this.notes,
  });

  double get slenderness => dirH.slenderness;
  double get slendernessLimit => dirH.slendernessLimit;
  double get imperfection => dirH.imperfection;
  double get secondOrder => dirH.secondOrder;
  double get mEd => dirH.mEd;
  double? get mRd => dirH.mRd;
  List<NMPoint> get interaction => dirH.interaction;

  bool get ok => checks.every((c) => c.ok);
}

const _diameters = [12, 14, 16, 20, 25, 32];

/// Exponent a of EN 1992-1-1 5.8.9(4), interpolated in NEd/NRd.
double biaxialExponent(double ratio) {
  if (ratio <= 0.1) return 1.0;
  if (ratio <= 0.7) return 1.0 + (ratio - 0.1) / 0.6 * 0.5;
  if (ratio <= 1.0) return 1.5 + (ratio - 0.7) / 0.3 * 0.5;
  return 2.0;
}

/// Geometry of one bending direction.
class _Dir {
  final ConcreteShape shape;
  final double depth;

  /// Effective depth for the nominal curvature (EC2 5.8.8.3(2)), mm.
  final double d;
  final double radius;
  final double m0;
  final List<SectionBar> Function(ColumnBars bars, double scale) barsFor;

  _Dir({
    required this.shape,
    required this.depth,
    required this.d,
    required this.radius,
    required this.m0,
    required this.barsFor,
  });
}

ColumnDesign designColumn(ColumnInput i) {
  requirePositive(i.b, 'b');
  if (!i.circular) requirePositive(i.h, 'h');
  requirePositive(i.l0, 'l0');
  requirePositive(i.nEd, 'nEd');
  if (i.m0Ed < 0) throw const InputError(InputProblem.outOfRange, 'm0Ed');
  if (i.m0EdB < 0) throw const InputError(InputProblem.outOfRange, 'm0EdB');
  requireRange(i.creepRatio, 0, 4, 'creepRatio');

  final concrete = Concrete(i.code, i.fck);
  final steel = RebarSteel(i.fyk);
  final edge = i.cover + i.linkDiameter; // to the bar surface
  final ac = i.circular ? math.pi * i.b * i.b / 4 : i.b * i.h;
  if (2 * edge + 24 >= math.min(i.b, i.circular ? i.b : i.h)) {
    throw const InputError(InputProblem.inconsistentGeometry, 'cover');
  }

  // Directions and bar positions.
  late final List<_Dir> dirs;
  if (i.circular) {
    final dia = i.b;
    List<SectionBar> circleBars(ColumnBars bars, double scale, double phase) {
      final rs = dia / 2 - edge - bars.diameter / 2;
      final a = barArea(bars.diameter) * scale;
      return [
        for (var k = 0; k < bars.count; k++)
          SectionBar(
            dia / 2 - rs * math.cos(phase + 2 * math.pi * k / bars.count),
            a,
          ),
      ];
    }

    dirs = [
      _Dir(
        shape: CircleShape(dia),
        depth: dia,
        // 5.8.8.3(2): d = h/2 + is, is = rs/√2 for bars on a circle.
        d: dia / 2 + (dia / 2 - edge - 8) / math.sqrt2,
        radius: dia / 4,
        m0: math.sqrt(i.m0Ed * i.m0Ed + i.m0EdB * i.m0EdB),
        barsFor: (bars, scale) => circleBars(bars, scale, 0),
      ),
    ];
  } else {
    List<SectionBar> rectBars(
      ColumnBars bars,
      double scale,
      double depth,
      int perFace,
      int perSide,
    ) {
      final a = barArea(bars.diameter) * scale;
      final e = edge + bars.diameter / 2;
      final out = [
        SectionBar(e, perFace * a),
        SectionBar(depth - e, perFace * a),
      ];
      for (var k = 1; k <= perSide - 2; k++) {
        out.add(SectionBar(e + (depth - 2 * e) * k / (perSide - 1), 2 * a));
      }
      return out;
    }

    dirs = [
      _Dir(
        shape: RectShape(i.b, i.h),
        depth: i.h,
        d: i.h - edge - 8,
        radius: i.h / math.sqrt(12),
        m0: i.m0Ed,
        barsFor: (bars, s) =>
            rectBars(bars, s, i.h, bars.perFaceB, bars.perFaceH),
      ),
      _Dir(
        shape: RectShape(i.h, i.b),
        depth: i.b,
        d: i.b - edge - 8,
        radius: i.b / math.sqrt(12),
        m0: i.m0EdB,
        barsFor: (bars, s) =>
            rectBars(bars, s, i.b, bars.perFaceH, bars.perFaceB),
      ),
    ];
  }

  final notes = <ColumnNote>[];
  final l0mm = i.l0 * 1000;
  final lambdas = [for (final d in dirs) l0mm / d.radius];

  // Steel limits.
  late double asMin, asMax;
  switch (i.code) {
    case DesignCode.ec2:
      asMin = math.max(0.10 * i.nEd * 1e3 / steel.fyd, 0.002 * ac); // 9.5.2(2)
      asMax = 0.04 * ac; // 9.5.2(3)
    case DesignCode.bael:
      final perimeter = i.circular ? math.pi * i.b : 2 * (i.b + i.h);
      asMin = math.max(400 * perimeter / 1000, 0.002 * ac); // A.8.1.21
      asMax = 0.05 * ac;
  }

  // EC2 slenderness limit (5.8.3.1) with A from φef, B = 1.1, C = 0.7.
  final nRel = i.nEd * 1e3 / (ac * concrete.fcd);
  final lambdaLimEc2 =
      20 * (1 / (1 + 0.2 * i.creepRatio)) * 1.1 * 0.7 / math.sqrt(nRel);

  final centred = i.code == DesignCode.bael && i.m0Ed == 0 && i.m0EdB == 0;
  final lambdaMax = lambdas.reduce(math.max);
  if (i.code == DesignCode.bael && lambdaMax > 70) {
    notes.add(ColumnNote.slendernessOutOfScope);
  }

  // Imperfection and minimum eccentricities, mm.
  final ei = i.code == DesignCode.ec2
      ? l0mm /
            400 // 5.2(9)
      : math.max(20.0, l0mm / 250); // BAEL A.4.3.5

  // Second-order eccentricity of direction k for total steel [as].
  double e2For(int k, double as) {
    final dir = dirs[k];
    switch (i.code) {
      case DesignCode.ec2:
        if (lambdas[k] <= lambdaLimEc2) return 0;
        // 5.8.8.3: 1/r = Kr·Kφ·εyd/(0.45·d); e2 = (1/r)·l0²/10.
        final omega = as * steel.fyd / (ac * concrete.fcd);
        final nu = 1 + omega;
        final kr = math.min(1.0, (nu - nRel) / (nu - 0.4));
        final beta = 0.35 + i.fck / 200 - lambdas[k] / 150;
        final kPhi = math.max(1.0, 1 + beta * i.creepRatio);
        return kr * kPhi * steel.epsYd / (0.45 * dir.d) * l0mm * l0mm / 10;
      case DesignCode.bael:
        // A.4.4 with φ = 2 and α = 1 (conservative).
        final e1 = dir.m0 * 1e3 / i.nEd + ei;
        if (l0mm / dir.depth > math.max(15, 20 * e1 / dir.depth) &&
            !notes.contains(ColumnNote.slendernessOutOfScope)) {
          notes.add(ColumnNote.slendernessOutOfScope);
        }
        return 3 * l0mm * l0mm * (2 + 2) / (1e4 * dir.depth);
    }
  }

  double minEcc(int k) => i.code == DesignCode.ec2
      ? math.max(dirs[k].depth / 30, 20.0) // 6.1(4)
      : 0;

  // Design moments of every direction for the case where the imperfection
  // acts in direction [k] (EC2 5.8.9(2): one direction at a time).
  List<double> momentsFor(int k, double as) => [
    for (var j = 0; j < dirs.length; j++)
      if (j == k)
        math.max(dirs[j].m0 + i.nEd * ei / 1e3, i.nEd * minEcc(j) / 1e3) +
            i.nEd * e2For(j, as) / 1e3
      else if (dirs[j].m0 > 0)
        dirs[j].m0 + i.nEd * e2For(j, as) / 1e3
      else
        0.0,
  ];

  SectionNM section(int k, ColumnBars bars, double scale) => SectionNM(
    shape: dirs[k].shape,
    bars: dirs[k].barsFor(bars, scale),
    fc: concrete.fBlock,
    fyd: steel.fyd,
  );

  // Worst utilisation of an arrangement (bar areas scaled by [scale]).
  double utilisation(ColumnBars bars, double scale) {
    final as = bars.area * scale;
    final mRd = <double>[];
    for (var k = 0; k < dirs.length; k++) {
      var m = section(k, bars, scale).momentResistance(i.nEd);
      if (m == null) return double.infinity;
      if (i.circular) {
        // Worst bar orientation: also try bars rotated by half a pitch.
        final rotated = SectionNM(
          shape: dirs[k].shape,
          bars: [
            for (var j = 0; j < bars.count; j++)
              SectionBar(
                i.b / 2 -
                    (i.b / 2 - edge - bars.diameter / 2) *
                        math.cos(
                          math.pi / bars.count + 2 * math.pi * j / bars.count,
                        ),
                barArea(bars.diameter) * scale,
              ),
          ],
          fc: concrete.fBlock,
          fyd: steel.fyd,
        ).momentResistance(i.nEd);
        if (rotated == null) return double.infinity;
        m = math.min(m, rotated);
      }
      mRd.add(m);
    }
    final nRd = (ac * concrete.fcd + as * steel.fyd) / 1e3;
    final a = biaxialExponent(i.nEd / nRd);
    var worst = 0.0;
    for (var k = 0; k < dirs.length; k++) {
      final m = momentsFor(k, as);
      final active = [
        for (var j = 0; j < m.length; j++)
          if (m[j] > 0) j,
      ];
      final double u;
      if (active.length <= 1) {
        final j = active.isEmpty ? k : active.first;
        u = mRd[j] <= 0 ? double.infinity : m[j] / mRd[j];
      } else {
        u = active.fold(0.0, (s, j) => s + math.pow(m[j] / mRd[j], a));
      }
      worst = math.max(worst, u);
    }
    return worst;
  }

  // Candidate arrangements, cheapest first.
  final candidates = <ColumnBars>[];
  for (final dia in _diameters) {
    if (i.circular) {
      final rs = i.b / 2 - edge - dia / 2;
      for (var n = 6; n <= 16; n++) {
        final clear = 2 * math.pi * rs / n - dia;
        if (clear >= minClearSpacing(dia)) {
          candidates.add(ColumnBars.circle(dia, n));
        }
      }
    } else {
      for (var pB = 2; pB <= 6; pB++) {
        for (var pH = 2; pH <= 6; pH++) {
          final innerB = i.b - 2 * edge, innerH = i.h - 2 * edge;
          final clearB = (innerB - pB * dia) / (pB - 1);
          final clearH = (innerH - pH * dia) / (pH - 1);
          if (clearB < minClearSpacing(dia) || clearH < minClearSpacing(dia)) {
            continue;
          }
          candidates.add(ColumnBars.rect(dia, pB, pH));
        }
      }
    }
  }
  candidates.sort((x, y) {
    final c = x.area.compareTo(y.area);
    return c != 0 ? c : x.count.compareTo(y.count);
  });

  // BAEL centred compression (B.8.4.1).
  double alphaBael() => lambdaMax <= 50
      ? 0.85 / (1 + 0.2 * math.pow(lambdaMax / 35, 2))
      : 0.6 * math.pow(50 / lambdaMax, 2);
  final br = i.circular
      ? math.pi * math.pow(i.b - 20, 2) / 4
      : (i.b - 20) * (i.h - 20);
  double nRdBael(double as) =>
      alphaBael() *
      (br * i.fck / (0.9 * Concrete.gammaC) + as * i.fyk / RebarSteel.gammaS) /
      1e3;

  ColumnBars? chosen;
  double asReq;
  if (centred) {
    final need =
        (i.nEd * 1e3 / alphaBael() - br * i.fck / (0.9 * Concrete.gammaC)) *
        RebarSteel.gammaS /
        i.fyk;
    asReq = need > asMax ? double.infinity : math.max(need, asMin);
    for (final c in candidates) {
      if (c.area + 1e-9 >= asReq && c.area <= asMax) {
        chosen = c;
        break;
      }
    }
  } else {
    for (final c in candidates) {
      if (c.area + 1e-9 < asMin || c.area > asMax) continue;
      if (utilisation(c, 1) <= 1) {
        chosen = c;
        break;
      }
    }
    if (chosen == null) {
      asReq = double.infinity;
    } else {
      // Smallest scale of the chosen layout that still works.
      double lo = 0, hi = 1;
      if (utilisation(chosen, 1e-6) <= 1) {
        hi = 1e-6;
      } else {
        for (var k = 0; k < 40; k++) {
          final mid = 0.5 * (lo + hi);
          if (utilisation(chosen, mid) <= 1) {
            hi = mid;
          } else {
            lo = mid;
          }
        }
      }
      asReq = math.max(hi * chosen.area, asMin);
    }
  }
  if (chosen == null) notes.add(ColumnNote.sectionTooSmall);

  final asProv = chosen?.area ?? 0;
  final shown = chosen ?? ColumnBars.rect(12, 2, 2);
  final scale = chosen == null ? 0.0 : 1.0;

  if (i.code == DesignCode.ec2 &&
      [for (final l in lambdas) l > lambdaLimEc2].any((s) => s)) {
    notes.add(ColumnNote.secondOrderIncluded);
  }
  if (centred) notes.add(ColumnNote.baelCentredCompression);

  // Per-direction results.
  final directions = <ColumnDirection>[];
  for (var k = 0; k < dirs.length; k++) {
    final mEd = [
      for (var c = 0; c < dirs.length; c++) momentsFor(c, asProv)[k],
    ].reduce(math.max);
    final sec = section(k, shown, scale);
    directions.add(
      ColumnDirection(
        slenderness: lambdas[k],
        slendernessLimit: i.code == DesignCode.ec2 ? lambdaLimEc2 : 70,
        imperfection: centred ? 0 : ei,
        secondOrder: centred ? 0 : e2For(k, asProv),
        mEd: centred ? 0 : mEd,
        mRd: centred ? null : sec.momentResistance(i.nEd),
        interaction: sec.curve(),
      ),
    );
  }
  final biaxial = !centred && !i.circular && (i.m0Ed > 0 || i.m0EdB > 0);
  if (biaxial && i.m0Ed > 0 && i.m0EdB > 0) notes.add(ColumnNote.biaxial);

  // Links: EC2 9.5.3 / BAEL A.8.1.3.
  final barDia = chosen?.diameter ?? 12;
  final linkDia = math.max(i.linkDiameter, (barDia / 4).ceil());
  final minDim = i.circular ? i.b : math.min(i.b, i.h);
  final sMax = switch (i.code) {
    DesignCode.ec2 => math.min(20.0 * barDia, math.min(minDim, 400.0)),
    DesignCode.bael => math.min(15.0 * barDia, math.min(minDim + 100, 400.0)),
  };
  final linkSpacing = (sMax / 25).floor() * 25;

  final nRd = centred ? nRdBael(asProv) : section(0, shown, scale).nMax;
  final util = centred || chosen == null ? null : utilisation(chosen, 1);

  final clauseNM = i.code == DesignCode.ec2
      ? 'EN 1992-1-1 6.1, 5.8.8'
      : 'BAEL A.4.3, A.4.4';
  final checks = <Check>[
    if (i.code == DesignCode.bael)
      Check(
        kind: CheckKind.slenderness,
        demand: lambdaMax,
        capacity: 70,
        clause: 'BAEL B.8.4.1',
      ),
    if (centred)
      Check(
        kind: CheckKind.axialBending,
        demand: i.nEd,
        capacity: nRd,
        clause: 'BAEL B.8.4.1',
        unit: 'kN',
      )
    else ...[
      for (final d in directions)
        Check(
          kind: CheckKind.axialBending,
          demand: d.mEd,
          capacity: d.mRd ?? 0,
          clause: clauseNM,
          unit: 'kN·m',
        ),
      if (biaxial)
        Check(
          kind: CheckKind.axialBending,
          demand: util ?? double.infinity,
          capacity: 1,
          clause: 'EN 1992-1-1 5.8.9(4)',
        ),
    ],
    Check(
      kind: CheckKind.minSteel,
      demand: asMin,
      capacity: asProv,
      clause: i.code == DesignCode.ec2
          ? 'EN 1992-1-1 9.5.2(2)'
          : 'BAEL A.8.1.21',
      unit: 'mm²',
    ),
    Check(
      kind: CheckKind.maxSteel,
      demand: asProv,
      capacity: asMax,
      clause: i.code == DesignCode.ec2
          ? 'EN 1992-1-1 9.5.2(3)'
          : 'BAEL A.8.1.21',
      unit: 'mm²',
    ),
  ];

  return ColumnDesign(
    input: i,
    dirH: directions[0],
    dirB: directions.length > 1 ? directions[1] : null,
    asRequired: asReq,
    asMin: asMin,
    asMax: asMax,
    bars: chosen,
    linkDiameter: linkDia,
    linkSpacing: linkSpacing,
    nRd: nRd,
    centred: centred,
    checks: checks,
    notes: notes,
  );
}
