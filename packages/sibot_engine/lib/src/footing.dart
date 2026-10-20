import 'dart:math' as math;

import 'beam.dart' show ulsLoad;
import 'bearing.dart';
import 'core.dart';
import 'materials.dart';
import 'rc_bending.dart';
import 'rebar.dart';

enum FootingNote {
  /// Sizes stopped at the maximum plan size tried (10 m).
  sizeLimitReached,
  barsNotFound,
}

class FootingInput {
  final DesignCode code;

  /// Column section: [a] parallel to the moment direction, mm.
  final double a;
  final double b;

  /// Characteristic column loads, kN, and moments about the b axis, kN·m.
  final double g;
  final double q;
  final double mg;
  final double mq;

  /// Allowable (SLS) bearing pressure, kPa (used when [soil] is null).
  final double qAllowable;

  /// Depth from ground level to the underside of the footing, m.
  final double depth;
  final double soilWeight;

  final double fck;
  final double fyk;
  final double cover;

  /// Soil parameters: when given, bearing is checked at ULS with
  /// EN 1997-1 Annex D, design approach 2, instead of [qAllowable].
  final Soil? soil;

  const FootingInput({
    required this.code,
    required this.a,
    required this.b,
    required this.g,
    required this.q,
    required this.qAllowable,
    required this.fck,
    required this.fyk,
    this.mg = 0,
    this.mq = 0,
    this.depth = 1.0,
    this.soilWeight = 18,
    this.cover = 50,
    this.soil,
  });
}

class FootingDesign {
  final FootingInput input;

  /// Plan size along a and b, thickness, effective depth: m, m, mm, mm.
  final double lengthA;
  final double widthB;
  final double h;
  final double d;

  /// Self-weight of footing plus backfill, kN.
  final double weight;

  /// Service eccentricity and ground pressure used in the bearing check.
  final double eccentricity;
  final double pressure;

  /// Pressure the footing may carry: qAllowable, or the EC7 design
  /// resistance R/(A′·γR,v), kPa.
  final double bearingLimit;

  /// ULS column load and moment.
  final double nUls;
  final double mUls;

  /// Steel parallel to A (bottom layer) and to B, mm².
  final double asA;
  final double asB;
  final double asMinA;
  final double asMinB;
  final BarSpacing? barsA;
  final BarSpacing? barsB;

  final List<Check> checks;
  final List<FootingNote> notes;

  const FootingDesign({
    required this.input,
    required this.lengthA,
    required this.widthB,
    required this.h,
    required this.d,
    required this.weight,
    required this.eccentricity,
    required this.pressure,
    required this.bearingLimit,
    required this.nUls,
    required this.mUls,
    required this.asA,
    required this.asB,
    required this.asMinA,
    required this.asMinB,
    required this.barsA,
    required this.barsB,
    required this.checks,
    required this.notes,
  });

  double get area => lengthA * widthB;
  bool get ok => checks.every((c) => c.ok);
}

double _ceil50(double mm) => (mm / 50).ceil() * 50.0;

/// Ground pressure compared with the allowable value, kPa.
/// BAEL: σ(3/4) = N/(A·B)·(1 + 3e/A). EC7 practice (Meyerhof): N/((A−2e)·B).
double _pressure(DesignCode code, double n, double e, double aM, double bM) =>
    switch (code) {
      DesignCode.bael => n / (aM * bM) * (1 + 3 * e / aM),
      DesignCode.ec2 => n / ((aM - 2 * e) * bM),
    };

