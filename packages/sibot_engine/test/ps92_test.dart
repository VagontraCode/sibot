import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  test('nominal accelerations by zone and class', () {
    expect(ps92NominalAcceleration(Ps92Zone.ia, 'B'), 1.0);
    expect(ps92NominalAcceleration(Ps92Zone.ii, 'C'), 3.0);
    expect(ps92NominalAcceleration(Ps92Zone.iii, 'D'), 4.5);
    expect(
      () => ps92NominalAcceleration(Ps92Zone.ii, 'A'),
      throwsA(isA<InputError>()),
    );
  });

  test('normalised spectrum branches are continuous', () {
    for (final s in Ps92Site.values) {
      final (ra, rm, tb, tc, td) = ps92SiteParams(s);
      expect(ps92R(0, s), ra);
      expect(ps92R(tb, s), closeTo(rm, 1e-12));
      expect(ps92R(tc, s), closeTo(rm, 1e-12));
      expect(ps92R(td, s), closeTo(rm * tc / td, 1e-12));
      expect(ps92R(td * 1.0000001, s), closeTo(rm * tc / td, 1e-6));
    }
  });

  test('S1 plateau: aN · 2.5 / q', () {
    expect(ps92Spectrum(0.3, 2.5, Ps92Site.s1, 2), closeTo(3.125, 1e-12));
  });

  test('response spectrum accepts a PS92 design function', () {
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
      ag: 0,
      spectrum: spectrumParams(GroundType.a, type1: true),
      q: 1,
      design: (t) => ps92Spectrum(t, 2.5, Ps92Site.s2, 2),
    );
    final mode = modal.modes.firstWhere((x) => x.massRatio[0] > 0.5);
    expect(
      r.baseShear,
      closeTo(10 * ps92Spectrum(mode.period, 2.5, Ps92Site.s2, 2), 1e-6),
    );
  });
}
