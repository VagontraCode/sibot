// Renders every main screen at phone and tablet sizes, in light and dark
// themes. Fails on layout overflows or exceptions.
//
// Set SIBOT_SHOTS=<dir> to also save PNG screenshots for visual review:
//   SIBOT_SHOTS=build/shots flutter test test/screens_smoke_test.dart
//
// SIBOT_ONLY=<screen key> renders a single screen; SIBOT_DEBUG=1 leaves
// layout errors uncaught so the full report (widget and file) is printed.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sibot/config/router.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/calculations/beams/presentation/beams_provider.dart';
import 'package:sibot/features/calculations/columns/presentation/columns_provider.dart';
import 'package:sibot/features/calculations/foundations/presentation/pile_cap_provider.dart';
import 'package:sibot/features/tools/septic_page.dart';
import 'package:sibot/features/calculations/geotech/presentation/slope_provider.dart';
import 'package:sibot/features/calculations/loads/presentation/seismic_provider.dart';
import 'package:sibot/features/calculations/loads/presentation/wind_snow_provider.dart';
import 'package:sibot/features/calculations/masonry/presentation/masonry_wall_provider.dart';
import 'package:sibot/features/calculations/steel/presentation/steel_member_provider.dart';
import 'package:sibot/features/calculations/timber/presentation/timber_member_provider.dart';
import 'package:sibot/features/calculations/timber/presentation/timber_connection_provider.dart';
import 'package:sibot/features/calculations/beams/presentation/continuous_beam_provider.dart';
import 'package:sibot/features/calculations/beams/presentation/beam_section_provider.dart';
import 'package:sibot/features/frame3d/model_link.dart';
import 'package:sibot/features/frame3d/frame3d_tables.dart';
import 'package:sibot/features/calculations/footings/presentation/footings_provider.dart';
import 'package:sibot/features/calculations/retaining_walls/presentation/retaining_wall_provider.dart';
import 'package:sibot/features/calculations/slabs/presentation/slabs_provider.dart';
import 'package:sibot/features/tools/tools_providers.dart';
import 'package:sibot/features/frame/frame_canvas.dart';
import 'package:sibot/features/frame/frame_providers.dart';
import 'package:sibot/features/frame/frame_repository.dart';
import 'package:sibot/features/frame3d/frame3d_data.dart';
import 'package:sibot/features/frame3d/frame3d_editor.dart';
import 'package:sibot/features/frame3d/frame3d_view.dart';
import 'package:sibot/features/plate/plate_provider.dart';
import 'package:sibot/features/frame/section_library.dart';
import 'package:sibot/main.dart';
import 'package:sibot_engine/sibot_engine.dart';
import 'package:sibot/ui/ui.dart';

final _shotsDir = Platform.environment['SIBOT_SHOTS'];
final _rootKey = GlobalKey();

Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(rootBundle.load(f));
    }
    await loader.load();
  }

  await family('Inter', [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
  ]);
  await family('JetBrainsMono', [
    'assets/fonts/JetBrainsMono-Regular.ttf',
    'assets/fonts/JetBrainsMono-Medium.ttf',
    'assets/fonts/JetBrainsMono-SemiBold.ttf',
  ]);

  // Material icons ship with the Flutter SDK.
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final icons = File(
      '$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
    );
    if (icons.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
      await loader.load();
    }
  }
}