FootingDesign designFooting(FootingInput i) {
  requirePositive(i.a, 'a');
  requirePositive(i.b, 'b');
  requirePositive(i.g + i.q, 'g');
  if (i.soil == null) requirePositive(i.qAllowable, 'qAllowable');
  requireRange(i.depth, 0.2, 10, 'depth');
  final concrete = Concrete(i.code, i.fck);
  final steel = RebarSteel(i.fyk);
  final notes = <FootingNote>[];

  final nSer = i.g + i.q;
  final mSer = i.mg + i.mq;
  final ratio = i.a / i.b; // homothetic: A/B = a/b

  // Size iteratively: plan size from pressure, thickness from the rigid
  // footing rule d ≥ (A − a)/4 (BAEL "semelle rigide").
  var hMm = 300.0;
  var bM = 0.6;
  var aM = bM * ratio;
  late double weight, e, sigma, limit;
  for (var pass = 0; pass < 20; pass++) {
    bM = math.max(0.6, i.b / 1000 + 0.2);
    while (true) {
      aM = bM * ratio;
      weight =
          aM * bM * (hMm / 1000) * reinforcedConcreteWeight +
          aM * bM * math.max(i.depth - hMm / 1000, 0) * i.soilWeight;
      final n = nSer + weight;
      e = mSer / n;
      final soil = i.soil;
      if (soil == null) {
        limit = i.qAllowable;
        sigma = e < aM / 6 ? _pressure(i.code, n, e, aM, bM) : double.infinity;
      } else {
        // EN 1997-1 DA2: Vd = 1.35·(G + W) + 1.5·Q on the effective area
        // A′ = (A − 2·ed)·B; Rd/A′ = qult/γR,v.
        final vd = 1.35 * (i.g + weight) + 1.5 * i.q;
        final ed = (1.35 * i.mg + 1.5 * i.mq) / vd;
        final aEff = aM - 2 * ed;
        if (e >= aM / 6 || aEff <= 0) {
          sigma = double.infinity;
          limit = 0;
        } else {
          sigma = vd / (aEff * bM);
          limit =
              ultimateBearingPressure(
                soil,
                bEff: math.min(aEff, bM),
                lEff: math.max(aEff, bM),
                depth: i.depth,
              ) /
              gammaRv;
        }
      }
      if (sigma <= limit || bM >= 10) break;
      bM += 0.05;
    }
    if (bM >= 10) notes.add(FootingNote.sizeLimitReached);
    final dNeed = math.max(
      math.max((aM * 1000 - i.a) / 4, (bM * 1000 - i.b) / 4),
      150.0,
    );
    final hNew = _ceil50(dNeed + i.cover + 12);
    if (hNew <= hMm) break;
    hMm = hNew;
  }
  final d = hMm - i.cover - 6; // centre of a Ø12 bottom layer
  final dB = d - 12; // second layer

  final nU = ulsLoad(i.g, i.q);
  final mU = 1.35 * i.mg + 1.5 * i.mq;
  final eU = mU / nU;
  final aMm = aM * 1000, bMm = bM * 1000;

  late double asA, asB;
  switch (i.code) {
    case DesignCode.bael:
      // Méthode des bielles: A = Nu·(A − a)/(8·d·fsu), with Nu(1 + 3e/A)
      // for a moderate eccentricity.
      final nEff = nU * (1 + 3 * eU / aM) * 1e3;
      asA = nEff * (aMm - i.a) / (8 * d * steel.fyd);
      asB = nU * 1e3 * (bMm - i.b) / (8 * dB * steel.fyd);
    case DesignCode.ec2:
      // Cantilever bending at 0.15·a inside the column face (9.8.2.2),
      // with the peak net ULS pressure.
      final sigmaMax = nU / (aM * bM) * (1 + 6 * eU / aM); // kPa
      final sigmaAvg = nU / (aM * bM);
      final cA = (aMm - i.a) / 2 + 0.15 * i.a; // mm
      final cB = (bMm - i.b) / 2 + 0.15 * i.b;
      final mA = sigmaMax * bM * math.pow(cA / 1000, 2) / 2; // kN·m
      final mB = sigmaAvg * aM * math.pow(cB / 1000, 2) / 2;
      asA = designRectangularBending(
        code: i.code,
        concrete: concrete,
        steel: steel,
        mEd: mA,
        b: bMm,
        d: d,
      ).asTension;
      asB = designRectangularBending(
        code: i.code,
        concrete: concrete,
        steel: steel,
        mEd: mB,
        b: aMm,
        d: dB,
      ).asTension;
  }

  final asMinA = minTensionSteel(
    code: i.code,
    concrete: concrete,
    steel: steel,
    b: bMm,
    d: d,
  );
  final asMinB = minTensionSteel(
    code: i.code,
    concrete: concrete,
    steel: steel,
    b: aMm,
    d: dB,
  );
  final reqA = math.max(asA, asMinA);
  final reqB = math.max(asB, asMinB);
  const diameters = [10, 12, 14, 16, 20, 25];
  final barsA = chooseSpacing(reqA / bM, 250, diameters: diameters);
  final barsB = chooseSpacing(reqB / aM, 250, diameters: diameters);
  if (barsA == null || barsB == null) notes.add(FootingNote.barsNotFound);

  // Punching.
  late Check punching;
  switch (i.code) {
    case DesignCode.ec2:
      final sigma = nU / (aM * bM) / 1e3; // N/mm²
      final k = math.min(1 + math.sqrt(200 / d), 2.0);
      final rhoA = (barsA?.areaPerMetre ?? reqA / bM) / (1000 * d);
      final rhoB = (barsB?.areaPerMetre ?? reqB / aM) / (1000 * dB);
      final rho = math.min(math.sqrt(rhoA * rhoB), 0.02);
      final vMin = 0.035 * math.pow(k, 1.5) * math.sqrt(i.fck);
      final vc = math.max(0.12 * k * math.pow(100 * rho * i.fck, 1 / 3), vMin);
      // 6.4.3(3): β = 1 + k·(M/V)·u1/W1 for a rectangular column.
      final c1 = i.a, c2 = i.b;
      final r12 = c1 / c2;
      final kb = r12 <= 0.5
          ? 0.45
          : r12 <= 1
          ? 0.45 + (r12 - 0.5) * 0.3
          : r12 <= 2
          ? 0.6 + (r12 - 1) * 0.1
          : math.min(0.7 + (r12 - 2) * 0.1, 0.8);
      final u1 = 2 * (c1 + c2) + 4 * math.pi * d;
      final w1 =
          c1 * c1 / 2 +
          c1 * c2 +
          4 * c2 * d +
          16 * d * d +
          2 * math.pi * d * c1;
      final beta = 1 + kb * (mU * 1e6 / (nU * 1e3)) * u1 / w1;
      // 6.4.4(2): check perimeters at a = d and a = 2d.
      var worst = 0.0;
      late double dem, cap;
      for (final dist in [d, 2 * d]) {
        final areaIn =
            i.a * i.b + 2 * dist * (i.a + i.b) + math.pi * dist * dist;
        final vRed = nU * 1e3 - sigma * areaIn;
        final u = 2 * (i.a + i.b) + 2 * math.pi * dist;
        final vEd = beta * vRed / (u * d);
        final vRd = vc * 2 * d / dist;
        if (vEd / vRd > worst) {
          worst = vEd / vRd;
          dem = vEd;
          cap = vRd;
        }
      }
      punching = Check(
        kind: CheckKind.punching,
        demand: dem,
        capacity: cap,
        clause: 'EN 1992-1-1 6.4.4',
        unit: 'MPa',
      );
    case DesignCode.bael:
      // A.5.2.42: Qu ≤ 0.045·uc·h·fc28/γb.
      final h = hMm;
      final uc = 2 * (i.a + i.b + 2 * h);
      final inside = (i.a + h) * (i.b + h) / (aMm * bMm);
      final qu = nU * 1e3 * (1 - inside);
      punching = Check(
        kind: CheckKind.punching,
        demand: qu / 1e3,
        capacity: 0.045 * uc * h * i.fck / Concrete.gammaC / 1e3,
        clause: 'BAEL A.5.2.42',
        unit: 'kN',
      );
  }

  final checks = <Check>[
    Check(
      kind: CheckKind.bearingPressure,
      demand: sigma,
      capacity: limit,
      clause: i.soil != null
          ? 'EN 1997-1 Annex D, DA2'
          : (i.code == DesignCode.bael ? 'DTU 13.12' : 'EN 1997-1 6.5.2'),
      unit: 'kPa',
    ),
    Check(
      kind: CheckKind.baseEccentricity,
      demand: e,
      capacity: aM / 6,
      clause: i.code == DesignCode.bael ? 'DTU 13.12' : 'EN 1997-1 6.5.4',
      unit: 'm',
    ),
    Check(
      kind: CheckKind.bendingSteel,
      demand: reqA,
      capacity: (barsA?.areaPerMetre ?? 0) * bM,
      clause: i.code == DesignCode.bael
          ? 'BAEL / DTU 13.12 (bielles)'
          : 'EN 1992-1-1 9.8.2',
      unit: 'mm²',
    ),
    Check(
      kind: CheckKind.bendingSteel,
      demand: reqB,
      capacity: (barsB?.areaPerMetre ?? 0) * aM,
      clause: i.code == DesignCode.bael
          ? 'BAEL / DTU 13.12 (bielles)'
          : 'EN 1992-1-1 9.8.2',
      unit: 'mm²',
    ),
    punching,
  ];

  return FootingDesign(
    input: i,
    lengthA: aM,
    widthB: bM,
    h: hMm,
    d: d,
    weight: weight,
    eccentricity: e,
    pressure: sigma,
    bearingLimit: limit,
    nUls: nU,
    mUls: mU,
    asA: asA,
    asB: asB,
    asMinA: asMinA,
    asMinB: asMinB,
    barsA: barsA,
    barsB: barsB,
    checks: checks,
    notes: notes,
  );
}
