import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// What the viewer colours the members by.
enum MemberValue { none, my, mz, n }

/// A tapped node or member.
sealed class Pick3D {
  const Pick3D();
}

class NodePick extends Pick3D {
  final int node;
  const NodePick(this.node);
}

class MemberPick extends Pick3D {
  final int member;
  const MemberPick(this.member);
}

/// Interactive orthographic view of a space frame: drag to orbit, pinch
/// (or scroll) to zoom, two fingers to pan, double-tap to reset, tap to
/// pick a node or a member.
class Frame3DView extends StatefulWidget {
  final Model3D model;

  /// Static result: deformed shape along the members and colours.
  final Frame3DResult? result;

  /// Node shape (6 values per node) drawn with straight members, e.g. a
  /// mode or buckling shape; animated when [animate] is true.
  final List<List<double>>? shape;
  final bool animate;
  final MemberValue colorBy;

  /// Editing aids: node dots and the loads of [loadCase].
  final bool showNodes;
  final int? loadCase;

  final int? selectedNode;
  final int? selectedMember;

  /// First node while connecting a new member.
  final int? pendingNode;
  final ValueChanged<Pick3D?>? onPick;

  const Frame3DView({
    super.key,
    required this.model,
    this.result,
    this.shape,
    this.animate = false,
    this.colorBy = MemberValue.none,
    this.showNodes = false,
    this.loadCase,
    this.selectedNode,
    this.selectedMember,
    this.pendingNode,
    this.onPick,
  });

  @override
  State<Frame3DView> createState() => _Frame3DViewState();
}

/// Orthographic camera fitted to the model.
class _Projector {
  final double cx, cy, cz, radius, scale;
  final Offset centre;
  final double cyw, syw, cp, sp;

  factory _Projector(
    Model3D m,
    Size size,
    double yaw,
    double pitch,
    double zoom,
    Offset pan,
  ) {
    final (cx, cy, cz, r) = _bounds(m);
    return _Projector._(
      cx,
      cy,
      cz,
      r,
      math.min(size.width, size.height) / (2.3 * r) * zoom,
      size.center(Offset.zero) + pan,
      math.cos(yaw),
      math.sin(yaw),
      math.cos(pitch),
      math.sin(pitch),
    );
  }

  _Projector._(
    this.cx,
    this.cy,
    this.cz,
    this.radius,
    this.scale,
    this.centre,
    this.cyw,
    this.syw,
    this.cp,
    this.sp,
  );

  static (double, double, double, double) _bounds(Model3D m) {
    if (m.nodes.isEmpty) return (0, 0, 0, 1);
    var minX = double.infinity, minY = minX, minZ = minX;
    var maxX = -double.infinity, maxY = maxX, maxZ = maxX;
    for (final n in m.nodes) {
      minX = math.min(minX, n.x);
      maxX = math.max(maxX, n.x);
      minY = math.min(minY, n.y);
      maxY = math.max(maxY, n.y);
      minZ = math.min(minZ, n.z);
      maxZ = math.max(maxZ, n.z);
    }
    final r = math.max(
      0.5,
      math.sqrt(
            math.pow(maxX - minX, 2) +
                math.pow(maxY - minY, 2) +
                math.pow(maxZ - minZ, 2),
          ) /
          2,
    );
    return ((minX + maxX) / 2, (minY + maxY) / 2, (minZ + maxZ) / 2, r);
  }

  /// Screen point and depth (larger = farther).
  (Offset, double) project(double x, double y, double z) {
    final px = x - cx, py = y - cy, pz = z - cz;
    final x1 = px * cyw - py * syw;
    final y1 = px * syw + py * cyw;
    final up = pz * cp + y1 * sp;
    final depth = y1 * cp - pz * sp;
    return (centre + Offset(x1 * scale, -up * scale), depth);
  }

  Offset node(Node3D n) => project(n.x, n.y, n.z).$1;

  /// Screen image of a global direction, [len] pixels per unit.
  Offset direction(double x, double y, double z, double len) {
    final x1 = x * cyw - y * syw;
    final y1 = x * syw + y * cyw;
    final up = z * cp + y1 * sp;
    return Offset(x1, -up) * len;
  }
}

