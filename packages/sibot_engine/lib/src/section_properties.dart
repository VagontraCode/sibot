import 'dart:math' as math;

import 'core.dart';

/// Cross-section types handled by [sectionProperties]. Dimensions in mm.
sealed class SectionShape {
  const SectionShape();
}

class RectangleSection extends SectionShape {
  final double b, h;
  const RectangleSection(this.b, this.h);
}

class CircleSection extends SectionShape {
  final double d;
  const CircleSection(this.d);
}

/// Hollow rectangle with uniform wall thickness [t].
class HollowRectangleSection extends SectionShape {
  final double b, h, t;
  const HollowRectangleSection(this.b, this.h, this.t);
}

/// Doubly symmetric I-section.
class ISection extends SectionShape {
  final double b, h, tf, tw;
  const ISection({
    required this.b,
    required this.h,
    required this.tf,
    required this.tw,
  });
}

/// T-section: flange b × tf on top of a web tw.
class TSection extends SectionShape {
  final double b, h, tf, tw;
  const TSection({
    required this.b,
    required this.h,
    required this.tf,
    required this.tw,
  });
}

class SectionProperties {
  /// Area (mm²), centroid depth from the top fibre (mm), overall depth.
  final double area;
  final double centroid;
  final double depth;

  /// Second moments about the horizontal (y) and vertical (z) centroidal
  /// axes, mm⁴.
  final double iy;
  final double iz;

  /// Elastic moduli to the top and bottom fibres (mm³) and plastic
  /// modulus about y (mm³).
  final double welTop;
  final double welBottom;
  final double wpl;

  const SectionProperties({
    required this.area,
    required this.centroid,
    required this.depth,
    required this.iy,
    required this.iz,
    required this.welTop,
    required this.welBottom,
    required this.wpl,
  });

  /// Radii of gyration, mm.
  double get iRadiusY => math.sqrt(iy / area);
  double get iRadiusZ => math.sqrt(iz / area);
}

/// Rectangle of width [w] between depths [y0] and [y1] from the top,
/// centred on the vertical axis; [sign] = −1 for holes.
class _Rect {
  final double w, y0, y1, sign;
  const _Rect(this.w, this.y0, this.y1, [this.sign = 1]);
  double get a => sign * w * (y1 - y0);
  double get yc => (y0 + y1) / 2;
  double get iOwn => sign * w * math.pow(y1 - y0, 3) / 12;
  double get izOwn => sign * (y1 - y0) * math.pow(w, 3) / 12;
}

SectionProperties sectionProperties(SectionShape s) {
  switch (s) {
    case CircleSection(:final d):
      requirePositive(d, 'd');
      final i = math.pi * math.pow(d, 4) / 64;
      return SectionProperties(
        area: math.pi * d * d / 4,
        centroid: d / 2,
        depth: d,
        iy: i,
        iz: i,
        welTop: i / (d / 2),
        welBottom: i / (d / 2),
        wpl: math.pow(d, 3) / 6,
      );
    case RectangleSection(:final b, :final h):
      requirePositive(b, 'b');
      requirePositive(h, 'h');
      return _fromRects([_Rect(b, 0, h)], h);
    case HollowRectangleSection(:final b, :final h, :final t):
      requirePositive(b, 'b');
      requirePositive(h, 'h');
      requirePositive(t, 't');
      if (2 * t >= math.min(b, h)) {
        throw const InputError(InputProblem.inconsistentGeometry, 't');
      }
      return _fromRects([_Rect(b, 0, h), _Rect(b - 2 * t, t, h - t, -1)], h);
    case ISection(:final b, :final h, :final tf, :final tw):
      for (final (v, f) in [(b, 'b'), (h, 'h'), (tf, 'tf'), (tw, 'tw')]) {
        requirePositive(v, f);
      }
      if (2 * tf >= h || tw > b) {
        throw const InputError(InputProblem.inconsistentGeometry, 'tf');
      }
      return _fromRects([
        _Rect(b, 0, tf),
        _Rect(tw, tf, h - tf),
        _Rect(b, h - tf, h),
      ], h);
    case TSection(:final b, :final h, :final tf, :final tw):
      for (final (v, f) in [(b, 'b'), (h, 'h'), (tf, 'tf'), (tw, 'tw')]) {
        requirePositive(v, f);
      }
      if (tf >= h || tw > b) {
        throw const InputError(InputProblem.inconsistentGeometry, 'tf');
      }
      return _fromRects([_Rect(b, 0, tf), _Rect(tw, tf, h)], h);
  }
}

SectionProperties _fromRects(List<_Rect> rects, double h) {
  final area = rects.fold(0.0, (s, r) => s + r.a);
  final yc = rects.fold(0.0, (s, r) => s + r.a * r.yc) / area;
  final iy = rects.fold(
    0.0,
    (s, r) => s + r.iOwn + r.a * math.pow(r.yc - yc, 2),
  );
  final iz = rects.fold(0.0, (s, r) => s + r.izOwn);

  // Plastic neutral axis: equal areas above and below (bisection).
  double areaAbove(double y) => rects.fold(0.0, (s, r) {
    final top = r.y0, bottom = math.min(r.y1, y);
    return bottom > top ? s + r.sign * r.w * (bottom - top) : s;
  });
  double lo = 0, hi = h;
  for (var k = 0; k < 100; k++) {
    final mid = 0.5 * (lo + hi);
    if (areaAbove(mid) < area / 2) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  final pna = 0.5 * (lo + hi);
  // First moments of the parts above and below the PNA.
  var wpl = 0.0;
  for (final r in rects) {
    for (final (a, b) in [
      (r.y0, math.min(r.y1, pna)),
      (math.max(r.y0, pna), r.y1),
    ]) {
      if (b > a) {
        wpl += r.sign * r.w * (b - a) * ((a + b) / 2 - pna).abs();
      }
    }
  }

  return SectionProperties(
    area: area,
    centroid: yc,
    depth: h,
    iy: iy,
    iz: iz,
    welTop: iy / yc,
    welBottom: iy / (h - yc),
    wpl: wpl,
  );
}
