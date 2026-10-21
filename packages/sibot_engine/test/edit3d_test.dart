import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  final base = buildingFrame(
    BuildingParams(
      spansX: const [5],
      spansY: const [4],
      storeyHeights: const [3],
      column: Section3D.rectangle(300, 300),
      beam: Section3D.rectangle(250, 500),
    ),
  );

  test('adding an existing node returns its index', () {
    final (m, i) = base.addNode(const Node3D(5, 4, 3));
    expect(identical(m, base), isTrue);
    expect(i, base.nodeAt(5, 4, 3));
    final (m2, j) = base.addNode(const Node3D(10, 0, 3));
    expect(j, base.nodes.length);
    expect(m2.nodes, hasLength(base.nodes.length + 1));
  });

  test('a duplicate member is not added', () {
    final e = base.elements.first;
    final (m, i) = base.addElement(e.n2, e.n1, 0);
    expect(identical(m, base), isTrue);
    expect(i, 0);
  });

  test('deleting a node removes its members and re-indexes the rest', () {
    // Node 0 is a fixed base with one column above it.
    final m = base.deleteNode(0);
    expect(m.nodes, hasLength(base.nodes.length - 1));
    expect(m.elements, hasLength(base.elements.length - 1));
    expect(m.supports.keys, isNot(contains(base.nodes.length - 1)));
    for (final el in m.elements) {
      expect(el.n1, lessThan(m.nodes.length));
      expect(el.n2, lessThan(m.nodes.length));
    }
    // Member loads now refer to valid members only.
    for (final c in m.cases) {
      for (final q in c.member) {
        expect(q.element, lessThan(m.elements.length));
      }
    }
    // Still analysable.
    expect(Frame3DAnalysis(m).solveCase(0).reactions, isNotEmpty);
  });

  test('loads are replaced, and removed when zero', () {
    var m = base.setNodalLoad(0, const NodalLoad3D(5, fx: 10));
    m = m.setNodalLoad(0, const NodalLoad3D(5, fx: 20));
    expect(m.cases[0].nodal.where((p) => p.node == 5), hasLength(1));
    expect(m.nodalLoadOf(0, 5).fx, 20);
    m = m.setNodalLoad(0, const NodalLoad3D(5));
    expect(m.cases[0].nodal.where((p) => p.node == 5), isEmpty);

    final beam = base.elements.indexWhere((e) => e.section == 1);
    m = base.setMemberLoad(1, MemberLoad3D(beam, qz: -12));
    expect(m.memberLoadOf(1, beam).qz, -12);
  });

  test('floors by level and seismic mass factors', () {
    final floors = base.floorsByLevel();
    expect(floors, hasLength(1));
    expect(floors.first, hasLength(4));
    expect(base.seismicMassFactors(), {0: 1.0, 1: 0.3});
  });

  test('copyWith keeps diaphragms', () {
    final m = base.addSection(Section3D.steel('IPE 300'));
    expect(m.sections, hasLength(3));
    expect(m.diaphragms, base.diaphragms);
  });
}
