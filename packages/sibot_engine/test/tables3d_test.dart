// Result tables and CSV export of 3D results.
import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  final m = Model3D(
    nodes: const [Node3D(0, 0, 0), Node3D(0, 0, 3)],
    supports: const {0: Support3D.fixed},
    sections: [Section3D.rectangle(300, 300)],
    elements: const [Element3D(0, 1, 0)],
    cases: const [
      LoadCase3D(name: 'P', nodal: [NodalLoad3D(1, fx: 10, fz: -100)]),
    ],
  );
  final r = Frame3DAnalysis(m).solveCase(0);

  test('reactions, displacements and member forces', () {
    final re = reactionsTable(m, r);
    expect(re.labels, ['1']);
    expect(re.rows.single[2], closeTo(100, 1e-6));
    expect(re.rows.single[0], closeTo(-10, 1e-6));
    final d = displacementsTable(m, r);
    expect(d.length, 2);
    expect(d.rows[1][0], greaterThan(0)); // mm
    final f = memberForcesTable(m, r);
    expect(f.labels.single, '1 (1-2)');
    expect(f.rows.single[0], closeTo(-100, 1e-6)); // Nmin
    expect(f.rows.single[3].abs() + f.rows.single[2].abs(), closeTo(10, 1e-6));
  });

  test('CSV: header, rows and quoting', () {
    final csv = reactionsTable(m, r).toCsv(first: 'node', decimals: 2);
    final lines = csv.trim().split('\n');
    expect(lines.first, 'node,Rx kN,Ry kN,Rz kN,Mx kNm,My kNm,Mz kNm');
    expect(lines[1].split(',')[3], '100.00');
    const t = ResultTable(['a'], ['x,y'], [
      [1],
    ]);
    expect(t.toCsv().split('\n')[1], '"x,y",1.0000');
  });
}