class _Frame3DViewState extends State<Frame3DView>
    with SingleTickerProviderStateMixin {
  static const _yaw0 = -0.65, _pitch0 = 0.45;
  double _yaw = _yaw0, _pitch = _pitch0, _zoom = 1;
  Offset _pan = Offset.zero;
  double _scaleStart = 1;
  Size _size = Size.zero;
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

  void _tap(Offset p) {
    final onPick = widget.onPick;
    if (onPick == null) return;
    final pr = _Projector(widget.model, _size, _yaw, _pitch, _zoom, _pan);
    final m = widget.model;
    // Nodes first (when shown), then the nearest member.
    if (widget.showNodes) {
      var best = -1;
      var bestD = 22.0;
      for (var i = 0; i < m.nodes.length; i++) {
        final d = (pr.node(m.nodes[i]) - p).distance;
        if (d < bestD) {
          bestD = d;
          best = i;
        }
      }
      if (best >= 0) {
        onPick(NodePick(best));
        return;
      }
    }
    var best = -1;
    var bestD = 18.0;
    for (var e = 0; e < m.elements.length; e++) {
      final a = pr.node(m.nodes[m.elements[e].n1]);
      final b = pr.node(m.nodes[m.elements[e].n2]);
      final ab = b - a;
      final len2 = ab.distanceSquared;
      final ap = p - a;
      final t = len2 == 0
          ? 0.0
          : ((ap.dx * ab.dx + ap.dy * ab.dy) / len2).clamp(0.0, 1.0);
      final d = (a + ab * t - p).distance;
      if (d < bestD) {
        bestD = d;
        best = e;
      }
    }
    onPick(best >= 0 ? MemberPick(best) : null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = _ViewColors(context);
    return LayoutBuilder(
      builder: (context, box) {
        _size = box.biggest;
        return Listener(
          onPointerSignal: (e) {
            if (e is PointerScrollEvent) {
              setState(() {
                _zoom = (_zoom * (e.scrollDelta.dy > 0 ? 0.9 : 1.1)).clamp(
                  0.2,
                  20,
                );
              });
            }
          },
          child: GestureDetector(
            onDoubleTap: _reset,
            onTapUp: (d) => _tap(d.localPosition),
            onScaleStart: (_) => _scaleStart = _zoom,
            onScaleUpdate: (d) => setState(() {
              if (d.pointerCount == 1) {
                _yaw += d.focalPointDelta.dx * 0.01;
                _pitch = (_pitch + d.focalPointDelta.dy * 0.01).clamp(
                  -1.5,
                  1.5,
                );
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
                    view: widget,
                    phase: widget.animate
                        ? math.cos(_anim.value * 2 * math.pi)
                        : 1,
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
      },
    );
  }
}

class _ViewColors {
  final Color member, ghost, support, select, load, axisX, axisY, axisZ, ink;
  _ViewColors(BuildContext c)
    : member = c.colors.onSurface,
      ghost = c.colors.outlineVariant,
      support = c.colors.primary,
      select = c.colors.tertiary,
      load = c.appColors.danger,
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
  final Frame3DView view;
  final double phase;
  final double yaw, pitch, zoom;
  final Offset pan;
  final _ViewColors c;

  _FramePainter({
    required this.view,
    required this.phase,
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required this.pan,
    required this.c,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final model = view.model;
    final nodes = model.nodes;
    if (nodes.isEmpty) return;
    final pr = _Projector(model, size, yaw, pitch, zoom, pan);
    final radius = pr.radius;
    final r = view.result, s = view.shape;

    // Deformation scale: largest displacement drawn at 16 % of the radius.
    double maxDisp = 0;
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

    double value(Station3D st) => switch (view.colorBy) {
      MemberValue.my => st.my.abs(),
      MemberValue.mz => st.mz.abs(),
      MemberValue.n => st.n.abs(),
      MemberValue.none => 0,
    };
    var vMax = 0.0;
    if (r != null && view.colorBy != MemberValue.none) {
      for (final m in r.members) {
        for (final st in m.stations) {
          vMax = math.max(vMax, value(st));
        }
      }
    }

    final deformed = defScale != 0;
    final segments = <(Offset, Offset, double, Color, double)>[];
    for (var e = 0; e < model.elements.length; e++) {
      final el = model.elements[e];
      final a = nodes[el.n1], b = nodes[el.n2];
      final (pa, da) = pr.project(a.x, a.y, a.z);
      final (pb, db) = pr.project(b.x, b.y, b.z);
      final depth = (da + db) / 2;
      final selected = e == view.selectedMember;
      if (deformed || vMax > 0) {
        segments.add((
          pa,
          pb,
          depth,
          selected ? c.select : c.ghost,
          selected ? 3.0 : 1.0,
        ));
      }
      if (r != null && e < r.members.length && (deformed || vMax > 0)) {
        final st = r.members[e].stations;
        final l = st.last.x;
        for (var k = 0; k < st.length - 1; k++) {
          Offset at(int i) {
            final t = l == 0 ? 0.0 : st[i].x / l;
            return pr
                .project(
                  a.x + (b.x - a.x) * t + st[i].disp[0] * defScale,
                  a.y + (b.y - a.y) * t + st[i].disp[1] * defScale,
                  a.z + (b.z - a.z) * t + st[i].disp[2] * defScale,
                )
                .$1;
          }

          final color = vMax > 0
              ? heat((value(st[k]) + value(st[k + 1])) / 2 / vMax)
              : c.member;
          segments.add((at(k), at(k + 1), depth - 1e-6, color, 2.4));
        }
      } else if (s != null && deformed) {
        Offset at(Node3D n, int i) => pr
            .project(
              n.x + s[i][0] * defScale,
              n.y + s[i][1] * defScale,
              n.z + s[i][2] * defScale,
            )
            .$1;
        segments.add((
          at(a, el.n1),
          at(b, el.n2),
          depth - 1e-6,
          c.support,
          2.4,
        ));
      } else {
        segments.add((
          pa,
          pb,
          depth,
          selected ? c.select : c.member,
          selected ? 4.0 : 1.8,
        ));
      }
    }

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
    final supportPaint = Paint()..color = c.support;
    for (final n in model.supports.keys) {
      if (n < 0 || n >= nodes.length) continue;
      canvas.drawRect(
        Rect.fromCenter(center: pr.node(nodes[n]), width: 7, height: 7),
        supportPaint,
      );
    }

    // Loads of the edited case: arrows for nodal forces and global
    // member loads.
    final lc = view.loadCase;
    if (lc != null && lc >= 0 && lc < model.cases.length) {
      final loadPaint = Paint()
        ..color = c.load
        ..strokeWidth = 1.6;
      void arrow(Offset tip, Offset dir) {
        canvas.drawLine(tip - dir, tip, loadPaint);
        final len = dir.distance;
        if (len == 0) return;
        final n = dir / len;
        final side = Offset(-n.dy, n.dx);
        final b1 = tip - n * 6 + side * 3, b2 = tip - n * 6 - side * 3;
        canvas.drawPath(
          Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(b1.dx, b1.dy)
            ..lineTo(b2.dx, b2.dy)
            ..close(),
          Paint()..color = c.load,
        );
      }

      final c3 = model.cases[lc];
      for (final p in c3.nodal) {
        if (p.node < 0 || p.node >= nodes.length) continue;
        final f = math.sqrt(p.fx * p.fx + p.fy * p.fy + p.fz * p.fz);
        if (f == 0) continue;
        arrow(
          pr.node(nodes[p.node]),
          pr.direction(p.fx / f, p.fy / f, p.fz / f, 28),
        );
      }
      for (final q in c3.member) {
        if (q.local || q.element < 0 || q.element >= model.elements.length) {
          continue;
        }
        final el = model.elements[q.element];
        final a = nodes[el.n1], b = nodes[el.n2];
        final w = math.sqrt(q.qx * q.qx + q.qy * q.qy + q.qz * q.qz);
        if (w == 0) continue;
        for (final t in const [0.25, 0.5, 0.75]) {
          final tip = pr
              .project(
                a.x + (b.x - a.x) * t,
                a.y + (b.y - a.y) * t,
                a.z + (b.z - a.z) * t,
              )
              .$1;
          arrow(tip, pr.direction(q.qx / w, q.qy / w, q.qz / w, 14));
        }
      }
    }

    // Nodes (editing) and selection rings.
    if (view.showNodes) {
      final dot = Paint()..color = c.ink;
      for (final n in nodes) {
        canvas.drawCircle(pr.node(n), 2.6, dot);
      }
    }
    for (final i in [view.selectedNode, view.pendingNode]) {
      if (i == null || i < 0 || i >= nodes.length) continue;
      canvas.drawCircle(
        pr.node(nodes[i]),
        7,
        Paint()
          ..color = c.select
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
    }

    // Axis triad.
    final origin = Offset(34, size.height - 30);
    void axis(double x, double y, double z, Color color, String label) {
      final tip = origin + pr.direction(x, y, z, 22);
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
