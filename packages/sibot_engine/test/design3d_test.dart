import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  const sec = Section3D(
    name: 'S',
    area: 0.005,
    iy: 8e-5,
    iz: 6e-6,
    j: 2e-7,
    youngModulus: 210000,
    shearModulus: 81000,
    unitWeight: 0,
  );

  test('envelope of a fixed-end beam under UDL: wL²/24 and wL²/12', () {
    const m = Model3D(
      nodes: [Node3D(0, 0, 0), Node3D(6, 0, 0)],
      supports: {0: Support3D.fixed, 1: Support3D.fixed},
      sections: [sec],
      elements: [Element3D(0, 1, 0)],
      cases: [
        LoadCase3D(name: 'q', member: [MemberLoad3D(0, qz: -10)]),
      ],
    );
    final r = Frame3DAnalysis(m).solveCase(0);
    final env = MemberEnvelope3D.of(m, 0, [r]);
    expect(env.vertical, isFalse);
    expect(env.mySagging, closeTo(10 * 36 / 24, 1e-6));
    expect(env.myHogging, closeTo(10 * 36 / 12, 1e-6));
    expect(env.vzMax, closeTo(30, 1e-6));
  });

  test('seismic situations bracket the quasi-permanent forces', () {
    const m = Model3D(
      nodes: [Node3D(0, 0, 0), Node3D(0, 0, 3)],
      supports: {0: Support3D.fixed},
      sections: [sec],
      elements: [Element3D(0, 1, 0)],
      cases: [
        LoadCase3D(name: 'G', nodal: [NodalLoad3D(1, fz: -100)]),
        LoadCase3D(name: 'E', nodal: [NodalLoad3D(1, fx: 20)]),
      ],
    );
    final an = Frame3DAnalysis(m);
    final g = an.solveCase(0), e = an.solveCase(1);
    final env = MemberEnvelope3D.of(m, 0, seismicSituations(g, e));
    expect(env.vertical, isTrue);
    expect(env.nCompression, closeTo(100, 1e-6));
    // Base moment from E: 20 × 3 = 60 in either sign.
    expect(env.myMax, closeTo(60, 1e-6));
  });
}
