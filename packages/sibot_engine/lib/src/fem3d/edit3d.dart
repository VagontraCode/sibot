import 'dart:math' as math;

import '../fem/model.dart';
import '../steel_profiles.dart';
import 'groups3d.dart';
import 'model3d.dart';

/// What a member is, from its direction.
enum MemberKind { column, beam, brace }

/// Plane of a mirror: X = c, Y = c or Z = c.
enum MirrorPlane { x, y, z }

/// Result of a copy: the model and the indices of the new items.
typedef CopyResult = ({Model3D model, Set<int> nodes, Set<int> elements});

/// Pure editing operations on a [Model3D]: each returns a new model,
/// keeping supports, loads and diaphragms consistent with the indices.
extension Model3DEdit on Model3D {
  Model3D copyWith({
    List<Node3D>? nodes,
    Map<int, Support3D>? supports,
    List<Section3D>? sections,
    List<Element3D>? elements,
    List<LoadCase3D>? cases,
    List<List<int>>? diaphragms,
    bool? plane,
    List<Combination>? combinations,
    bool autoCombinations = false,
    List<DesignGroup>? groups,
  }) => Model3D(
    nodes: nodes ?? this.nodes,
    supports: supports ?? this.supports,
    sections: sections ?? this.sections,
    elements: elements ?? this.elements,
    cases: cases ?? this.cases,
    diaphragms: diaphragms ?? this.diaphragms,
    plane: plane ?? this.plane,
    combinations: autoCombinations ? null : (combinations ?? this.combinations),
    groups: groups ?? this.groups,
  );

  /// Index of a node at (x, y, z) within [tol], or −1.
  int nodeAt(double x, double y, double z, {double tol = 1e-6}) {
    for (var i = 0; i < nodes.length; i++) {
      final n = nodes[i];
      if ((n.x - x).abs() <= tol &&
          (n.y - y).abs() <= tol &&
          (n.z - z).abs() <= tol) {
        return i;
      }
    }
    return -1;
  }

  /// Plane models keep every node at Y = 0.
  Node3D _inPlane(Node3D n) => plane && n.y != 0 ? Node3D(n.x, 0, n.z) : n;

  /// Adds a node unless one already exists at that point; returns the
  /// model and the node index.
  (Model3D, int) addNode(Node3D n) {
    n = _inPlane(n);
    final existing = nodeAt(n.x, n.y, n.z);
    if (existing >= 0) return (this, existing);
    return (copyWith(nodes: [...nodes, n]), nodes.length);
  }

  Model3D moveNode(int i, Node3D n) =>
      copyWith(nodes: [...nodes]..[i] = _inPlane(n));

  /// Moves nodes by (dx, dy, dz).
  Model3D moveNodes(Set<int> which, double dx, double dy, double dz) =>
      copyWith(
        nodes: [
          for (var i = 0; i < nodes.length; i++)
            which.contains(i)
                ? _inPlane(
                    Node3D(nodes[i].x + dx, nodes[i].y + dy, nodes[i].z + dz),
                  )
                : nodes[i],
        ],
      );

  /// Sets (or removes, with null or a free support) the support of a node.
  Model3D setSupport(int node, Support3D? s) {
    final map = {...supports};
    if (s == null || s.isFree) {
      map.remove(node);
    } else {
      map[node] = s;
    }
    return copyWith(supports: map);
  }

  /// Same support on several nodes.
  Model3D setSupports(Set<int> which, Support3D? s) {
    var m = this;
    for (final n in which) {
      m = m.setSupport(n, s);
    }
    return m;
  }

  /// Adds a member between two distinct nodes unless it already exists.
  (Model3D, int) addElement(
    int n1,
    int n2,
    int section, {
    double roll = 0,
    List<int> releases = const [],
  }) {
    if (n1 == n2) return (this, -1);
    final existing = elementBetween(n1, n2);
    if (existing >= 0) return (this, existing);
    return (
      copyWith(
        elements: [
          ...elements,
          Element3D(n1, n2, section, roll: roll, releases: releases),
        ],
      ),
      elements.length,
    );
  }

