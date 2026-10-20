import 'dart:math' as math;

import 'core.dart';
import 'materials.dart';
import 'rc_bending.dart';
import 'rc_shear.dart';
import 'rebar.dart';

enum BeamSupport {
  /// Single span on two simple supports: M = wL²/8, V = wL/2.
  simplySupported,

  /// Cantilever: M = wL²/2, V = wL.
  cantilever,
}

enum BeamNote {
  compressionSteelRequired,
  barsDoNotFit,
  linksNotFound,
  deflectionNotCovered,
}

class BeamInput {
  final DesignCode code;
  final BeamSupport support;

  /// Span, m.
  final double span;

  /// Width and overall depth, mm.
  final double b;
  final double h;

  /// Nominal cover to the links, mm.
  final double cover;
  final int linkDiameter;

  /// Characteristic permanent and variable line loads, kN/m
  /// (permanent excludes self-weight when [includeSelfWeight]).
  final double g;
  final double q;
  final bool includeSelfWeight;

  /// Characteristic material strengths, MPa.
  final double fck;
  final double fyk;

  const BeamInput({
    required this.code,
    required this.span,
    required this.b,
    required this.h,
    required this.g,
    required this.q,
    required this.fck,
    required this.fyk,
    this.support = BeamSupport.simplySupported,
    this.cover = 30,
    this.linkDiameter = 8,
    this.includeSelfWeight = true,
  });
}

class BeamDesign {
  final BeamInput input;

  /// Self-weight, kN/m (0 when not included).
  final double selfWeight;

  /// ULS line load 1.35·G + 1.5·Q, kN/m (EN 1990 6.10 / BAEL A.3.3).
  final double wUls;

  /// Design moment and shear, kN·m and kN.
  final double mEd;
  final double vEd;

  /// Effective depth used, mm.
  final double d;

  final BendingDesign bending;
  final double asMin;
  final BarSet? tensionBars;
  final BarSet? compressionBars;
  final ShearDesign shear;

  /// Span / effective depth: actual and limit (EC2 only), else null.
  final double? spanDepthActual;
  final double? spanDepthLimit;

  final List<Check> checks;
  final List<BeamNote> notes;

  const BeamDesign({
    required this.input,
    required this.selfWeight,
    required this.wUls,
    required this.mEd,
    required this.vEd,
    required this.d,
    required this.bending,
    required this.asMin,
    required this.tensionBars,
    required this.compressionBars,
    required this.shear,
    required this.spanDepthActual,
    required this.spanDepthLimit,
    required this.checks,
    required this.notes,
  });

  bool get ok => checks.every((c) => c.ok);

  /// Highest utilisation over all checks.
  double get maxRatio => checks.map((c) => c.ratio).fold(0.0, math.max);
}

/// ULS combination for persistent design situations:
/// EN 1990 eq. 6.10 and BAEL A.3.3.21 both give 1.35·G + 1.5·Q.
double ulsLoad(double g, double q) => 1.35 * g + 1.5 * q;

