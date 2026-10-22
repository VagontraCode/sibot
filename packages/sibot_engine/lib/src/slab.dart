import 'dart:math' as math;

import 'beam.dart' show ulsLoad;
import 'core.dart';
import 'materials.dart';
import 'punching.dart';
import 'rc_bending.dart';
import 'rebar.dart';

enum SlabSupport {
  /// All edges simply supported.
  simplySupported,

  /// Continuous over supports: span moment 0.75·M0, supports 0.5·M0
  /// (BAEL A.8.2.32, satisfies Mt + (Mw + Me)/2 ≥ 1.25·M0).
  continuous,
}

enum SlabNote {
  /// α = lx/ly < 0.4: the panel is designed as one-way.
  treatedAsOneWay,
  barsNotFound,
}

class SlabInput {
  final DesignCode code;

  /// Short span lx and long span ly, m. One-way when [ly] is null.
  final double lx;
  final double? ly;

  /// Thickness and cover, mm.
  final double h;
  final double cover;

  /// Characteristic loads excluding self-weight, kN/m².
  final double g;
  final double q;

  final SlabSupport support;

  /// Optional punching check: ULS load (kN) on a c1 × c2 area (mm),
  /// column position and EC2 factor β (null = by position; 1.0 for a
  /// centred load).
  final double? punchLoad;
  final double punchC1;
  final double punchC2;
  final double? punchBeta;
  final PunchingPosition punchPosition;
  final double fck;
  final double fyk;

  const SlabInput({
    required this.code,
    required this.lx,
    required this.h,
    required this.g,
    required this.q,
    required this.fck,
    required this.fyk,
    this.ly,
    this.cover = 25,
    this.support = SlabSupport.simplySupported,
    this.punchLoad,
    this.punchC1 = 300,
    this.punchC2 = 300,
    this.punchBeta,
    this.punchPosition = PunchingPosition.interior,
  });

  bool get twoWay => ly != null;
}

/// Design of one reinforcement direction per metre width.
class SlabDirection {
  /// Design span and support moments, kN·m/m (support null if simply
  /// supported).
  final double mSpan;
  final double? mSupport;

  /// Effective depth, mm.
  final double d;
  final double asSpan;
  final double? asSupport;
  final double asMin;
  final double maxSpacing;
  final BarSpacing? barsSpan;
  final BarSpacing? barsSupport;

  const SlabDirection({
    required this.mSpan,
    required this.mSupport,
    required this.d,
    required this.asSpan,
    required this.asSupport,
    required this.asMin,
    required this.maxSpacing,
    required this.barsSpan,
    required this.barsSupport,
  });
}

class SlabDesign {
  final SlabInput input;
  final double selfWeight;
  final double wUls;

  /// α = lx/ly (two-way only).
  final double? alpha;
  final double? muX;
  final double? muY;

  final SlabDirection x;
  final SlabDirection y;

  /// Shear per metre at the support of the short span, kN/m.
  final double vEd;

  final List<Check> checks;
  final List<SlabNote> notes;

  final PunchingDesign? punching;

  const SlabDesign({
    required this.input,
    required this.selfWeight,
    required this.wUls,
    required this.alpha,
    required this.muX,
    required this.muY,
    required this.x,
    required this.y,
    required this.vEd,
    required this.checks,
    required this.notes,
    this.punching,
  });

  bool get ok => checks.every((c) => c.ok);
}

/// BAEL 91 Annexe E3, ULS (ν = 0): μx = 1/(8(1 + 2.4α³)),
/// μy = α³(1.9 − 0.9α), and My ≥ Mx/4.
(double, double) baelPanelCoefficients(double alpha) {
  final a3 = alpha * alpha * alpha;
  final muX = 1 / (8 * (1 + 2.4 * a3));
  final muY = math.max(a3 * (1.9 - 0.9 * alpha), 0.25);
  return (muX, muY);
}

