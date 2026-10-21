/// 2D frame model. Units: lengths m, forces kN, moments kN·m,
/// E in MPa (converted internally), A in m², I in m⁴.
library;

class Node2D {
  final double x;
  final double y;
  const Node2D(this.x, this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
  factory Node2D.fromJson(Map<String, dynamic> j) =>
      Node2D((j['x'] as num).toDouble(), (j['y'] as num).toDouble());
}

/// Nodal restraints and optional springs (kN/m, kN·m/rad).
class Support {
  final bool ux;
  final bool uy;
  final bool rz;
  final double kx;
  final double ky;
  final double kr;

  const Support({
    this.ux = false,
    this.uy = false,
    this.rz = false,
    this.kx = 0,
    this.ky = 0,
    this.kr = 0,
  });

  static const fixed = Support(ux: true, uy: true, rz: true);
  static const pinned = Support(ux: true, uy: true);
  static const rollerX = Support(uy: true); // free to slide along x

  bool get isEmpty => !ux && !uy && !rz && kx == 0 && ky == 0 && kr == 0;

  Map<String, dynamic> toJson() => {
    'ux': ux,
    'uy': uy,
    'rz': rz,
    'kx': kx,
    'ky': ky,
    'kr': kr,
  };
  factory Support.fromJson(Map<String, dynamic> j) => Support(
    ux: j['ux'] as bool? ?? false,
    uy: j['uy'] as bool? ?? false,
    rz: j['rz'] as bool? ?? false,
    kx: (j['kx'] as num?)?.toDouble() ?? 0,
    ky: (j['ky'] as num?)?.toDouble() ?? 0,
    kr: (j['kr'] as num?)?.toDouble() ?? 0,
  );
}

/// Cross-section and material of a member.
class FrameSection {
  final String name;

  /// Area (m²), second moment (m⁴), Young's modulus (MPa).
  final double area;
  final double inertia;
  final double youngModulus;

  /// Unit weight of the material (kN/m³) for self-weight.
  final double unitWeight;

  const FrameSection({
    required this.name,
    required this.area,
    required this.inertia,
    required this.youngModulus,
    this.unitWeight = 25,
  });

  /// Rectangular section b × h (mm) in concrete of modulus [e] (MPa).
  factory FrameSection.rectangle(
    double bMm,
    double hMm, {
    double e = 31000,
    double unitWeight = 25,
  }) {
    final b = bMm / 1000, h = hMm / 1000;
    return FrameSection(
      name: '${bMm.round()}×${hMm.round()}',
      area: b * h,
      inertia: b * h * h * h / 12,
      youngModulus: e,
      unitWeight: unitWeight,
    );
  }

  /// E in kN/m².
  double get eKpa => youngModulus * 1000;

  Map<String, dynamic> toJson() => {
    'name': name,
    'area': area,
    'inertia': inertia,
    'e': youngModulus,
    'gamma': unitWeight,
  };
  factory FrameSection.fromJson(Map<String, dynamic> j) => FrameSection(
    name: j['name'] as String? ?? '',
    area: (j['area'] as num).toDouble(),
    inertia: (j['inertia'] as num).toDouble(),
    youngModulus: (j['e'] as num).toDouble(),
    unitWeight: (j['gamma'] as num?)?.toDouble() ?? 25,
  );
}

enum ElementKind {
  /// Bending member (frame / beam).
  beam,

  /// Pin-ended member (both ends released).
  truss,
}

class Element2D {
  final int n1;
  final int n2;
  final int section;
  final ElementKind kind;

  /// Moment releases (hinges) at the start and end.
  final bool hingeStart;
  final bool hingeEnd;

  const Element2D(
    this.n1,
    this.n2, {
    this.section = 0,
    this.kind = ElementKind.beam,
    this.hingeStart = false,
    this.hingeEnd = false,
  });

  bool get releasedStart => hingeStart || kind == ElementKind.truss;
  bool get releasedEnd => hingeEnd || kind == ElementKind.truss;