  /// Index of the member joining two nodes (either way), or −1.
  int elementBetween(int n1, int n2) {
    for (var e = 0; e < elements.length; e++) {
      final el = elements[e];
      if ((el.n1 == n1 && el.n2 == n2) || (el.n1 == n2 && el.n2 == n1)) {
        return e;
      }
    }
    return -1;
  }

  Model3D updateElement(
    int e, {
    int? section,
    double? roll,
    List<int>? releases,
  }) => updateElements({e}, section: section, roll: roll, releases: releases);

  /// Same section, roll or releases on several members.
  Model3D updateElements(
    Set<int> which, {
    int? section,
    double? roll,
    List<int>? releases,
  }) => copyWith(
    elements: [
      for (var e = 0; e < elements.length; e++)
        which.contains(e)
            ? elements[e].copyWith(
                section: section,
                roll: roll,
                releases: releases == null ? null : _validReleases(releases),
              )
            : elements[e],
    ],
  );

  /// Releasable DOFs only, sorted; torsion is kept at one end at least.
  static List<int> _validReleases(List<int> r) {
    final s = {...r}..retainAll(Element3D.releasable);
    if (s.contains(3) && s.contains(9)) s.remove(9);
    return s.toList()..sort();
  }

  /// Removes members; member and point loads are dropped or re-indexed.
  Model3D deleteElements(Set<int> remove) {
    if (remove.isEmpty) return this;
    final map = <int, int>{};
    final kept = <Element3D>[];
    for (var e = 0; e < elements.length; e++) {
      if (remove.contains(e)) continue;
      map[e] = kept.length;
      kept.add(elements[e]);
    }
    return copyWith(
      elements: kept,
      groups: [
        for (final g in groups)
          g.copyWith(
            members: [
              for (final e in g.members)
                if (map.containsKey(e)) map[e]!,
            ],
          ),
      ],
      cases: [
        for (final c in cases)
          c.copyWith(
            member: [
              for (final q in c.member)
                if (map.containsKey(q.element))
                  q.copyWith(element: map[q.element]!),
            ],
            point: [
              for (final p in c.point)
                if (map.containsKey(p.element))
                  p.copyWith(element: map[p.element]!),
            ],
          ),
      ],
    );
  }

  /// Removes a node with its members, support, loads and diaphragm
  /// membership; higher indices shift down.
  Model3D deleteNode(int node) => deleteNodes({node});

  /// Removes nodes with their members, supports, loads and diaphragm
  /// membership; the other nodes are renumbered in order.
  Model3D deleteNodes(Set<int> remove) {
    if (remove.isEmpty) return this;
    final m = deleteElements({
      for (var e = 0; e < elements.length; e++)
        if (remove.contains(elements[e].n1) || remove.contains(elements[e].n2))
          e,
    });
    final map = <int, int>{};
    for (var i = 0, k = 0; i < m.nodes.length; i++) {
      if (!remove.contains(i)) map[i] = k++;
    }
    return Model3D(
      nodes: [
        for (var i = 0; i < m.nodes.length; i++)
          if (!remove.contains(i)) m.nodes[i],
      ],
      supports: {
        for (final e in m.supports.entries)
          if (map.containsKey(e.key)) map[e.key]!: e.value,
      },
      sections: m.sections,
      elements: [
        for (final el in m.elements)
          el.copyWith(n1: map[el.n1], n2: map[el.n2]),
      ],
      cases: [
        for (final c in m.cases)
          c.copyWith(
            nodal: [
              for (final p in c.nodal)
                if (map.containsKey(p.node))
                  NodalLoad3D(
                    map[p.node]!,
                    fx: p.fx,
                    fy: p.fy,
                    fz: p.fz,
                    mx: p.mx,
                    my: p.my,
                    mz: p.mz,
                  ),
            ],
          ),
      ],
      diaphragms: [
        for (final g in m.diaphragms)
          [
            for (final i in g)
              if (map.containsKey(i)) map[i]!,
          ],
      ],
      plane: plane,
      combinations: combinations,
      groups: m.groups,
    );
  }

