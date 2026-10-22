import 'dart:math' as math;

import '../fem/model.dart' show Combination, LoadType;
import '../steel_profiles.dart';

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

/// Restrained degrees of freedom (translations then rotations) and
/// elastic springs on the free ones: kN/m for translations, kN·m/rad for
/// rotations (global axes).
class Support3D {
  final bool ux, uy, uz, rx, ry, rz;
  final List<double> springs;
  const Support3D({
    this.ux = false,
    this.uy = false,
    this.uz = false,
    this.rx = false,
    this.ry = false,
    this.rz = false,
    this.springs = const [0, 0, 0, 0, 0, 0],
  });

  /// A support from six restraint flags and optional springs.
  factory Support3D.of(List<bool> d, [List<double>? k]) => Support3D(
    ux: d[0],
    uy: d[1],
    uz: d[2],
    rx: d[3],
    ry: d[4],
    rz: d[5],
    springs: k ?? const [0, 0, 0, 0, 0, 0],
  );

  /// Nothing restrained and no spring.
  bool get isFree => !dofs.any((d) => d) && !springs.any((k) => k > 0);

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

  Map<String, dynamic> toJson() => {
    'd': dofs,
    if (springs.any((k) => k != 0)) 'k': springs,
  };
  factory Support3D.fromJson(Map<String, dynamic> j) => Support3D.of(
    (j['d'] as List).cast<bool>(),
    (j['k'] as List?)?.map((e) => (e as num).toDouble()).toList(),
  );
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
    final p = steelProfiles[name]!;
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

  /// Released end actions, as local degree-of-freedom indices of the
  /// 12-vector: 3, 4, 5 (Mx, My, Mz at the start) and 9, 10, 11 (at the
  /// end). Empty = rigid connections.
  final List<int> releases;

  const Element3D(
    this.n1,
    this.n2,
    this.section, {
    this.roll = 0,
    this.releases = const [],
  });

  /// Local DOF indices that may be released.
  static const releasable = [3, 4, 5, 9, 10, 11];

  /// Both bending moments released at both ends (a pin-ended member).
  static const pinnedEnds = [4, 5, 10, 11];

  Element3D copyWith({
    int? n1,
    int? n2,
    int? section,
    double? roll,
    List<int>? releases,
  }) => Element3D(
    n1 ?? this.n1,
    n2 ?? this.n2,
    section ?? this.section,
    roll: roll ?? this.roll,
    releases: releases ?? this.releases,
  );

