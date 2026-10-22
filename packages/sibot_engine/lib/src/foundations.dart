import 'dart:math' as math;

import 'bearing.dart';
import 'core.dart';
import 'materials.dart';
import 'punching.dart';
import 'rc_bending.dart';
import 'rebar.dart';

double _ceil50mm(double mm) => (mm / 50).ceil() * 50.0;
double _ceil50m(double m) => (m * 20 - 1e-9).ceil() / 20;

/// Shear resistance per metre width of a member without links, kN/m.
/// EC2 6.2.2(1); BAEL A.5.2.2 (τu ≤ 0.07·fc28/γb).
double _shearNoLinks(DesignCode code, double fck, double d, double rho) {
  switch (code) {
    case DesignCode.ec2:
      final k = math.min(1 + math.sqrt(200 / d), 2.0);
      final vMin = 0.035 * math.pow(k, 1.5) * math.sqrt(fck);
      final vc = math.max(
        0.12 * k * math.pow(100 * math.min(rho, 0.02) * fck, 1 / 3),
        vMin,
      );
      return vc * d; // N/mm per mm = kN/m
    case DesignCode.bael:
      return 0.07 * fck / Concrete.gammaC * d;
  }
}

String _shearClause(DesignCode c) =>
    c == DesignCode.ec2 ? 'EN 1992-1-1 6.2.2' : 'BAEL A.5.2.2';

// ============================ STRIP FOOTING ============================

class StripFootingInput {
  final DesignCode code;

  /// Wall thickness, mm.
  final double wall;

  /// Characteristic loads per metre run, kN/m, and moments, kN·m/m.
  final double g;
  final double q;
  final double mg;
  final double mq;

  final double qAllowable;
  final Soil? soil;
  final double depth;
  final double soilWeight;
  final double fck;
  final double fyk;
  final double cover;

  const StripFootingInput({
    required this.code,
    required this.wall,
    required this.g,
    required this.q,
    required this.fck,
    required this.fyk,
    this.qAllowable = 0,
    this.soil,
    this.mg = 0,
    this.mq = 0,
    this.depth = 1.0,
    this.soilWeight = 18,
    this.cover = 50,
  });
}

class StripFootingDesign {
  final StripFootingInput input;

  /// Width (m), thickness and effective depth (mm).
  final double width;
  final double h;
  final double d;
  final double weight;
  final double eccentricity;
  final double pressure;
  final double bearingLimit;

  /// Transverse steel and distribution steel, mm²/m.
  final double asMain;
  final double asDistribution;
  final BarSpacing? barsMain;
  final BarSpacing? barsDistribution;

  final List<Check> checks;

  const StripFootingDesign({
    required this.input,
    required this.width,
    required this.h,
    required this.d,
    required this.weight,
    required this.eccentricity,
    required this.pressure,
    required this.bearingLimit,
    required this.asMain,
    required this.asDistribution,
    required this.barsMain,
    required this.barsDistribution,
    required this.checks,
  });

  bool get ok => checks.every((c) => c.ok);
}

/// (pressure, limit) for a footing of plan B × L (m) with service load
/// [n], service eccentricity [e] along B and ULS values for EC7.
(double, double) _bearing({
  required DesignCode code,
  required Soil? soil,
  required double qAllowable,
  required double depth,
  required double bM,
  required double lM,
  required double nSer,
  required double e,
  required double vd,
  required double ed,
}) {
  if (e >= bM / 6) return (double.infinity, 0);
  if (soil == null) {
    final p = code == DesignCode.bael
        ? nSer / (bM * lM) * (1 + 3 * e / bM)
        : nSer / ((bM - 2 * e) * lM);
    return (p, qAllowable);
  }
  final bEff = bM - 2 * ed;
  if (bEff <= 0) return (double.infinity, 0);
  final limit =
      ultimateBearingPressure(
        soil,
        bEff: math.min(bEff, lM),
        lEff: math.max(bEff, lM),
        depth: depth,
      ) /
      gammaRv;
  return (vd / (bEff * lM), limit);
}