Future<void> _seed() async {
  final now = DateTime(2026, 10, 20, 9);
  final projects = HiveService.getBox(HiveService.projectsBox);
  final calcs = HiveService.getBox(HiveService.calculationsBox);
  await FrameRepository.save(
    FrameModelRecord(
      id: 'FM_1',
      projectId: 'PRJ_1',
      name: 'Two-bay frame',
      updatedAt: now,
      model: portalFrame(
        bays: 2,
        bayWidth: 5,
        storeys: 2,
        storeyHeight: 3,
        column: concreteRectangle(300, 300),
        beam: concreteRectangle(300, 500),
        g: 20,
        q: 10,
        wind: 15,
      ),
    ),
  );
  await Frame3DRepository.save(
    Frame3DRecord(
      id: 'F3_1',
      projectId: 'PRJ_1',
      name: 'Office R+3',
      updatedAt: now,
      params: BuildingParams(
        spansX: const [5, 5, 5],
        spansY: const [4.5, 4.5],
        storeyHeights: const [3.5, 3, 3, 3],
        column: Section3D.rectangle(350, 350),
        beam: Section3D.rectangle(250, 500),
      ),
    ),
  );
  // Free 3D models: one drawn with releases, a spring support and
  // general loads, one still empty.
  await Frame3DRepository.save(
    Frame3DRecord.free(
      id: 'F3_FREE',
      projectId: 'PRJ_1',
      name: 'Canopy',
      model: Model3D(
        nodes: const [
          Node3D(0, 0, 0),
          Node3D(0, 0, 3),
          Node3D(5, 0, 3),
          Node3D(5, 0, 0),
          Node3D(5, 4, 3),
          Node3D(5, 4, 0),
        ],
        supports: {
          0: Support3D.fixed,
          3: Support3D.fixed,
          5: Support3D.of(
            [true, true, false, true, true, true],
            [0, 0, 20000, 0, 0, 0],
          ),
        },
        sections: [Section3D.rectangle(300, 300), Section3D.steel('IPE 300')],
        elements: const [
          Element3D(0, 1, 0),
          Element3D(3, 2, 0),
          Element3D(1, 2, 1, releases: Element3D.pinnedEnds),
          Element3D(2, 4, 1),
          Element3D(5, 4, 0),
          Element3D(0, 2, 1, releases: Element3D.pinnedEnds),
        ],
        cases: const [
          LoadCase3D(
            name: 'G',
            selfWeight: true,
            member: [
              MemberLoad3D(2, qz: -8, start: 1, end: 4, end2: [0, 0, -12]),
            ],
            point: [PointLoad3D(3, 2, fz: -25)],
          ),
          LoadCase3D(
            name: 'Q',
            type: LoadType.imposed,
            member: [MemberLoad3D(3, qz: -5)],
          ),
        ],
      ),
    ),
  );
  await Frame3DRepository.save(
    Frame3DRecord.free(
      id: 'F3_EMPTY',
      projectId: 'PRJ_1',
      name: 'Empty',
      model: Model3D.empty(),
    ),
  );
  await projects.put(
    'PRJ_1',
    Project(
      id: 'PRJ_1',
      name: 'Résidence Les Palmiers',
      description: 'R+3 reinforced concrete residential building, 12 flats.',
      createdAt: now,
      updatedAt: now,
      location: 'Port-au-Prince',
      engineer: 'G. Tong',
      status: 'active',
      metadata: {},
    ),
  );
  await projects.put(
    'PRJ_2',
    Project(
      id: 'PRJ_2',
      name: 'Warehouse extension',
      description: '',
      createdAt: now,
      updatedAt: now.subtract(const Duration(days: 3)),
      location: 'Douala',
      engineer: 'G. Tong',
      status: 'completed',
      metadata: {},
    ),
  );
  await calcs.put(
    'CALC_1',
    BeamCalculation(
      id: 'CALC_1',
      projectId: 'PRJ_1',
      name: 'Beam B1',
      span: 6,
      load: 25,
      width: 250,
      depth: 500,
      concrete: 25,
      steel: 500,
      createdAt: now,
      isValid: true,
      metadata: {},
    ),
  );
}