BeamDesign designBeam(BeamInput i) {
  requirePositive(i.span, 'span');
  requirePositive(i.b, 'b');
  requirePositive(i.h, 'h');
  requireRange(i.cover, 10, 100, 'cover');
  if (i.g < 0) throw const InputError(InputProblem.outOfRange, 'g');
  if (i.q < 0) throw const InputError(InputProblem.outOfRange, 'q');

  final concrete = Concrete(i.code, i.fck);
  final steel = RebarSteel(i.fyk);

  final sw = i.includeSelfWeight
      ? reinforcedConcreteWeight * i.b * i.h / 1e6
      : 0.0;
  final w = ulsLoad(i.g + sw, i.q);
  final l = i.span;
  final (mEd, vEd) = switch (i.support) {
    BeamSupport.simplySupported => (w * l * l / 8, w * l / 2),
    BeamSupport.cantilever => (w * l * l / 2, w * l),
  };

  final inner = i.b - 2 * (i.cover + i.linkDiameter);
  if (inner <= 0) {
    throw const InputError(InputProblem.inconsistentGeometry, 'cover');
  }

  // Effective depth depends on the bar chosen: iterate from Ø16.
  var barDia = 16;
  late double d;
  late BendingDesign bending;
  BarSet? bars;
  for (var pass = 0; pass < 3; pass++) {
    d = i.h - i.cover - i.linkDiameter - barDia / 2;
    if (d <= 0) {
      throw const InputError(InputProblem.inconsistentGeometry, 'h');
    }
    const compDia = 12;
    final d2 = i.cover + i.linkDiameter + compDia / 2;
    bending = designRectangularBending(
      code: i.code,
      concrete: concrete,
      steel: steel,
      mEd: mEd,
      b: i.b,
      d: d,
      d2: d2,
    );
    final asMin = minTensionSteel(
      code: i.code,
      concrete: concrete,
      steel: steel,
      b: i.b,
      d: d,
    );
    bars = chooseBars(math.max(bending.asTension, asMin), inner);
    if (bars == null || bars.diameter == barDia) break;
    barDia = bars.diameter;
  }

  final asMin = minTensionSteel(
    code: i.code,
    concrete: concrete,
    steel: steel,
    b: i.b,
    d: d,
  );
  final compBars = bending.needsCompressionSteel
      ? chooseBars(bending.asCompression, inner)
      : null;
  final asProv = bars?.area ?? 0;

  final shear = designShear(
    code: i.code,
    concrete: concrete,
    steel: steel,
    vEd: vEd,
    b: i.b,
    d: d,
    rhoL: asProv / (i.b * d),
  );

  final checks = <Check>[
    Check(
      kind: CheckKind.bendingSteel,
      demand: bending.asTension,
      capacity: asProv,
      clause: bendingClause(i.code),
      unit: 'mm²',
    ),
    if (bending.needsCompressionSteel)
      Check(
        kind: CheckKind.bendingSteel,
        demand: bending.asCompression,
        capacity: compBars?.area ?? 0,
        clause: bendingClause(i.code),
        unit: 'mm²',
      ),
    Check(
      kind: CheckKind.minSteel,
      demand: asMin,
      capacity: asProv,
      clause: minSteelClause(i.code),
      unit: 'mm²',
    ),
    Check(
      kind: CheckKind.maxSteel,
      demand: asProv + (compBars?.area ?? 0),
      capacity: 0.04 * i.b * i.h,
      // BAEL sets no maximum for beams; the EC2 4 % limit is applied.
      clause: i.code == DesignCode.ec2
          ? 'EN 1992-1-1 9.2.1.1(3)'
          : 'cf. EN 1992-1-1 9.2.1.1(3)',
      unit: 'mm²',
    ),
    if (bars != null && bars.count > 1)
      Check(
        kind: CheckKind.barSpacing,
        demand: minClearSpacing(bars.diameter),
        capacity: (inner - bars.count * bars.diameter) / (bars.count - 1),
        clause: i.code == DesignCode.ec2 ? 'EN 1992-1-1 8.2' : 'BAEL A.7.2.8',
        unit: 'mm',
      ),
    shear.crushing,
    Check(
      kind: CheckKind.shearLinks,
      demand: shear.aswPerSRequired,
      capacity: shear.links?.aswPerS ?? 0,
      clause: i.code == DesignCode.ec2
          ? 'EN 1992-1-1 6.2.3, 9.2.2'
          : 'BAEL A.5.1.23',
      unit: 'mm²/mm',
    ),
  ];

  // Serviceability: deflection by span/depth rules.
  double? ldActual;
  double? ldLimit;
  final notes = <BeamNote>[
    if (bending.needsCompressionSteel) BeamNote.compressionSteelRequired,
    if (bars == null) BeamNote.barsDoNotFit,
    if (shear.links == null) BeamNote.linksNotFound,
  ];

  switch (i.code) {
    case DesignCode.ec2:
      // 7.4.2(2) eq. 7.16, with K from Table 7.4N and eq. 7.17 factor.
      final k = switch (i.support) {
        BeamSupport.simplySupported => 1.0,
        BeamSupport.cantilever => 0.4,
      };
      final fck = i.fck;
      final rho0 = math.sqrt(fck) * 1e-3;
      final asReq = math.max(bending.asTension, 1e-9);
      final rho = asReq / (i.b * d);
      final rhoC = bending.asCompression / (i.b * d);
      final base = rho <= rho0
          ? 11 +
                1.5 * math.sqrt(fck) * rho0 / rho +
                3.2 * math.sqrt(fck) * math.pow(rho0 / rho - 1, 1.5)
          : 11 +
                1.5 * math.sqrt(fck) * rho0 / (rho - rhoC) +
                math.sqrt(fck) / 12 * math.sqrt(rhoC / rho0);
      final steelFactor =
          500 / i.fyk * math.min(asProv > 0 ? asProv / asReq : 1, 1.5);
      ldLimit = k * base * steelFactor;
      ldActual = l * 1000 / d;
      checks.add(
        Check(
          kind: CheckKind.deflection,
          demand: ldActual,
          capacity: ldLimit,
          clause: 'EN 1992-1-1 7.4.2',
        ),
      );
    case DesignCode.bael:
      if (i.support == BeamSupport.simplySupported) {
        // B.6.5.1: h/l ≥ 1/16, h/l ≥ Mt/(10·M0) (= 1/10 for a simple
        // span), A/(b0·d) ≤ 4.2/fe → deflection need not be calculated.
        checks.add(
          Check(
            kind: CheckKind.deflection,
            demand: 1 / 10,
            capacity: i.h / (l * 1000),
            clause: 'BAEL B.6.5.1',
          ),
        );
        checks.add(
          Check(
            kind: CheckKind.deflection,
            demand: asProv / (i.b * d),
            capacity: 4.2 / i.fyk,
            clause: 'BAEL B.6.5.1',
          ),
        );
      } else {
        notes.add(BeamNote.deflectionNotCovered);
      }
  }

  return BeamDesign(
    input: i,
    selfWeight: sw,
    wUls: w,
    mEd: mEd,
    vEd: vEd,
    d: d,
    bending: bending,
    asMin: asMin,
    tensionBars: bars,
    compressionBars: compBars,
    shear: shear,
    spanDepthActual: ldActual,
    spanDepthLimit: ldLimit,
    checks: checks,
    notes: notes,
  );
}
