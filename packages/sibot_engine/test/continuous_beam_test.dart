// Continuous beams under pattern loading against beam tables.
import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  test('load arrangements of EC2 5.1.3', () {
    expect(patternArrangements(1), hasLength(1));
    // All, alternate ×2 (adjacent pair = all for two spans).
    expect(patternArrangements(2), hasLength(3));
    // All, alternate ×2, adjacent pairs (1-2) and (2-3).
    expect(patternArrangements(3), hasLength(5));
  });

  group('two equal 6 m spans, g = q = 10 kN/m', () {
    final r = designContinuousBeam(
      const ContinuousBeamInput(
        code: DesignCode.ec2,
        spans: [6, 6],
        b: 300,
        h: 550,
        g: 10,
        q: 10,
        includeSelfWeight: false,
        fck: 30,
        fyk: 500,
      ),
    );
    const gd = 13.5, qd = 15.0;
    test('support moment wL²/8 with both spans loaded', () {
      expect(r.supportMoments[1], closeTo((gd + qd) * 36 / 8, 0.01));
      expect(r.supportMoments[0], closeTo(0, 1e-6));
    });
    test('span moment with the variable load on one span only', () {
      // RA = 3/8 gd L + 7/16 qd L; M = RA² / (2 (gd + qd)).
      const ra = 3 / 8 * gd * 6 + 7 / 16 * qd * 6;
      expect(r.spans[0].mSagging, closeTo(ra * ra / (2 * (gd + qd)), 0.5));
      expect(r.spans[0].mSagging, greaterThan(9 / 128 * (gd + qd) * 36));
    });
    test('central reaction 1.25 wL; sections are designed', () {
      expect(r.reactions[1], closeTo(1.25 * (gd + qd) * 6, 0.01));
      expect(r.spans[0].mHogging, closeTo(r.supportMoments[1], 0.01));
      expect(r.spans[0].section.asTop, greaterThan(0));
      expect(r.ok, isTrue, reason: r.checks.join('\n'));
    });
  });

  test('fixed ends: single span gives wL²/12 at the supports', () {
    final r = designContinuousBeam(
      const ContinuousBeamInput(
        code: DesignCode.bael,
        spans: [5],
        b: 250,
        h: 450,
        g: 10,
        q: 0,
        includeSelfWeight: false,
        fixedLeft: true,
        fixedRight: true,
        fck: 25,
        fyk: 500,
      ),
    );
    expect(r.supportMoments[0], closeTo(13.5 * 25 / 12, 0.01));
    expect(r.spans.single.mSagging, closeTo(13.5 * 25 / 24, 0.05));
  });

  test('rejects an empty span list', () {
    expect(
      () => designContinuousBeam(
        const ContinuousBeamInput(
          code: DesignCode.ec2,
          spans: [],
          b: 300,
          h: 500,
          g: 10,
          q: 5,
          fck: 30,
          fyk: 500,
        ),
      ),
      throwsA(isA<InputError>()),
    );
  });
}
