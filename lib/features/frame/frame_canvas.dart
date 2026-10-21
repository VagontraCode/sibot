import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/frame/frame_providers.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// What the results overlay shows.
enum ResultView { deformed, moment, shear, axial, reactions }

/// Results to draw: one load case/combination, or the ULS envelope.
class ResultOverlay {
  final ResultView view;
  final FrameResult? result;
  final List<List<(double, double)>>? envelope;

  const ResultOverlay({required this.view, this.result, this.envelope});
}

class FrameCanvas extends StatefulWidget {
  final Model2D model;
  final Selection? selection;
  final int? pendingNode;
  final int activeCase;
  final double grid;
  final ResultOverlay? overlay;

  final void Function(double x, double y)? onTapEmpty;
  final void Function(int node)? onTapNode;
  final void Function(int element)? onTapElement;

  const FrameCanvas({
    super.key,
    required this.model,
    this.selection,
    this.pendingNode,
    this.activeCase = 0,
    this.grid = 0.5,
    this.overlay,
    this.onTapEmpty,
    this.onTapNode,
    this.onTapElement,
  });

  @override
  State<FrameCanvas> createState() => FrameCanvasState();
}

class FrameCanvasState extends State<FrameCanvas> {
  double _scale = 40; // px per metre
  Offset _origin = Offset.zero; // screen position of world (0, 0)
  bool _fitted = false;
  Size _size = Size.zero;

  double _startScale = 40;
  Offset _startFocalWorld = Offset.zero;

  Offset toScreen(double x, double y) =>
      Offset(_origin.dx + x * _scale, _origin.dy - y * _scale);

  Offset toWorld(Offset p) =>
      Offset((p.dx - _origin.dx) / _scale, (_origin.dy - p.dy) / _scale);

  /// Frames the whole model in the view.
  void fit() {
    final nodes = widget.model.nodes;
    if (_size.isEmpty) return;
    if (nodes.isEmpty) {
      _scale = 40;
      _origin = Offset(_size.width * 0.15, _size.height * 0.8);
      setState(() {});
      return;
    }
    var minX = nodes.first.x, maxX = minX, minY = nodes.first.y, maxY = minY;
    for (final n in nodes) {
      minX = math.min(minX, n.x);
      maxX = math.max(maxX, n.x);
      minY = math.min(minY, n.y);
      maxY = math.max(maxY, n.y);
    }
    final w = math.max(maxX - minX, 1.0), h = math.max(maxY - minY, 1.0);
    _scale = math
        .min(_size.width * 0.7 / w, _size.height * 0.6 / h)
        .clamp(4.0, 400.0);
    final cx = (minX + maxX) / 2, cy = (minY + maxY) / 2;
    _origin = Offset(
      _size.width / 2 - cx * _scale,
      _size.height / 2 + cy * _scale,
    );
    setState(() {});
  }