  /// Nodes no member uses.
  Set<int> get unusedNodes {
    final used = {
      for (final e in elements) ...[e.n1, e.n2],
    };
    return {
      for (var i = 0; i < nodes.length; i++)
        if (!used.contains(i)) i,
    };
  }

  Model3D addSection(Section3D s) => copyWith(sections: [...sections, s]);

  Model3D addCase(String name, LoadType type) => copyWith(
    cases: [
      ...cases,
      LoadCase3D(name: name, type: type),
    ],
  );

  Model3D _withCase(int index, LoadCase3D c) =>
      copyWith(cases: [...cases]..[index] = c);

  /// Replaces the nodal load of [node] in a case (zero vector removes it).
  Model3D setNodalLoad(int caseIndex, NodalLoad3D load) {
    final c = cases[caseIndex];
    return _withCase(
      caseIndex,
      c.copyWith(
        nodal: [
          for (final p in c.nodal)
            if (p.node != load.node) p,
          if (load.vector.any((v) => v != 0)) load,
        ],
      ),
    );
  }

  /// Replaces the global distributed load(s) of a member in a case by
  /// [load] (zero intensities remove them); local loads are kept.
  Model3D setMemberLoad(int caseIndex, MemberLoad3D load) {
    final c = cases[caseIndex];
    final nonZero = [...load.q1, ...load.q2].any((v) => v != 0);
    return _withCase(
      caseIndex,
      c.copyWith(
        member: [
          for (final q in c.member)
            if (q.element != load.element || q.local) q,
          if (nonZero) load,
        ],
      ),
    );
  }

  /// Replaces the point load of a member in a case (zero removes it).
  Model3D setPointLoad(int caseIndex, PointLoad3D load) {
    final c = cases[caseIndex];
    return _withCase(
      caseIndex,
      c.copyWith(
        point: [
          for (final p in c.point)
            if (p.element != load.element) p,
          if (load.vector.any((v) => v != 0)) load,
        ],
      ),
    );
  }

  /// The global distributed load of a member in a case: the load itself
  /// when there is one, the sum of the uniform ones otherwise.
  MemberLoad3D memberLoadOf(int caseIndex, int element) {
    final global = [
      for (final q in cases[caseIndex].member)
        if (q.element == element && !q.local) q,
    ];
    if (global.length == 1) return global.single;
    var qx = 0.0, qy = 0.0, qz = 0.0;
    for (final q in global) {
      if (!q.uniform) continue;
      qx += q.qx;
      qy += q.qy;
      qz += q.qz;
    }
    return MemberLoad3D(element, qx: qx, qy: qy, qz: qz);
  }

  PointLoad3D? pointLoadOf(int caseIndex, int element) {
    for (final p in cases[caseIndex].point) {
      if (p.element == element) return p;
    }
    return null;
  }

  NodalLoad3D nodalLoadOf(int caseIndex, int node) {
    for (final p in cases[caseIndex].nodal) {
      if (p.node == node) return p;
    }
    return NodalLoad3D(node);
  }

  // ───────────────────────── selection helpers ─────────────────────────

