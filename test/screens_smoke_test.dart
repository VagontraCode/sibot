// Renders every main screen at phone and tablet sizes, in light and dark
// themes. Fails on layout overflows or exceptions.
//
// Set SIBOT_SHOTS=<dir> to also save PNG screenshots for visual review:
//   SIBOT_SHOTS=build/shots flutter test test/screens_smoke_test.dart
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
import 'package:sibot/features/calculations/masonry/presentation/masonry_wall_provider.dart';
import 'package:sibot/features/calculations/steel/presentation/steel_member_provider.dart';
import 'package:sibot/features/calculations/timber/presentation/timber_member_provider.dart';
import 'package:sibot/features/calculations/footings/presentation/footings_provider.dart';
import 'package:sibot/features/calculations/retaining_walls/presentation/retaining_wall_provider.dart';
import 'package:sibot/features/calculations/slabs/presentation/slabs_provider.dart';
import 'package:sibot/features/tools/tools_providers.dart';
import 'package:sibot/features/frame/frame_canvas.dart';
import 'package:sibot/features/frame/frame_repository.dart';
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
          }))
          .calculate(),
  'masonry_wall': (c) => (c.read(
    masonryWallStateProvider('PRJ_1').notifier,
  )..setAll({'t': 200, 'height': 2.7, 'nEd': 300, 'eTop': 20})).calculate(),
  'slab': (c) =>
      (c.read(slabStateProvider('PRJ_1').notifier)
            ..setOption('type', 'twoWay')
            ..setOption('support', 'continuous')
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

  const screens = {
    'dashboard': '/dashboard',
    'projects': '/projects',
    'project': '/projects/PRJ_1',
    'beam': '/projects/PRJ_1/beam',
    'column': '/projects/PRJ_1/column',
    'column_circular': '/projects/PRJ_1/column',
    'slab': '/projects/PRJ_1/slab',
    'masonry_wall': '/projects/PRJ_1/masonry-wall',
    'timber_member': '/projects/PRJ_1/timber-member',
    'steel_member': '/projects/PRJ_1/steel-member',
    'footing': '/projects/PRJ_1/footing',
    'footing_combined': '/projects/PRJ_1/footing',
    'bearing': '/projects/PRJ_1/bearing',
    'sections': '/projects/PRJ_1/sections',
    'quantities': '/projects/PRJ_1/quantities',
    'frame_list': '/projects/PRJ_1/frame2d',
    'frame_editor': '/projects/PRJ_1/frame2d/FM_1',
    'frame_results': '/projects/PRJ_1/frame2d/FM_1',
    'retaining_wall': '/projects/PRJ_1/retaining-wall',
    'field': '/field',
    'punch_list': '/field/punch-list/PRJ_1',
    'reports': '/reports',
    'library': '/reference',
    'settings': '/dashboard/settings',
  };

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
            await tester.pumpAndSettle();

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
            expect(tester.takeException(), isNull, reason: s.key);

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
