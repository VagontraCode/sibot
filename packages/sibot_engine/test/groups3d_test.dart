// Design groups of 3D models: storage, editing, automatic grouping and
// the design of every member.
import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  // Portal: two concrete columns, a concrete beam, a steel brace.
  Model3D portal({List<DesignGroup> groups = const []}) => Model3D(
    nodes: const [
      Node3D(0, 0, 0),
      Node3D(0, 0, 4),
      Node3D(6, 0, 4),
      Node3D(6, 0, 0),
    ],
    supports: const {0: Support3D.fixed, 3: Support3D.fixed},
    sections: [
      Section3D.rectangle(300, 300),
      Section3D.rectangle(300, 600),
      Section3D.steel('HEA 200'),
    ],
    elements: const [
      Element3D(0, 1, 0),
      Element3D(1, 2, 1),
      Element3D(3, 2, 0),
      Element3D(0, 2, 2, releases: Element3D.pinnedEnds),
    ],
    cases: const [
      LoadCase3D(
        name: 'G',
        selfWeight: true,
        member: [MemberLoad3D(1, qz: -30)],
      ),
      LoadCase3D(
        name: 'Q',
        type: LoadType.imposed,
        member: [MemberLoad3D(1, qz: -15)],
      ),
    ],
    groups: groups,
  );

  String label(DesignMaterial m, MemberKind k) => '${m.name} ${k.name}';

  test('automatic groups by material and kind', () {
    final g = autoGroups(portal(), label);
    expect(g.map((x) => x.name), [
      'concrete column',
      'concrete beam',
      'steel brace',
    ]);
    expect(g[0].members, [0, 2]);
    expect(g[0].role, ConcreteRole.column);
    // Members already grouped are left alone.
    final again = autoGroups(portal(groups: g), label, existing: g);
    expect(again, hasLength(3));
  });

  test('groups survive JSON and follow deletions and copies', () {
    final g = autoGroups(portal(), label);
    final m = portal(groups: [g[0].copyWith(fck: 30, l0Factor: 0.7), g[1]]);
    final back = Model3D.fromJson(m.toJson());
    expect(back.groups.first.fck, 30);
    expect(back.groups.first.l0Factor, 0.7);
    // Deleting member 0 shifts the others down.
    final d = back.deleteElements({0});
    expect(d.groups[0].members, [1]);
    expect(d.groups[1].members, [0]);
    // A copied column joins its group.
    final c = back.copyItems(elems: {0}, dx: 0, dy: 5, dz: 0);
    expect(c.model.groups[0].members, [0, 2, 4]);
  });

  test('design of every member: RC columns and beam, steel brace', () {
    final m0 = portal();
    final m = m0.copyWith(groups: autoGroups(m0, label));
    final an = Frame3DAnalysis(m);
    final cases = an.solveAll();
    final uls = [cases[0].scaled(1.35).plus(cases[1].scaled(1.5))];
    final sls = [cases[0].plus(cases[1])];
    final d = designGroups(m, m.groups, uls, sls);
    expect(d.map((x) => x.member), [0, 2, 1, 3]);
    final beam = d.firstWhere((x) => x.member == 1);
    expect(beam.asColumn, isFalse);
    expect(beam.summary, contains('Ø'));
    expect(beam.checks.any((c) => c.kind == CheckKind.deflection), isTrue);
    final col = d.firstWhere((x) => x.member == 0);
    expect(col.asColumn, isTrue);
    final brace = d.firstWhere((x) => x.member == 3);
    expect(brace.material, DesignMaterial.steel);
    expect(brace.summary, startsWith('HEA 200'));
    for (final x in d) {
      expect(x.ratio.isFinite, isTrue, reason: 'member ${x.member}');
      expect(x.governing, isNotNull);
    }
    // Beam deflection check = SLS chord deflection against L/250.
    final defl = beam.checks.firstWhere((c) => c.kind == CheckKind.deflection);
    expect(defl.capacity, closeTo(6000 / 250, 1e-9));
    expect(defl.demand, closeTo(relativeDeflection(sls.first, 1) * 1000, 1e-9));
  });

  test('a section that does not fit the group material is reported', () {
    final m = portal();
    const wrong = DesignGroup(
      id: 'w',
      name: 'w',
      members: [3],
      material: DesignMaterial.concrete,
    );
    final an = Frame3DAnalysis(m);
    final r = an.solveCase(0);
    final d = designGroups(m, const [wrong], [r], [r]).single;
    expect(d.error, isNotNull);
    expect(d.ratio, double.infinity);
    expect(d.ok, isFalse);
  });

  test('timber rectangles are recognised and designed to EC5', () {
    final timber = Section3D.rectangle(100, 200, e: 11000, unitWeight: 4.2);
    expect(sectionMaterial(timber), DesignMaterial.timber);
    final m = Model3D(
      nodes: const [Node3D(0, 0, 3), Node3D(4, 0, 3)],
      supports: {
        0: Support3D.pinned,
        1: Support3D.of([false, true, true, true, false, false]),
      },
      sections: [timber],
      elements: const [Element3D(0, 1, 0)],
      cases: const [
        LoadCase3D(name: 'G', member: [MemberLoad3D(0, qz: -2)]),
      ],
    );
    final r = Frame3DAnalysis(m).solveCase(0);
    final g = autoGroups(m, label);
    final d = designGroups(m, g, [r.scaled(1.35)], [r]).single;
    expect(d.material, DesignMaterial.timber);
    expect(d.error, isNull);
    expect(d.summary, startsWith('C24'));
  });
}