SlabDesign designSlab(SlabInput i) {
  requirePositive(i.lx, 'lx');
  requirePositive(i.h, 'h');
  requireRange(i.cover, 10, 80, 'cover');
  if (i.ly != null && i.ly! < i.lx) {
    throw const InputError(InputProblem.inconsistentGeometry, 'ly');
  }
  if (i.g < 0) throw const InputError(InputProblem.outOfRange, 'g');
  if (i.q < 0) throw const InputError(InputProblem.outOfRange, 'q');

  final concrete = Concrete(i.code, i.fck);
  final steel = RebarSteel(i.fyk);
  final sw = reinforcedConcreteWeight * i.h / 1000;
  final w = ulsLoad(i.g + sw, i.q);
  final notes = <SlabNote>[];

  double? alpha, muX, muY;
  late double m0x, m0y;
  var twoWay = i.twoWay;
  if (twoWay) {
    alpha = i.lx / i.ly!;
    if (alpha < 0.4) {
      twoWay = false;
      notes.add(SlabNote.treatedAsOneWay);
    }
  }
  if (twoWay) {
    (muX, muY) = baelPanelCoefficients(alpha!);
    m0x = muX * w * i.lx * i.lx;
    m0y = muY * m0x;
  } else {
    m0x = w * i.lx * i.lx / 8;
    m0y = 0;
  }

  final continuous = i.support == SlabSupport.continuous;
  final kt = continuous ? 0.75 : 1.0;
  final ka = continuous ? 0.5 : 0.0;

  // Minimum steel and spacing rules.
  final (sMaxMain, sMaxSecondary) = switch (i.code) {
    // EC2 9.3.1.1(3).
    DesignCode.ec2 => (math.min(3 * i.h, 400.0), math.min(3.5 * i.h, 450.0)),
    // BAEL A.8.2.42, fissuration peu préjudiciable.
    DesignCode.bael => (math.min(3 * i.h, 330.0), math.min(4 * i.h, 450.0)),
  };

  const assumedBar = 10;
  final dx = i.h - i.cover - assumedBar / 2;
  final dy = dx - assumedBar;
  if (dy <= 0) throw const InputError(InputProblem.inconsistentGeometry, 'h');

  double asFor(double m, double d) => designRectangularBending(
    code: i.code,
    concrete: concrete,
    steel: steel,
    mEd: m,
    b: 1000,
    d: d,
  ).asTension;

  double minFor(double d, {required bool main}) {
    switch (i.code) {
      case DesignCode.ec2:
        final base = minTensionSteel(
          code: i.code,
          concrete: concrete,
          steel: steel,
          b: 1000,
          d: d,
        );
        return base;
      case DesignCode.bael:
        if (!twoWay) {
          return minTensionSteel(
            code: i.code,
            concrete: concrete,
            steel: steel,
            b: 1000,
            d: d,
          );
        }
        // B.7.4: ρ0 = 0.8‰ (FeE400) or 0.6‰ (FeE500).
        final rho0 = i.fyk >= 500 ? 0.0006 : 0.0008;
        return main ? rho0 * (3 - alpha!) / 2 * 1000 * i.h : rho0 * 1000 * i.h;
    }
  }

  // X direction (main).
  final mSpanX = kt * m0x;
  final mSuppX = continuous ? ka * m0x : null;
  final asMinX = minFor(dx, main: true);
  final asX = math.max(asFor(mSpanX, dx), asMinX);
  final asXs = mSuppX == null ? null : math.max(asFor(mSuppX, dx), asMinX);

  // Y direction: computed moment (two-way) or distribution steel.
  late double mSpanY, asY, asMinY;
  double? mSuppY, asYs;
  if (twoWay) {
    mSpanY = kt * m0y;
    asMinY = minFor(dy, main: false);
    asY = math.max(asFor(mSpanY, dy), asMinY);
    // Supports carry the same moment on all edges (BAEL A.8.2.32).
    mSuppY = mSuppX;
    asYs = asXs;
  } else {
    mSpanY = 0;
    // Distribution steel: EC2 9.3.1.1(2) 20 %; BAEL A.8.2.41 25 %.
    final share = i.code == DesignCode.ec2 ? 0.20 : 0.25;
    asMinY = share * asX;
    asY = asMinY;
  }

  final barsX = chooseSpacing(asX, sMaxMain);
  final barsXs = asXs == null ? null : chooseSpacing(asXs, sMaxMain);
  final barsY = chooseSpacing(asY, twoWay ? sMaxMain : sMaxSecondary);
  if (barsX == null || barsY == null) notes.add(SlabNote.barsNotFound);

  final x = SlabDirection(
    mSpan: mSpanX,
    mSupport: mSuppX,
    d: dx,
    asSpan: asX,
    asSupport: asXs,
    asMin: asMinX,
    maxSpacing: sMaxMain,
    barsSpan: barsX,
    barsSupport: barsXs,
  );
  final y = SlabDirection(
    mSpan: mSpanY,
    mSupport: mSuppY,
    d: dy,
    asSpan: asY,
    asSupport: asYs,
    asMin: asMinY,
    maxSpacing: twoWay ? sMaxMain : sMaxSecondary,
    barsSpan: barsY,
    barsSupport: asYs == null ? null : chooseSpacing(asYs, sMaxMain),
  );

  // Shear at the long edges, per metre.
  final vEd = twoWay
      ? w *
            i.lx *
            i.ly! /
            (2 * i.ly! + i.lx) // BAEL A.8.2.3 (Vx)
      : w * i.lx / 2;

  final checks = <Check>[
    Check(
      kind: CheckKind.bendingSteel,
      demand: asX,
      capacity: barsX?.areaPerMetre ?? 0,
      clause: bendingClause(i.code),
      unit: 'mm²/m',
    ),
    if (asXs != null)
      Check(
        kind: CheckKind.bendingSteel,
        demand: asXs,
        capacity: barsXs?.areaPerMetre ?? 0,
        clause: bendingClause(i.code),
        unit: 'mm²/m',
      ),
    Check(
      kind: CheckKind.bendingSteel,
      demand: asY,
      capacity: barsY?.areaPerMetre ?? 0,
      clause: twoWay
          ? bendingClause(i.code)
          : (i.code == DesignCode.ec2
                ? 'EN 1992-1-1 9.3.1.1(2)'
                : 'BAEL A.8.2.41'),
      unit: 'mm²/m',
    ),
  ];

  switch (i.code) {
    case DesignCode.ec2:
      // 6.2.2(1): slab without shear reinforcement.
      final d = dx;
      final k = math.min(1 + math.sqrt(200 / d), 2.0);
      final rho = math.min((barsX?.areaPerMetre ?? asX) / (1000 * d), 0.02);
      final vMin = 0.035 * math.pow(k, 1.5) * math.sqrt(i.fck);
      final vc = math.max(0.12 * k * math.pow(100 * rho * i.fck, 1 / 3), vMin);
      checks.add(
        Check(
          kind: CheckKind.shearCrushing,
          demand: vEd,
          capacity: vc * 1000 * d / 1e3,
          clause: 'EN 1992-1-1 6.2.2',
          unit: 'kN/m',
        ),
      );
      // 7.4.2: K = 1.0 simply supported, 1.3 end span of continuous.
      final kDefl = continuous ? 1.3 : 1.0;
      final rho0 = math.sqrt(i.fck) * 1e-3;
      final rhoReq = math.max(asFor(mSpanX, d), 1e-9) / (1000 * d);
      final base = rhoReq <= rho0
          ? 11 +
                1.5 * math.sqrt(i.fck) * rho0 / rhoReq +
                3.2 * math.sqrt(i.fck) * math.pow(rho0 / rhoReq - 1, 1.5)
          : 11 + 1.5 * math.sqrt(i.fck) * rho0 / rhoReq;
      final provided = barsX?.areaPerMetre ?? asX;
      final factor =
          500 /
          i.fyk *
          math.min(provided / math.max(asFor(mSpanX, d), 1e-9), 1.5);
      checks.add(
        Check(
          kind: CheckKind.deflection,
          demand: i.lx * 1000 / d,
          capacity: kDefl * base * factor,
          clause: 'EN 1992-1-1 7.4.2',
        ),
      );
    case DesignCode.bael:
      // A.5.2.2: no shear reinforcement if τu ≤ 0.07·fc28/γb.
      checks.add(
        Check(
          kind: CheckKind.shearCrushing,
          demand: vEd * 1e3 / (1000 * dx),
          capacity: 0.07 * i.fck / Concrete.gammaC,
          clause: 'BAEL A.5.2.2',
          unit: 'MPa',
        ),
      );
      // B.7.5: h/lx ≥ Mt/(20·M0x) and ρ ≤ 2/fe exempt from deflection
      // calculation.
      checks.add(
        Check(
          kind: CheckKind.deflection,
          demand: kt / 20,
          capacity: i.h / (i.lx * 1000),
          clause: 'BAEL B.7.5',
        ),
      );
      checks.add(
        Check(
          kind: CheckKind.deflection,
          demand: (barsX?.areaPerMetre ?? asX) / (1000 * dx),
          capacity: 2 / i.fyk,
          clause: 'BAEL B.7.5',
        ),
      );
  }

  // Optional punching at a column or concentrated load. Over a support of
  // a continuous slab the top bars resist; otherwise the bottom bars.
  PunchingDesign? punching;
  final pLoad = i.punchLoad;
  if (pLoad != null && pLoad > 0) {
    final topX = barsXs?.areaPerMetre;
    final rhoX = (topX ?? barsX?.areaPerMetre ?? asX) / (1000 * dx);
    final rhoY = (y.barsSpan?.areaPerMetre ?? asY) / (1000 * dy);
    punching = designPunching(
      code: i.code,
      c1: i.punchC1,
      c2: i.punchC2,
      vEd: pLoad,
      d: (dx + dy) / 2,
      h: i.h,
      rhoL: math.sqrt(rhoX * rhoY),
      fck: i.fck,
      fyk: i.fyk,
      beta: i.punchBeta,
      position: i.punchPosition,
    );
    checks.addAll(punching.checks);
  }

  return SlabDesign(
    punching: punching,
    input: i,
    selfWeight: sw,
    wUls: w,
    alpha: alpha,
    muX: twoWay ? muX : null,
    muY: twoWay ? muY : null,
    x: x,
    y: y,
    vEd: vEd,
    checks: checks,
    notes: notes,
  );
}
