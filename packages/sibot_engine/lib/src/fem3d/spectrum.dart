import 'dart:math' as math;
import 'dart:typed_data';

import '../seismic.dart';
import 'analysis3d.dart';
import 'modal.dart';
import 'model3d.dart';

/// One mode's contribution to a response spectrum analysis.
class ModalResponse {
  final int mode;
  final double period;

  /// Design spectral acceleration, m/s².
  final double sd;

  /// Base shear of the mode in the excitation direction, kN.
  final double baseShear;
  final Frame3DResult result;

  const ModalResponse(
    this.mode,
    this.period,
    this.sd,
    this.baseShear,
    this.result,
  );
}

class SpectrumResult {
  /// Excitation direction: 0 = X, 1 = Y.
  final int direction;
  final List<ModalResponse> modal;

  /// CQC-combined response (absolute values).
  final Frame3DResult combined;
  final double baseShear;

  /// Mass ratio of the modes used, in the excitation direction.
  final double massRatio;

  /// Accidental torsional moments per rigid floor, kN·m (empty when not
  /// applied), and their static effects (included in [combined]).
  final List<double> torsionMoments;
  final Frame3DResult? torsion;

  const SpectrumResult({
    required this.direction,
    required this.modal,
    required this.combined,
    required this.baseShear,
    required this.massRatio,
    this.torsionMoments = const [],
    this.torsion,
  });

  /// EN 1998-1 4.3.3.3.1: modes taken into account should reach 90 % of
  /// the mass.
  bool get enoughModes => massRatio >= 0.9;
}

/// CQC correlation coefficient for equal damping ζ (Der Kiureghian).
double cqcCoefficient(double wi, double wj, {double zeta = 0.05}) {
  final b = wj / wi;
  final num = 8 * zeta * zeta * (1 + b) * math.pow(b, 1.5);
  final den = math.pow(1 - b * b, 2) + 4 * zeta * zeta * b * math.pow(1 + b, 2);
  return num / den;
}

