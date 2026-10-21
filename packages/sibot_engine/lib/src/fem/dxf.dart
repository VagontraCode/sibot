import 'dart:math' as math;

import '../core.dart';
import '../fem3d/model3d.dart';
import 'model.dart';

/// A straight segment read from a drawing, with its layer.
class DxfLine {
  final double x1, y1, z1, x2, y2, z2;
  final String layer;
  const DxfLine(
    this.x1,
    this.y1,
    this.z1,
    this.x2,
    this.y2,
    this.z2, {
    this.layer = '0',
  });

  double get length => math.sqrt(
    math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2) + math.pow(z2 - z1, 2),
  );
}

String _layerName(String s) {
  final t = s.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
  return t.isEmpty ? '0' : t;
}

String _num(double v) {
  final s = v.toStringAsFixed(6);
  return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
}

String _dxf(
  Iterable<(String, double, double, double, double, double, double)> lines,
) {
  final b = StringBuffer()
    ..writeln('0')
    ..writeln('SECTION')
    ..writeln('2')
    ..writeln('ENTITIES');
  for (final (layer, x1, y1, z1, x2, y2, z2) in lines) {
    b
      ..writeln('0')
      ..writeln('LINE')
      ..writeln('8')
      ..writeln(_layerName(layer))
      ..writeln('10')
      ..writeln(_num(x1))
      ..writeln('20')
      ..writeln(_num(y1))
      ..writeln('30')
      ..writeln(_num(z1))
      ..writeln('11')
      ..writeln(_num(x2))
      ..writeln('21')
      ..writeln(_num(y2))
      ..writeln('31')
      ..writeln(_num(z2));
  }
  b
    ..writeln('0')
    ..writeln('ENDSEC')
    ..writeln('0')
    ..writeln('EOF');
  return b.toString();
}

/// Space frame as an R12 ASCII DXF: one LINE per member, on a layer
/// named after its section (metres).
String model3dToDxf(Model3D m) => _dxf([
  for (final e in m.elements)
    (
      m.sections[e.section].name,
      m.nodes[e.n1].x,
      m.nodes[e.n1].y,
      m.nodes[e.n1].z,
      m.nodes[e.n2].x,
      m.nodes[e.n2].y,
      m.nodes[e.n2].z,
    ),
]);

/// Plane frame as DXF in the X–Y plane of the drawing (Y up).
String model2dToDxf(Model2D m) => _dxf([
  for (final e in m.elements)
    (
      m.sections[e.section].name,
      m.nodes[e.n1].x,
      m.nodes[e.n1].y,
      0,
      m.nodes[e.n2].x,
      m.nodes[e.n2].y,
      0,
    ),
]);

/// Reads LINE, LWPOLYLINE and POLYLINE/VERTEX entities of a DXF file
/// (ASCII). Coordinates are taken as they are; scale with [unit].
List<DxfLine> parseDxf(String text, {double unit = 1}) {
  final raw = text.split(RegExp(r'\r?\n'));
  final pairs = <(int, String)>[];
  for (var i = 0; i + 1 < raw.length; i += 2) {
    final code = int.tryParse(raw[i].trim());
    if (code == null) {
      throw const InputError(InputProblem.outOfRange, 'dxf');
    }
    pairs.add((code, raw[i + 1].trim()));
  }
  final out = <DxfLine>[];
  var inEntities = false;
  var i = 0;

  // Group codes of the entity starting at [i] (after its 0 code).
  List<(int, String)> entity() {
    final list = <(int, String)>[];
    i++;
    while (i < pairs.length && pairs[i].$1 != 0) {
      list.add(pairs[i]);
      i++;
    }
    return list;
  }

  double d(String s) => (double.tryParse(s) ?? 0) * unit;
  String layerOf(List<(int, String)> g) =>
      g.firstWhere((p) => p.$1 == 8, orElse: () => (8, '0')).$2;

  while (i < pairs.length) {
    final (code, value) = pairs[i];
    if (code == 2 && value == 'ENTITIES') inEntities = true;
    if (code == 0 && value == 'ENDSEC') inEntities = false;
    if (code != 0 || !inEntities) {
      i++;
      continue;
    }
    switch (value) {
      case 'LINE':
        final g = entity();
        double v(int c) =>
            d(g.firstWhere((p) => p.$1 == c, orElse: () => (c, '0')).$2);
        out.add(
          DxfLine(v(10), v(20), v(30), v(11), v(21), v(31), layer: layerOf(g)),
        );
      case 'LWPOLYLINE':
        final g = entity();
        final layer = layerOf(g);
        final closed =
            (int.tryParse(
                      g
                          .firstWhere(
                            (p) => p.$1 == 70,
                            orElse: () => (70, '0'),
                          )
                          .$2,
                    ) ??
                    0) &
                1 ==
            1;
        final elevation = d(
          g.firstWhere((p) => p.$1 == 38, orElse: () => (38, '0')).$2,
        );
        final xs = [
          for (final p in g)
            if (p.$1 == 10) d(p.$2),
        ];
        final ys = [
          for (final p in g)
            if (p.$1 == 20) d(p.$2),
        ];
        final n = math.min(xs.length, ys.length);
        for (var k = 0; k + 1 < n; k++) {
          out.add(
            DxfLine(
              xs[k],
              ys[k],
              elevation,
              xs[k + 1],
              ys[k + 1],
              elevation,
              layer: layer,
            ),
          );
        }
        if (closed && n > 2) {
          out.add(
            DxfLine(
              xs[n - 1],
              ys[n - 1],
              elevation,
              xs[0],
              ys[0],
              elevation,
              layer: layer,
            ),
          );
        }
      case 'POLYLINE':
        final g = entity();
        final layer = layerOf(g);
        final closed =
            (int.tryParse(
                      g
                          .firstWhere(
                            (p) => p.$1 == 70,
                            orElse: () => (70, '0'),
                          )
                          .$2,
                    ) ??
                    0) &
                1 ==
            1;
        final pts = <(double, double, double)>[];
        while (i < pairs.length && pairs[i] == (0, 'VERTEX')) {
          final v = entity();
          double c(int k) =>
              d(v.firstWhere((p) => p.$1 == k, orElse: () => (k, '0')).$2);
          pts.add((c(10), c(20), c(30)));
        }
        for (var k = 0; k + 1 < pts.length; k++) {
          out.add(
            DxfLine(
              pts[k].$1,
              pts[k].$2,
              pts[k].$3,
              pts[k + 1].$1,
              pts[k + 1].$2,
              pts[k + 1].$3,
              layer: layer,
            ),
          );
        }
        if (closed && pts.length > 2) {
          out.add(
            DxfLine(
              pts.last.$1,
              pts.last.$2,
              pts.last.$3,
              pts[0].$1,
              pts[0].$2,
              pts[0].$3,
              layer: layer,
            ),
          );
        }
      default:
        entity();
    }
  }
  return out;
}