StripFootingDesign designStripFooting(StripFootingInput i) {
  requirePositive(i.wall, 'wall');
  requirePositive(i.g + i.q, 'g');
  if (i.soil == null) requirePositive(i.qAllowable, 'qAllowable');
  requireRange(i.depth, 0.2, 10, 'depth');
  final concrete = Concrete(i.code, i.fck);
  final steel = RebarSteel(i.fyk);
  const lM = 1.0; // per metre run; EC7 treats it as a strip (L′ ≫ B′)

  var hMm = 300.0;
  late double bM, weight, e, pressure, limit;
  for (var pass = 0; pass < 20; pass++) {
    bM = _ceil50m(math.max(0.4, i.wall / 1000 + 0.2));
    while (true) {
      weight =
          bM *
          ((hMm / 1000) * reinforcedConcreteWeight +
              math.max(i.depth - hMm / 1000, 0) * i.soilWeight);
      final n = i.g + i.q + weight;
      e = (i.mg + i.mq) / n;
      final vd = 1.35 * (i.g + weight) + 1.5 * i.q;
      (pressure, limit) = _bearing(
        code: i.code,
        soil: i.soil,
        qAllowable: i.qAllowable,
        depth: i.depth,
        bM: bM,
        // A strip: use a very long L′ for the shape factors.
        lM: i.soil == null ? lM : 1000,
        nSer: n,
        e: e,
        vd: i.soil == null ? vd : vd * 1000,
        ed: (1.35 * i.mg + 1.5 * i.mq) / vd,
      );
      if (pressure <= limit || bM >= 10) break;
      bM = _ceil50m(bM + 0.05);
    }
    // Rigid footing: d ≥ (B − a)/4.
    final dNeed = math.max((bM * 1000 - i.wall) / 4, 150.0);
    final hNew = _ceil50mm(dNeed + i.cover + 8);
    if (hNew <= hMm) break;
    hMm = hNew;
  }
  final d = hMm - i.cover - 6;
  final bMm = bM * 1000;

  final nU = 1.35 * i.g + 1.5 * i.q;
  final mU = 1.35 * i.mg + 1.5 * i.mq;
  final eU = mU / nU;
  final sigmaMax = nU / bM * (1 + 6 * eU / bM); // kPa, net
  final cant = (bMm - i.wall) / 2; // mm

  late double asMain;
  switch (i.code) {
    case DesignCode.bael:
      // Méthode des bielles per metre: A = Nu(1 + 3e/B)(B − a)/(8·d·fsu).
      asMain =
          nU * 1e3 * (1 + 3 * eU / bM) * (bMm - i.wall) / (8 * d * steel.fyd);
    case DesignCode.ec2:
      final c = cant + 0.15 * i.wall;
      final m = sigmaMax * math.pow(c / 1000, 2) / 2;
      asMain = designRectangularBending(
        code: i.code,
        concrete: concrete,
        steel: steel,
        mEd: m,
        b: 1000,
        d: d,
      ).asTension;
  }
  final asMin = minTensionSteel(
    code: i.code,
    concrete: concrete,
    steel: steel,
    b: 1000,
    d: d,
  );
  final main = math.max(asMain, asMin);
  final barsMain = chooseSpacing(
    main,
    250,
    diameters: const [10, 12, 14, 16, 20],
  );
  final share = i.code == DesignCode.ec2 ? 0.20 : 0.25;
  final dist = share * main;
  final barsDist = chooseSpacing(dist, 300, diameters: const [8, 10, 12]);

  final checks = <Check>[
    Check(
      kind: CheckKind.bearingPressure,
      demand: pressure,
      capacity: limit,
      clause: i.soil != null
          ? 'EN 1997-1 Annex D, DA2'
          : (i.code == DesignCode.bael ? 'DTU 13.12' : 'EN 1997-1 6.5.2'),
      unit: 'kPa',
    ),
    Check(
      kind: CheckKind.baseEccentricity,
      demand: e,
      capacity: bM / 6,
      clause: i.code == DesignCode.bael ? 'DTU 13.12' : 'EN 1997-1 6.5.4',
      unit: 'm',
    ),
    Check(
      kind: CheckKind.bendingSteel,
      demand: main,
      capacity: barsMain?.areaPerMetre ?? 0,
      clause: i.code == DesignCode.bael
          ? 'DTU 13.12 (bielles)'
          : 'EN 1992-1-1 9.8.2',
      unit: 'mm²/m',
    ),
    if (i.code == DesignCode.ec2)
      Check(
        kind: CheckKind.shearCrushing,
        // Shear at d from the wall face, per metre.
        demand: sigmaMax * math.max(cant - d, 0) / 1000,
        capacity: _shearNoLinks(
          i.code,
          i.fck,
          d,
          (barsMain?.areaPerMetre ?? main) / (1000 * d),
        ),
        clause: _shearClause(i.code),
        unit: 'kN/m',
      ),
  ];

  return StripFootingDesign(
    input: i,
    width: bM,
    h: hMm,
    d: d,
    weight: weight,
    eccentricity: e,
    pressure: pressure,
    bearingLimit: limit,
    asMain: main,
    asDistribution: dist,
    barsMain: barsMain,
    barsDistribution: barsDist,
    checks: checks,
  );
}

