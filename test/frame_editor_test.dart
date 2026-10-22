// 2D editor edits: partial / trapezoidal and point loads, node dragging
// and member arrays.
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/frame/frame_providers.dart';
import 'package:sibot/features/frame/frame_repository.dart';
import 'package:sibot_engine/sibot_engine.dart';

void main() {
  late ProviderContainer c;
  FrameEditorNotifier n() => c.read(frameEditorProvider('FM_T').notifier);
  Model2D model() => c.read(frameEditorProvider('FM_T')).model;

  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('sibot_editor_');
    Hive.init(dir.path);
    await HiveService.init();
  });

  setUp(() async {
    // Portal frame: columns 0-1 and 3-2, beam 1-2 (6 m span, 4 m high).
    await FrameRepository.save(
      FrameModelRecord(
        id: 'FM_T',
        projectId: 'P',
        name: 'Test',
        updatedAt: DateTime(2026),
        model: Model2D(
          nodes: const [Node2D(0, 0), Node2D(0, 4), Node2D(6, 4), Node2D(6, 0)],
          supports: const {0: Support.fixed, 3: Support.fixed},
          sections: [FrameSection.rectangle(300, 500)],
          elements: const [Element2D(0, 1), Element2D(1, 2), Element2D(3, 2)],
          cases: const [
            LoadCase(name: 'G', distributed: [DistributedLoad(1, -10)]),
          ],
        ),
      ),
    );
    c = ProviderContainer();
  });

  tearDown(() => c.dispose());

  test('trapezoidal partial load replaces the uniform one', () {
    n().setMemberLoad(1, -5, LoadAxis.globalY, w2: -15, start: 1, end: 5);
    final d = model().cases.first.distributed.single;
    expect((d.w1, d.w2, d.start, d.end), (-5.0, -15.0, 1.0, 5.0));
    // The analysis accepts it: total vertical reaction = 10 × 4 = 40 kN.
    final r = FrameAnalysis(model()).solveCase(0);
    final ry = r.reactions.values.fold<double>(0, (s, v) => s + v[1]);
    expect(ry, closeTo(40, 1e-6));
  });

  test('point load on a member; 0 removes it', () {
    n().setMemberPointLoad(1, 2, -30, LoadAxis.globalY);
    expect(model().cases.first.point.single.p, -30);
    n().setMemberPointLoad(1, 2, 0, LoadAxis.globalY);
    expect(model().cases.first.point, isEmpty);
  });

  test('dragging snaps the node to the grid and can be undone', () {
    n().dragNode(2, 6.23, 4.6);
    expect(model().nodes[2].x, closeTo(6.0, 1e-9));
    expect(model().nodes[2].y, closeTo(4.5, 1e-9));
    n().undo();
    expect(model().nodes[2].y, 4);
  });

  test('array copies a column with its loads and shares nodes', () {
    n().setMemberLoad(0, 2, LoadAxis.globalX);
    // Column 0-1 copied twice at 6 m: the first copy reuses nodes 3 and 2
    // of the existing column 3-2 (duplicate skipped), the second is new.
    n().arrayElement(0, 6, 0, 2);
    final m = model();
    expect(m.elements, hasLength(4));
    expect(m.nodes, hasLength(6));
    final last = m.elements.last;
    expect((m.nodes[last.n1].x, m.nodes[last.n2].y), (12.0, 4.0));
    final wind = m.cases.first.distributed.where(
      (l) => l.axis == LoadAxis.globalX,
    );
    expect(wind.map((l) => l.element), [0, 3]);
  });
}
