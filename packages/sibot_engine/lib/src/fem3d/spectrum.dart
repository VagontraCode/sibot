import 'dart:math' as math;
import 'dart:typed_data';

import '../seismic.dart';
import 'analysis3d.dart';
import 'modal.dart';

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

  const SpectrumResult({
    required this.direction,
    required this.modal,
    required this.combined,
    required this.baseShear,
    required this.massRatio,
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
  return SpectrumResult(
    direction: direction,
    modal: responses,
    combined: combined,
    baseShear: vb,
    massRatio: ratio,
  );
}
