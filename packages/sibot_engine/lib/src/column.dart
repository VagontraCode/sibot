import 'dart:math' as math;

import 'core.dart';
import 'materials.dart';
import 'rc_interaction.dart';
import 'rebar.dart';

enum ColumnNote {
  /// EC2: λ > λlim, second-order moment added (nominal curvature).
  secondOrderIncluded,

  /// BAEL: centred compression formula (B.8.4) used.
  baelCentredCompression,

  /// BAEL: λ beyond the method's range; a buckling analysis is needed.
  slendernessOutOfScope,

  /// No bar arrangement up to the maximum ratio is sufficient.
  sectionTooSmall,
}

class ColumnInput {
  final DesignCode code;

  /// Section b × h, mm; bending acts about the axis parallel to b.
  final double b;
  final double h;
  final double cover;
  final int linkDiameter;

  /// Effective (buckling) length l0 / lf, m.
  final double l0;

  /// Design axial load (compression) and first-order moment.
  final double nEd;
  final double m0Ed;

  final double fck;
  final double fyk;

  /// EC2 effective creep ratio φef (5.8.4).
  final double creepRatio;

  const ColumnInput({
    required this.code,
    required this.b,
    required this.h,
    required this.l0,
    required this.nEd,
    required this.fck,
    required this.fyk,
    this.m0Ed = 0,
    this.cover = 30,
    this.linkDiameter = 8,
    this.creepRatio = 1.0,
  });
}

class ColumnDesign {
  final ColumnInput input;
  final double slenderness;

  /// EC2 λlim (5.8.3.1); BAEL: 70 (B.8.4.1).
  final double slendernessLimit;

  /// Eccentricities used, mm.
  final double imperfection;
  final double secondOrder;

  /// Design moment including imperfections and second order, kN·m.
  final double mEd;

  final double asRequired;
  final double asMin;
  final double asMax;
  final BarSet? bars;

  /// Links: diameter and maximum spacing (mm).
  final int linkDiameter;
  final int linkSpacing;

  /// Moment resistance at NEd with the chosen bars, kN·m (null for the
  /// BAEL centred-compression method).
  final double? mRd;

  /// Axial resistance with the chosen bars, kN.
  final double nRd;

  /// N–M curve of the section with the chosen bars.
  final List<NMPoint> interaction;

  final List<Check> checks;
  final List<ColumnNote> notes;

  const ColumnDesign({
    required this.input,
    required this.slenderness,
    required this.slendernessLimit,
    required this.imperfection,
    required this.secondOrder,
    required this.mEd,
    required this.asRequired,
    required this.asMin,
    required this.asMax,
    required this.bars,
    required this.linkDiameter,
    required this.linkSpacing,
    required this.mRd,
    required this.nRd,
    required this.interaction,
    required this.checks,
    required this.notes,
  });

  bool get ok => checks.every((c) => c.ok);
}

const _columnBarCounts = [4, 6, 8, 10, 12];
const _columnBarDiameters = [12, 14, 16, 20, 25, 32];

