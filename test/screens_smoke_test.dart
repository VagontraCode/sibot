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
import 'package:sibot/features/calculations/footings/presentation/footings_provider.dart';
import 'package:sibot/main.dart';

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
  'beam': (c) {
    final n = c.read(beamStateProvider('PRJ_1').notifier)
      ..updateSpan(6)
      ..updateLoad(25)
      ..updateWidth(250)
      ..updateDepth(500)
      ..updateConcreteStrength(25)
      ..updateSteelStrength(500);
    return n.calculate();
  },
  'footing': (c) {
    final n = c.read(footingStateProvider('PRJ_1').notifier)
      ..updateColumnLoad(500)
      ..updateColumnMoment(40)
      ..updateSoilBearingCapacity(250)
      ..updateSoilDensity(18)
      ..updateConcreteStrength(25)
      ..updateSteelStrength(500);
    return n.calculate();
  },
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
    'footing': '/projects/PRJ_1/footing',
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
          tester.view.physicalSize = size.value * 2;
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

            // Run a calculation so the results view is rendered too.
            final calculate = _calculations[s.key];
            if (calculate != null) {
              final container = ProviderScope.containerOf(
                tester.element(find.byType(Scaffold).last),
              );
              await tester.runAsync(() => calculate(container));
              await tester.pumpAndSettle();
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