  void _onTap(Offset p) {
    final m = widget.model;
    // Nodes first (largest touch target), then members.
    var best = -1;
    var bestD = 22.0;
    for (var i = 0; i < m.nodes.length; i++) {
      final d = (toScreen(m.nodes[i].x, m.nodes[i].y) - p).distance;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    if (best >= 0) {
      widget.onTapNode?.call(best);
      return;
    }
    var bestE = -1;
    var bestDe = 16.0;
    for (var k = 0; k < m.elements.length; k++) {
      final e = m.elements[k];
      final a = toScreen(m.nodes[e.n1].x, m.nodes[e.n1].y);
      final b = toScreen(m.nodes[e.n2].x, m.nodes[e.n2].y);
      final d = _distanceToSegment(p, a, b);
      if (d < bestDe) {
        bestDe = d;
        bestE = k;
      }
    }
    if (bestE >= 0) {
      widget.onTapElement?.call(bestE);
      return;
    }
    final w = toWorld(p);
    widget.onTapEmpty?.call(w.dx, w.dy);
  }

  static double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 == 0) return (p - a).distance;
    final t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2).clamp(
      0.0,
      1.0,
    );
    return (p - (a + ab * t)).distance;
  }

  void _zoomAt(Offset focal, double factor) {
    final world = toWorld(focal);
    _scale = (_scale * factor).clamp(2.0, 2000.0);
    _origin = Offset(
      focal.dx - world.dx * _scale,
      focal.dy + world.dy * _scale,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = c.biggest;
        if (size != _size) {
          _size = size;
          if (!_fitted) {
            _fitted = true;
            WidgetsBinding.instance.addPostFrameCallback((_) => fit());
          }
        }
        return Listener(
          onPointerSignal: (e) {
            if (e is PointerScrollEvent) {
              _zoomAt(e.localPosition, e.scrollDelta.dy < 0 ? 1.15 : 1 / 1.15);
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _onTap(d.localPosition),
            onScaleStart: (d) {
              _startScale = _scale;
              _startFocalWorld = toWorld(d.localFocalPoint);
            },
            onScaleUpdate: (d) {
              _scale = (_startScale * d.scale).clamp(2.0, 2000.0);
              _origin = Offset(
                d.localFocalPoint.dx - _startFocalWorld.dx * _scale,
                d.localFocalPoint.dy + _startFocalWorld.dy * _scale,
              );
              setState(() {});
            },
            child: CustomPaint(
              size: size,
              painter: _FramePainter(
                this,
                widget,
                _Palette.of(context),
                context,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Palette {
  final Color grid, gridMajor, member, truss, node, selected, support, load;
  final Color diagramPos, diagramNeg, deformed, text, background;
  _Palette.of(BuildContext c)
    : grid = c.colors.outlineVariant,
      gridMajor = c.colors.outline,
      member = c.colors.onSurface,
      truss = c.colors.onSurfaceVariant,
      node = c.colors.onSurface,
      selected = c.colors.primary,
      support = c.colors.onSurfaceVariant,
      load = c.appColors.danger,
      diagramPos = c.colors.primary,
      diagramNeg = c.appColors.warning,
      deformed = c.colors.primary,
      text = c.colors.onSurface,
      background = c.colors.surface;
}

class _FramePainter extends CustomPainter {
  final FrameCanvasState v;
  final FrameCanvas w;
  final _Palette p;
  final BuildContext context;

  _FramePainter(this.v, this.w, this.p, this.context);

  Model2D get m => w.model;

  @override
  void paint(Canvas canvas, Size size) {
    _grid(canvas, size);
    final overlay = w.overlay;
    final deformed = overlay?.view == ResultView.deformed;
    _members(canvas, faded: deformed);
    if (overlay != null) {
      switch (overlay.view) {
        case ResultView.deformed:
          if (overlay.result != null) _deformed(canvas, overlay.result!);
        case ResultView.moment || ResultView.shear || ResultView.axial:
          _diagrams(canvas, overlay);
        case ResultView.reactions:
          if (overlay.result != null) _reactions(canvas, overlay.result!);
      }
    } else {
      _loads(canvas);
    }
    _supports(canvas);
    _nodes(canvas);
  }

  void _grid(Canvas canvas, Size size) {
    var step = w.grid;
    while (step * v._scale < 14) {
      step *= 2;
    }
    final tl = v.toWorld(Offset.zero),
        br = v.toWorld(Offset(size.width, size.height));
    final minor = Paint()
      ..color = p.grid
      ..strokeWidth = 1;
    final axis = Paint()
      ..color = p.gridMajor
      ..strokeWidth = 1.2;
    for (var x = (tl.dx / step).floor() * step; x <= br.dx; x += step) {
      final sx = v.toScreen(x, 0).dx;
      canvas.drawLine(
        Offset(sx, 0),
        Offset(sx, size.height),
        x.abs() < 1e-9 ? axis : minor,
      );
    }
    for (var y = (br.dy / step).floor() * step; y <= tl.dy; y += step) {
      final sy = v.toScreen(0, y).dy;
      canvas.drawLine(
        Offset(0, sy),
        Offset(size.width, sy),
        y.abs() < 1e-9 ? axis : minor,
      );
    }
  }

  void _members(Canvas canvas, {bool faded = false}) {
    final sel = w.selection;
    for (var k = 0; k < m.elements.length; k++) {
      final e = m.elements[k];
      final a = v.toScreen(m.nodes[e.n1].x, m.nodes[e.n1].y);
      final b = v.toScreen(m.nodes[e.n2].x, m.nodes[e.n2].y);
      final selected = sel is ElementSelection && sel.index == k;
      final truss = e.kind == ElementKind.truss;
      final paint = Paint()
        ..color = selected
            ? p.selected
            : (truss ? p.truss : p.member).withValues(alpha: faded ? 0.35 : 1)
        ..strokeWidth = selected ? 4.5 : (truss ? 2.2 : 3.2)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(a, b, paint);
      // Hinges: hollow circles just inside the released ends.
      final dir = (b - a) / math.max((b - a).distance, 1);
      for (final (at, on) in [
        (a + dir * 9, e.hingeStart),
        (b - dir * 9, e.hingeEnd),
      ]) {
        if (!on) continue;
        canvas.drawCircle(at, 4.5, Paint()..color = p.background);
        canvas.drawCircle(
          at,
          4.5,
          Paint()
            ..color = paint.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      }
    }
  }

  void _nodes(Canvas canvas) {
    final sel = w.selection;
    for (var i = 0; i < m.nodes.length; i++) {
      final o = v.toScreen(m.nodes[i].x, m.nodes[i].y);
      final selected = (sel is NodeSelection && sel.index == i);
      final pending = w.pendingNode == i;
      canvas.drawCircle(
        o,
        selected || pending ? 6 : 4,
        Paint()..color = selected || pending ? p.selected : p.node,
      );
      if (pending) {
        canvas.drawCircle(
          o,
          11,
          Paint()
            ..color = p.selected
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  void _supports(Canvas canvas) {
    final paint = Paint()
      ..color = p.support
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final e in m.supports.entries) {
      if (e.key >= m.nodes.length) continue;
      final s = e.value;
      final o = v.toScreen(m.nodes[e.key].x, m.nodes[e.key].y);
      if (s.ux && s.uy && s.rz) {
        // Fixed: thick base with hatching.
        canvas.drawLine(
          o.translate(-14, 0),
          o.translate(14, 0),
          paint..strokeWidth = 3,
        );
        paint.strokeWidth = 1.4;
        for (var k = -2; k <= 2; k++) {
          final s0 = o.translate(k * 6.0, 0);
          canvas.drawLine(s0, s0.translate(-6, 8), paint);
        }
      } else if (s.uy || s.ux) {
        final tri = Path()
          ..moveTo(o.dx, o.dy)
          ..lineTo(o.dx - 10, o.dy + 14)
          ..lineTo(o.dx + 10, o.dy + 14)
          ..close();
        canvas.drawPath(tri, paint);
        if (s.ux && s.uy) {
          for (var k = -2; k <= 2; k++) {
            final s0 = o.translate(k * 5.0, 14);
            canvas.drawLine(s0, s0.translate(-5, 6), paint);
          }
        } else {
          canvas.drawCircle(o.translate(-5, 18), 3, paint);
          canvas.drawCircle(o.translate(5, 18), 3, paint);
        }
      }
      if (s.kx > 0 || s.ky > 0 || s.kr > 0) {
        final zig = Path()..moveTo(o.dx, o.dy);
        for (var k = 1; k <= 6; k++) {
          zig.lineTo(o.dx + (k.isOdd ? 6 : -6), o.dy + k * 4);
        }
        canvas.drawPath(zig, paint);
      }
    }
  }

  void _arrow(Canvas canvas, Offset tip, Offset dir, double len, Paint paint) {
    final tail = tip - dir * len;
    canvas.drawLine(tail, tip, paint);
    final n = Offset(-dir.dy, dir.dx);
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo((tip - dir * 7 + n * 3.5).dx, (tip - dir * 7 + n * 3.5).dy)
      ..lineTo((tip - dir * 7 - n * 3.5).dx, (tip - dir * 7 - n * 3.5).dy)
      ..close();
    canvas.drawPath(head, Paint()..color = paint.color);
  }

  void _label(Canvas canvas, String text, Offset at, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontFamily: AppTheme.monoFamily,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  void _loads(Canvas canvas) {
    if (w.activeCase >= m.cases.length) return;
    final c = m.cases[w.activeCase];
    final paint = Paint()
      ..color = p.load
      ..strokeWidth = 1.4;
    for (final d in c.distributed) {
      if (d.element >= m.elements.length) continue;
      final e = m.elements[d.element];
      final a = v.toScreen(m.nodes[e.n1].x, m.nodes[e.n1].y);
      final b = v.toScreen(m.nodes[e.n2].x, m.nodes[e.n2].y);
      final along = (b - a);
      final len = along.distance;
      if (len == 0) continue;
      final u = along / len;
      // Load direction in screen space (y flipped).
      final dir = switch (d.axis) {
        LoadAxis.globalY => Offset(0, d.w1 < 0 ? 1 : -1),
        LoadAxis.globalX => Offset(d.w1 > 0 ? 1 : -1, 0),
        LoadAxis.localY => Offset(u.dy, -u.dx) * (d.w1 > 0 ? -1 : 1),
      };
      final count = math.max(3, (len / 22).floor());
      final tops = <Offset>[];
      for (var k = 0; k <= count; k++) {
        final tip = a + along * (k / count);
        _arrow(canvas, tip - dir * 3, dir, 22, paint);
        tops.add(tip - dir * 25);
      }
      canvas.drawLine(tops.first, tops.last, paint);
      _label(
        canvas,
        fmt(context, d.w1.abs(), 1),
        (tops.first + tops.last) / 2 - dir * 9,
        p.load,
      );
    }
    for (final n in c.nodal) {
      if (n.node >= m.nodes.length) continue;
      final o = v.toScreen(m.nodes[n.node].x, m.nodes[n.node].y);
      final f = Offset(n.fx, -n.fy);
      if (f.distance > 0) {
        final dir = f / f.distance;
        _arrow(canvas, o - dir * 4, dir, 34, paint..strokeWidth = 2);
        _label(
          canvas,
          fmt(context, math.sqrt(n.fx * n.fx + n.fy * n.fy), 1),
          o - dir * 46,
          p.load,
        );
      }
      if (n.mz != 0) {
        canvas.drawArc(
          Rect.fromCircle(center: o, radius: 14),
          -math.pi * 0.8,
          math.pi * 1.4,
          false,
          paint..style = PaintingStyle.stroke,
        );
        paint.style = PaintingStyle.fill;
      }
    }
  }

  /// Station point in screen space, offset along the member normal.
  Offset _station(Element2D e, double x, double normalPx) {
    final a = m.nodes[e.n1], b = m.nodes[e.n2];
    final l = math.sqrt(math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2));
    final c = (b.x - a.x) / l, s = (b.y - a.y) / l;
    final base = v.toScreen(a.x + c * x, a.y + s * x);
    // Local y′ = (−s, c) in world → (−s, −c) on screen.
    return base + Offset(-s, -c) * normalPx;
  }

  void _diagrams(Canvas canvas, ResultOverlay o) {
    double pick(MemberStation st) => switch (o.view) {
      ResultView.moment => st.m,
      ResultView.shear => st.v,
      _ => st.n,
    };
    // Moments are drawn on the tension side (−y′ for positive).
    final sign = o.view == ResultView.moment ? -1.0 : 1.0;

    // Scale so the largest value spans ~45 px.
    var maxAbs = 0.0;
    if (o.envelope != null) {
      for (final mem in o.envelope!) {
        for (final (lo, hi) in mem) {
          maxAbs = math.max(maxAbs, math.max(lo.abs(), hi.abs()));
        }
      }
    } else if (o.result != null) {
      for (final mem in o.result!.members) {
        for (final st in mem.stations) {
          maxAbs = math.max(maxAbs, pick(st).abs());
        }
      }
    }
    if (maxAbs < 1e-9) return;
    final k = 45 / maxAbs;

    void polygon(Element2D e, List<double> xs, List<double> vals, Color color) {
      final path = Path();
      final start = _station(e, xs.first, 0);
      path.moveTo(start.dx, start.dy);
      for (var i = 0; i < xs.length; i++) {
        final pt = _station(e, xs[i], sign * vals[i] * k);
        path.lineTo(pt.dx, pt.dy);
      }
      final end = _station(e, xs.last, 0);
      path.lineTo(end.dx, end.dy);
      path.close();
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.18));
      final line = Path();
      for (var i = 0; i < xs.length; i++) {
        final pt = _station(e, xs[i], sign * vals[i] * k);
        i == 0 ? line.moveTo(pt.dx, pt.dy) : line.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(
        line,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }

    for (var idx = 0; idx < m.elements.length; idx++) {
      final e = m.elements[idx];
      if (o.envelope != null) {
        if (idx >= o.envelope!.length || o.result == null) continue;
        final xs = [for (final st in o.result!.members[idx].stations) st.x];
        final env = o.envelope![idx];
        polygon(e, xs, [for (final (_, hi) in env) hi], p.diagramPos);
        polygon(e, xs, [for (final (lo, _) in env) lo], p.diagramNeg);
      } else if (o.result != null) {
        final mem = o.result!.members[idx];
        final xs = [for (final st in mem.stations) st.x];
        final vals = [for (final st in mem.stations) pick(st)];
        polygon(e, xs, vals, p.diagramPos);
        // Label the extreme value of each member.
        var iMax = 0;
        for (var i = 1; i < vals.length; i++) {
          if (vals[i].abs() > vals[iMax].abs()) iMax = i;
        }
        if (vals[iMax].abs() > maxAbs * 0.08) {
          final at = _station(
            e,
            xs[iMax],
            sign * vals[iMax] * k + sign * vals[iMax].sign * 10,
          );
          _label(canvas, fmt(context, vals[iMax]), at, p.text);
        }
      }
    }
  }

  void _deformed(Canvas canvas, FrameResult r) {
    var maxD = 0.0;
    for (final mem in r.members) {
      for (final st in mem.stations) {
        maxD = math.max(maxD, math.sqrt(st.u * st.u + st.w * st.w));
      }
    }
    if (maxD < 1e-12) return;
    // Exaggerate so the largest displacement is ~40 px.
    final k = 40 / (maxD * v._scale);
    final paint = Paint()
      ..color = p.deformed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    for (var idx = 0; idx < m.elements.length; idx++) {
      final e = m.elements[idx];
      final a = m.nodes[e.n1], b = m.nodes[e.n2];
      final l = math.sqrt(math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2));
      final c = (b.x - a.x) / l, s = (b.y - a.y) / l;
      final path = Path();
      final sts = r.members[idx].stations;
      for (var i = 0; i < sts.length; i++) {
        final st = sts[i];
        final dx = (st.u * c - st.w * s) * k, dy = (st.u * s + st.w * c) * k;
        final pt = v.toScreen(a.x + c * st.x + dx, a.y + s * st.x + dy);
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path, paint);
    }
    // Label the largest nodal displacement.
    var iMax = 0;
    for (var i = 1; i < r.displacements.length; i++) {
      final d = r.displacements[i], dm = r.displacements[iMax];
      if (d[0] * d[0] + d[1] * d[1] > dm[0] * dm[0] + dm[1] * dm[1]) iMax = i;
    }
    final d = r.displacements[iMax];
    final mag = math.sqrt(d[0] * d[0] + d[1] * d[1]) * 1000;
    if (mag > 0) {
      final n = m.nodes[iMax];
      _label(
        canvas,
        '${fmt(context, mag, 1)} mm',
        v.toScreen(n.x + d[0] * k, n.y + d[1] * k) + const Offset(0, -16),
        p.deformed,
      );
    }
  }

  void _reactions(Canvas canvas, FrameResult r) {
    final paint = Paint()
      ..color = p.diagramPos
      ..strokeWidth = 2;
    for (final e in r.reactions.entries) {
      final n = m.nodes[e.key];
      final o = v.toScreen(n.x, n.y);
      final rx = e.value[0], ry = e.value[1], mz = e.value[2];
      if (ry.abs() > 1e-6) {
        final dir = Offset(0, ry > 0 ? -1 : 1);
        _arrow(canvas, o - dir * 6, dir, 30, paint);
        _label(
          canvas,
          'Ry ${fmt(context, ry)}',
          o + Offset(0, ry > 0 ? 48 : -48),
          p.text,
        );
      }
      if (rx.abs() > 1e-6) {
        final dir = Offset(rx > 0 ? 1 : -1, 0);
        _arrow(canvas, o - dir * 6, dir, 30, paint);
        _label(
          canvas,
          'Rx ${fmt(context, rx)}',
          o - dir * 52 + const Offset(0, -10),
          p.text,
        );
      }
      if (mz.abs() > 1e-6) {
        _label(
          canvas,
          'M ${fmt(context, mz)}',
          o + const Offset(34, 18),
          p.text,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) => true;
}
