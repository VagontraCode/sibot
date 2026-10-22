import 'dart:math' as math;

import 'beam.dart';
import 'core.dart';
import 'fem/analysis.dart';
import 'fem/model.dart';

/// Continuous rectangular RC beam over several spans on line supports,
/// analysed elastically (no redistribution) under the pattern loading of
/// EN 1992-1-1 5.1.3 (also used with BAEL).
class ContinuousBeamInput {
  final DesignCode code;

  /// Span lengths, m, left to right.
  final List<double> spans;

  /// Width and overall depth, mm.
  final double b;
  final double h;

  /// Characteristic permanent and variable line loads, kN/m.
  final double g;
  final double q;
  final bool includeSelfWeight;

  /// Built-in end supports (otherwise simply supported).
  final bool fixedLeft;
  final bool fixedRight;

  final double cover;
  final int linkDiameter;
  final double fck;
  final double fyk;

  const ContinuousBeamInput({
    required this.code,
    required this.spans,
    required this.b,
    required this.h,
    required this.g,
    required this.q,
    required this.fck,
    required this.fyk,
    this.includeSelfWeight = true,
    this.fixedLeft = false,
    this.fixedRight = false,
    this.cover = 30,
    this.linkDiameter = 8,
  });
}

/// ULS envelope at a station along the beam.
class EnvelopePoint {
  /// Position from the left end, m.
  final double x;

  /// Extreme moments (kN·m, sagging +) and shears (kN).
  final double mMax;
  final double mMin;
  final double vMax;
  final double vMin;
  const EnvelopePoint(this.x, this.mMax, this.mMin, this.vMax, this.vMin);
}

class SpanDesign {
  final double length;

  /// Largest sagging moment in the span and largest hogging moment over
  /// the span and its supports (magnitudes), kN·m; largest shear, kN.
  final double mSagging;
  final double mHogging;
  final double vEd;
  final BeamSectionDesign section;
  const SpanDesign({
    required this.length,
    required this.mSagging,
    required this.mHogging,
    required this.vEd,
    required this.section,
  });
}

class ContinuousBeamDesign {
  final ContinuousBeamInput input;

  /// Design line loads at ULS: permanent (incl. self-weight) and variable.
  final double gd;
  final double qd;
  final List<SpanDesign> spans;

  /// Hogging moment envelope at each support (magnitude), kN·m, and the
  /// largest ULS reaction, kN.
  final List<double> supportMoments;
  final List<double> reactions;

  final List<EnvelopePoint> envelope;

  /// Number of load arrangements analysed.
  final int arrangements;

  final List<Check> checks;
  bool get ok => checks.every((c) => c.ok);

  const ContinuousBeamDesign({
    required this.input,
    required this.gd,
    required this.qd,
    required this.spans,
    required this.supportMoments,
    required this.reactions,
    required this.envelope,
    required this.arrangements,
    required this.checks,
  });
}

/// Load arrangements of EN 1992-1-1 5.1.3(1)P (recommended): every span
/// loaded, alternate spans loaded and any two adjacent spans loaded; the
/// other spans carry the permanent load only.
List<List<bool>> patternArrangements(int n) {
  final out = <List<bool>>[
    List.filled(n, true),
    if (n > 1) [for (var k = 0; k < n; k++) k.isEven],
    if (n > 1) [for (var k = 0; k < n; k++) k.isOdd],
    for (var k = 0; k + 1 < n; k++)
      if (n > 2) [for (var j = 0; j < n; j++) j == k || j == k + 1],
  ];
  // Remove duplicates (e.g. two spans: adjacent pair = all loaded).
  final seen = <String>{};
  return [
    for (final a in out)
      if (seen.add(a.map((b) => b ? '1' : '0').join())) a,
  ];
}