  Map<String, dynamic> toJson() => {
    'n1': n1,
    'n2': n2,
    's': section,
    'roll': roll,
    if (releases.isNotEmpty) 'rel': releases,
  };
  factory Element3D.fromJson(Map<String, dynamic> j) => Element3D(
    j['n1'] as int,
    j['n2'] as int,
    j['s'] as int,
    roll: (j['roll'] as num?)?.toDouble() ?? 0,
    releases: (j['rel'] as List?)?.cast<int>() ?? const [],
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

/// Distributed load on a member, kN/m, in global axes (gravity is
/// qz < 0) or in the member's local axes: (qx, qy, qz) at [start] varying
/// linearly to [end2] at [end] (m from the start node; null = member
/// end). Uniform over the whole member by default.
class MemberLoad3D {
  final int element;
  final double qx, qy, qz;
  final bool local;
  final double start;
  final double? end;

  /// Intensities at [end] (null = same as at [start]).
  final List<double>? end2;

  const MemberLoad3D(
    this.element, {
    this.qx = 0,
    this.qy = 0,
    this.qz = 0,
    this.local = false,
    this.start = 0,
    this.end,
    this.end2,
  });

  List<double> get q1 => [qx, qy, qz];
  List<double> get q2 => end2 ?? q1;

  /// Uniform over the whole member.
  bool get uniform => start == 0 && end == null && end2 == null;

  /// Total and moment about the start node of a component of the load
  /// over a member of length [l]: (∫q, ∫q·x).
  (double, double) resultant(int component, double l) {
    final a = start.clamp(0.0, l), b = (end ?? l).clamp(0.0, l);
    if (b <= a) return (0, 0);
    final w1 = q1[component], w2 = q2[component];
    final len = b - a;
    final total = (w1 + w2) / 2 * len;
    // Centroid of a trapezoid from a.
    final xc = w1 + w2 == 0 ? len / 2 : len * (w1 + 2 * w2) / (3 * (w1 + w2));
    return (total, total * (a + xc));
  }

  MemberLoad3D copyWith({int? element}) => MemberLoad3D(
    element ?? this.element,
    qx: qx,
    qy: qy,
    qz: qz,
    local: local,
    start: start,
    end: end,
    end2: end2,
  );

  Map<String, dynamic> toJson() => {
    'e': element,
    'q': [qx, qy, qz],
    'local': local,
    if (start != 0) 'a': start,
    'b': ?end,
    'q2': ?end2,
  };
  factory MemberLoad3D.fromJson(Map<String, dynamic> j) {
    List<double>? list(Object? v) =>
        (v as List?)?.map((e) => (e as num).toDouble()).toList();
    final q = list(j['q'])!;
    return MemberLoad3D(
      j['e'] as int,
      qx: q[0],
      qy: q[1],
      qz: q[2],
      local: j['local'] as bool? ?? false,
      start: (j['a'] as num?)?.toDouble() ?? 0,
      end: (j['b'] as num?)?.toDouble(),
      end2: list(j['q2']),
    );
  }
}

/// Concentrated force on a member at [a] (m from the start node), kN, in
/// global or local axes.
class PointLoad3D {
  final int element;
  final double a;
  final double fx, fy, fz;
  final bool local;
  const PointLoad3D(
    this.element,
    this.a, {
    this.fx = 0,
    this.fy = 0,
    this.fz = 0,
    this.local = false,
  });

  List<double> get vector => [fx, fy, fz];

  PointLoad3D copyWith({int? element}) => PointLoad3D(
    element ?? this.element,
    a,
    fx: fx,
    fy: fy,
    fz: fz,
    local: local,
  );

  Map<String, dynamic> toJson() => {
    'e': element,
    'a': a,
    'f': vector,
    'local': local,
  };
  factory PointLoad3D.fromJson(Map<String, dynamic> j) {
    final f = (j['f'] as List).map((e) => (e as num).toDouble()).toList();
    return PointLoad3D(
      j['e'] as int,
      (j['a'] as num).toDouble(),
      fx: f[0],
      fy: f[1],
      fz: f[2],
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
  final List<PointLoad3D> point;

  const LoadCase3D({
    required this.name,
    this.type = LoadType.permanent,
    this.selfWeight = false,
    this.nodal = const [],
    this.member = const [],
    this.point = const [],
  });

  LoadCase3D copyWith({
    String? name,
    LoadType? type,
    bool? selfWeight,
    List<NodalLoad3D>? nodal,
    List<MemberLoad3D>? member,
    List<PointLoad3D>? point,
  }) => LoadCase3D(
    name: name ?? this.name,
    type: type ?? this.type,
    selfWeight: selfWeight ?? this.selfWeight,
    nodal: nodal ?? this.nodal,
    member: member ?? this.member,
    point: point ?? this.point,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.name,
    'sw': selfWeight,
    'nodal': [for (final l in nodal) l.toJson()],
    'member': [for (final l in member) l.toJson()],
    if (point.isNotEmpty) 'point': [for (final l in point) l.toJson()],
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
    point: [
      for (final l in (j['point'] as List? ?? const []))
        PointLoad3D.fromJson(Map<String, dynamic>.from(l as Map)),
    ],
  );
}

class Model3D {
  final List<Node3D> nodes;
  final Map<int, Support3D> supports;
  final List<Section3D> sections;
  final List<Element3D> elements;
  final List<LoadCase3D> cases;

  /// Rigid floor diaphragms: groups of nodes moving together in plan
  /// (ux, uy, rz).
  final List<List<int>> diaphragms;

  /// Plane frame in the global X–Z plane: every node is held out of the
  /// plane (uy, rx, rz restrained).
  final bool plane;

  /// The user's own load combinations; null = generated from the load
  /// cases (EN 1990 or BAEL) by [combinationsOf].
  final List<Combination>? combinations;

  const Model3D({
    required this.nodes,
    required this.supports,
    required this.sections,
    required this.elements,
    this.cases = const [],
    this.diaphragms = const [],
    this.plane = false,
    this.combinations,
  });

  /// An empty model with a default concrete section and permanent and
  /// imposed load cases.
  factory Model3D.empty({bool plane = false}) => Model3D(
    nodes: const [],
    supports: const {},
    sections: [Section3D.rectangle(300, 500)],
    elements: const [],
    cases: const [
      LoadCase3D(name: 'G', selfWeight: true),
      LoadCase3D(name: 'Q', type: LoadType.imposed),
    ],
    plane: plane,
  );

  Map<String, dynamic> toJson() => {
    'version': 1,
    'nodes': [for (final n in nodes) n.toJson()],
    'supports': {
      for (final e in supports.entries) '${e.key}': e.value.toJson(),
    },
    'sections': [for (final s in sections) s.toJson()],
    'elements': [for (final e in elements) e.toJson()],
    'cases': [for (final c in cases) c.toJson()],
    'diaphragms': diaphragms,
    if (plane) 'plane': true,
    if (combinations != null)
      'combinations': [for (final c in combinations!) c.toJson()],
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
    diaphragms: [
      for (final g in (j['diaphragms'] as List? ?? const []))
        (g as List).cast<int>(),
    ],
    plane: j['plane'] as bool? ?? false,
    combinations: (j['combinations'] as List?)
        ?.map((c) => Combination.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList(),
  );
}
