import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

class _Colors {
  final Color concrete, edge, steel, link, ink, muted, accent, danger, ok;
  _Colors(BuildContext c)
    : concrete = c.colors.surfaceContainerHigh,
      edge = c.colors.outline,
      steel = c.colors.onSurface,
      link = c.colors.primary,
      ink = c.colors.onSurface,
      muted = c.colors.onSurfaceVariant,
      accent = c.colors.primary,
      danger = c.appColors.danger,
      ok = c.appColors.success;
}

TextPainter _label(String text, Color color, {double size = 11}) => TextPainter(
  text: TextSpan(
    text: text,
    style: TextStyle(
      color: color,
      fontSize: size,
      fontFamily: AppTheme.monoFamily,
    ),
  ),
  textDirection: TextDirection.ltr,
)..layout();

/// Cross-section b × h (mm) with bottom and top bars and the link.
class SectionSketch extends StatelessWidget {
  final double b;
  final double h;
  final double cover;
  final int linkDiameter;
  final BarSet? bottom;
  final BarSet? top;

  /// Intermediate bars on each side face (columns), same diameter.
  final int sideBars;

  const SectionSketch({
    super.key,
    required this.b,
    required this.h,
    required this.cover,
    this.linkDiameter = 8,
    this.bottom,
    this.top,
    this.sideBars = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: AspectRatio(
        aspectRatio: 1.4,
        child: CustomPaint(painter: _SectionPainter(this, _Colors(context))),
      ),
    );
  }
}

class _SectionPainter extends CustomPainter {
  final SectionSketch s;
  final _Colors c;
  _SectionPainter(this.s, this.c);

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 28.0;
    final scale = math.min(
      (size.width - 2 * pad) / s.b,
      (size.height - 2 * pad) / s.h,
    );
    final w = s.b * scale, h = s.h * scale;
    final origin = Offset((size.width - w) / 2, (size.height - h) / 2);
    final rect = origin & Size(w, h);

    canvas.drawRect(rect, Paint()..color = c.concrete);
    canvas.drawRect(
      rect,
      Paint()
        ..color = c.edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Link.
    final inset = (s.cover + s.linkDiameter / 2) * scale;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(inset), Radius.circular(4 * scale)),
      Paint()
        ..color = c.link
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, s.linkDiameter * scale),
    );

    void bars(BarSet? set, bool atBottom) {
      if (set == null || set.count == 0) return;
      final r = set.diameter / 2 * scale;
      final edge = (s.cover + s.linkDiameter) * scale + r;
      final y = atBottom ? rect.bottom - edge : rect.top + edge;
      final n = set.count;
      final x0 = rect.left + edge, x1 = rect.right - edge;
      for (var i = 0; i < n; i++) {
        final x = n == 1 ? (x0 + x1) / 2 : x0 + (x1 - x0) * i / (n - 1);
        canvas.drawCircle(
          Offset(x, y),
          math.max(r, 2.5),
          Paint()..color = c.steel,
        );
      }
    }

    bars(s.bottom, true);
    bars(s.top, false);

    // Intermediate bars on the side faces.
    final ref = s.bottom ?? s.top;
    if (s.sideBars > 0 && ref != null) {
      final r = ref.diameter / 2 * scale;
      final edge = (s.cover + s.linkDiameter) * scale + r;
      final y0 = rect.top + edge, y1 = rect.bottom - edge;
      for (var k = 1; k <= s.sideBars; k++) {
        final y = y0 + (y1 - y0) * k / (s.sideBars + 1);
        for (final x in [rect.left + edge, rect.right - edge]) {
          canvas.drawCircle(
            Offset(x, y),
            math.max(r, 2.5),
            Paint()..color = c.steel,
          );
        }
      }
    }

    // Dimensions.
    final bl = _label('${s.b.round()}', c.muted);
    bl.paint(canvas, Offset(rect.center.dx - bl.width / 2, rect.bottom + 6));
    final hl = _label('${s.h.round()}', c.muted);
    canvas.save();
    canvas.translate(rect.left - 8, rect.center.dy + hl.width / 2);
    canvas.rotate(-math.pi / 2);
    hl.paint(canvas, Offset(0, -hl.height));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SectionPainter old) => true;
}

/// N–M interaction diagram with the design point (N vertical, as in RSA).
class InteractionDiagram extends StatelessWidget {
  final List<NMPoint> curve;
  final double nEd;
  final double mEd;
  final bool ok;
  final String? title;