ContinuousBeamDesign designContinuousBeam(ContinuousBeamInput i) {
  if (i.spans.isEmpty || i.spans.length > 12) {
    throw const InputError(InputProblem.outOfRange, 'spans');
  }
  for (final l in i.spans) {
    requireRange(l, 0.5, 30, 'spans');
  }
  requirePositive(i.b, 'b');
  requirePositive(i.h, 'h');
  if (i.g < 0 || i.q < 0) {
    throw const InputError(InputProblem.notPositive, 'g');
  }
  final n = i.spans.length;
  final sw = i.includeSelfWeight ? 25 * i.b * i.h * 1e-6 : 0.0;
  final gk = i.g + sw;
  final (gammaG, gammaQ) = (1.35, 1.5);

  // FEM model: one member per span, cases G and Q on each span.
  final xs = <double>[0];
  for (final l in i.spans) {
    xs.add(xs.last + l);
  }
  final model = Model2D(
    nodes: [for (final x in xs) Node2D(x, 0)],
    supports: {
      for (var k = 0; k <= n; k++)
        k: (k == 0 && i.fixedLeft) || (k == n && i.fixedRight)
            ? Support.fixed
            : k == 0
            ? Support.pinned
            : Support.rollerX,
    },
    sections: [FrameSection.rectangle(i.b, i.h, fck: i.fck)],
    elements: [for (var k = 0; k < n; k++) Element2D(k, k + 1)],
    cases: [
      LoadCase(
        name: 'G',
        distributed: [for (var k = 0; k < n; k++) DistributedLoad(k, -gk)],
      ),
      for (var k = 0; k < n; k++)
        LoadCase(
          name: 'Q${k + 1}',
          type: LoadType.imposed,
          distributed: [DistributedLoad(k, -i.q)],
        ),
    ],
  );
  final analysis = FrameAnalysis(model);
  final res = analysis.solveAll();
  final arrangements = patternArrangements(n);
  final combos = [
    for (final a in arrangements)
      () {
        var r = res[0].scaled(gammaG);
        for (var k = 0; k < n; k++) {
          if (a[k]) r = r.plus(res[k + 1].scaled(gammaQ));
        }
        return r;
      }(),
  ];

  // Envelope along each span.
  final envelope = <EnvelopePoint>[];
  final spans = <SpanDesign>[];
  final spanSag = List.filled(n, 0.0);
  final spanHog = List.filled(n, 0.0);
  final spanV = List.filled(n, 0.0);
  for (var k = 0; k < n; k++) {
    final stations = combos.first.members[k].stations;
    for (var s = 0; s < stations.length; s++) {
      var mMax = -double.infinity, mMin = double.infinity;
      var vMax = -double.infinity, vMin = double.infinity;
      for (final c in combos) {
        final st = c.members[k].stations[s];
        mMax = math.max(mMax, st.m);
        mMin = math.min(mMin, st.m);
        vMax = math.max(vMax, st.v);
        vMin = math.min(vMin, st.v);
      }
      envelope.add(
        EnvelopePoint(xs[k] + stations[s].x, mMax, mMin, vMax, vMin),
      );
      spanSag[k] = math.max(spanSag[k], mMax);
      spanHog[k] = math.max(spanHog[k], -mMin);
      spanV[k] = math.max(spanV[k], math.max(vMax.abs(), vMin.abs()));
    }
  }

  // Support moments and reactions.
  final supportMoments = List.filled(n + 1, 0.0);
  final reactions = List.filled(n + 1, 0.0);
  for (final c in combos) {
    for (var s = 0; s <= n; s++) {
      final ms = <double>[
        if (s > 0) c.members[s - 1].stations.last.m,
        if (s < n) c.members[s].stations.first.m,
      ];
      supportMoments[s] = math.max(supportMoments[s], -ms.reduce(math.min));
      reactions[s] = math.max(reactions[s], c.reactions[s]![1]);
    }
  }

  final checks = <Check>[];
  for (var k = 0; k < n; k++) {
    final section = designBeamSection(
      BeamSectionInput(
        code: i.code,
        b: i.b,
        h: i.h,
        mSagging: math.max(spanSag[k], 0),
        mHogging: math.max(spanHog[k], 0),
        vEd: spanV[k],
        fck: i.fck,
        fyk: i.fyk,
        cover: i.cover,
        linkDiameter: i.linkDiameter,
      ),
    );
    spans.add(
      SpanDesign(
        length: i.spans[k],
        mSagging: math.max(spanSag[k], 0),
        mHogging: math.max(spanHog[k], 0),
        vEd: spanV[k],
        section: section,
      ),
    );
    checks.addAll(section.checks);
  }

  return ContinuousBeamDesign(
    input: i,
    gd: gammaG * gk,
    qd: gammaQ * i.q,
    spans: spans,
    supportMoments: supportMoments,
    reactions: reactions,
    envelope: envelope,
    arrangements: arrangements.length,
    checks: checks,
  );
}