// =========================== COMBINED FOOTING ===========================

class CombinedFootingInput {
  final DesignCode code;

  /// Columns: dimension along the footing (a) and across (b), mm.
  final double a1;
  final double b1;
  final double a2;
  final double b2;

  /// Centre-to-centre column spacing, m.
  final double spacing;

  /// Characteristic loads, kN.
  final double g1;
  final double q1;
  final double g2;
  final double q2;

  final double qAllowable;
  final Soil? soil;
  final double depth;
  final double soilWeight;
  final double fck;
  final double fyk;
  final double cover;

  /// Try wider (and so thinner) footings and keep the one with the least
  /// concrete and steel, instead of the narrowest one.
  final bool optimiseWidth;

  const CombinedFootingInput({
    required this.code,
    required this.a1,
    required this.b1,
    required this.a2,
    required this.b2,
    required this.spacing,
    required this.g1,
    required this.q1,
    required this.g2,
    required this.q2,
    required this.fck,
    required this.fyk,
    this.optimiseWidth = false,
    this.qAllowable = 0,
    this.soil,
    this.depth = 1.0,
    this.soilWeight = 18,
    this.cover = 50,
  });
}

class _CombinedTrial {
  final double width, h, pressure, limit, d, asB, asT;
  final BarSpacing? barsB, barsT;
  final List<Check> structural;
  final List<double> asTr;
  final List<BarSpacing?> barsTr;
  const _CombinedTrial({
    required this.width,
    required this.h,
    required this.pressure,
    required this.limit,
    required this.d,
    required this.asB,
    required this.asT,
    required this.barsB,
    required this.barsT,
    required this.structural,
    required this.asTr,
    required this.barsTr,
  });
}

/// Point of a shear / moment diagram along the footing.
class DiagramPoint {
  /// Position from the left end, m.
  final double x;

  /// Shear (kN) and moment (kN·m, positive = bottom fibre in tension).
  final double v;
  final double m;
  const DiagramPoint(this.x, this.v, this.m);
}

class CombinedFootingDesign {
  final CombinedFootingInput input;

  /// Length, width (m); left overhang from column 1 centre (m).
  final double length;
  final double width;
  final double overhang1;
  final double h;
  final double d;
  final double pressure;
  final double bearingLimit;

  /// Extreme ULS moments: sagging (bottom tension) and hogging, kN·m.
  final double mBottom;
  final double mTop;

  final double asBottom;
  final double asTop;
  final BarSpacing? barsBottom;
  final BarSpacing? barsTop;

  /// Transverse steel under each column (band a + 2d), mm² and bars.
  final List<double> asTransverse;
  final List<BarSpacing?> barsTransverse;

  /// ULS diagrams along the footing.
  final List<DiagramPoint> diagram;

  final List<Check> checks;

  const CombinedFootingDesign({
    required this.input,
    required this.length,
    required this.width,
    required this.overhang1,
    required this.h,
    required this.d,
    required this.pressure,
    required this.bearingLimit,
    required this.mBottom,
    required this.mTop,
    required this.asBottom,
    required this.asTop,
    required this.barsBottom,
    required this.barsTop,
    required this.asTransverse,
    required this.barsTransverse,
    required this.diagram,
    required this.checks,
  });

  bool get ok => checks.every((c) => c.ok);
}