final _calculations = <String, Future<void> Function(ProviderContainer)>{
  'frame_editor_member': (c) async => c
      .read(frameEditorProvider('FM_1').notifier)
      .select(const ElementSelection(1)),
  'beam': (c) => (c.read(
    beamStateProvider('PRJ_1').notifier,
  )..setAll({'span': 6, 'b': 300, 'h': 600, 'g': 20, 'q': 15})).calculate(),
  'column': (c) =>
      (c.read(columnStateProvider('PRJ_1').notifier)..setAll({
            'b': 400,
            'h': 400,
            'l0': 3,
            'nEd': 1500,
            'm0Ed': 120,
            'm0EdB': 80,
          }))
          .calculate(),
  'column_circular': (c) =>
      (c.read(columnStateProvider('PRJ_1').notifier)
            ..setOption('shape', 'circle')
            ..setAll({'b': 400, 'l0': 3, 'nEd': 1500, 'm0Ed': 60, 'm0EdB': 0}))
          .calculate(),
  'steel_member': (c) =>
      (c.read(steelMemberStateProvider('PRJ_1').notifier)
            ..setSeries('HEB')
            ..setOption('shape', 'linear')
            ..setAll({
              'length': 4,
              'nEd': 600,
              'myEd': 60,
              'vEd': 40,
              'psi': 0,
            }))
          .calculate(),
  'timber_member': (c) =>
      (c.read(timberMemberStateProvider('PRJ_1').notifier)..setAll({
            'b': 75,
            'h': 200,
            'length': 4,
            'myEd': 5,
            'vEd': 6,
            'gk': 1,
            'qk': 1.5,
            'bearingLength': 60,
            'notchDepth': 150,
            'notchX': 50,
          }))
          .calculate(),
  'timber_connection': (c) =>
      (c.read(timberConnectionStateProvider('PRJ_1').notifier)..setAll({
            'd': 12,
            't1': 45,
            't2': 45,
            'fEd': 15,
            'perRow': 4,
            'a1': 84,
          }))
          .calculate(),
  'beam_section': (c) =>
      (c.read(beamSectionStateProvider('PRJ_1').notifier)
            ..setAll({'b': 300, 'h': 500, 'mSag': 140, 'mHog': 90, 'vEd': 120}))
          .calculate(),
  'continuous_beam': (c) =>
      (c.read(continuousBeamStateProvider('PRJ_1').notifier)..setAll({
            'span1': 5,
            'span2': 6,
            'span3': 5,
            'b': 300,
            'h': 500,
            'g': 15,
            'q': 10,
          }))
          .calculate(),
  'masonry_wall': (c) =>
      (c.read(masonryWallStateProvider('PRJ_1').notifier)..setAll({
            't': 200,
            'height': 2.7,
            'nEd': 300,
            'eTop': 20,
            'otherLeaf': 100,
            'lateralLoad': 0.8,
            'concentratedLoad': 100,
            'bearingLength': 200,
            'bearingWidth': 150,
            'edgeDistance': 400,
          }))
          .calculate(),
  'wind_snow': (c) =>
      (c.read(windSnowStateProvider('PRJ_1').notifier)
            ..setOption('roof', 'duopitch')
            ..setOption('windRegion', '3')
            ..setOption('snowRegion', 'C1')
            ..setAll({
              'vb': 26,
              'h': 8,
              'b': 20,
              'd': 12,
              'altitude': 400,
              'co': 1.1,
              'alpha1': 35,
              'alpha2': 20,
            }))
          .calculate(),
  'seismic': (c) =>
      (c.read(seismicStateProvider('PRJ_1').notifier)
            ..setZone('4')
            ..setOption('ground', 'c')
            ..setAll({'storeys': 4, 'mass': 300}))
          .calculate(),
  'seismic_ps92': (c) =>
      (c.read(seismicStateProvider('PRJ_1').notifier)
            ..setOption('regulation', 'ps92')
            ..setOption('ps92Zone', 'ii')
            ..setAll({'storeys': 4, 'mass': 300, 'le': 20, 'xe': 8}))
          .calculate(),
  'slope_janbu': (c) =>
      (c.read(slopeStateProvider('PRJ_1').notifier)
            ..setOption('method', 'janbu')
            ..setAll({
              'height': 6,
              'angle': 70,
              'cohesion': 25,
              'phi': 20,
              'waterLevel': 1,
              'l1Top': 1.5,
              'l1C': 5,
              'l1Phi': 15,
            }))
          .calculate(),
  'slope': (c) =>
      (c.read(slopeStateProvider('PRJ_1').notifier)..setAll({
            'height': 8,
            'angle': 33.7,
            'cohesion': 10,
            'phi': 28,
            'surcharge': 10,
          }))
          .calculate(),
  'pile_cap': (c) =>
      (c.read(pileCapStateProvider('PRJ_1').notifier)..setAll({
            'nEd': 2500,
            'spacing': 1.5,
            'pileDiameter': 500,
            'column': 450,
            'columnB': 600,
            'h': 700,
            'mx': 150,
            'my': 300,
            'pileCapacity': 900,
          }))
          .calculate(),
  'septic': (c) => (c.read(
    septicStateProvider('PRJ_1').notifier,
  )..setAll({'users': 12, 'rooms': 6})).calculate(),
  'plate': (c) =>
      (c.read(plateStateProvider('PRJ_1').notifier)
            ..setOption('columns', '')
            ..setAll({'lx': 6, 'ly': 5, 't': 200}))
          .calculate(),
  'plate_raft': (c) =>
      (c.read(plateStateProvider('PRJ_1').notifier)
            ..setMode('raft')
            ..setOption('points', '1,1,600 9,1,600 9,7,600 1,7,600')
            ..setAll({'lx': 10, 'ly': 8, 't': 500}))
          .calculate(),
  'slab': (c) =>
      (c.read(slabStateProvider('PRJ_1').notifier)
            ..setOption('type', 'twoWay')
            ..setOption('support', 'continuous')
            ..setOption('punchType', 'edge')
            ..setAll({
              'lx': 4,
              'ly': 5,
              'h': 200,
              'g': 1.5,
              'q': 2.5,
              'punchLoad': 250,
            }))
          .calculate(),
  'footing': (c) => (c.read(
    footingStateProvider('PRJ_1').notifier,
  )..setAll({'a': 300, 'b': 300, 'g': 400, 'q': 150, 'qAdm': 200})).calculate(),
  'footing_combined': (c) =>
      (c.read(footingStateProvider('PRJ_1').notifier)
            ..setOption('type', 'combined')
            ..setOption('bearing', 'soil')
            ..setOption('optimise', 'yes')
            ..setAll({
              'a1': 300,
              'b1': 300,
              'a2': 400,
              'b2': 400,
              'spacing': 3.5,
              'g1': 300,
              'q1': 100,
              'g2': 600,
              'q2': 250,
            }))
          .calculate(),
  'retaining_wall': (c) {
    final n = c.read(retainingWallStateProvider('PRJ_1').notifier)
      ..setAll({'stemHeight': 3, 'qAdm': 200})
      ..presize();
    return n.calculate();
  },
  'bearing': (c) => (c.read(
    bearingStateProvider('PRJ_1').notifier,
  )..setAll({'b': 2, 'l': 2, 'g': 600, 'q': 200})).calculate(),
  'sections': (c) =>
      (c.read(sectionStateProvider('PRJ_1').notifier)
            ..setOption('shape', 'i')
            ..setAll({'b': 150, 'h': 300, 'tf': 10.7, 'tw': 7.1}))
          .calculate(),
  'quantities': (c) =>
      (c.read(quantitiesStateProvider('PRJ_1').notifier)..setAll({
            'length': 5,
            'width': 0.3,
            'height': 0.6,
            'barDia': 12,
            'barCount': 10,
            'barLength': 6,
          }))
          .calculate(),
};