ColumnDesign designColumn(ColumnInput i) {
  requirePositive(i.b, 'b');
  requirePositive(i.h, 'h');
  requirePositive(i.l0, 'l0');
  requirePositive(i.nEd, 'nEd');
  if (i.m0Ed < 0) throw const InputError(InputProblem.outOfRange, 'm0Ed');
  requireRange(i.creepRatio, 0, 4, 'creepRatio');

  final concrete = Concrete(i.code, i.fck);
  final steel = RebarSteel(i.fyk);
  final ac = i.b * i.h;
  final d2 = i.cover + i.linkDiameter + 8; // centre of a Ø16 bar
  final d = i.h - d2;
  if (d <= d2) throw const InputError(InputProblem.inconsistentGeometry, 'h');

  final radius = i.h / math.sqrt(12);
  final lambda = i.l0 * 1000 / radius;
  final notes = <ColumnNote>[];

  RectSectionNM section(double asTotal) => RectSectionNM(
    b: i.b,
    h: i.h,
    d2: d2,
    asPerFace: asTotal / 2,
    fc: concrete.fBlock,
    fyd: steel.fyd,
  );

  // Smallest symmetric steel area for which MRd(NEd) ≥ mEd(As).
  double requiredSteel(double Function(double as) mEdFor, double asMax) {
    bool enough(double as) {
      final mRd = section(as).momentResistance(i.nEd);
      return mRd != null && mRd >= mEdFor(as);
    }

    if (enough(0)) return 0;
    if (!enough(asMax)) return double.infinity;
    double lo = 0, hi = asMax;
    for (var k = 0; k < 60; k++) {
      final mid = 0.5 * (lo + hi);
      if (enough(mid)) {
        hi = mid;
      } else {
        lo = mid;
      }
    }
    return hi;
  }

  late double lambdaLim, ei, asReq, asMin, asMax;
  late double Function(double as) e2Of;
  late double Function(double as) mEdFor;
  var centred = false;

  switch (i.code) {
    case DesignCode.ec2:
      final n = i.nEd * 1e3 / (ac * concrete.fcd);
      // 5.8.3.1: A from φef, B = 1.1, C = 0.7 (recommended defaults).
      final a = 1 / (1 + 0.2 * i.creepRatio);
      lambdaLim = 20 * a * 1.1 * 0.7 / math.sqrt(n);
      // 5.2(9): ei = l0/400; 6.1(4): e0 ≥ max(h/30, 20 mm).
      ei = i.l0 * 1000 / 400;
      final e0 = math.max(i.h / 30, 20.0);
      final m0 = math.max(i.m0Ed + i.nEd * ei / 1e3, i.nEd * e0 / 1e3);
      final slender = lambda > lambdaLim;
      if (slender) notes.add(ColumnNote.secondOrderIncluded);

      // 5.8.8.3: 1/r = Kr·Kφ·εyd/(0.45·d); e2 = (1/r)·l0²/10.
      double e2For(double as) {
        if (!slender) return 0;
        final omega = as * steel.fyd / (ac * concrete.fcd);
        final nu = 1 + omega;
        final kr = math.min(1.0, (nu - n) / (nu - 0.4));
        final beta = 0.35 + i.fck / 200 - lambda / 150;
        final kPhi = math.max(1.0, 1 + beta * i.creepRatio);
        final curvature = kr * kPhi * steel.epsYd / (0.45 * d);
        return curvature * math.pow(i.l0 * 1000, 2) / 10;
      }

      mEdFor = (as) => m0 + i.nEd * e2For(as) / 1e3;
      // 9.5.2(2) and (3).
      asMin = math.max(0.10 * i.nEd * 1e3 / steel.fyd, 0.002 * ac);
      asMax = 0.04 * ac;
      asReq = math.max(requiredSteel(mEdFor, asMax), asMin);
      e2Of = e2For;
    case DesignCode.bael:
      lambdaLim = 70;
      // A.8.1.21: 4 cm²/m of perimeter and 0.2 % of B; at most 5 % of B.
      final perimeterM = 2 * (i.b + i.h) / 1000;
      asMin = math.max(400 * perimeterM, 0.002 * ac);
      asMax = 0.05 * ac;
      if (lambda > 70) notes.add(ColumnNote.slendernessOutOfScope);

      if (i.m0Ed == 0 && lambda <= 70) {
        // B.8.4.1: Nu ≤ α·[Br·fc28/(0.9·γb) + A·fe/γs].
        centred = true;
        notes.add(ColumnNote.baelCentredCompression);
        final alpha = lambda <= 50
            ? 0.85 / (1 + 0.2 * math.pow(lambda / 35, 2))
            : 0.6 * math.pow(50 / lambda, 2);
        final br = (i.b - 20) * (i.h - 20);
        final concretePart = br * i.fck / (0.9 * Concrete.gammaC);
        final need =
            (i.nEd * 1e3 / alpha - concretePart) * RebarSteel.gammaS / i.fyk;
        asReq = math.max(need, asMin);
        if (need > asMax) asReq = double.infinity;
        ei = 0;
        e2Of = (_) => 0;
        mEdFor = (_) => 0;
      } else {
        // A.4.3.5: e1 = M/N + ea, ea = max(20 mm, l/250).
        ei = math.max(20.0, i.l0 * 1000 / 250);
        final e1 = i.m0Ed * 1e3 / i.nEd + ei;
        // A.4.4: second-order eccentricity when lf/h ≤ max(15, 20·e1/h),
        // with φ = 2 and α = 1 (conservative).
        final lfh = i.l0 * 1000 / i.h;
        if (lfh > math.max(15, 20 * e1 / i.h)) {
          notes.add(ColumnNote.slendernessOutOfScope);
        }
        final e2 = 3 * math.pow(i.l0 * 1000, 2) * (2 + 1 * 2) / (1e4 * i.h);
        e2Of = (_) => e2;
        final mu = i.nEd * (e1 + e2) / 1e3;
        mEdFor = (_) => mu;
        asReq = math.max(requiredSteel(mEdFor, asMax), asMin);
      }
  }

  // Bars: symmetric arrangement, least area ≥ required.
  BarSet? bars;
  if (asReq.isFinite) {
    for (final dia in _columnBarDiameters) {
      for (final n in _columnBarCounts) {
        final set = BarSet(n, dia);
        if (set.area + 1e-9 < asReq || set.area > asMax) continue;
        // Bars per face along b must keep the minimum clear spacing.
        final perFace = (n / 2).ceil();
        final inner = i.b - 2 * (i.cover + i.linkDiameter);
        final clear = perFace > 1 ? (inner - perFace * dia) / (perFace - 1) : 0;
        if (perFace > 1 && clear < minClearSpacing(dia)) continue;
        if (bars == null || set.area < bars.area - 1e-6) bars = set;
      }
    }
  }
  if (bars == null) notes.add(ColumnNote.sectionTooSmall);

  final asProv = bars?.area ?? 0;
  final sec = section(asProv);
  final mEd = mEdFor(asProv);
  final mRd = centred ? null : sec.momentResistance(i.nEd);

  // Links: EC2 9.5.3 / BAEL A.8.1.3.
  final barDia = bars?.diameter ?? 12;
  final linkDia = math.max(i.linkDiameter, (barDia / 4).ceil());
  final sMax = switch (i.code) {
    DesignCode.ec2 => math.min(20.0 * barDia, math.min(i.b, 400.0)),
    DesignCode.bael => math.min(15.0 * barDia, math.min(i.b + 100, 400.0)),
  };
  final linkSpacing = (sMax / 25).floor() * 25;

  final double nRd;
  if (centred) {
    final alpha = lambda <= 50
        ? 0.85 / (1 + 0.2 * math.pow(lambda / 35, 2))
        : 0.6 * math.pow(50 / lambda, 2);
    final br = (i.b - 20) * (i.h - 20);
    nRd =
        alpha *
        (br * i.fck / (0.9 * Concrete.gammaC) + asProv * i.fyk / 1.15) /
        1e3;
  } else {
    nRd = sec.nMax;
  }

  final checks = <Check>[
    if (i.code == DesignCode.bael)
      Check(
        kind: CheckKind.slenderness,
        demand: lambda,
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
    else
      Check(
        kind: CheckKind.axialBending,
        demand: mEd,
        capacity: mRd ?? 0,
        clause: i.code == DesignCode.ec2
            ? 'EN 1992-1-1 6.1, 5.8.8'
            : 'BAEL A.4.3, A.4.4',
        unit: 'kN·m',
      ),
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
    slenderness: lambda,
    slendernessLimit: lambdaLim,
    imperfection: ei,
    secondOrder: e2Of(asProv),
    mEd: mEd,
    asRequired: asReq,
    asMin: asMin,
    asMax: asMax,
    bars: bars,
    linkDiameter: linkDia,
    linkSpacing: linkSpacing,
    mRd: mRd,
    nRd: nRd,
    interaction: sec.curve(),
    checks: checks,
    notes: notes,
  );
}