  double length(int e) {
    final a = nodes[elements[e].n1], b = nodes[elements[e].n2];
    return math.sqrt(
      math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2) + math.pow(b.z - a.z, 2),
    );
  }

  /// Vertical within 5° = column, horizontal within 5° = beam, else brace.
  MemberKind kindOf(int e) {
    final a = nodes[elements[e].n1], b = nodes[elements[e].n2];
    final l = length(e);
    if (l == 0) return MemberKind.brace;
    final s = (b.z - a.z).abs() / l;
    if (s >= math.cos(5 * math.pi / 180)) return MemberKind.column;
    if (s <= math.sin(5 * math.pi / 180)) return MemberKind.beam;
    return MemberKind.brace;
  }

  /// Distinct node levels (Z), ascending.
  List<double> levels({double tol = 1e-3}) {
    final out = <double>[];
    for (final z in [for (final n in nodes) n.z]..sort()) {
      if (out.isEmpty || z - out.last > tol) out.add(z);
    }
    return out;
  }

  Set<int> nodesAtLevel(double z, {double tol = 1e-3}) => {
    for (var i = 0; i < nodes.length; i++)
      if ((nodes[i].z - z).abs() <= tol) i,
  };

  /// Beams lying at level [z] and columns / braces ending at it from below
  /// (the storey under that floor).
  Set<int> elementsAtLevel(double z, {double tol = 1e-3}) => {
    for (var e = 0; e < elements.length; e++)
      if (() {
        final a = nodes[elements[e].n1].z, b = nodes[elements[e].n2].z;
        final top = math.max(a, b);
        return (top - z).abs() <= tol;
      }())
        e,
  };

  Set<int> elementsOfKind(MemberKind k) => {
    for (var e = 0; e < elements.length; e++)
      if (kindOf(e) == k) e,
  };

  /// Nodes of a set of members.
  Set<int> nodesOf(Set<int> elems) => {
    for (final e in elems) ...[elements[e].n1, elements[e].n2],
  };

  // ───────────────────────── copy / array / mirror ─────────────────────────

  /// Copies the members [elems] and the nodes [extraNodes] (with the
  /// members' nodes) [count] times, each shifted by (dx, dy, dz) from the
  /// previous one. Coincident nodes are shared and duplicate members
  /// skipped; supports and loads of the copied items follow when asked.
  CopyResult copyItems({
    Set<int> elems = const {},
    Set<int> extraNodes = const {},
    required double dx,
    required double dy,
    required double dz,
    int count = 1,
    bool withLoads = true,
    bool withSupports = true,
  }) {
    if (plane) dy = 0;
    return _transformCopy(
      elems: elems,
      extraNodes: extraNodes,
      count: count,
      withLoads: withLoads,
      withSupports: withSupports,
      map: (n, k) => Node3D(n.x + k * dx, n.y + k * dy, n.z + k * dz),
    );
  }

  /// Mirrored copy of the members [elems] and nodes [extraNodes] about
  /// the plane X, Y or Z = [c].
  CopyResult mirrorItems({
    Set<int> elems = const {},
    Set<int> extraNodes = const {},
    required MirrorPlane about,
    required double c,
    bool withLoads = true,
    bool withSupports = true,
  }) => _transformCopy(
    elems: elems,
    extraNodes: extraNodes,
    count: 1,
    withLoads: withLoads,
    withSupports: withSupports,
    mirror: about,
    map: (n, _) => switch (about) {
      MirrorPlane.x => Node3D(2 * c - n.x, n.y, n.z),
      MirrorPlane.y => Node3D(n.x, plane ? 0 : 2 * c - n.y, n.z),
      MirrorPlane.z => Node3D(n.x, n.y, 2 * c - n.z),
    },
  );

  CopyResult _transformCopy({
    required Set<int> elems,
    required Set<int> extraNodes,
    required int count,
    required bool withLoads,
    required bool withSupports,
    required Node3D Function(Node3D n, int k) map,
    MirrorPlane? mirror,
  }) {
    final newNodes = [...nodes];
    final newElements = [...elements];
    final newSupports = {...supports};
    final nodal = [
      for (final c in cases) [...c.nodal],
    ];
    final member = [
      for (final c in cases) [...c.member],
    ];
    final point = [
      for (final c in cases) [...c.point],
    ];
    final addedNodes = <int>{}, addedElements = <int>{};
    final groupMembers = [
      for (final g in groups) [...g.members],
    ];
    final srcNodes = {...nodesOf(elems), ...extraNodes};

    int nodeFor(Node3D p) {
      for (var i = 0; i < newNodes.length; i++) {
        final n = newNodes[i];
        if ((n.x - p.x).abs() <= 1e-6 &&
            (n.y - p.y).abs() <= 1e-6 &&
            (n.z - p.z).abs() <= 1e-6) {
          return i;
        }
      }
      newNodes.add(p);
      addedNodes.add(newNodes.length - 1);
      return newNodes.length - 1;
    }

    // A mirrored load points the other way across the plane.
    List<double> flip(List<double> v) {
      if (mirror == null) return v;
      final i = mirror.index;
      return [for (var k = 0; k < 3; k++) k == i ? -v[k] : v[k]];
    }

    for (var k = 1; k <= count; k++) {
      final target = <int, int>{};
      final before = newNodes.length;
      for (final n in srcNodes) {
        final t = nodeFor(_inPlane(map(nodes[n], k)));
        target[n] = t;
        // Supports and nodal loads go to nodes created by this copy only.
        if (t < before) continue;
        if (withSupports && supports[n] != null) newSupports[t] = supports[n]!;
        if (withLoads) {
          for (var c = 0; c < cases.length; c++) {
            for (final p in cases[c].nodal) {
              if (p.node != n) continue;
              final f = flip([p.fx, p.fy, p.fz]);
              nodal[c].add(
                NodalLoad3D(
                  t,
                  fx: f[0],
                  fy: f[1],
                  fz: f[2],
                  mx: p.mx,
                  my: p.my,
                  mz: p.mz,
                ),
              );
            }
          }
        }
      }
      for (final e in elems) {
        final src = elements[e];
        final n1 = target[src.n1]!, n2 = target[src.n2]!;
        if (n1 == n2) continue;
        var exists = false;
        for (final el in newElements) {
          if ((el.n1 == n1 && el.n2 == n2) || (el.n1 == n2 && el.n2 == n1)) {
            exists = true;
            break;
          }
        }
        if (exists) continue;
        newElements.add(src.copyWith(n1: n1, n2: n2));
        final index = newElements.length - 1;
        addedElements.add(index);
        for (var g = 0; g < groups.length; g++) {
          if (groups[g].members.contains(e)) groupMembers[g].add(index);
        }
        if (!withLoads) continue;
        for (var c = 0; c < cases.length; c++) {
          for (final q in cases[c].member) {
            if (q.element != e) continue;
            member[c].add(
              q.local
                  ? q.copyWith(element: index)
                  : MemberLoad3D(
                      index,
                      qx: flip(q.q1)[0],
                      qy: flip(q.q1)[1],
                      qz: flip(q.q1)[2],
                      start: q.start,
                      end: q.end,
                      end2: q.end2 == null ? null : flip(q.end2!),
                    ),
            );
          }
          for (final p in cases[c].point) {
            if (p.element != e) continue;
            final f = p.local ? p.vector : flip(p.vector);
            point[c].add(
              PointLoad3D(
                index,
                p.a,
                fx: f[0],
                fy: f[1],
                fz: f[2],
                local: p.local,
              ),
            );
          }
        }
      }
    }
    return (
      model: copyWith(
        nodes: newNodes,
        elements: newElements,
        supports: newSupports,
        groups: [
          for (var g = 0; g < groups.length; g++)
            groups[g].copyWith(members: groupMembers[g]),
        ],
        cases: [
          for (var c = 0; c < cases.length; c++)
            cases[c].copyWith(
              nodal: nodal[c],
              member: member[c],
              point: point[c],
            ),
        ],
      ),
      nodes: addedNodes,
      elements: addedElements,
    );
  }

  /// Rigid floors grouped by level: nodes sharing the same z (above the
  /// lowest level), at least two per group.
  List<List<int>> floorsByLevel({double tol = 1e-3}) {
    if (nodes.isEmpty) return const [];
    final zMin = nodes.map((n) => n.z).reduce((a, b) => a < b ? a : b);
    final groups = <double, List<int>>{};
    for (var i = 0; i < nodes.length; i++) {
      final z = nodes[i].z;
      if (z - zMin <= tol) continue;
      final key = groups.keys.firstWhere(
        (k) => (k - z).abs() <= tol,
        orElse: () => z,
      );
      groups.putIfAbsent(key, () => []).add(i);
    }
    final levels = groups.keys.toList()..sort();
    return [
      for (final z in levels)
        if (groups[z]!.length >= 2) groups[z]!,
    ];
  }

  /// Seismic mass factors of the load cases: permanent 1, imposed ψ2 0.3,
  /// snow and wind 0 (EN 1998-1 3.2.4, EN 1990 Table A1.1).
  Map<int, double> seismicMassFactors() => {
    for (var i = 0; i < cases.length; i++)
      if (cases[i].type == LoadType.permanent)
        i: 1.0
      else if (cases[i].type == LoadType.imposed)
        i: 0.3,
  };
}

