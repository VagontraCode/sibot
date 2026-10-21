import 'dart:math' as math;

import '../fem/model.dart' show LoadType;
import '../steel_sections.dart';

/// Space frame model. Global axes: X, Y horizontal, Z up. Units: m, kN,
/// kN·m, kN/m; section properties in m² / m⁴; moduli in MPa.
class Node3D {
  final double x;
  final double y;
  final double z;
  const Node3D(this.x, this.y, this.z);

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'z': z};
  factory Node3D.fromJson(Map<String, dynamic> j) => Node3D(
    (j['x'] as num).toDouble(),
    (j['y'] as num).toDouble(),
    (j['z'] as num).toDouble(),
  );
}

/// Restrained degrees of freedom: translations then rotations.
class Support3D {
  final bool ux, uy, uz, rx, ry, rz;
  const Support3D({
    this.ux = false,
    this.uy = false,
    this.uz = false,
    this.rx = false,
    this.ry = false,
    this.rz = false,
  });

  static const fixed = Support3D(
    ux: true,
    uy: true,
    uz: true,
    rx: true,
    ry: true,
    rz: true,
  );
  static const pinned = Support3D(ux: true, uy: true, uz: true);

  List<bool> get dofs => [ux, uy, uz, rx, ry, rz];

  Map<String, dynamic> toJson() => {'d': dofs};
  factory Support3D.fromJson(Map<String, dynamic> j) {
    final d = (j['d'] as List).cast<bool>();
    return Support3D(
      ux: d[0],
      uy: d[1],
      uz: d[2],
      rx: d[3],
      ry: d[4],
      rz: d[5],
    );
  }
}

/// Prismatic section. Iy is the major-axis inertia (bending in the local
/// x–z plane), Iz the minor-axis one, J the torsion constant.
class Section3D {
  final String name;
  final double area;
  final double iy;
  final double iz;
  final double j;
  final double youngModulus;
  final double shearModulus;

  /// Unit weight, kN/m³.
  final double unitWeight;

  /// Library profile or rectangle dimensions (mm) for design links.
  final String? profile;
  final double? b;
  final double? h;

  const Section3D({
    required this.name,
    required this.area,
    required this.iy,
    required this.iz,
    required this.j,
    required this.youngModulus,
    required this.shearModulus,
    this.unitWeight = 25,
    this.profile,
    this.b,
    this.h,
  });

  /// Concrete rectangle b × h (mm): h along local z (major axis).
  factory Section3D.rectangle(
    double bMm,
    double hMm, {
    double e = 31000,
    double nu = 0.2,
    double unitWeight = 25,
  }) {
    final b = bMm / 1000, h = hMm / 1000;
    final (lo, hi) = b < h ? (b, h) : (h, b);
    // Saint-Venant torsion constant of a rectangle (Roark).
    final j =
        hi *
        math.pow(lo, 3) *
        (1 / 3 - 0.21 * lo / hi * (1 - math.pow(lo / hi, 4) / 12));
    return Section3D(
      name: '${bMm.round()}×${hMm.round()}',
      area: b * h,
      iy: b * h * h * h / 12,
      iz: h * b * b * b / 12,
      j: j.toDouble(),
      youngModulus: e,
      shearModulus: e / (2 * (1 + nu)),
      unitWeight: unitWeight,
      b: bMm,
      h: hMm,
    );
  }

  /// Rolled steel profile from the library (web along local z).
  factory Section3D.steel(String name) {
    final p = steelSections[name]!;
    return Section3D(
      name: name,
      area: p.area * 1e-6,
      iy: p.iy * 1e-12,
      iz: p.iz * 1e-12,
      j: p.it * 1e-12,
      youngModulus: 210000,
      shearModulus: 81000,
      unitWeight: 78.5,
      profile: name,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'a': area,
    'iy': iy,
    'iz': iz,
    'j': j,
    'e': youngModulus,
    'g': shearModulus,
    'gamma': unitWeight,
    'profile': profile,
    'b': b,
    'h': h,
  };
  factory Section3D.fromJson(Map<String, dynamic> j) => Section3D(
    name: j['name'] as String? ?? '',
    area: (j['a'] as num).toDouble(),
    iy: (j['iy'] as num).toDouble(),
    iz: (j['iz'] as num).toDouble(),
    j: (j['j'] as num).toDouble(),
    youngModulus: (j['e'] as num).toDouble(),
    shearModulus: (j['g'] as num).toDouble(),
    unitWeight: (j['gamma'] as num?)?.toDouble() ?? 25,
    profile: j['profile'] as String?,
    b: (j['b'] as num?)?.toDouble(),
    h: (j['h'] as num?)?.toDouble(),
  );
}

/// Beam element between two nodes. Local x runs from n1 to n2; local z
/// lies in the vertical plane through the member, pointing up (for a
/// vertical member local z is global X); [roll] rotates y and z about x
/// (degrees).
class Element3D {
  final int n1;
  final int n2;
  final int section;
  final double roll;
  const Element3D(this.n1, this.n2, this.section, {this.roll = 0});

