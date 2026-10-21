import '../fem/model.dart' show LoadType;
import 'model3d.dart';

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
  }) => Model3D(
    nodes: nodes ?? this.nodes,
    supports: supports ?? this.supports,
    sections: sections ?? this.sections,
    elements: elements ?? this.elements,
    cases: cases ?? this.cases,
    diaphragms: diaphragms ?? this.diaphragms,
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

  /// Adds a node unless one already exists at that point; returns the
  /// model and the node index.
  (Model3D, int) addNode(Node3D n) {
    final existing = nodeAt(n.x, n.y, n.z);
    if (existing >= 0) return (this, existing);
    return (copyWith(nodes: [...nodes, n]), nodes.length);
  }

  Model3D moveNode(int i, Node3D n) => copyWith(nodes: [...nodes]..[i] = n);

  /// Sets (or removes, with null or a free support) the support of a node.
  Model3D setSupport(int node, Support3D? s) {
    final map = {...supports};
    if (s == null || !s.dofs.any((d) => d)) {
      map.remove(node);
    } else {
      map[node] = s;
    }
    return copyWith(supports: map);
  }

  /// Adds a member between two distinct nodes unless it already exists.
  (Model3D, int) addElement(int n1, int n2, int section, {double roll = 0}) {
    if (n1 == n2) return (this, -1);
    for (var e = 0; e < elements.length; e++) {
      final el = elements[e];
      if ((el.n1 == n1 && el.n2 == n2) || (el.n1 == n2 && el.n2 == n1)) {
        return (this, e);
      }
    }
    return (
      copyWith(
        elements: [
          ...elements,
          Element3D(n1, n2, section, roll: roll),
        ],
      ),
      elements.length,
    );
  }

  Model3D updateElement(int e, {int? section, double? roll}) {
    final el = elements[e];
    return copyWith(
      elements: [...elements]
        ..[e] = Element3D(
          el.n1,
          el.n2,
          section ?? el.section,
          roll: roll ?? el.roll,
        ),
    );
  }

  /// Removes members; member loads are dropped or re-indexed.
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
      cases: [
        for (final c in cases)
          LoadCase3D(
            name: c.name,
            type: c.type,
            selfWeight: c.selfWeight,
            nodal: c.nodal,
            member: [
              for (final q in c.member)
                if (map.containsKey(q.element))
                  MemberLoad3D(
                    map[q.element]!,
                    qx: q.qx,
                    qy: q.qy,
                    qz: q.qz,
                    local: q.local,
                  ),
            ],
          ),
      ],
    );
  }

  /// Removes a node with its members, support, loads and diaphragm
  /// membership; higher indices shift down.
  Model3D deleteNode(int node) {
    final m = deleteElements({
      for (var e = 0; e < elements.length; e++)
        if (elements[e].n1 == node || elements[e].n2 == node) e,
    });
    int re(int i) => i > node ? i - 1 : i;
    return Model3D(
      nodes: [...m.nodes]..removeAt(node),
      supports: {
        for (final e in m.supports.entries)
          if (e.key != node) re(e.key): e.value,
      },
      sections: m.sections,
      elements: [
        for (final el in m.elements)
          Element3D(re(el.n1), re(el.n2), el.section, roll: el.roll),
      ],
      cases: [
        for (final c in m.cases)
          LoadCase3D(
            name: c.name,
            type: c.type,
            selfWeight: c.selfWeight,
            member: c.member,
            nodal: [
              for (final p in c.nodal)
                if (p.node != node)
                  NodalLoad3D(
                    re(p.node),
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
              if (i != node) re(i),
          ],
      ],
    );
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
    final nodal = [
      for (final p in c.nodal)
        if (p.node != load.node) p,
      if (load.vector.any((v) => v != 0)) load,
    ];
    return _withCase(
      caseIndex,
      LoadCase3D(
        name: c.name,
        type: c.type,
        selfWeight: c.selfWeight,
        nodal: nodal,
        member: c.member,
      ),
    );
  }

  /// Replaces the global uniform load of a member in a case (zero
  /// removes it); local loads on that member are kept.
  Model3D setMemberLoad(int caseIndex, MemberLoad3D load) {
    final c = cases[caseIndex];
    final member = [
      for (final q in c.member)
        if (q.element != load.element || q.local) q,
      if (load.qx != 0 || load.qy != 0 || load.qz != 0) load,
    ];
    return _withCase(
      caseIndex,
      LoadCase3D(
        name: c.name,
        type: c.type,
        selfWeight: c.selfWeight,
        nodal: c.nodal,
        member: member,
      ),
    );
  }

  /// Total global uniform load of a member in a case.
  MemberLoad3D memberLoadOf(int caseIndex, int element) {
    var qx = 0.0, qy = 0.0, qz = 0.0;
    for (final q in cases[caseIndex].member) {
      if (q.element == element && !q.local) {
        qx += q.qx;
        qy += q.qy;
        qz += q.qz;
      }
    }
    return MemberLoad3D(element, qx: qx, qy: qy, qz: qz);
  }

  NodalLoad3D nodalLoadOf(int caseIndex, int node) {
    for (final p in cases[caseIndex].nodal) {
      if (p.node == node) return p;
    }
    return NodalLoad3D(node);
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