/// Modal response spectrum analysis (EN 1998-1 4.3.3.3) in one
/// horizontal direction with the design spectrum of [seismic], combined
/// by CQC.
SpectrumResult responseSpectrum(
  ModalResult modal, {
  required int direction,
  required double ag,
  required SpectrumParams spectrum,
  required double q,
  double zeta = 0.05,
  bool accidentalTorsion = false,
}) {
  final an = modal.analysis;
  final responses = <ModalResponse>[];
  final omegas = <double>[];
  var ratio = 0.0;
  for (var j = 0; j < modal.modes.length; j++) {
    final m = modal.modes[j];
    if (m.omega <= 0) continue;
    final sd = designSpectrum(m.period, ag, spectrum, q);
    final gamma = m.participation[direction];
    // Modal displacements u = Γ φ Sd / ω².
    final f = gamma * sd / (m.omega * m.omega);
    final x = Float64List.fromList([for (final v in m.vector) v * f]);
    final r = an.resultFromDisplacements(x);
    final vb = r.reactions.values.fold(0.0, (s, v) => s + v[direction]);
    responses.add(ModalResponse(j, m.period, sd, vb.abs(), r));
    omegas.add(m.omega);
    ratio += m.massRatio[direction];
  }

  final n = responses.length;
  final rho = List.generate(
    n,
    (i) => List.generate(
      n,
      (k) => cqcCoefficient(omegas[i], omegas[k], zeta: zeta),
    ),
  );
  double cqc(double Function(Frame3DResult) pick) {
    final v = [for (final r in responses) pick(r.result)];
    var s = 0.0;
    for (var i = 0; i < n; i++) {
      for (var k = 0; k < n; k++) {
        s += rho[i][k] * v[i] * v[k];
      }
    }
    return math.sqrt(math.max(s, 0));
  }

  final base = responses.first.result;
  final combined = Frame3DResult(
    [
      for (var node = 0; node < base.displacements.length; node++)
        [for (var d = 0; d < 6; d++) cqc((r) => r.displacements[node][d])],
    ],
    {
      for (final key in base.reactions.keys)
        key: [for (var d = 0; d < 6; d++) cqc((r) => r.reactions[key]![d])],
    },
    [
      for (var e = 0; e < base.members.length; e++)
        Member3DResult(
          [for (var k = 0; k < 12; k++) cqc((r) => r.members[e].endForces[k])],
          [
            for (var s = 0; s < base.members[e].stations.length; s++)
              Station3D(
                base.members[e].stations[s].x,
                cqc((r) => r.members[e].stations[s].n),
                cqc((r) => r.members[e].stations[s].vy),
                cqc((r) => r.members[e].stations[s].vz),
                cqc((r) => r.members[e].stations[s].t),
                cqc((r) => r.members[e].stations[s].my),
                cqc((r) => r.members[e].stations[s].mz),
                [
                  for (var d = 0; d < 3; d++)
                    cqc((r) => r.members[e].stations[s].disp[d]),
                ],
              ),
          ],
        ),
    ],
  );
  final vb = cqc(
    (r) => r.reactions.values.fold(0.0, (s, v) => s + v[direction]),
  );

  // Accidental torsion (EN 1998-1 4.3.2, 4.3.3.3.3): Mai = ±0.05 Li Fi
  // at each rigid floor, Fi distributing the base shear by height × mass
  // (4.11); its effects are added to the modal response.
  final model = an.model;
  if (accidentalTorsion && model.diaphragms.isNotEmpty) {
    final floors = <(List<int>, double, double, double)>[]; // nodes, z, m, L
    for (final g in model.diaphragms) {
      final nodes = [
        for (final i in g)
          if (i >= 0 && i < model.nodes.length) i,
      ];
      if (nodes.isEmpty) continue;
      var m = 0.0, lo = double.infinity, hi = -double.infinity;
      for (final i in nodes) {
        m += modal.nodeMass[i];
        final c = direction == 0 ? model.nodes[i].y : model.nodes[i].x;
        lo = math.min(lo, c);
        hi = math.max(hi, c);
      }
      floors.add((nodes, model.nodes[nodes.first].z, m, hi - lo));
    }
    final sumZm = floors.fold(0.0, (s, f) => s + f.$2 * f.$3);
    if (sumZm > 0) {
      final moments = [
        for (final f in floors) 0.05 * f.$4 * vb * f.$2 * f.$3 / sumZm,
      ];
      final torsion = an.solveNodal([
        for (var k = 0; k < floors.length; k++)
          NodalLoad3D(floors[k].$1.first, mz: moments[k]),
      ]);
      return SpectrumResult(
        direction: direction,
        modal: responses,
        combined: mapResults(combined, torsion, (a, b) => a.abs() + b.abs()),
        baseShear: vb,
        massRatio: ratio,
        torsionMoments: moments,
        torsion: torsion,
      );
    }
  }
  return SpectrumResult(
    direction: direction,
    modal: responses,
    combined: combined,
    baseShear: vb,
    massRatio: ratio,
  );
}

/// Applies [f] value by value to two results of the same model.
Frame3DResult mapResults(
  Frame3DResult a,
  Frame3DResult b,
  double Function(double, double) f,
) => Frame3DResult(
  [
    for (var n = 0; n < a.displacements.length; n++)
      [
        for (var d = 0; d < 6; d++)
          f(a.displacements[n][d], b.displacements[n][d]),
      ],
  ],
  {
    for (final k in a.reactions.keys)
      k: [
        for (var d = 0; d < 6; d++) f(a.reactions[k]![d], b.reactions[k]![d]),
      ],
  },
  [
    for (var e = 0; e < a.members.length; e++)
      Member3DResult(
        [
          for (var k = 0; k < 12; k++)
            f(a.members[e].endForces[k], b.members[e].endForces[k]),
        ],
        [
          for (var s = 0; s < a.members[e].stations.length; s++)
            () {
              final p = a.members[e].stations[s], q = b.members[e].stations[s];
              return Station3D(
                p.x,
                f(p.n, q.n),
                f(p.vy, q.vy),
                f(p.vz, q.vz),
                f(p.t, q.t),
                f(p.my, q.my),
                f(p.mz, q.mz),
                [for (var d = 0; d < 3; d++) f(p.disp[d], q.disp[d])],
              );
            }(),
        ],
      ),
  ],
);

/// EN 1998-1 4.3.3.5.1 (4.18, 4.19): the larger of EX + 0.3 EY and
/// 0.3 EX + EY, value by value (absolute values).
Frame3DResult combineDirections(Frame3DResult ex, Frame3DResult ey) =>
    mapResults(
      ex,
      ey,
      (a, b) => math.max(a.abs() + 0.3 * b.abs(), 0.3 * a.abs() + b.abs()),
    );
