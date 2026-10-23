import 'dart:math' as math;

import 'analysis3d.dart';
import 'model3d.dart';

/// A table of results: one label per row (node or member number), the
/// column headers with their units, and the values.
class ResultTable {
  final List<String> columns;
  final List<String> labels;
  final List<List<double>> rows;
  const ResultTable(this.columns, this.labels, this.rows);

  int get length => rows.length;

  /// Comma-separated values with a header line; decimals with a point.
  String toCsv({String first = 'id', int decimals = 4}) {
    String cell(String s) =>
        s.contains(',') || s.contains('"') ? '"${s.replaceAll('"', '""')}"' : s;
    final b = StringBuffer()..writeln([first, ...columns].map(cell).join(','));
    for (var i = 0; i < rows.length; i++) {
      b.writeln(
        [
          cell(labels[i]),
          for (final v in rows[i]) v.toStringAsFixed(decimals),
        ].join(','),
      );
    }
    return b.toString();
  }
}

/// Support reactions (kN, kN·m), global axes.
ResultTable reactionsTable(Model3D m, Frame3DResult r) {
  final nodes = r.reactions.keys.toList()..sort();
  return ResultTable(
    const ['Rx kN', 'Ry kN', 'Rz kN', 'Mx kNm', 'My kNm', 'Mz kNm'],
    [for (final n in nodes) '${n + 1}'],
    [for (final n in nodes) List<double>.of(r.reactions[n]!)],
  );
}

/// Node displacements: translations in mm, rotations in mrad.
ResultTable displacementsTable(Model3D m, Frame3DResult r) => ResultTable(
  const ['ux mm', 'uy mm', 'uz mm', 'rx mrad', 'ry mrad', 'rz mrad'],
  [for (var i = 0; i < m.nodes.length; i++) '${i + 1}'],
  [
    for (final d in r.displacements) [for (final v in d) v * 1000],
  ],
);

/// Extreme internal forces of each member over its stations: axial
/// force range, largest shears and torque, major moment range, largest
/// minor moment (kN, kN·m; N > 0 tension, My > 0 sagging).
ResultTable memberForcesTable(Model3D m, Frame3DResult r) {
  final rows = <List<double>>[];
  for (final mem in r.members) {
    var nMin = double.infinity, nMax = -double.infinity;
    var myMin = double.infinity, myMax = -double.infinity;
    var vy = 0.0, vz = 0.0, t = 0.0, mz = 0.0;
    for (final s in mem.stations) {
      nMin = math.min(nMin, s.n);
      nMax = math.max(nMax, s.n);
      myMin = math.min(myMin, s.my);
      myMax = math.max(myMax, s.my);
      vy = math.max(vy, s.vy.abs());
      vz = math.max(vz, s.vz.abs());
      t = math.max(t, s.t.abs());
      mz = math.max(mz, s.mz.abs());
    }
    rows.add([nMin, nMax, vy, vz, t, myMin, myMax, mz]);
  }
  return ResultTable(
    const [
      'Nmin kN',
      'Nmax kN',
      '|Vy| kN',
      '|Vz| kN',
      '|T| kNm',
      'My min kNm',
      'My max kNm',
      '|Mz| kNm',
    ],
    [
      for (var e = 0; e < m.elements.length; e++)
        '${e + 1} (${m.elements[e].n1 + 1}-${m.elements[e].n2 + 1})',
    ],
    rows,
  );
}
