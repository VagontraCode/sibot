import 'package:sibot_engine/sibot_engine.dart';
import 'package:test/test.dart';

void main() {
  final building = buildingFrame(
    BuildingParams(
      spansX: const [5, 5],
      spansY: const [4],
      storeyHeights: const [3, 3],
      column: Section3D.rectangle(300, 300),
      beam: Section3D.rectangle(250, 500),
    ),
  );

  test('a 3D model survives a DXF round trip', () {
    final text = model3dToDxf(building);
    expect(text, contains('ENTITIES'));
    final lines = parseDxf(text);
    expect(lines, hasLength(building.elements.length));
    final m = model3dFromLines(lines, section: Section3D.rectangle(300, 300));
    expect(m.nodes, hasLength(building.nodes.length));
    expect(m.elements, hasLength(building.elements.length));
    // One section per layer: the column and beam names.
    expect(m.sections.map((s) => s.name).toSet(), {'300_300', '250_500'});
    // Fixed supports at the base.
    expect(m.supports, hasLength(6));
    expect(Frame3DAnalysis(m).solveCase(0).reactions, isNotEmpty);
  });

  test('LWPOLYLINE (closed) and R12 POLYLINE are read', () {
    const text = '''0
SECTION
2
ENTITIES
0
LWPOLYLINE
8
FRAME
90
3
70
1
10
0
20
0
10
4
20
0
10
4
20
3
0
POLYLINE
8
P
70
0
0
VERTEX
10
0
20
0
30
0
0
VERTEX
10
0
20
0
30
3
0
SEQEND
0
ENDSEC
0
EOF
''';
    final lines = parseDxf(text);
    // Triangle (3 segments, closed) + one polyline segment.
    expect(lines, hasLength(4));
    expect(lines.first.layer, 'FRAME');
    expect(lines.last.z2, 3);
  });

  test('duplicate and zero-length lines are dropped; nodes merge', () {
    const lines = [
      DxfLine(0, 0, 0, 0, 0, 3),
      DxfLine(0, 0, 3, 0, 0, 0), // duplicate, reversed
      DxfLine(0, 0, 3.0004, 5, 0, 3), // starts within 1 mm of a node
      DxfLine(5, 0, 3, 5, 0, 3), // zero length
      DxfLine(5, 0, 0, 5, 0, 3),
    ];
    final m = model3dFromLines(lines, section: Section3D.rectangle(300, 300));
    expect(m.nodes, hasLength(4));
    expect(m.elements, hasLength(3));
  });

  test('2D export writes one line per member in the X–Y plane', () {
    final m = portalFrame(
      bays: 1,
      bayWidth: 6,
      storeys: 1,
      storeyHeight: 3,
      column: FrameSection.rectangle(300, 300),
      beam: FrameSection.rectangle(300, 500),
    );
    final lines = parseDxf(model2dToDxf(m));
    expect(lines, hasLength(m.elements.length));
    expect(lines.every((l) => l.z1 == 0 && l.z2 == 0), isTrue);
  });

  test('2D round trip: portal frame to DXF and back', () {
    final m = portalFrame(
      bays: 2,
      bayWidth: 5,
      storeys: 2,
      storeyHeight: 3,
      column: FrameSection.rectangle(300, 300),
      beam: FrameSection.rectangle(300, 500),
    );
    final back = model2dFromLines(
      parseDxf(model2dToDxf(m)),
      section: FrameSection.rectangle(300, 300),
    );
    expect(back.nodes, hasLength(m.nodes.length));
    expect(back.elements, hasLength(m.elements.length));
    expect(back.supports, hasLength(3));
    expect(FrameAnalysis(back).solveCase(0).reactions, isNotEmpty);
  });

  test('a units factor scales the drawing (millimetres to metres)', () {
    final lines = parseDxf(model3dToDxf(building), unit: 0.001);
    expect(lines.first.length, closeTo(3e-3, 1e-12));
  });

  test('garbage is rejected', () {
    expect(() => parseDxf('hello\nworld\n'), throwsA(isA<InputError>()));
  });
}