  Map<String, dynamic> toJson() => {
    'n1': n1,
    'n2': n2,
    'section': section,
    'kind': kind.name,
    'hs': hingeStart,
    'he': hingeEnd,
  };
  factory Element2D.fromJson(Map<String, dynamic> j) => Element2D(
    j['n1'] as int,
    j['n2'] as int,
    section: j['section'] as int? ?? 0,
    kind: ElementKind.values.byName(j['kind'] as String? ?? 'beam'),
    hingeStart: j['hs'] as bool? ?? false,
    hingeEnd: j['he'] as bool? ?? false,
  );
}

/// Direction of a member load.
enum LoadAxis {
  /// Global X (horizontal), positive to the right.
  globalX,

  /// Global Y (vertical), positive upwards. Gravity loads are negative.
  globalY,

  /// Perpendicular to the member (local y), positive to its left.
  localY,
}

class NodalLoad {
  final int node;
  final double fx;
  final double fy;
  final double mz;
  const NodalLoad(this.node, {this.fx = 0, this.fy = 0, this.mz = 0});

  Map<String, dynamic> toJson() => {'node': node, 'fx': fx, 'fy': fy, 'mz': mz};
  factory NodalLoad.fromJson(Map<String, dynamic> j) => NodalLoad(
    j['node'] as int,
    fx: (j['fx'] as num?)?.toDouble() ?? 0,
    fy: (j['fy'] as num?)?.toDouble() ?? 0,
    mz: (j['mz'] as num?)?.toDouble() ?? 0,
  );
}

/// Linearly varying distributed load from [start] to [end] (m from the
/// member start), intensities [w1] → [w2] (kN per m of member). A uniform
/// load over the whole member has start = 0, end = null (= length).
class DistributedLoad {
  final int element;
  final double w1;
  final double w2;
  final LoadAxis axis;
  final double start;
  final double? end;

  /// For global loads: intensity per metre of horizontal (globalY) or
  /// vertical (globalX) projection instead of per metre of member.
  final bool projected;

  const DistributedLoad(
    this.element,
    this.w1, {
    double? w2,
    this.axis = LoadAxis.globalY,
    this.start = 0,
    this.end,
    this.projected = false,
  }) : w2 = w2 ?? w1;

  Map<String, dynamic> toJson() => {
    'element': element,
    'w1': w1,
    'w2': w2,
    'axis': axis.name,
    'start': start,
    'end': end,
    'projected': projected,
  };
  factory DistributedLoad.fromJson(Map<String, dynamic> j) => DistributedLoad(
    j['element'] as int,
    (j['w1'] as num).toDouble(),
    w2: (j['w2'] as num?)?.toDouble(),
    axis: LoadAxis.values.byName(j['axis'] as String? ?? 'globalY'),
    start: (j['start'] as num?)?.toDouble() ?? 0,
    end: (j['end'] as num?)?.toDouble(),
    projected: j['projected'] as bool? ?? false,
  );
}

/// Concentrated force on a member at distance [a] (m) from its start.
class MemberPointLoad {
  final int element;
  final double a;
  final double p;
  final LoadAxis axis;

  const MemberPointLoad(
    this.element,
    this.a,
    this.p, {
    this.axis = LoadAxis.globalY,
  });

  Map<String, dynamic> toJson() => {
    'element': element,
    'a': a,
    'p': p,
    'axis': axis.name,
  };
  factory MemberPointLoad.fromJson(Map<String, dynamic> j) => MemberPointLoad(
    j['element'] as int,
    (j['a'] as num).toDouble(),
    (j['p'] as num).toDouble(),
    axis: LoadAxis.values.byName(j['axis'] as String? ?? 'globalY'),
  );
}

/// Nature of a load case, used to build combinations.
enum LoadType { permanent, imposed, snow, wind }

class LoadCase {
  final String name;
  final LoadType type;
  final bool selfWeight;
  final List<NodalLoad> nodal;
  final List<DistributedLoad> distributed;
  final List<MemberPointLoad> point;

