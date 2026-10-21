import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// What the viewer colours the members by.
enum MemberValue { none, my, mz, n }

/// Interactive orthographic view of a space frame: drag to orbit, pinch
/// (or scroll) to zoom, two fingers to pan, double-tap to reset.
class Frame3DView extends StatefulWidget {
  final Model3D model;

  /// Static result: deformed shape along the members and colours.
  final Frame3DResult? result;

  /// Node shape (6 values per node) drawn with straight members, e.g. a
  /// mode or buckling shape; animated when [animate] is true.
  final List<List<double>>? shape;
  final bool animate;
  final MemberValue colorBy;

  const Frame3DView({
    super.key,
    required this.model,
    this.result,
    this.shape,
    this.animate = false,
    this.colorBy = MemberValue.none,
  });

  @override
  State<Frame3DView> createState() => _Frame3DViewState();
}

class _Frame3DViewState extends State<Frame3DView>
    with SingleTickerProviderStateMixin {
  static const _yaw0 = -0.65, _pitch0 = 0.45;
  double _yaw = _yaw0, _pitch = _pitch0, _zoom = 1;
  Offset _pan = Offset.zero;
  double _scaleStart = 1;
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(Frame3DView old) {
    super.didUpdateWidget(old);
    _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.animate && widget.shape != null) {
      if (!_anim.isAnimating) _anim.repeat();
    } else {
      _anim.stop();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _reset() => setState(() {
    _yaw = _yaw0;
    _pitch = _pitch0;
    _zoom = 1;
    _pan = Offset.zero;
  });

  @override
  Widget build(BuildContext context) {
    final colors = _ViewColors(context);
    return Listener(
      onPointerSignal: (e) {
        if (e is PointerScrollEvent) {
          setState(() {
            _zoom = (_zoom * (e.scrollDelta.dy > 0 ? 0.9 : 1.1)).clamp(0.2, 20);
          });
        }
      },
      child: GestureDetector(
        onDoubleTap: _reset,
        onScaleStart: (_) => _scaleStart = _zoom,
        onScaleUpdate: (d) => setState(() {
          if (d.pointerCount == 1) {
            _yaw += d.focalPointDelta.dx * 0.01;
            _pitch = (_pitch + d.focalPointDelta.dy * 0.01).clamp(-1.5, 1.5);
          } else {
            _zoom = (_scaleStart * d.scale).clamp(0.2, 20);
            _pan += d.focalPointDelta;
          }
        }),
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, _) => CustomPaint(
              size: Size.infinite,
              painter: _FramePainter(
                model: widget.model,
                result: widget.result,
                shape: widget.shape,
                phase: widget.animate ? math.cos(_anim.value * 2 * math.pi) : 1,
                colorBy: widget.colorBy,
                yaw: _yaw,
                pitch: _pitch,
                zoom: _zoom,
                pan: _pan,
                c: colors,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewColors {
  final Color member, ghost, support, axisX, axisY, axisZ, ink;
  _ViewColors(BuildContext c)
    : member = c.colors.onSurface,
      ghost = c.colors.outlineVariant,
      support = c.colors.primary,
      axisX = const Color(0xFFE5484D),
      axisY = const Color(0xFF30A46C),
      axisZ = const Color(0xFF3E63DD),
      ink = c.colors.onSurfaceVariant;
}

/// Blue → teal → yellow → red for 0 … 1.
Color heat(double t) {
  const stops = [
    Color(0xFF3E63DD),
    Color(0xFF12A594),
    Color(0xFFF5D90A),
    Color(0xFFE5484D),
  ];
  final x = t.clamp(0.0, 1.0) * (stops.length - 1);
  final i = math.min(x.floor(), stops.length - 2);
  return Color.lerp(stops[i], stops[i + 1], x - i)!;
}

class _FramePainter extends CustomPainter {
  final Model3D model;
  final Frame3DResult? result;
  final List<List<double>>? shape;
  final double phase;
  final MemberValue colorBy;
  final double yaw, pitch, zoom;
  final Offset pan;
  final _ViewColors c;

  _FramePainter({
    required this.model,
    required this.result,
    required this.shape,
    required this.phase,
    required this.colorBy,
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required this.pan,
    required this.c,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = model.nodes;
    if (nodes.isEmpty) return;
    var minX = double.infinity, minY = minX, minZ = minX;
    var maxX = -double.infinity, maxY = maxX, maxZ = maxX;
    for (final n in nodes) {
      minX = math.min(minX, n.x);
      maxX = math.max(maxX, n.x);
      minY = math.min(minY, n.y);
      maxY = math.max(maxY, n.y);
      minZ = math.min(minZ, n.z);
      maxZ = math.max(maxZ, n.z);
    }
    final cx = (minX + maxX) / 2,
        cy = (minY + maxY) / 2,
        cz = (minZ + maxZ) / 2;
    final radius = math.max(
      0.5,
      math.sqrt(
            math.pow(maxX - minX, 2) +
                math.pow(maxY - minY, 2) +
                math.pow(maxZ - minZ, 2),
          ) /
          2,
    );
    final scale = math.min(size.width, size.height) / (2.3 * radius) * zoom;
    final centre = size.center(Offset.zero) + pan;
    final cyw = math.cos(yaw), syw = math.sin(yaw);
    final cp = math.cos(pitch), sp = math.sin(pitch);

    // Returns screen point and depth (larger = farther).
    (Offset, double) project(double x, double y, double z) {
      final px = x - cx, py = y - cy, pz = z - cz;
      final x1 = px * cyw - py * syw;
      final y1 = px * syw + py * cyw;
      final up = pz * cp + y1 * sp;
      final depth = y1 * cp - pz * sp;
      return (centre + Offset(x1 * scale, -up * scale), depth);
    }

    // Deformation scale: largest displacement drawn at 8 % of the size.
    double maxDisp = 0;
    final r = result, s = shape;
    if (r != null) {
      for (final m in r.members) {
        for (final st in m.stations) {
          for (final d in st.disp) {
            maxDisp = math.max(maxDisp, d.abs());
          }
        }
      }
    } else if (s != null) {
      for (final n in s) {
        for (var d = 0; d < 3; d++) {
          maxDisp = math.max(maxDisp, n[d].abs());
        }
      }
    }
    final defScale = maxDisp > 0 ? 0.16 * radius / maxDisp * phase : 0.0;

    // Member colouring range.
    double value(Station3D st) => switch (colorBy) {
      MemberValue.my => st.my.abs(),
      MemberValue.mz => st.mz.abs(),
      MemberValue.n => st.n.abs(),
      MemberValue.none => 0,
    };
    var vMax = 0.0;
    if (r != null && colorBy != MemberValue.none) {
      for (final m in r.members) {
        for (final st in m.stations) {
          vMax = math.max(vMax, value(st));
        }
      }
    }

    // Undeformed model as a ghost when showing deformation.
    final deformed = defScale != 0;
    final segments = <(Offset, Offset, double, Color, double)>[];
    for (var e = 0; e < model.elements.length; e++) {
      final el = model.elements[e];
      final a = nodes[el.n1], b = nodes[el.n2];
      final (pa, da) = project(a.x, a.y, a.z);
      final (pb, db) = project(b.x, b.y, b.z);
      if (deformed || vMax > 0) {
        segments.add((pa, pb, (da + db) / 2, c.ghost, 1));
      }
      if (r != null && (deformed || vMax > 0)) {
        final st = r.members[e].stations;
        final l = st.last.x;
        for (var k = 0; k < st.length - 1; k++) {
          Offset at(int i) {
            final t = l == 0 ? 0.0 : st[i].x / l;
            final x = a.x + (b.x - a.x) * t + st[i].disp[0] * defScale;
            final y = a.y + (b.y - a.y) * t + st[i].disp[1] * defScale;
            final z = a.z + (b.z - a.z) * t + st[i].disp[2] * defScale;
            return project(x, y, z).$1;
          }

          final color = vMax > 0
              ? heat((value(st[k]) + value(st[k + 1])) / 2 / vMax)
              : c.member;
          segments.add((at(k), at(k + 1), (da + db) / 2 - 1e-6, color, 2.4));
        }
      } else if (s != null && deformed) {
        Offset at(Node3D n, int i) => project(
          n.x + s[i][0] * defScale,
          n.y + s[i][1] * defScale,
          n.z + s[i][2] * defScale,
        ).$1;
        segments.add((
          at(a, el.n1),
          at(b, el.n2),
          (da + db) / 2 - 1e-6,
          c.support,
          2.4,
        ));
      } else {
        segments.add((pa, pb, (da + db) / 2, c.member, 1.8));
      }
    }

    // Far to near, with depth fading.
    segments.sort((p, q) => q.$3.compareTo(p.$3));
    final depthRange = radius * 2;
    for (final (p, q, depth, color, width) in segments) {
      final fade = (0.45 + 0.55 * (1 - (depth + radius) / depthRange)).clamp(
        0.35,
        1.0,
      );
      canvas.drawLine(
        p,
        q,
        Paint()
          ..color = color.withValues(alpha: color.a * fade)
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    // Supports.
    final sp2 = Paint()..color = c.support;
    for (final n in model.supports.keys) {
      if (n < 0 || n >= nodes.length) continue;
      final (p, _) = project(nodes[n].x, nodes[n].y, nodes[n].z);
      canvas.drawRect(Rect.fromCenter(center: p, width: 7, height: 7), sp2);
    }

    // Axis triad.
    final origin = Offset(34, size.height - 30);
    void axis(double x, double y, double z, Color color, String label) {
      final x1 = x * cyw - y * syw;
      final y1 = x * syw + y * cyw;
      final up = z * cp + y1 * sp;
      final tip = origin + Offset(x1 * 22, -up * 22);
      canvas.drawLine(
        origin,
        tip,
        Paint()
          ..color = color
          ..strokeWidth = 2,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            fontFamily: AppTheme.monoFamily,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, tip + Offset(-tp.width / 2, -tp.height / 2) * 1.6);
    }

    axis(1, 0, 0, c.axisX, 'X');
    axis(0, 1, 0, c.axisY, 'Y');
    axis(0, 0, 1, c.axisZ, 'Z');

    // Colour legend.
    if (vMax > 0) {
      const w = 110.0, h = 8.0;
      final left = size.width - w - 12, top = 12.0;
      final rect = Rect.fromLTWH(left, top, w, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()
          ..shader = LinearGradient(
            colors: [for (var i = 0; i <= 3; i++) heat(i / 3)],
          ).createShader(rect),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '0 … ${vMax.toStringAsFixed(vMax < 10 ? 2 : 0)}',
          style: TextStyle(
            color: c.ink,
            fontSize: 10,
            fontFamily: AppTheme.monoFamily,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(left, top + h + 3));
    }
  }

  @override
  bool shouldRepaint(_FramePainter o) => true;
}
