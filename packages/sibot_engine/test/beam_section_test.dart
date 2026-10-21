import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  test('section design matches the load-based beam for the same forces', () {
    final load = designBeam(
      const BeamInput(
        code: DesignCode.ec2,
        span: 6,
        b: 300,
        h: 600,
        g: 20,
        q: 15,
        fck: 30,
        fyk: 500,
      ),
    );
    final sec = designBeamSection(
      BeamSectionInput(
        code: DesignCode.ec2,
        b: 300,
        h: 600,
        mSagging: load.mEd,
        mHogging: 0,
        vEd: load.vEd,
        fck: 30,
        fyk: 500,
      ),
    );
    expect(sec.d, load.d);
    expect(sec.bottom.asTension, closeTo(load.bending.asTension, 1e-9));
    expect(sec.bottomBars.toString(), load.tensionBars.toString());
    // No hogging: constructional top bars.
    expect(sec.topBars.toString(), '2 Ø10');
    expect(sec.ok, isTrue);
  });

  test('hogging and sagging give steel on both faces', () {
    final r = designBeamSection(
      const BeamSectionInput(
        code: DesignCode.bael,
        b: 300,
        h: 500,
        mSagging: 80,
        mHogging: 140,
        vEd: 150,
        fck: 25,
        fyk: 500,
      ),
    );
    expect(r.asTop, greaterThan(r.asBottom));
    expect(r.topBars!.area, greaterThanOrEqualTo(r.asTop));
    expect(r.bottomBars!.area, greaterThanOrEqualTo(r.asBottom));
  });
}
