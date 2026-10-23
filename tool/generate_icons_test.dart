// Generates every app icon from the logo painter.
//
//   flutter test tool/generate_icons_test.dart
//
// Writes the Android launcher icons (legacy, round and adaptive layers
// with a monochrome one for themed icons), the iOS app icon set, the web
// icons and favicon, the Windows .ico and assets/branding/logo.png.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibot/ui/widgets/brand.dart';

/// Renders [paint] into a [px] square PNG.
Future<Uint8List> _png(int px, void Function(Canvas c, double s) paint) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  paint(canvas, px.toDouble());
  final image = await rec.endRecording().toImage(px, px);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

Future<void> _write(String path, Uint8List bytes) async {
  final f = File(path);
  await f.parent.create(recursive: true);
  await f.writeAsBytes(bytes);
}

/// ICO file with PNG-compressed entries (Windows Vista and later).
Uint8List _ico(List<(int, Uint8List)> images) {
  final header = BytesBuilder();
  final data = BytesBuilder();
  var offset = 6 + 16 * images.length;
  void u16(BytesBuilder b, int v) => b.add([v & 0xff, (v >> 8) & 0xff]);
  void u32(BytesBuilder b, int v) =>
      b.add([v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff]);
  u16(header, 0);
  u16(header, 1);
  u16(header, images.length);
  for (final (px, png) in images) {
    header.add([px >= 256 ? 0 : px, px >= 256 ? 0 : px, 0, 0]);
    u16(header, 1);
    u16(header, 32);
    u32(header, png.length);
    u32(header, offset);
    offset += png.length;
    data.add(png);
  }
  return Uint8List.fromList([...header.takeBytes(), ...data.takeBytes()]);
}

void main() {
  testWidgets('generate icons', (tester) async {
    await tester.runAsync(() async {
      // Full logo with rounded corners (stores, web, in-app).
      Future<Uint8List> rounded(int px) =>
          _png(px, (c, s) => paintSibotLogo(c, s));
      // Square, full bleed (iOS masks the corners itself; no alpha).
      Future<Uint8List> square(int px) =>
          _png(px, (c, s) => paintSibotLogo(c, s, rounded: false));
      // Circular legacy icon.
      Future<Uint8List> circle(int px) => _png(px, (c, s) {
        c.clipPath(Path()..addOval(Rect.fromLTWH(0, 0, s, s)));
        paintSibotLogo(c, s, rounded: false);
      });
      // Adaptive layers: 108 dp canvas, the logo square on the central
      // 72 dp so the mark stays inside the 66 dp safe zone.
      Future<Uint8List> foreground(int px, {bool mono = false}) =>
          _png(px, (c, s) {
            paintSibotLogo(
              c,
              s * 72 / 108,
              origin: Offset(s * 18 / 108, s * 18 / 108),
              background: false,
              monochrome: mono,
            );
          });
      Future<Uint8List> backgroundLayer(int px) =>
          _png(px, (c, s) => paintSibotLogo(c, s, mark: false, rounded: false));

      const res = 'android/app/src/main/res';
      const densities = {
        'mdpi': 1.0,
        'hdpi': 1.5,
        'xhdpi': 2.0,
        'xxhdpi': 3.0,
        'xxxhdpi': 4.0,
      };
      for (final e in densities.entries) {
        final legacy = (48 * e.value).round();
        final layer = (108 * e.value).round();
        await _write(
          '$res/mipmap-${e.key}/ic_launcher.png',
          await rounded(legacy),
        );
        await _write(
          '$res/mipmap-${e.key}/ic_launcher_round.png',
          await circle(legacy),
        );
        await _write(
          '$res/mipmap-${e.key}/ic_launcher_foreground.png',
          await foreground(layer),
        );
        await _write(
          '$res/mipmap-${e.key}/ic_launcher_background.png',
          await backgroundLayer(layer),
        );
        await _write(
          '$res/mipmap-${e.key}/ic_launcher_monochrome.png',
          await foreground(layer, mono: true),
        );
      }
      const adaptive = '''
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
''';
      for (final name in ['ic_launcher', 'ic_launcher_round']) {
        final f = File('$res/mipmap-anydpi-v26/$name.xml');
        await f.parent.create(recursive: true);
        await f.writeAsString(adaptive);
      }

      // iOS app icon set.
      const ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
      const iosIcons = {
        'Icon-App-20x20@1x.png': 20,
        'Icon-App-20x20@2x.png': 40,
        'Icon-App-20x20@3x.png': 60,
        'Icon-App-29x29@1x.png': 29,
        'Icon-App-29x29@2x.png': 58,
        'Icon-App-29x29@3x.png': 87,
        'Icon-App-40x40@1x.png': 40,
        'Icon-App-40x40@2x.png': 80,
        'Icon-App-40x40@3x.png': 120,
        'Icon-App-60x60@2x.png': 120,
        'Icon-App-60x60@3x.png': 180,
        'Icon-App-76x76@1x.png': 76,
        'Icon-App-76x76@2x.png': 152,
        'Icon-App-83.5x83.5@2x.png': 167,
        'Icon-App-1024x1024@1x.png': 1024,
      };
      if (Directory(ios).existsSync()) {
        for (final e in iosIcons.entries) {
          await _write('$ios/${e.key}', await square(e.value));
        }
      }

      // Web.
      await _write('web/favicon.png', await rounded(32));
      await _write('web/icons/Icon-192.png', await rounded(192));
      await _write('web/icons/Icon-512.png', await rounded(512));
      // Maskable: full-bleed background, mark inside the 80 % safe zone.
      Future<Uint8List> maskable(int px) => _png(px, (c, s) {
        paintSibotLogo(c, s, mark: false, rounded: false);
        paintSibotLogo(
          c,
          s * 0.8,
          origin: Offset(s * 0.1, s * 0.1),
          background: false,
        );
      });
      await _write('web/icons/Icon-maskable-192.png', await maskable(192));
      await _write('web/icons/Icon-maskable-512.png', await maskable(512));

      // Windows.
      await _write(
        'windows/runner/resources/app_icon.ico',
        _ico([
          for (final px in const [16, 24, 32, 48, 64, 128, 256])
            (px, await rounded(px)),
        ]),
      );

      // Branding for the README and the stores.
      await _write('assets/branding/logo.png', await rounded(1024));
      await _write('assets/branding/play_store_512.png', await square(512));
    });
  });
}