  const LoadCase({
    required this.name,
    this.type = LoadType.permanent,
    this.selfWeight = false,
    this.nodal = const [],
    this.distributed = const [],
    this.point = const [],
  });

  LoadCase copyWith({
    String? name,
    LoadType? type,
    bool? selfWeight,
    List<NodalLoad>? nodal,
    List<DistributedLoad>? distributed,
    List<MemberPointLoad>? point,
  }) => LoadCase(
    name: name ?? this.name,
    type: type ?? this.type,
    selfWeight: selfWeight ?? this.selfWeight,
    nodal: nodal ?? this.nodal,
    distributed: distributed ?? this.distributed,
    point: point ?? this.point,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.name,
    'sw': selfWeight,
    'nodal': [for (final l in nodal) l.toJson()],
    'dist': [for (final l in distributed) l.toJson()],
    'point': [for (final l in point) l.toJson()],
  };
  factory LoadCase.fromJson(Map<String, dynamic> j) => LoadCase(
    name: j['name'] as String,
    type: LoadType.values.byName(j['type'] as String? ?? 'permanent'),
    selfWeight: j['sw'] as bool? ?? false,
    nodal: [
      for (final l in (j['nodal'] as List? ?? const []))
        NodalLoad.fromJson(Map<String, dynamic>.from(l as Map)),
    ],
    distributed: [
      for (final l in (j['dist'] as List? ?? const []))
        DistributedLoad.fromJson(Map<String, dynamic>.from(l as Map)),
    ],
    point: [
      for (final l in (j['point'] as List? ?? const []))
        MemberPointLoad.fromJson(Map<String, dynamic>.from(l as Map)),
    ],
  );
}

enum CombinationKind { uls, slsCharacteristic, slsQuasiPermanent }

class Combination {
  final String name;
  final CombinationKind kind;

  /// Factor per load case index.
  final Map<int, double> factors;

  const Combination(this.name, this.kind, this.factors);

  Map<String, dynamic> toJson() => {
    'name': name,
    'kind': kind.name,
    'factors': {for (final e in factors.entries) '${e.key}': e.value},
  };
  factory Combination.fromJson(Map<String, dynamic> j) => Combination(
    j['name'] as String,
    CombinationKind.values.byName(j['kind'] as String),
    {
      for (final e in Map<String, dynamic>.from(j['factors'] as Map).entries)
        int.parse(e.key): (e.value as num).toDouble(),
    },
  );
}

class Model2D {
  final List<Node2D> nodes;
  final Map<int, Support> supports;
  final List<FrameSection> sections;
  final List<Element2D> elements;
  final List<LoadCase> cases;

  const Model2D({
    required this.nodes,
    required this.supports,
    required this.sections,
    required this.elements,
    required this.cases,
  });

  Model2D copyWith({
    List<Node2D>? nodes,
    Map<int, Support>? supports,
    List<FrameSection>? sections,
    List<Element2D>? elements,
    List<LoadCase>? cases,
  }) => Model2D(
    nodes: nodes ?? this.nodes,
    supports: supports ?? this.supports,
    sections: sections ?? this.sections,
    elements: elements ?? this.elements,
    cases: cases ?? this.cases,
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
  };

  factory Model2D.fromJson(Map<String, dynamic> j) => Model2D(
    nodes: [
      for (final n in j['nodes'] as List)
        Node2D.fromJson(Map<String, dynamic>.from(n as Map)),
    ],
    supports: {
      for (final e in Map<String, dynamic>.from(j['supports'] as Map).entries)
        int.parse(e.key): Support.fromJson(
          Map<String, dynamic>.from(e.value as Map),
        ),
    },
    sections: [
      for (final s in j['sections'] as List)
        FrameSection.fromJson(Map<String, dynamic>.from(s as Map)),
    ],
    elements: [
      for (final e in j['elements'] as List)
        Element2D.fromJson(Map<String, dynamic>.from(e as Map)),
    ],
    cases: [
      for (final c in j['cases'] as List)
        LoadCase.fromJson(Map<String, dynamic>.from(c as Map)),
    ],
  );
}