/// A 2D frame as a plane model in the X–Z plane: x → X, y → Z. Hinges
/// and truss members become released bending moments, supports and
/// loads keep their meaning (2D rotations about z are rotations about
/// −Y).
Model3D planeModelFrom2D(Model2D m) {
  Section3D section(FrameSection s) {
    if (s.profile != null && steelProfiles.containsKey(s.profile)) {
      return Section3D.steel(s.profile!);
    }
    if (s.b != null && s.h != null) {
      return Section3D.rectangle(
        s.b!,
        s.h!,
        e: s.youngModulus,
        unitWeight: s.unitWeight,
      );
    }
    // Generic section: out-of-plane properties do not matter in a plane
    // model; keep them positive.
    return Section3D(
      name: s.name,
      area: s.area,
      iy: s.inertia,
      iz: s.inertia,
      j: s.inertia,
      youngModulus: s.youngModulus,
      shearModulus: s.youngModulus / 2.6,
      unitWeight: s.unitWeight,
    );
  }

  List<int> releases(Element2D e) => [
    if (e.releasedStart) ...[4, 5],
    if (e.releasedEnd) ...[10, 11],
  ];

  final elements = [
    for (final e in m.elements)
      Element3D(e.n1, e.n2, e.section, releases: releases(e)),
  ];
  final lengths = [
    for (final e in m.elements)
      math.sqrt(
        math.pow(m.nodes[e.n2].x - m.nodes[e.n1].x, 2) +
            math.pow(m.nodes[e.n2].y - m.nodes[e.n1].y, 2),
      ),
  ];

  // Global (qx, qz) of a 2D load along an axis for element e.
  (double, double) global(int e, LoadAxis axis, double w) {
    final el = m.elements[e];
    final a = m.nodes[el.n1], b = m.nodes[el.n2];
    final l = lengths[e];
    final c = (b.x - a.x) / l, s = (b.y - a.y) / l;
    return switch (axis) {
      LoadAxis.globalX => (w, 0),
      LoadAxis.globalY => (0, w),
      // Perpendicular, to the member's left: (−s, c).
      LoadAxis.localY => (-s * w, c * w),
    };
  }

  return Model3D(
    nodes: [for (final n in m.nodes) Node3D(n.x, 0, n.y)],
    supports: {
      for (final e in m.supports.entries)
        e.key: Support3D.of(
          [e.value.ux, false, e.value.uy, false, e.value.rz, false],
          [e.value.kx, 0, e.value.ky, 0, e.value.kr, 0],
        ),
    },
    sections: [for (final s in m.sections) section(s)],
    elements: elements,
    plane: true,
    cases: [
      for (final c in m.cases)
        LoadCase3D(
          name: c.name,
          type: c.type,
          selfWeight: c.selfWeight,
          nodal: [
            for (final p in c.nodal)
              NodalLoad3D(p.node, fx: p.fx, fz: p.fy, my: -p.mz),
          ],
          member: [
            for (final d in c.distributed)
              () {
                // Projected loads are per horizontal (or vertical) metre:
                // per metre of member they are smaller.
                var f = 1.0;
                if (d.projected) {
                  final el = m.elements[d.element];
                  final a = m.nodes[el.n1], b = m.nodes[el.n2];
                  final l = lengths[d.element];
                  f = switch (d.axis) {
                    LoadAxis.globalY => ((b.x - a.x) / l).abs(),
                    LoadAxis.globalX => ((b.y - a.y) / l).abs(),
                    LoadAxis.localY => 1.0,
                  };
                }
                final (x1, z1) = global(d.element, d.axis, d.w1 * f);
                final (x2, z2) = global(d.element, d.axis, d.w2 * f);
                return MemberLoad3D(
                  d.element,
                  qx: x1,
                  qz: z1,
                  start: d.start,
                  end: d.end,
                  end2: d.w1 == d.w2 ? null : [x2, 0, z2],
                );
              }(),
          ],
          point: [
            for (final p in c.point)
              () {
                final (fx, fz) = global(p.element, p.axis, p.p);
                return PointLoad3D(p.element, p.a, fx: fx, fz: fz);
              }(),
          ],
        ),
    ],
  );
}