/// Builds a space frame from drawn lines: nodes merged within [tol] (m),
/// one section per layer (copies of [section] named after the layer),
/// fixed supports at the lowest level. Zero-length lines are skipped.
Model3D model3dFromLines(
  List<DxfLine> lines, {
  required Section3D section,
  double tol = 1e-3,
}) {
  if (lines.isEmpty) throw const InputError(InputProblem.outOfRange, 'dxf');
  final nodes = <Node3D>[];
  final grid = <String, List<int>>{};
  String cell(double x, double y, double z) =>
      '${(x / tol).floor()},${(y / tol).floor()},${(z / tol).floor()}';
  int nodeAt(double x, double y, double z) {
    // Search the neighbouring cells for a node within tol.
    final cx = (x / tol).floor(),
        cy = (y / tol).floor(),
        cz = (z / tol).floor();
    for (var a = -1; a <= 1; a++) {
      for (var b = -1; b <= 1; b++) {
        for (var c = -1; c <= 1; c++) {
          for (final i
              in grid['${cx + a},${cy + b},${cz + c}'] ?? const <int>[]) {
            final n = nodes[i];
            if ((n.x - x).abs() <= tol &&
                (n.y - y).abs() <= tol &&
                (n.z - z).abs() <= tol) {
              return i;
            }
          }
        }
      }
    }
    nodes.add(Node3D(x, y, z));
    grid.putIfAbsent(cell(x, y, z), () => []).add(nodes.length - 1);
    return nodes.length - 1;
  }

  final layers = <String>[];
  final elements = <Element3D>[];
  final seen = <String>{};
  for (final l in lines) {
    if (l.length <= tol) continue;
    final a = nodeAt(l.x1, l.y1, l.z1), b = nodeAt(l.x2, l.y2, l.z2);
    if (a == b) continue;
    final key = a < b ? '$a-$b' : '$b-$a';
    if (!seen.add(key)) continue;
    var s = layers.indexOf(l.layer);
    if (s < 0) {
      layers.add(l.layer);
      s = layers.length - 1;
    }
    elements.add(Element3D(a, b, s));
  }
  if (elements.isEmpty) {
    throw const InputError(InputProblem.outOfRange, 'dxf');
  }
  final zMin = nodes.map((n) => n.z).reduce(math.min);
  return Model3D(
    nodes: nodes,
    supports: {
      for (var i = 0; i < nodes.length; i++)
        if ((nodes[i].z - zMin).abs() <= tol) i: Support3D.fixed,
    },
    sections: [
      for (final layer in layers)
        Section3D(
          name: layer,
          area: section.area,
          iy: section.iy,
          iz: section.iz,
          j: section.j,
          youngModulus: section.youngModulus,
          shearModulus: section.shearModulus,
          unitWeight: section.unitWeight,
          profile: section.profile,
          b: section.b,
          h: section.h,
        ),
    ],
    elements: elements,
    cases: [const LoadCase3D(name: 'G', selfWeight: true)],
  );
}

/// Builds a plane frame from drawn lines in the X–Y plane (Y up, Z
/// ignored): nodes merged within [tol], one section per layer, fixed
/// supports at the lowest level.
Model2D model2dFromLines(
  List<DxfLine> lines, {
  required FrameSection section,
  double tol = 1e-3,
}) {
  final flat = [
    for (final l in lines)
      DxfLine(l.x1, 0, l.y1, l.x2, 0, l.y2, layer: l.layer),
  ];
  final m3 = model3dFromLines(
    flat,
    section: Section3D(
      name: section.name,
      area: section.area,
      iy: section.inertia,
      iz: section.inertia,
      j: section.inertia,
      youngModulus: section.youngModulus,
      shearModulus: section.youngModulus / 2.4,
    ),
    tol: tol,
  );
  return Model2D(
    nodes: [for (final n in m3.nodes) Node2D(n.x, n.z)],
    supports: {for (final k in m3.supports.keys) k: Support.fixed},
    sections: [
      for (final s in m3.sections)
        FrameSection(
          name: s.name,
          area: section.area,
          inertia: section.inertia,
          youngModulus: section.youngModulus,
          unitWeight: section.unitWeight,
          material: section.material,
          b: section.b,
          h: section.h,
          fck: section.fck,
          profile: section.profile,
        ),
    ],
    elements: [
      for (final e in m3.elements) Element2D(e.n1, e.n2, section: e.section),
    ],
    cases: const [LoadCase(name: 'G', selfWeight: true)],
  );
}
