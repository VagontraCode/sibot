// Response spectrum analysis against single-degree-of-freedom results.
import 'dart:math' as math;

import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  const sec = Section3D(
    name: 'S',
    area: 0.01,
    iy: 2e-4,
    iz: 5e-5,
    j: 1e-5,
    youngModulus: 30000,
    shearModulus: 12500,
    unitWeight: 0,
  );
  final params = spectrumParams(GroundType.c, type1: false);

  test('SDOF: base shear = m Sd(T), displacement = Sd / ω²', () {
    const m = Model3D(
      nodes: [Node3D(0, 0, 0), Node3D(0, 0, 4)],
      supports: {0: Support3D.fixed},
      sections: [sec],
      elements: [Element3D(0, 1, 0)],
      cases: [
        LoadCase3D(name: 'G', nodal: [NodalLoad3D(1, fz: -98.1)]),
      ],
    );
    final modal = modalAnalysis(
      m,
      options: const ModalOptions(modes: 3, massCases: {0: 1}),
    );
    final r = responseSpectrum(
      modal,
      direction: 0,
      ag: 1.6,
      spectrum: params,
      q: 1.5,
    );
    final mode = modal.modes.firstWhere((x) => x.massRatio[0] > 0.5);
    final sd = designSpectrum(mode.period, 1.6, params, 1.5);
    expect(r.baseShear, closeTo(10 * sd, 1e-6));
    expect(
      r.combined.displacements[1][0],
      closeTo(sd / (mode.omega * mode.omega), 1e-9),
    );
    // Base moment = V × L.
    expect(r.combined.reactions[0]![4], closeTo(10 * sd * 4, 1e-5));
    expect(r.enoughModes, isTrue);
  });

  test('CQC coefficient: 1 for equal frequencies, small when far apart', () {
    expect(cqcCoefficient(10, 10), closeTo(1, 1e-12));
    expect(cqcCoefficient(10, 30), lessThan(0.01));
    // Close modes (5 % apart) are strongly correlated.
    expect(cqcCoefficient(10, 10.5), greaterThan(0.5));
  });

  test(
    'two-storey frame: CQC base shear is close to SRSS for distinct modes',
    () {
      const col = Section3D(
        name: 'C',
        area: 0.16,
        iy: 2.133e-3,
        iz: 2.133e-3,
        j: 3.6e-3,
        youngModulus: 30000,
        shearModulus: 12500,
        unitWeight: 0,
      );
      const beam = Section3D(
        name: 'R',
        area: 10,
        iy: 10,
        iz: 10,
        j: 10,
        youngModulus: 30000,
        shearModulus: 12500,
        unitWeight: 0,
      );
      final nodes = <Node3D>[];
      for (final z in [0.0, 3.0, 6.0]) {
        nodes.add(Node3D(0, 0, z));
        nodes.add(Node3D(5, 0, z));
      }
      final m = Model3D(
        nodes: nodes,
        supports: {0: Support3D.fixed, 1: Support3D.fixed},
        sections: const [col, beam],
        elements: const [
          Element3D(0, 2, 0),
          Element3D(1, 3, 0),
          Element3D(2, 4, 0),
          Element3D(3, 5, 0),
          Element3D(2, 3, 1),
          Element3D(4, 5, 1),
        ],
        cases: [
          LoadCase3D(
            name: 'M',
            nodal: [for (var i = 2; i < 6; i++) NodalLoad3D(i, fz: -100)],
          ),
        ],
      );
      final modal = modalAnalysis(
        m,
        options: const ModalOptions(modes: 12, massCases: {0: 1}),
      );
      final r = responseSpectrum(
        modal,
        direction: 0,
        ag: 1.6,
        spectrum: params,
        q: 1.5,
      );
      final srss = math.sqrt(
        r.modal.fold(0.0, (s, x) => s + x.baseShear * x.baseShear),
      );
      expect(r.baseShear, closeTo(srss, srss * 0.05));
      expect(r.massRatio, greaterThan(0.9));
      // Total mass 40.8 t: base shear cannot exceed m · max Sd.
      final sdMax = 1.6 * params.s * 2.5 / 1.5;
      expect(r.baseShear, lessThanOrEqualTo(40.8 * sdMax * 1.001));
    },
  );
}