  Map<String, dynamic> toJson() => {
    'n1': n1,
    'n2': n2,
    's': section,
    'roll': roll,
  };
  factory Element3D.fromJson(Map<String, dynamic> j) => Element3D(
    j['n1'] as int,
    j['n2'] as int,
    j['s'] as int,
    roll: (j['roll'] as num?)?.toDouble() ?? 0,
  );
}

class NodalLoad3D {
  final int node;
  final double fx, fy, fz, mx, my, mz;
  const NodalLoad3D(
    this.node, {
    this.fx = 0,
    this.fy = 0,
    this.fz = 0,
    this.mx = 0,
    this.my = 0,
    this.mz = 0,
  });

  List<double> get vector => [fx, fy, fz, mx, my, mz];

  Map<String, dynamic> toJson() => {'n': node, 'v': vector};
  factory NodalLoad3D.fromJson(Map<String, dynamic> j) {
    final v = (j['v'] as List).map((e) => (e as num).toDouble()).toList();
    return NodalLoad3D(
      j['n'] as int,
      fx: v[0],
      fy: v[1],
      fz: v[2],
      mx: v[3],
      my: v[4],
      mz: v[5],
    );
  }
}

/// Uniform load over a whole member, kN/m, in global axes (gravity is
/// qz < 0) or in the member's local axes.
class MemberLoad3D {
  final int element;
  final double qx, qy, qz;
  final bool local;
  const MemberLoad3D(
    this.element, {
    this.qx = 0,
    this.qy = 0,
    this.qz = 0,
    this.local = false,
  });

  Map<String, dynamic> toJson() => {
    'e': element,
    'q': [qx, qy, qz],
    'local': local,
  };
  factory MemberLoad3D.fromJson(Map<String, dynamic> j) {
    final q = (j['q'] as List).map((e) => (e as num).toDouble()).toList();
    return MemberLoad3D(
      j['e'] as int,
      qx: q[0],
      qy: q[1],
      qz: q[2],
      local: j['local'] as bool? ?? false,
    );
  }
}

class LoadCase3D {
  final String name;
  final LoadType type;
  final bool selfWeight;
  final List<NodalLoad3D> nodal;
  final List<MemberLoad3D> member;

  const LoadCase3D({
    required this.name,
    this.type = LoadType.permanent,
    this.selfWeight = false,
    this.nodal = const [],
    this.member = const [],
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.name,
    'sw': selfWeight,
    'nodal': [for (final l in nodal) l.toJson()],
    'member': [for (final l in member) l.toJson()],
  };
  factory LoadCase3D.fromJson(Map<String, dynamic> j) => LoadCase3D(
    name: j['name'] as String,
    type: LoadType.values.byName(j['type'] as String? ?? 'permanent'),
    selfWeight: j['sw'] as bool? ?? false,
    nodal: [
      for (final l in (j['nodal'] as List? ?? const []))
        NodalLoad3D.fromJson(Map<String, dynamic>.from(l as Map)),
    ],
    member: [
      for (final l in (j['member'] as List? ?? const []))
        MemberLoad3D.fromJson(Map<String, dynamic>.from(l as Map)),
    ],
  );
}

class Model3D {
  final List<Node3D> nodes;
  final Map<int, Support3D> supports;
  final List<Section3D> sections;
  final List<Element3D> elements;
  final List<LoadCase3D> cases;

  const Model3D({
    required this.nodes,
    required this.supports,
    required this.sections,
    required this.elements,
    this.cases = const [],
  });

  Map<String, dynamic> toJson() => {
    'version': 1,
    'nodes': [for (final n in nodes) n.toJson()],
    'supports': {
      for (final e in supports.entries) '${e.key}': e.value.toJson(),
    },
    'sections': [for (final s in sections) s.toJson()],
    'elements': [for (final e in elements) e.toJson()],
    'cases': [for (final c in cases) c.toJson()],
  };

  factory Model3D.fromJson(Map<String, dynamic> j) => Model3D(
    nodes: [
      for (final n in j['nodes'] as List)
        Node3D.fromJson(Map<String, dynamic>.from(n as Map)),
    ],
    supports: {
      for (final e in Map<String, dynamic>.from(j['supports'] as Map).entries)
        int.parse(e.key): Support3D.fromJson(
          Map<String, dynamic>.from(e.value as Map),
        ),
    },
    sections: [
      for (final s in j['sections'] as List)
        Section3D.fromJson(Map<String, dynamic>.from(s as Map)),
    ],
    elements: [
      for (final e in j['elements'] as List)
        Element3D.fromJson(Map<String, dynamic>.from(e as Map)),
    ],
    cases: [
      for (final c in (j['cases'] as List? ?? const []))
        LoadCase3D.fromJson(Map<String, dynamic>.from(c as Map)),
    ],
  );
}
