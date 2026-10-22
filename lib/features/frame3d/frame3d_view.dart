import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// What the viewer colours the members by.
enum MemberValue { none, my, mz, n, utilisation }

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

/// Orientation of a working plane: a level (Z = value), a front plane
/// (Y = value) or a side plane (X = value).
enum PlaneAxis { z, y, x }

/// Plane on which taps place nodes, snapped to a square grid.
class WorkPlane {
  final PlaneAxis axis;
  final double value;
  final double step;
  const WorkPlane(this.axis, this.value, {this.step = 1});

  /// The point of the plane nearest to [p] on the grid.
  Node3D snap(Node3D p) {
    double s(double v) => (v / step).round() * step;
    return switch (axis) {
      PlaneAxis.z => Node3D(s(p.x), s(p.y), value),
      PlaneAxis.y => Node3D(s(p.x), value, s(p.z)),
      PlaneAxis.x => Node3D(value, s(p.y), s(p.z)),
    };
  }

  /// Grid rectangle (in-plane coordinates u, v) covering the model's
  /// nodes with a margin, at least 10 m × 10 m from the origin.
  (double, double, double, double) extent(Model3D m) {
    var u0 = 0.0, u1 = 10.0, v0 = 0.0, v1 = 10.0;
    for (final n in m.nodes) {
      final (u, v) = coords(n);
      u0 = math.min(u0, u - 2 * step);
      u1 = math.max(u1, u + 2 * step);
      v0 = math.min(v0, v - 2 * step);
      v1 = math.max(v1, v + 2 * step);
    }
    double down(double x) => (x / step).floor() * step;
    double up(double x) => (x / step).ceil() * step;
    return (down(u0), up(u1), down(v0), up(v1));
  }

  (double, double) coords(Node3D n) => switch (axis) {
    PlaneAxis.z => (n.x, n.y),
    PlaneAxis.y => (n.x, n.z),
    PlaneAxis.x => (n.y, n.z),
  };

  Node3D point(double u, double v) => switch (axis) {
    PlaneAxis.z => Node3D(u, v, value),
    PlaneAxis.y => Node3D(u, value, v),
    PlaneAxis.x => Node3D(value, u, v),
  };
}

/// Standard camera orientations.
enum ViewPreset { iso, top, front, side }

/// Lets a parent turn the camera of a [Frame3DView] to a preset.
class ViewCamera extends ChangeNotifier {
  ViewPreset preset = ViewPreset.iso;
  void show(ViewPreset p) {
    preset = p;
    notifyListeners();
  }
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

  /// Per-member values for [MemberValue.utilisation] (null = not
  /// checked, drawn neutral); 1.0 is the limit.
  final List<double?>? memberValues;

  /// Editing aids: node dots and the loads of [loadCase].
  final bool showNodes;
  final int? loadCase;

  final int? selectedNode;
  final int? selectedMember;

  /// First node while connecting a new member.
  final int? pendingNode;
  final ValueChanged<Pick3D?>? onPick;

  /// Multi-selection highlights.
  final Set<int> selectedNodes;
  final Set<int> selectedMembers;

  /// Working plane drawn as a grid; taps away from nodes call
  /// [onPlaneTap] with the snapped point.
  final WorkPlane? workPlane;
  final ValueChanged<Node3D>? onPlaneTap;
  final ViewCamera? camera;