  const InteractionDiagram({
    super.key,
    required this.curve,
    required this.nEd,
    required this.mEd,
    required this.ok,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title ?? l.columnInteraction, style: context.text.titleMedium),
          const SizedBox(height: Gap.md),
          AspectRatio(
            aspectRatio: 1.2,
            child: CustomPaint(
              painter: _InteractionPainter(this, _Colors(context), context),
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractionPainter extends CustomPainter {
  final InteractionDiagram d;
  final _Colors c;
  final BuildContext context;
  _InteractionPainter(this.d, this.c, this.context);

  @override
  void paint(Canvas canvas, Size size) {
    if (d.curve.isEmpty) return;
    const left = 46.0, bottom = 26.0, top = 8.0, right = 12.0;
    final plot = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );

    final mMax =
        math.max(d.curve.map((p) => p.m).reduce(math.max), d.mEd) * 1.1;
    final nMax =
        math.max(d.curve.map((p) => p.n).reduce(math.max), d.nEd) * 1.05;
    final nMin = math.min(d.curve.map((p) => p.n).reduce(math.min), 0.0);

    Offset at(double m, double n) => Offset(
      plot.left + (m + mMax) / (2 * mMax) * plot.width,
      plot.bottom - (n - nMin) / (nMax - nMin) * plot.height,
    );

    // Axes.
    final axis = Paint()
      ..color = c.edge
      ..strokeWidth = 1;
    canvas.drawLine(at(-mMax, 0), at(mMax, 0), axis);
    canvas.drawLine(at(0, nMin), at(0, nMax), axis);

    // Curve, mirrored for negative moments.
    final path = Path()
      ..moveTo(
        at(d.curve.first.m, d.curve.first.n).dx,
        at(d.curve.first.m, d.curve.first.n).dy,
      );
    for (final p in d.curve) {
      path.lineTo(at(p.m, p.n).dx, at(p.m, p.n).dy);
    }
    for (final p in d.curve.reversed) {
      path.lineTo(at(-p.m, p.n).dx, at(-p.m, p.n).dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = c.accent.withValues(alpha: 0.12));
    canvas.drawPath(
      path,
      Paint()
        ..color = c.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Design point.
    final pt = at(d.mEd, d.nEd);
    final color = d.ok ? c.ok : c.danger;
    canvas.drawCircle(pt, 6, Paint()..color = color);
    canvas.drawCircle(
      pt,
      9,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Labels.
    _label('N (kN)', c.muted).paint(canvas, Offset(at(0, nMax).dx + 6, top));
    final ml = _label('M (kN·m)', c.muted);
    ml.paint(canvas, Offset(plot.right - ml.width, at(0, 0).dy + 4));
    final nTop = _label(fmt(context, nMax / 1.05, 0), c.muted, size: 10);
    nTop.paint(
      canvas,
      Offset(left - nTop.width - 6, at(0, nMax / 1.05).dy - 6),
    );
    final mRight = _label(fmt(context, mMax / 1.1, 0), c.muted, size: 10);
    mRight.paint(
      canvas,
      Offset(at(mMax / 1.1, 0).dx - mRight.width / 2, size.height - bottom + 8),
    );
  }

  @override
  bool shouldRepaint(_InteractionPainter old) => true;
}

/// Cross-section of a cantilever retaining wall from the current inputs.
class WallSketch extends StatelessWidget {
  final double stemHeight;
  final double baseThickness;
  final double toe;
  final double heel;
  final double stemTop;
  final double stemBottom;
  final double surcharge;

  const WallSketch({
    super.key,
    required this.stemHeight,
    required this.baseThickness,
    required this.toe,
    required this.heel,
    required this.stemTop,
    required this.stemBottom,
    required this.surcharge,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: AspectRatio(
        aspectRatio: 1.5,
        child: CustomPaint(
          painter: _WallPainter(this, _Colors(context), context),
        ),
      ),
    );
  }
}

class _WallPainter extends CustomPainter {
  final WallSketch w;
  final _Colors c;
  final BuildContext context;
  _WallPainter(this.w, this.c, this.context);

  @override
  void paint(Canvas canvas, Size size) {
    final l = context.l10n;
    final b = w.toe + w.stemBottom + w.heel;
    final hTot = w.stemHeight + w.baseThickness;
    if (b <= 0 || hTot <= 0) return;
    const pad = 30.0;
    final scale = math.min(
      (size.width - 2 * pad) / (b + 0.6),
      (size.height - 2 * pad) / (hTot + 0.4),
    );
    final ox = (size.width - b * scale) / 2;
    final oy = size.height - pad;
    Offset p(double x, double y) => Offset(ox + x * scale, oy - y * scale);

    // Backfill over the heel.
    final soil = Path()
      ..moveTo(
        p(w.toe + w.stemBottom, w.baseThickness).dx,
        p(0, w.baseThickness).dy,
      )
      ..lineTo(p(b + 0.4, w.baseThickness).dx, p(0, w.baseThickness).dy)
      ..lineTo(p(b + 0.4, hTot).dx, p(0, hTot).dy)
      ..lineTo(p(w.toe + w.stemBottom, hTot).dx, p(0, hTot).dy)
      ..close();
    canvas.drawPath(
      soil,
      Paint()..color = const Color(0xFFB08850).withValues(alpha: 0.25),
    );

    final concrete = Paint()..color = c.concrete;
    final edge = Paint()
      ..color = c.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Base and stem (back face vertical, front face battered).
    final base = Rect.fromPoints(p(0, 0), p(b, w.baseThickness));
    canvas.drawRect(base, concrete);
    canvas.drawRect(base, edge);
    final xBack = w.toe + w.stemBottom;
    final stem = Path()
      ..moveTo(p(w.toe, w.baseThickness).dx, p(0, w.baseThickness).dy)
      ..lineTo(p(xBack, w.baseThickness).dx, p(0, w.baseThickness).dy)
      ..lineTo(p(xBack, hTot).dx, p(0, hTot).dy)
      ..lineTo(p(xBack - w.stemTop, hTot).dx, p(0, hTot).dy)
      ..close();
    canvas.drawPath(stem, concrete);
    canvas.drawPath(stem, edge);

    // Surcharge arrows.
    if (w.surcharge > 0) {
      final arrow = Paint()
        ..color = c.accent
        ..strokeWidth = 1.4;
      for (var i = 0; i <= 5; i++) {
        final x = xBack + (b + 0.4 - xBack) * i / 5;
        final tip = p(x, hTot);
        canvas.drawLine(tip.translate(0, -18), tip, arrow);
        canvas.drawLine(tip, tip.translate(-3, -6), arrow);
        canvas.drawLine(tip, tip.translate(3, -6), arrow);
      }
    }

    // Labels: toe, heel, H.
    void under(String text, double x0, double x1) {
      final t = _label(text, c.muted, size: 10);
      t.paint(
        canvas,
        Offset((p(x0, 0).dx + p(x1, 0).dx - t.width) / 2, oy + 6),
      );
    }

    if (w.toe > 0) under(l.wallToe, 0, w.toe);
    if (w.heel > 0) under(l.wallHeel, xBack, b);
    final hl = _label(
      'H = ${fmt(context, w.stemHeight, 2)} m',
      c.muted,
      size: 10,
    );
    hl.paint(
      canvas,
      Offset(p(w.toe, 0).dx - hl.width - 6, p(0, hTot * 0.6).dy),
    );
  }

  @override
  bool shouldRepaint(_WallPainter old) => true;
}

/// Circular column section with bars on a circle.
class CircularSectionSketch extends StatelessWidget {
  final double diameter;
  final double cover;
  final int linkDiameter;
  final BarSet? bars;

  const CircularSectionSketch({
    super.key,
    required this.diameter,
    required this.cover,
    this.linkDiameter = 8,
    this.bars,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: AspectRatio(
        aspectRatio: 1.4,
        child: CustomPaint(painter: _CirclePainter(this, _Colors(context))),
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final CircularSectionSketch s;
  final _Colors c;
  _CirclePainter(this.s, this.c);

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 24.0;
    final scale = (math.min(size.width, size.height) - 2 * pad) / s.diameter;
    final centre = size.center(Offset.zero);
    final r = s.diameter / 2 * scale;
    canvas.drawCircle(centre, r, Paint()..color = c.concrete);
    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..color = c.edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final linkR = (s.diameter / 2 - s.cover - s.linkDiameter / 2) * scale;
    canvas.drawCircle(
      centre,
      linkR,
      Paint()
        ..color = c.link
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, s.linkDiameter * scale),
    );
    final set = s.bars;
    if (set != null) {
      final rb =
          (s.diameter / 2 - s.cover - s.linkDiameter - set.diameter / 2) *
          scale;
      for (var k = 0; k < set.count; k++) {
        final a = 2 * math.pi * k / set.count;
        canvas.drawCircle(
          centre + Offset(rb * math.sin(a), -rb * math.cos(a)),
          math.max(set.diameter / 2 * scale, 2.5),
          Paint()..color = c.steel,
        );
      }
    }
    final l = _label('Ø${s.diameter.round()}', c.muted);
    l.paint(canvas, Offset(centre.dx - l.width / 2, centre.dy + r + 4));
  }

  @override
  bool shouldRepaint(_CirclePainter old) => true;
}

/// One sample of a member diagram: position (m), shear (kN) and moment
/// (kN·m, positive = bottom fibre in tension).
class ForcePoint {
  final double x;
  final double v;
  final double m;
  const ForcePoint(this.x, this.v, this.m);
}

/// Shear and bending-moment diagrams along a member. Moments are drawn
/// on the tension side (positive below the axis), as on site drawings.
class ForceDiagram extends StatelessWidget {
  final List<ForcePoint> points;

  /// Positions (m) to mark, e.g. columns or supports.
  final List<double> marks;

  const ForceDiagram({super.key, required this.points, this.marks = const []});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.diagramShear, style: context.text.titleMedium),
          const SizedBox(height: Gap.sm),
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: _ForcePainter(
                points,
                marks,
                (p) => p.v,
                'kN',
                _Colors(context),
                context,
                downPositive: false,
              ),
            ),
          ),
          const SizedBox(height: Gap.lg),
          Text(l.diagramMoment, style: context.text.titleMedium),
          const SizedBox(height: Gap.sm),
          SizedBox(
            height: 140,
            child: CustomPaint(
              painter: _ForcePainter(
                points,
                marks,
                (p) => p.m,
                'kN·m',
                _Colors(context),
                context,
                downPositive: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForcePainter extends CustomPainter {
  final List<ForcePoint> pts;
  final List<double> marks;
  final double Function(ForcePoint) value;
  final String unit;
  final _Colors c;
  final BuildContext context;
  final bool downPositive;

  _ForcePainter(
    this.pts,
    this.marks,
    this.value,
    this.unit,
    this.c,
    this.context, {
    required this.downPositive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length < 2) return;
    const padX = 8.0, padY = 16.0;
    final x0 = pts.first.x, x1 = pts.last.x;
    final vals = pts.map(value).toList();
    final vMax = vals.reduce(math.max), vMin = vals.reduce(math.min);
    final range = math.max(vMax.abs(), vMin.abs());
    if (range == 0) return;
    final mid = size.height / 2;
    final half = size.height / 2 - padY;
    Offset at(double x, double v) => Offset(
      padX + (x - x0) / (x1 - x0) * (size.width - 2 * padX),
      mid + (downPositive ? 1 : -1) * v / range * half,
    );

    final area = Path()..moveTo(at(x0, 0).dx, mid);
    for (var k = 0; k < pts.length; k++) {
      final o = at(pts[k].x, vals[k]);
      area.lineTo(o.dx, o.dy);
    }
    area.lineTo(at(x1, 0).dx, mid);
    area.close();
    canvas.drawPath(area, Paint()..color = c.accent.withValues(alpha: 0.14));
    final line = Path();
    for (var k = 0; k < pts.length; k++) {
      final o = at(pts[k].x, vals[k]);
      k == 0 ? line.moveTo(o.dx, o.dy) : line.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = c.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    canvas.drawLine(
      Offset(padX, mid),
      Offset(size.width - padX, mid),
      Paint()
        ..color = c.ink
        ..strokeWidth = 1.5,
    );
    for (final m in marks) {
      final o = at(m, 0);
      final path = Path()
        ..moveTo(o.dx, mid - 7)
        ..lineTo(o.dx - 5, mid - 14)
        ..lineTo(o.dx + 5, mid - 14)
        ..close();
      canvas.drawPath(path, Paint()..color = c.ink);
    }

    // Extreme values.
    void tag(int k) {
      final o = at(pts[k].x, vals[k]);
      final t = _label('${fmt(context, vals[k])} $unit', c.ink, size: 10);
      final dx = (o.dx - t.width / 2).clamp(0.0, size.width - t.width);
      final below = o.dy >= mid;
      t.paint(canvas, Offset(dx, below ? o.dy + 2 : o.dy - t.height - 2));
    }

    var iMax = 0, iMin = 0;
    for (var k = 1; k < vals.length; k++) {
      if (vals[k] > vals[iMax]) iMax = k;
      if (vals[k] < vals[iMin]) iMin = k;
    }
    if (vals[iMax].abs() > range * 0.05) tag(iMax);
    if (vals[iMin].abs() > range * 0.05 && iMin != iMax) tag(iMin);
  }

  @override
  bool shouldRepaint(_ForcePainter old) => true;
}