void main() {
  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('sibot_test_');
    Hive.init(dir.path);
    await HiveService.init();
    await _seed();
    await _loadFonts();
  });

  const sizes = {'phone': Size(390, 844), 'tablet': Size(1194, 834)};

  final screens = {
    'dashboard': '/dashboard',
    'projects': '/projects',
    'project': '/projects/PRJ_1',
    'beam': '/projects/PRJ_1/beam',
    'column': '/projects/PRJ_1/column',
    'column_circular': '/projects/PRJ_1/column',
    'slab': '/projects/PRJ_1/slab',
    'plate': '/projects/PRJ_1/plate',
    'plate_raft': '/projects/PRJ_1/plate',
    'pile_cap': '/projects/PRJ_1/pile-cap',
    'septic': '/projects/PRJ_1/septic',
    'slope': '/projects/PRJ_1/slope',
    'seismic': '/projects/PRJ_1/seismic',
    'wind_snow': '/projects/PRJ_1/wind-snow',
    'masonry_wall': '/projects/PRJ_1/masonry-wall',
    'timber_member': '/projects/PRJ_1/timber-member',
    'timber_connection': '/projects/PRJ_1/timber-connection',
    'continuous_beam': '/projects/PRJ_1/continuous-beam',
    'beam_section': '/projects/PRJ_1/beam-section',
    'seismic_ps92': '/projects/PRJ_1/seismic',
    'slope_janbu': '/projects/PRJ_1/slope',
    'steel_member': '/projects/PRJ_1/steel-member',
    'footing': '/projects/PRJ_1/footing',
    'footing_combined': '/projects/PRJ_1/footing',
    'bearing': '/projects/PRJ_1/bearing',
    'sections': '/projects/PRJ_1/sections',
    'quantities': '/projects/PRJ_1/quantities',
    'frame_list': '/projects/PRJ_1/frame2d',
    'frame_editor': '/projects/PRJ_1/frame2d/FM_1',
    'frame_editor_member': '/projects/PRJ_1/frame2d/FM_1',
    'frame_results': '/projects/PRJ_1/frame2d/FM_1',
    'frame3d_list': '/projects/PRJ_1/frame3d',
    'frame3d_static': '/projects/PRJ_1/frame3d/F3_1',
    'frame3d_modes': '/projects/PRJ_1/frame3d/F3_1',
    'frame3d_edit': '/projects/PRJ_1/frame3d/F3_1',
    'frame3d_seismic': '/projects/PRJ_1/frame3d/F3_1',
    'frame3d_combos': '/projects/PRJ_1/frame3d/F3_1',
    'frame3d_design': '/projects/PRJ_1/frame3d/F3_1',
    'frame3d_free': '/projects/PRJ_1/frame3d/F3_FREE',
    'frame3d_free_multi': '/projects/PRJ_1/frame3d/F3_FREE',
    'frame3d_empty_draw': '/projects/PRJ_1/frame3d/F3_EMPTY',
    'frame3d_new': '/projects/PRJ_1/frame3d',
    'retaining_wall': '/projects/PRJ_1/retaining-wall',
    'field': '/field',
    'punch_list': '/field/punch-list/PRJ_1',
    'reports': '/reports',
    'library': '/reference',
    'settings': '/dashboard/settings',
  };

  final only = Platform.environment['SIBOT_ONLY'];
  if (only != null) screens.removeWhere((k, _) => k != only);
  for (final size in sizes.entries) {
    for (final lang in ['en', 'fr']) {
      for (final dark in [false, true]) {
        final theme = dark ? 'dark' : 'light';
        testWidgets('${size.key} $theme $lang renders all screens', (
          tester,
        ) async {
          await tester.runAsync(() => SettingsService.setLanguage(lang));
          // SIBOT_TALL=1 renders very tall pages to review full results.
          final tall = Platform.environment['SIBOT_TALL'] == '1';
          tester.view.physicalSize =
              Size(size.value.width, size.value.height * (tall ? 4 : 1)) * 2;
          tester.view.devicePixelRatio = 2;
          tester.platformDispatcher.platformBrightnessTestValue = dark
              ? Brightness.dark
              : Brightness.light;
          addTearDown(tester.view.reset);
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );

          await tester.pumpWidget(
            RepaintBoundary(
              key: _rootKey,
              child: const ProviderScope(child: SibotApp()),
            ),
          );

          for (final s in screens.entries) {
            appRouter.go(s.value);
            final live3d =
                s.key.startsWith('frame3d_') &&
                s.key != 'frame3d_list' &&
                s.key != 'frame3d_new';
            if (live3d) {
              // The analysis runs in an isolate behind a progress bar.
              await tester.pump(const Duration(milliseconds: 500));
            } else {
              await tester.pumpAndSettle();
            }

            // Frame results: switch to the Results tab and let the isolate
            // finish outside the fake clock.
            if (s.key == 'frame_results') {
              await tester.tap(find.byIcon(Icons.insights_rounded).first);
              await tester.pump();
              await tester.runAsync(
                () => Future<void>.delayed(const Duration(seconds: 2)),
              );
              await tester.pumpAndSettle();
              expect(find.byType(FrameCanvas), findsOneWidget);
            }

            // 3D model: let the isolate analysis finish; open the modes tab.
            if (live3d) {
              for (var i = 0; i < 40; i++) {
                await tester.runAsync(
                  () => Future<void>.delayed(const Duration(milliseconds: 250)),
                );
                await tester.pump();
                if (find.byType(LinearProgressIndicator).evaluate().isEmpty) {
                  break;
                }
              }
              // The scrolling panel beside or under the 3D view.
              Finder panelScroll() =>
                  find.byKey(const ValueKey('frame3d-panel'));

              // Brings the results under the list into view.
              Future<void> scrollPanel() async {
                for (var k = 0; k < 4; k++) {
                  await tester.drag(panelScroll(), const Offset(0, -300));
                  await tester.pump();
                }
              }

              // Scrolls the panel down until [f] is built.
              Future<void> scrollTo(Finder f) async {
                for (var k = 0; k < 15 && f.evaluate().isEmpty; k++) {
                  await tester.drag(panelScroll(), const Offset(0, -200));
                  await tester.pump();
                }
              }

              // Waits until no analysis is running.
              Future<void> settle() async {
                for (var i = 0; i < 80; i++) {
                  await tester.runAsync(
                    () =>
                        Future<void>.delayed(const Duration(milliseconds: 250)),
                  );
                  await tester.pump();
                  if (find.byType(LinearProgressIndicator).evaluate().isEmpty) {
                    break;
                  }
                }
              }

              // The same model may be shown again: start at the top.
              if (panelScroll().evaluate().isNotEmpty) {
                for (var k = 0; k < 6; k++) {
                  await tester.drag(panelScroll(), const Offset(0, 400));
                  await tester.pump();
                }
              }
              // A few frames (pumpAndSettle would wait for the progress bars).
              Future<void> frames() async {
                for (var k = 0; k < 10; k++) {
                  await tester.pump(const Duration(milliseconds: 100));
                }
              }

              // Analyses tab for the screens that run something.
              Future<void> analysesTab() async {
                final tab = find.byType(ChoiceChip).at(3);
                await tester.ensureVisible(tab);
                await tester.pump();
                await tester.tap(tab);
                await tester.pump();
              }

              if (s.key == 'frame3d_static') {
                // Let the analysis status settle, then bring the button up.
                await frames();
                final tables = find.byIcon(Icons.table_chart_outlined);
                await scrollTo(tables);
                await tester.ensureVisible(tables);
                await tester.pump();
                await tester.tap(tables);
                await frames();
                expect(find.byType(Frame3DTablesPage), findsOneWidget);
                expect(tester.takeException(), isNull, reason: s.key);
                Navigator.of(
                  tester.element(find.byType(Frame3DTablesPage)),
                ).pop();
                await frames();
              }
              if (s.key == 'frame3d_modes') {
                await analysesTab();
                // The default list: static, modal, buckling; run the modes.
                final run = find.byIcon(Icons.play_arrow_rounded).first;
                await tester.ensureVisible(run);
                await tester.pump();
                await tester.tap(run);
                await tester.pump();
                await settle();
                await scrollPanel();
                expect(find.byType(CircleAvatar), findsWidgets, reason: s.key);
              }
              if (s.key == 'frame3d_combos') {
                final tab = find.byType(ChoiceChip).at(2);
                await tester.ensureVisible(tab);
                await tester.pump();
                await tester.tap(tab);
                await tester.pump();
                final add = find.byIcon(Icons.add_rounded).first;
                await tester.ensureVisible(add);
                await tester.tap(add);
                await tester.pumpAndSettle();
                // Name and the first factor, then save.
                await tester.enterText(find.byType(TextField).first, 'C perso');
                await tester.enterText(find.byType(TextField).at(1), '1.2');
                await tester.tap(find.byType(FilledButton).last);
                // Let the sheet close (fake clock), then the analysis.
                for (var k = 0; k < 10; k++) {
                  await tester.pump(const Duration(milliseconds: 100));
                }
                await settle();
                expect(find.byType(BottomSheet), findsNothing, reason: s.key);
                await scrollPanel();
                expect(find.text('C perso'), findsWidgets, reason: s.key);
              }
              if (s.key == 'frame3d_edit') {
                final edit = find.byType(ChoiceChip).at(1);
                await tester.ensureVisible(edit);
                await tester.pump();
                await tester.tap(edit);
                await tester.pump();
                expect(find.byType(Frame3DEditPanel), findsOneWidget);
              }
              if (s.key == 'frame3d_free_multi') {
                final edit = find.byType(ChoiceChip).at(1);
                await tester.ensureVisible(edit);
                await tester.pump();
                await tester.tap(edit);
                await tester.pump();
                await tester.tap(find.byIcon(Icons.select_all_rounded));
                await tester.pump();
                // Camera presets first, then the quick selections.
                final all = find.byType(ActionChip).at(4);
                await tester.ensureVisible(all);
                await tester.pump();
                await tester.tap(all);
                await tester.pump();
                await scrollPanel();
                expect(find.byIcon(Icons.copy_all_rounded), findsOneWidget);
              }
              if (s.key == 'frame3d_empty_draw') {
                // An empty model opens on the Edit tab.
                expect(find.byType(Frame3DEditPanel), findsOneWidget);
                await tester.tap(find.byIcon(Icons.draw_outlined));
                await tester.pump();
                final view = tester.getRect(find.byType(Frame3DView));
                await tester.tapAt(view.center);
                await tester.pump();
                await tester.tapAt(view.center + const Offset(40, 0));
                await tester.pump();
                await tester.runAsync(
                  () => Future<void>.delayed(const Duration(milliseconds: 50)),
                );
                await tester.pump();
                final drawn = tester.widget<Frame3DView>(
                  find.byType(Frame3DView),
                );
                expect(drawn.model.nodes, hasLength(2), reason: s.key);
                expect(drawn.model.elements, hasLength(1), reason: s.key);
                // Undo both taps: the next configuration starts empty again.
                for (var k = 0; k < 2; k++) {
                  await tester.tap(find.byIcon(Icons.undo_rounded));
                  await tester.pump();
                }
                expect(
                  tester
                      .widget<Frame3DView>(find.byType(Frame3DView))
                      .model
                      .nodes,
                  isEmpty,
                );
              }
              if (s.key == 'frame3d_design') {
                final tab = find.byType(ChoiceChip).at(4);
                await tester.ensureVisible(tab);
                await tester.pump();
                await tester.tap(tab);
                await tester.pump();
                await tester.tap(find.byIcon(Icons.auto_awesome_rounded));
                await frames();
                final all = find.byIcon(Icons.fact_check_outlined);
                await scrollTo(all);
                await tester.ensureVisible(all);
                await tester.pump();
                await tester.tap(all);
                await tester.pump();
                await settle();
                final view = tester.widget<Frame3DView>(
                  find.byType(Frame3DView),
                );
                expect(view.memberValues, isNotNull, reason: s.key);
                expect(
                  view.memberValues!.whereType<double>(),
                  isNotEmpty,
                  reason: s.key,
                );
                await scrollPanel();
                // A result row, then "Design in the calculator".
                final row = find.byWidgetPredicate(
                  (w) => w is ListTile && w.dense == true && w.trailing is Text,
                );
                await scrollTo(row);
                await tester.ensureVisible(row.first);
                await tester.pump();
                await tester.tap(row.first);
                await frames();
                await tester.tap(find.byIcon(Icons.open_in_new_rounded));
                await frames();
                expect(
                  find.byType(ModelLinkBanner),
                  findsOneWidget,
                  reason: s.key,
                );
                expect(tester.takeException(), isNull, reason: s.key);
                // Back to the model.
                appRouter.pop();
                await frames();
              }
              if (s.key == 'frame3d_seismic') {
                await analysesTab();
                // Add a spectrum analysis with its default settings, run it.
                final add = find.byIcon(Icons.add_rounded);
                await tester.ensureVisible(add);
                await tester.pump();
                await tester.tap(add);
                await frames();
                await tester.tap(find.byIcon(Icons.waves_outlined).last);
                await frames();
                await tester.tap(find.byType(FilledButton).last);
                await frames();
                final run = find.byIcon(Icons.play_arrow_rounded).last;
                await tester.ensureVisible(run);
                await tester.pump();
                await tester.tap(run);
                await tester.pump();
                await settle();
                await scrollPanel();
                expect(find.textContaining('kN'), findsWidgets, reason: s.key);
              }
              await tester.pump(const Duration(milliseconds: 400));
              expect(find.byType(Frame3DView), findsOneWidget);
            }

            if (s.key == 'frame3d_new') {
              await tester.tap(find.byType(FloatingActionButton));
              await tester.pumpAndSettle();
              expect(find.byType(ListTile), findsAtLeastNWidgets(3));
              expect(tester.takeException(), isNull, reason: s.key);
              await tester.tapAt(const Offset(4, 4));
              await tester.pumpAndSettle();
            }

            // Run a calculation so the results view is rendered too.
            final calculate = _calculations[s.key];
            if (calculate != null) {
              final container = ProviderScope.containerOf(
                tester.element(find.byType(Scaffold).last),
              );
              await tester.runAsync(() => calculate(container));
              await tester.pumpAndSettle();
              expect(
                find.byType(ResultsPlaceholder),
                findsNothing,
                reason: s.key,
              );
            }
            if (Platform.environment['SIBOT_DEBUG'] == null) {
              expect(tester.takeException(), isNull, reason: s.key);
            }

            if (_shotsDir != null) {
              final boundary =
                  tester.renderObject(find.byKey(_rootKey))
                      as RenderRepaintBoundary;
              await tester.runAsync(() async {
                final image = await boundary.toImage(pixelRatio: 2);
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final out = File(
                  '$_shotsDir/${size.key}_${theme}_${lang}_${s.key}.png',
                );
                out.parent.createSync(recursive: true);
                out.writeAsBytesSync(bytes!.buffer.asUint8List());
              });
            }
          }
        });
      }
    }
  }
}