  const Frame3DView({
    super.key,
    required this.model,
    this.result,
    this.shape,
    this.animate = false,
    this.colorBy = MemberValue.none,
    this.memberValues,
    this.showNodes = false,
    this.loadCase,
    this.selectedNode,
    this.selectedMember,
    this.pendingNode,
    this.onPick,
    this.selectedNodes = const {},
    this.selectedMembers = const {},
    this.workPlane,
    this.onPlaneTap,
    this.camera,
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
    Offset pan, [
    List<Node3D> extra = const [],
  ]) {
    final (cx, cy, cz, r) = _bounds([...m.nodes, ...extra]);
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

  static (double, double, double, double) _bounds(List<Node3D> nodes) {
    if (nodes.isEmpty) return (0, 0, 0, 1);
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

  /// The point of the plane under screen point [p] (null when the plane
  /// is seen edge-on).
  Node3D? unproject(Offset p, PlaneAxis axis, double value) {
    final x1 = (p.dx - centre.dx) / scale;
    final up = -(p.dy - centre.dy) / scale;
    // Screen (x1, up) and depth d back to model coordinates.
    final double d;
    switch (axis) {
      case PlaneAxis.z:
        if (sp.abs() < 0.05) return null;
        d = (up * cp - (value - cz)) / sp;
      case PlaneAxis.y:
        final den = cp * cyw;
        if (den.abs() < 0.05) return null;
        d = ((value - cy) + x1 * syw - up * sp * cyw) / den;
      case PlaneAxis.x:
        final den = cp * syw;
        if (den.abs() < 0.05) return null;
        d = ((value - cx) - x1 * cyw - up * sp * syw) / den;
    }
    final y1 = up * sp + d * cp;
    final pz = up * cp - d * sp;
    final px = x1 * cyw + y1 * syw;
    final py = -x1 * syw + y1 * cyw;
    return Node3D(cx + px, cy + py, cz + pz);
  }

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
    widget.camera?.addListener(_applyPreset);
  }

  @override
  void didUpdateWidget(Frame3DView old) {
    super.didUpdateWidget(old);
    _syncAnimation();
    if (old.camera != widget.camera) {
      old.camera?.removeListener(_applyPreset);
      widget.camera?.addListener(_applyPreset);
    }
  }

  void _applyPreset() {
    final p = widget.camera?.preset;
    if (p == null) return;
    setState(() {
      final (yaw, pitch) = switch (p) {
        ViewPreset.iso => (_yaw0, _pitch0),
        ViewPreset.top => (0.0, math.pi / 2),
        ViewPreset.front => (0.0, 0.0),
        ViewPreset.side => (-math.pi / 2, 0.0),
      };
      _yaw = yaw;
      _pitch = pitch;
      _zoom = 1;
      _pan = Offset.zero;
    });
  }

  /// Corners of the working-plane grid, kept inside the framed volume.
  List<Node3D> get _extra {
    final w = widget.workPlane;
    if (w == null) return const [];
    final (u0, u1, v0, v1) = w.extent(widget.model);
    return [w.point(u0, v0), w.point(u1, v1)];
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
    widget.camera?.removeListener(_applyPreset);
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
    final pr = _Projector(
      widget.model,
      _size,
      _yaw,
      _pitch,
      _zoom,
      _pan,
      _extra,
    );
    final m = widget.model;
    // Nodes first (when shown), then the nearest member; while drawing,
    // a tap away from the nodes gives a point of the working plane.
    final plane = widget.workPlane, onPlane = widget.onPlaneTap;
    if (widget.showNodes || onPlane != null) {
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
    if (plane != null && onPlane != null) {
      final hit = pr.unproject(p, plane.axis, plane.value);
      if (hit != null) onPlane(plane.snap(hit));
      return;
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
            // While drawing, taps must act at once (no double-tap wait).
            onDoubleTap: widget.onPlaneTap == null ? _reset : null,
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
                    extra: _extra,
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
  final List<Node3D> extra;
  final double phase;
  final double yaw, pitch, zoom;
  final Offset pan;
  final _ViewColors c;

  _FramePainter({
    required this.view,
    this.extra = const [],
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
    final plane = view.workPlane;
    if (nodes.isEmpty && plane == null) return;
    final pr = _Projector(model, size, yaw, pitch, zoom, pan, extra);

    // Working-plane grid (thicker every 5 steps).
    if (plane != null) {
      final (u0, u1, v0, v1) = plane.extent(model);
      final thin = Paint()
        ..color = c.ghost.withValues(alpha: 0.45)
        ..strokeWidth = 0.6;
      final thick = Paint()
        ..color = c.ghost
        ..strokeWidth = 1.1;
      final st = plane.step;
      bool major(double v) => ((v / st).round() % 5) == 0;
      for (var u = u0; u <= u1 + 1e-9; u += st) {
        final a = plane.point(u, v0), b = plane.point(u, v1);
        canvas.drawLine(pr.node(a), pr.node(b), major(u) ? thick : thin);
      }
      for (var v = v0; v <= v1 + 1e-9; v += st) {
        final a = plane.point(u0, v), b = plane.point(u1, v);
        canvas.drawLine(pr.node(a), pr.node(b), major(v) ? thick : thin);
      }
    }
    if (nodes.isEmpty) return;
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
      MemberValue.none || MemberValue.utilisation => 0,
    };
    var vMax = 0.0;
    if (r != null && view.colorBy != MemberValue.none) {
      for (final m in r.members) {
        for (final st in m.stations) {
          vMax = math.max(vMax, value(st));
        }
      }
    }

    final util = view.colorBy == MemberValue.utilisation
        ? view.memberValues
        : null;
    final deformed = defScale != 0;
    final segments = <(Offset, Offset, double, Color, double)>[];
    for (var e = 0; e < model.elements.length; e++) {
      final el = model.elements[e];
      final a = nodes[el.n1], b = nodes[el.n2];
      final (pa, da) = pr.project(a.x, a.y, a.z);
      final (pb, db) = pr.project(b.x, b.y, b.z);
      final depth = (da + db) / 2;
      final selected =
          e == view.selectedMember || view.selectedMembers.contains(e);
      if (util != null) {
        final u = e < util.length ? util[e] : null;
        segments.add((
          pa,
          pb,
          depth,
          u == null ? c.ghost : heat(u.clamp(0.0, 1.0)),
          u == null ? 1.2 : (u > 1 ? 4.5 : 2.8),
        ));
        continue;
      }
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

    // Supports: filled for restraints, hollow for springs only.
    final supportPaint = Paint()..color = c.support;
    final springPaint = Paint()
      ..color = c.support
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final e in model.supports.entries) {
      final n = e.key;
      if (n < 0 || n >= nodes.length) continue;
      final rect = Rect.fromCenter(
        center: pr.node(nodes[n]),
        width: 8,
        height: 8,
      );
      canvas.drawRect(
        rect,
        e.value.dofs.any((d) => d) ? supportPaint : springPaint,
      );
    }

    // End releases (editing): a hollow ring near each released end.
    if (view.showNodes) {
      final ring = Paint()
        ..color = c.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3;
      for (final el in model.elements) {
        if (el.releases.isEmpty) continue;
        final a = pr.node(nodes[el.n1]), b = pr.node(nodes[el.n2]);
        final ab = b - a;
        if (ab.distance < 1) continue;
        final off = ab / ab.distance * math.min(10.0, ab.distance / 4);
        if (el.releases.any((d) => d < 6)) {
          canvas.drawCircle(a + off, 3.4, ring);
        }
        if (el.releases.any((d) => d >= 6)) {
          canvas.drawCircle(b - off, 3.4, ring);
        }
      }
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
      double memberLength(Element3D el) {
        final a = nodes[el.n1], b = nodes[el.n2];
        return math.sqrt(
          math.pow(b.x - a.x, 2) +
              math.pow(b.y - a.y, 2) +
              math.pow(b.z - a.z, 2),
        );
      }

      for (final p in c3.point) {
        if (p.local || p.element < 0 || p.element >= model.elements.length) {
          continue;
        }
        final el = model.elements[p.element];
        final a = nodes[el.n1], b = nodes[el.n2];
        final l = memberLength(el);
        final f = math.sqrt(p.fx * p.fx + p.fy * p.fy + p.fz * p.fz);
        if (f == 0 || l == 0) continue;
        final t = (p.a / l).clamp(0.0, 1.0);
        final tip = pr
            .project(
              a.x + (b.x - a.x) * t,
              a.y + (b.y - a.y) * t,
              a.z + (b.z - a.z) * t,
            )
            .$1;
        arrow(tip, pr.direction(p.fx / f, p.fy / f, p.fz / f, 26));
      }
      for (final q in c3.member) {
        if (q.local || q.element < 0 || q.element >= model.elements.length) {
          continue;
        }
        final el = model.elements[q.element];
        final a = nodes[el.n1], b = nodes[el.n2];
        final qx = q.qx + q.q2[0], qy = q.qy + q.q2[1], qz = q.qz + q.q2[2];
        final w = math.sqrt(qx * qx + qy * qy + qz * qz);
        if (w == 0) continue;
        final l = memberLength(el);
        final t0 = l == 0 ? 0.0 : (q.start / l).clamp(0.0, 1.0);
        final t1 = l == 0 ? 1.0 : ((q.end ?? l) / l).clamp(0.0, 1.0);
        for (final t in [
          t0 + (t1 - t0) * 0.2,
          (t0 + t1) / 2,
          t0 + (t1 - t0) * 0.8,
        ]) {
          final tip = pr
              .project(
                a.x + (b.x - a.x) * t,
                a.y + (b.y - a.y) * t,
                a.z + (b.z - a.z) * t,
              )
              .$1;
          arrow(tip, pr.direction(qx / w, qy / w, qz / w, 14));
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
    for (final i in [
      view.selectedNode,
      view.pendingNode,
      ...view.selectedNodes,
    ]) {
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

    if (util != null) vMax = 1;
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