/// Footing proportioned so that the service resultant is at mid-length
/// (uniform soil pressure), then designed as a beam on a linear ULS soil
/// reaction. Thickness is increased until no shear links are needed and
/// punching is satisfied.
CombinedFootingDesign designCombinedFooting(CombinedFootingInput i) {
  for (final (v, f) in [
    (i.a1, 'a1'),
    (i.b1, 'b1'),
    (i.a2, 'a2'),
    (i.b2, 'b2'),
    (i.spacing, 'spacing'),
  ]) {
    requirePositive(v, f);
  }
  requirePositive(i.g1 + i.q1, 'g1');
  requirePositive(i.g2 + i.q2, 'g2');
  if (i.soil == null) requirePositive(i.qAllowable, 'qAllowable');
  if (i.spacing * 1000 < (i.a1 + i.a2) / 2) {
    throw const InputError(InputProblem.inconsistentGeometry, 'spacing');
  }
  final concrete = Concrete(i.code, i.fck);
  final steel = RebarSteel(i.fyk);

  // Length: resultant at mid-length, at least 0.3 m beyond each column face.
  final n1 = i.g1 + i.q1, n2 = i.g2 + i.q2;
  final xBar = n2 * i.spacing / (n1 + n2);
  final e1Min = i.a1 / 2000 + 0.3, e2Min = i.a2 / 2000 + 0.3;
  final length = _ceil50m(
    math.max(2 * (xBar + e1Min), 2 * (i.spacing - xBar + e2Min)),
  );
  final e1 = length / 2 - xBar;
  final x1 = e1, x2 = e1 + i.spacing;

  final p1 = 1.35 * i.g1 + 1.5 * i.q1;
  final p2 = 1.35 * i.g2 + 1.5 * i.q2;
  final r = p1 + p2;
  final xr = (p1 * x1 + p2 * x2) / r;
  // Linear reaction q(x) = qa + qb·x with ∫q = R and ∫q·x = R·xr.
  final qb = 12 * r * (xr - length / 2) / math.pow(length, 3);
  final qa = r / length - qb * length / 2;

  double shearAt(double x) {
    var v = qa * x + qb * x * x / 2;
    if (x > x1) v -= p1;
    if (x > x2) v -= p2;
    return v;
  }

  double momentAt(double x) {
    var m = qa * x * x / 2 + qb * x * x * x / 6;
    if (x > x1) m -= p1 * (x - x1);
    if (x > x2) m -= p2 * (x - x2);
    return m;
  }

  final diagram = <DiagramPoint>[
    for (var k = 0; k <= 200; k++)
      () {
        final x = length * k / 200;
        return DiagramPoint(x, shearAt(x), momentAt(x));
      }(),
  ];
  // Include the exact points just either side of each column.
  for (final xc in [x1, x2]) {
    diagram.add(DiagramPoint(xc - 1e-6, shearAt(xc - 1e-6), momentAt(xc)));
    diagram.add(DiagramPoint(xc + 1e-6, shearAt(xc + 1e-6), momentAt(xc)));
  }
  diagram.sort((p, q) => p.x.compareTo(q.x));
  final mBottom = diagram.map((p) => p.m).reduce(math.max);
  final mTop = -diagram.map((p) => p.m).reduce(math.min);

  // Width and thickness for a starting width: widened until the bearing
  // pressure is acceptable, then thickened until no links are needed.
  _CombinedTrial trial(double wStart) {
    var hMm = 400.0;
    late double width, pressure, limit, d, asB, asT;
    BarSpacing? barsB, barsT;
    late List<Check> structural;
    late List<double> asTr;
    late List<BarSpacing?> barsTr;
    for (var pass = 0; pass < 40; pass++) {
      width = wStart;
      while (true) {
        final w =
            width *
            length *
            ((hMm / 1000) * reinforcedConcreteWeight +
                math.max(i.depth - hMm / 1000, 0) * i.soilWeight);
        final vd = 1.35 * (i.g1 + i.g2 + w) + 1.5 * (i.q1 + i.q2);
        (pressure, limit) = _bearing(
          code: i.code,
          soil: i.soil,
          qAllowable: i.qAllowable,
          depth: i.depth,
          bM: length,
          lM: width,
          nSer: n1 + n2 + w,
          e: 0,
          vd: vd,
          ed: (xr - length / 2).abs(),
        );
        if (pressure <= limit || width >= 10) break;
        width = _ceil50m(width + 0.05);
      }

      d = hMm - i.cover - 10;
      final bMm = width * 1000;
      BendingDesign bend(double m) => designRectangularBending(
        code: i.code,
        concrete: concrete,
        steel: steel,
        mEd: math.max(m, 0),
        b: bMm,
        d: d,
      );
      final asMin = minTensionSteel(
        code: i.code,
        concrete: concrete,
        steel: steel,
        b: bMm,
        d: d,
      );
      asB = math.max(bend(mBottom).asTension, asMin);
      asT = math.max(bend(mTop).asTension, asMin);
      const dias = [12, 14, 16, 20, 25];
      barsB = chooseSpacing(asB / width, 250, diameters: dias);
      barsT = chooseSpacing(asT / width, 250, diameters: dias);

      // Longitudinal shear at d from the column faces, without links.
      final rhoT = (barsT?.areaPerMetre ?? asT / width) / (1000 * d);
      final vCap = _shearNoLinks(i.code, i.fck, d, rhoT) * width;
      var vMax = 0.0;
      for (final (xc, a) in [(x1, i.a1), (x2, i.a2)]) {
        for (final s in [-1.0, 1.0]) {
          final x = xc + s * (a / 2 + d) / 1000;
          if (x > 0 && x < length) vMax = math.max(vMax, shearAt(x).abs());
        }
      }

      // Transverse steel under each column on a band a + 2d.
      asTr = [];
      barsTr = [];
      for (final (p, a, b) in [(p1, i.a1, i.b1), (p2, i.a2, i.b2)]) {
        final band = math.min(a + 2 * d, length * 1000);
        final cant = (bMm - b) / 2;
        final double as = switch (i.code) {
          DesignCode.bael => p * 1e3 * (bMm - b) / (8 * (d - 12) * steel.fyd),
          DesignCode.ec2 => designRectangularBending(
            code: i.code,
            concrete: concrete,
            steel: steel,
            mEd: p / width * math.pow((cant + 0.15 * b) / 1000, 2) / 2,
            b: band,
            d: d - 12,
          ).asTension,
        };
        final asReq = math.max(
          as,
          minTensionSteel(
            code: i.code,
            concrete: concrete,
            steel: steel,
            b: band,
            d: d - 12,
          ),
        );
        asTr.add(asReq);
        barsTr.add(chooseSpacing(asReq / (band / 1000), 250, diameters: dias));
      }

      final sigmaNet = r / (length * width);
      final rhoAvg = math.sqrt(
        rhoT * (barsTr[0]?.areaPerMetre ?? 500) / (1000 * d),
      );
      structural = [
        Check(
          kind: CheckKind.shearCrushing,
          demand: vMax,
          capacity: vCap,
          clause: _shearClause(i.code),
          unit: 'kN',
        ),
        for (final (p, a, b) in [(p1, i.a1, i.b1), (p2, i.a2, i.b2)])
          footingPunching(
            code: i.code,
            c1: a,
            c2: b,
            nEd: p,
            sigma: sigmaNet,
            d: d,
            h: hMm,
            rhoL: rhoAvg,
            fck: i.fck,
          ),
      ];
      if (structural.every((c) => c.ok) || hMm >= 2000) break;
      hMm += 50;
    }
    return _CombinedTrial(
      width: width,
      h: hMm,
      pressure: pressure,
      limit: limit,
      d: d,
      asB: asB,
      asT: asT,
      barsB: barsB,
      barsT: barsT,
      structural: structural,
      asTr: asTr,
      barsTr: barsTr,
    );
  }

  final wMin = _ceil50m(math.max(i.b1, i.b2) / 1000 + 0.2);
  var best = trial(wMin);
  if (i.optimiseWidth) {
    // Concrete volume plus steel at 75 times its price by volume.
    double cost(_CombinedTrial t) {
      final steelMm2 =
          (t.asB + t.asT) * length * 1000 +
          t.asTr.fold<double>(0, (s, a) => s + a) * t.width * 1000;
      return t.width * length * t.h / 1000 + 75 * steelMm2 * 1e-9;
    }

    bool passes(_CombinedTrial t) =>
        t.pressure <= t.limit && t.structural.every((c) => c.ok);
    for (var k = 1; k <= 20; k++) {
      final t = trial(_ceil50m(wMin + 0.1 * k));
      if (passes(t) && (!passes(best) || cost(t) < cost(best))) best = t;
    }
  }
  final _CombinedTrial(
    :width,
    :h,
    :pressure,
    :limit,
    :d,
    :asB,
    :asT,
    :barsB,
    :barsT,
    :structural,
    :asTr,
    :barsTr,
  ) = best;
  final hMm = h;

  final checks = <Check>[
    Check(
      kind: CheckKind.bearingPressure,
      demand: pressure,
      capacity: limit,
      clause: i.soil != null
          ? 'EN 1997-1 Annex D, DA2'
          : (i.code == DesignCode.bael ? 'DTU 13.12' : 'EN 1997-1 6.5.2'),
      unit: 'kPa',
    ),
    Check(
      kind: CheckKind.bendingSteel,
      demand: asB,
      capacity: (barsB?.areaPerMetre ?? 0) * width,
      clause: bendingClause(i.code),
      unit: 'mm²',
    ),
    Check(
      kind: CheckKind.bendingSteel,
      demand: asT,
      capacity: (barsT?.areaPerMetre ?? 0) * width,
      clause: bendingClause(i.code),
      unit: 'mm²',
    ),
    ...structural,
  ];

  return CombinedFootingDesign(
    input: i,
    length: length,
    width: width,
    overhang1: e1,
    h: hMm,
    d: d,
    pressure: pressure,
    bearingLimit: limit,
    mBottom: mBottom,
    mTop: mTop,
    asBottom: asB,
    asTop: asT,
    barsBottom: barsB,
    barsTop: barsT,
    asTransverse: asTr,
    barsTransverse: barsTr,
    diagram: diagram,
    checks: checks,
  );
}
