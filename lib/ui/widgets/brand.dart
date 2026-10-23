import 'package:flutter/material.dart';
import 'package:sibot/config/theme.dart';

/// Brand colours of the logo (fixed: the same in light and dark themes).
const _logoBlueTop = Color(0xFF4C74FF);
const _logoBlueBottom = Color(0xFF1E3BD6);
const _logoAmber = Color(0xFFF5A524);

/// Paints the Sibot logo in a [size] square at [origin]: a squared "S"
/// drawn as a two-bay structural frame with amber joints and a pinned
/// support, on a blue rounded square.
///
/// [background] and [mark] select the layers (adaptive launcher icons
/// need them apart); [monochrome] draws the mark in [ink] only.
void paintSibotLogo(
  Canvas canvas,
  double size, {
  Offset origin = Offset.zero,
  bool background = true,
  bool mark = true,
  bool monochrome = false,
  bool rounded = true,
  Color ink = Colors.white,
}) {
  canvas.save();
  canvas.translate(origin.dx, origin.dy);
  canvas.scale(size);
  if (background) {
    final rect = const Rect.fromLTWH(0, 0, 1, 1);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_logoBlueTop, _logoBlueBottom],
      ).createShader(rect);
    if (rounded) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(0.225)),
        paint,
      );
    } else {
      canvas.drawRect(rect, paint);
    }
    // Faint blueprint grid.
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 0.006;
    canvas.save();
    if (rounded) {
      canvas.clipRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(0.225)),
      );
    }
    for (var k = 1; k < 10; k++) {
      canvas.drawLine(Offset(k / 10, 0), Offset(k / 10, 1), grid);
      canvas.drawLine(Offset(0, k / 10), Offset(1, k / 10), grid);
    }
    canvas.restore();
  }
  if (mark) {
    final accent = monochrome ? ink : _logoAmber;
    const a = Offset(0.72, 0.22), b = Offset(0.32, 0.22);
    const c = Offset(0.32, 0.44), d = Offset(0.72, 0.44);
    const e = Offset(0.72, 0.66), f = Offset(0.32, 0.66);
    final member = Paint()
      ..color = ink
      ..strokeWidth = 0.088
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy)
        ..lineTo(d.dx, d.dy)
        ..lineTo(e.dx, e.dy)
        ..lineTo(f.dx, f.dy),
      member,
    );
    // Pinned support under the free end, with its ground line.
    final support = Paint()..color = accent;
    canvas.drawPath(
      Path()
        ..moveTo(f.dx, f.dy + 0.02)
        ..lineTo(f.dx - 0.07, f.dy + 0.13)
        ..lineTo(f.dx + 0.07, f.dy + 0.13)
        ..close(),
      support,
    );
    canvas.drawLine(
      Offset(f.dx - 0.11, f.dy + 0.155),
      Offset(f.dx + 0.11, f.dy + 0.155),
      Paint()
        ..color = ink
        ..strokeWidth = 0.03
        ..strokeCap = StrokeCap.round,
    );
    // Rigid joints.
    final joint = Paint()..color = accent;
    for (final p in [b, c, d, e]) {
      canvas.drawCircle(p, 0.05, joint);
    }
    canvas.drawCircle(a, 0.044, Paint()..color = ink);
  }
  canvas.restore();
}

/// The Sibot logo at [size] logical pixels.
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter();

  @override
  void paint(Canvas canvas, Size size) =>
      paintSibotLogo(canvas, size.shortestSide);

  @override
  bool shouldRepaint(_LogoPainter old) => false;
}

