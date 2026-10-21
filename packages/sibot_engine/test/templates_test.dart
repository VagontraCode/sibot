import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

const _sec = FrameSection(
  name: 'S',
  area: 0.005,
  inertia: 5e-5,
  youngModulus: 210000,
  unitWeight: 78.5,
);

void main() {
  test('continuous beam: two equal spans give 3/8, 10/8, 3/8 wL', () {
    final m = continuousBeam(
      spans: const [5, 5],
      section: _sec,
      g: 10,
      selfWeight: false,
    );
    final r = FrameAnalysis(m).solveCase(0);
    expect(r.reactions[1]![1], closeTo(62.5, 1e-9));
    expect(m.cases.length, 1);
  });

  test('portal frame geometry and loads', () {
    final m = portalFrame(
      bays: 3,
      bayWidth: 5,
      storeys: 2,
      storeyHeight: 3,
      column: _sec,
      beam: _sec,
      g: 20,
      q: 10,
      wind: 15,
    );
    expect(m.nodes.length, 4 * 3);
    expect(m.elements.length, 4 * 2 + 3 * 2);
    expect(m.cases.map((c) => c.name), ['G', 'Q', 'W']);
    final a = FrameAnalysis(m);
    final w = a.solveCase(2);
    final sumX = w.reactions.values.fold(0.0, (s, v) => s + v[0]);
    expect(sumX, closeTo(-30, 1e-8));
  });

  group('trusses', () {
    Model2D truss(TrussType t) => flatTruss(
      span: 12,
      height: 2,
      panels: 6,
      section: _sec,
      type: t,
      g: 10,
      selfWeight: false,
    );

    for (final t in TrussType.values) {
      test('${t.name}: equilibrium and pin-jointed members', () {
        final m = truss(t);
        final r = FrameAnalysis(m).solveCase(0);
        final sumY = r.reactions.values.fold(0.0, (s, v) => s + v[1]);
        expect(sumY, closeTo(70, 1e-8)); // 7 top nodes × 10 kN
        for (final mem in r.members) {
          expect(mem.maxMoment.abs(), lessThan(1e-6));
        }
      });
    }

    test('Pratt diagonals are in tension under gravity', () {
      final m = truss(TrussType.pratt);
      final r = FrameAnalysis(m).solveCase(0);
      final diagonals = [
        for (var k = 0; k < m.elements.length; k++)
          if (m.nodes[m.elements[k].n1].x != m.nodes[m.elements[k].n2].x &&
              m.nodes[m.elements[k].n1].y != m.nodes[m.elements[k].n2].y)
            k,
      ];
      expect(diagonals.length, 6);
      for (final k in diagonals) {
        expect(r.members[k].stations.first.n, greaterThan(0));
      }
    });

    test('Howe diagonals are in compression under gravity', () {
      final m = truss(TrussType.howe);
      final r = FrameAnalysis(m).solveCase(0);
      for (var k = 0; k < m.elements.length; k++) {
        final e = m.elements[k];
        final a = m.nodes[e.n1], b = m.nodes[e.n2];
        if (a.x != b.x && a.y != b.y) {
          expect(r.members[k].stations.first.n, lessThan(0));
        }
      }
    });
  });
}
