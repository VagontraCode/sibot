import 'package:flutter/material.dart';
import 'package:sibot/config/theme.dart';

/// Sibot logo: a Warren truss inside a rounded square.
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: CustomPaint(painter: _TrussPainter(context.colors.onPrimary)),
    );
  }
}

class _TrussPainter extends CustomPainter {
  final Color color;
  _TrussPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final paint = Paint()
      ..color = color
      ..strokeWidth = s * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final l = s * 0.2, r = s * 0.8, top = s * 0.34, bot = s * 0.66;
    final m = (l + r) / 2;
    final q1 = (l + m) / 2, q3 = (m + r) / 2;

    final path = Path()
      ..moveTo(l, bot)
      ..lineTo(r, bot)
      ..moveTo(q1, top)
      ..lineTo(q3, top)
      // diagonals
      ..moveTo(l, bot)
      ..lineTo(q1, top)
      ..lineTo(m, bot)
      ..lineTo(q3, top)
      ..lineTo(r, bot);
    canvas.drawPath(path, paint);

    final dot = Paint()..color = color;
    for (final p in [Offset(l, bot), Offset(m, bot), Offset(r, bot)]) {
      canvas.drawCircle(p, s * 0.06, dot);
    }
  }

  @override
  bool shouldRepaint(_TrussPainter old) => old.color != color;
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