/// Line drawing of a two-bay portal frame under a uniform load with its
/// bending-moment diagram, used as the hero illustration on tablets.
class FrameSketch extends StatelessWidget {
  const FrameSketch({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FramePainter(
        ink: context.colors.onSurface,
        accent: context.colors.primary,
        muted: context.colors.onSurfaceVariant,
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  final Color ink;
  final Color accent;
  final Color muted;
  _FramePainter({required this.ink, required this.accent, required this.muted});

  @override
  void paint(Canvas canvas, Size size) {
    // Fit a 2-bay frame (2:1.1 aspect) into the box.
    final w = size.width.clamp(0, size.height * 1.9).toDouble();
    final h = w / 1.9;
    final ox = (size.width - w) / 2, oy = (size.height - h) / 2;
    Offset pt(double x, double y) => Offset(ox + x * w, oy + y * h);

    final member = Paint()
      ..color = ink
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final thin = Paint()
      ..color = muted
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const beamY = 0.32, baseY = 0.86;
    const cols = [0.08, 0.5, 0.92];

    // Bending-moment diagram on the beam: hogging at supports, sagging
    // mid-span (drawn below the beam, as on the tension side).
    final bmd = Path()..moveTo(pt(cols[0], beamY).dx, pt(cols[0], beamY).dy);
    for (var bay = 0; bay < 2; bay++) {
      final a = cols[bay], b = cols[bay + 1];
      for (var i = 0; i <= 40; i++) {
        final t = i / 40;
        // Fixed-fixed-ish: M(t) ∝ 6t(1-t) - 1 (hog at ends, sag in middle)
        final m = 6 * t * (1 - t) - 1;
        bmd.lineTo(pt(a + (b - a) * t, beamY).dx, pt(0, beamY + m * 0.085).dy);
      }
    }
    bmd.lineTo(pt(cols[2], beamY).dx, pt(0, beamY).dy);
    bmd.close();
    canvas.drawPath(bmd, Paint()..color = accent.withValues(alpha: 0.14));
    canvas.drawPath(
      bmd,
      Paint()
        ..color = accent
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke,
    );

    // Uniform load arrows.
    final arrow = Paint()
      ..color = accent
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const loadTop = beamY - 0.16;
    canvas.drawLine(pt(cols[0], loadTop), pt(cols[2], loadTop), arrow);
    for (var i = 0; i <= 16; i++) {
      final x = cols[0] + (cols[2] - cols[0]) * i / 16;
      final tip = pt(x, beamY - 0.025);
      canvas.drawLine(pt(x, loadTop), tip, arrow);
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx - 3.5, tip.dy - 6)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(tip.dx + 3.5, tip.dy - 6),
        arrow,
      );
    }

    // Members.
    canvas.drawLine(pt(cols[0], beamY), pt(cols[2], beamY), member);
    for (final x in cols) {
      canvas.drawLine(pt(x, beamY), pt(x, baseY), member);
    }

    // Fixed supports with hatching.
    for (final x in cols) {
      final base = pt(x, baseY);
      canvas.drawLine(base.translate(-16, 0), base.translate(16, 0), member);
      for (var i = -2; i <= 2; i++) {
        final s = base.translate(i * 7.0, 0);
        canvas.drawLine(s, s.translate(-6, 8), thin);
      }
    }

    // Nodes.
    final node = Paint()..color = ink;
    final hole = Paint()..color = accent;
    for (final x in cols) {
      canvas.drawCircle(pt(x, beamY), 5, node);
      canvas.drawCircle(pt(x, beamY), 2.2, hole);
    }

    // Dimension line under the frame.
    final dimY = baseY + 0.1;
    canvas.drawLine(pt(cols[0], dimY), pt(cols[2], dimY), thin);
    for (final x in cols) {
      canvas.drawLine(pt(x, dimY - 0.025), pt(x, dimY + 0.025), thin);
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.ink != ink || old.accent != accent || old.muted != muted;
}

/// Blueprint-style grid used behind hero cards.
class BlueprintGrid extends StatelessWidget {
  final Widget child;
  final double spacing;

  const BlueprintGrid({super.key, required this.child, this.spacing = 22});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(context.appColors.grid, spacing),
      child: child,
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  final double spacing;
  _GridPainter(this.color, this.spacing);

  @override
  void paint(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = color
      ..strokeWidth = 1;
    final major = Paint()
      ..color = color.withValues(alpha: (color.a * 2.2).clamp(0, 1))
      ..strokeWidth = 1;

    var i = 0;
    for (double x = 0; x <= size.width; x += spacing, i++) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        i % 4 == 0 ? major : minor,
      );
    }
    i = 0;
    for (double y = 0; y <= size.height; y += spacing, i++) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        i % 4 == 0 ? major : minor,
      );
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.color != color || old.spacing != spacing;
}
