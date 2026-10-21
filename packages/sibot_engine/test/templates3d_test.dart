import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  final params = BuildingParams(
    spansX: const [5, 5, 6],
    spansY: const [4, 4],
    storeyHeights: const [3.5, 3, 3],
    column: Section3D.rectangle(300, 300),
    beam: Section3D.rectangle(250, 500),
    g: 5,
    q: 2.5,
  );

  test('grid of nodes, columns and beams', () {
    final m = buildingFrame(params);
    expect(m.nodes, hasLength(4 * 3 * 4));
    expect(m.supports, hasLength(12));
    // Per storey: 12 columns, 3 × 3 beams in X, 4 × 2 in Y.
    expect(m.elements, hasLength(3 * (12 + 9 + 8)));
  });

  test('panel line loads: triangle a/3, trapezoid a/2 (1 − a²/3b²)', () {
    expect(panelLineLoad(4, 5), closeTo(4 / 3, 1e-12));
    expect(panelLineLoad(5, 4), closeTo(2 * (1 - 16 / 75), 1e-12));
    // Square panel: both a/3.
    expect(panelLineLoad(4, 4), closeTo(4 / 3, 1e-12));
  });

  test('vertical reactions balance self-weight and floor loads', () {
    final m = buildingFrame(params);
    final an = Frame3DAnalysis(m);
    final g = an.solveCase(0), q = an.solveCase(1);
    double sumZ(Frame3DResult r) =>
        r.reactions.values.fold(0.0, (s, v) => s + v[2]);
    // Applied member loads (moment-equivalent, slightly above the panel
    // totals) plus self-weight.
    var gApplied = 0.0, qApplied = 0.0;
    final lengths = an.lengths;
    for (final l in m.cases[0].member) {
      gApplied += -l.qz * lengths[l.element];
    }
    for (final l in m.cases[1].member) {
      qApplied += -l.qz * lengths[l.element];
    }
    for (var i = 0; i < m.elements.length; i++) {
      final s = m.sections[m.elements[i].section];
      gApplied += s.unitWeight * s.area * lengths[i];
    }
    expect(sumZ(g), closeTo(gApplied, 1e-6));
    expect(sumZ(q), closeTo(qApplied, 1e-6));
    // Moment-equivalent loads are at least the true floor load.
    expect(qApplied, greaterThanOrEqualTo(2.5 * 16 * 8 * 3 * 0.999));
  });

  test('combined case equals the sum of scaled cases', () {
    final m = buildingFrame(params);
    final combo = combinedCase(m, const {0: 1.35, 1: 1.5});
    final an = Frame3DAnalysis(withCase(m, combo));
    final direct = an.solveCase(2);
    final summed = an
        .solveCase(0)
        .scaled(1.35)
        .plus(an.solveCase(1).scaled(1.5));
    final top = m.nodes.length - 1;
    expect(
      direct.displacements[top][2],
      closeTo(summed.displacements[top][2], 1e-12),
    );
  });

  test('params survive JSON', () {
    final back = BuildingParams.fromJson(params.toJson());
    expect(back.spansX, params.spansX);
    expect(back.beam.iy, params.beam.iy);
  });
}
