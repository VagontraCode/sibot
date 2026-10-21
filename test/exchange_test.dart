import 'package:flutter_test/flutter_test.dart';
import 'package:sibot/features/exchange/exchange.dart';
import 'package:sibot/features/frame/frame_repository.dart';
import 'package:sibot/features/frame3d/frame3d_data.dart';
import 'package:sibot_engine/sibot_engine.dart';

void main() {
  final params = BuildingParams(
    spansX: const [5, 5],
    spansY: const [4],
    storeyHeights: const [3],
    column: Section3D.rectangle(300, 300),
    beam: Section3D.rectangle(250, 500),
  );

  test('3D models round-trip through .sibot, with their edits', () {
    final base = Frame3DRecord(
      id: 'A',
      projectId: 'P',
      name: 'Office',
      updatedAt: DateTime(2026),
      params: params,
    );
    final edited = base.withModel(
      base.model.setNodalLoad(0, const NodalLoad3D(5, fx: 12)),
    );
    final f = decodeSibot(encodeFrame3d(edited));
    expect(f, isA<Sibot3D>());
    f as Sibot3D;
    expect(f.name, 'Office');
    expect(f.params.spansX, [5, 5]);
    expect(f.custom!.nodalLoadOf(0, 5).fx, 12);
  });

  test('2D models round-trip through .sibot', () {
    final m = portalFrame(
      bays: 1,
      bayWidth: 6,
      storeys: 1,
      storeyHeight: 3,
      column: FrameSection.rectangle(300, 300),
      beam: FrameSection.rectangle(300, 500),
      g: 10,
    );
    final f = decodeSibot(
      encodeFrame2d(
        FrameModelRecord(
          id: 'B',
          projectId: 'P',
          name: 'Portal',
          updatedAt: DateTime(2026),
          model: m,
        ),
      ),
    );
    expect(f, isA<Sibot2D>());
    expect((f as Sibot2D).model.elements, hasLength(m.elements.length));
  });

  test('other files are rejected', () {
    expect(() => decodeSibot('not json'), throwsFormatException);
    expect(() => decodeSibot('{"format": "other"}'), throwsFormatException);
    expect(
      () =>
          decodeSibot('{"format": "sibot", "version": 99, "kind": "frame2d"}'),
      throwsFormatException,
    );
  });

  test('imported DXF models get placeholder parameters', () {
    final model = buildingFrame(params);
    final p = importedParams(model);
    expect(p.spansX.single, 10);
    expect(p.storeyHeights.single, 3);
  });
}
