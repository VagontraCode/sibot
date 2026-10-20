import 'dart:math' as math;

import 'materials.dart';

/// Point on an N–M interaction curve: N in kN (compression positive),
/// M in kN·m.
class NMPoint {
  final double n;
  final double m;
  const NMPoint(this.n, this.m);
}

/// Concrete outline seen in the bending direction: [depth] is measured
/// from the most compressed fibre.
abstract class ConcreteShape {
  double get depth;
  double get area;

  /// Area (mm²) of the part within [a] mm of the compressed fibre and the
  /// distance (mm) of its centroid from that fibre.
  (double, double) compressed(double a);
}

class RectShape implements ConcreteShape {
  /// Width perpendicular to the bending direction and depth along it, mm.
  final double width;
  @override
  final double depth;

  const RectShape(this.width, this.depth);

  @override
  double get area => width * depth;

  @override
  (double, double) compressed(double a) {
    final c = a.clamp(0.0, depth);
    return (width * c, c / 2);
  }
}

class CircleShape implements ConcreteShape {
  final double diameter;
  const CircleShape(this.diameter);

  @override
  double get depth => diameter;

  @override
  double get area => math.pi * diameter * diameter / 4;

  /// Circular segment of height a.
  @override
  (double, double) compressed(double a) {
    final r = diameter / 2;
    if (a <= 0) return (0, 0);
    if (a >= diameter) return (area, r);
    final theta = 2 * math.acos((r - a) / r);
    final segment = r * r * (theta - math.sin(theta)) / 2;
    final fromCentre =
        4 *
        r *
        math.pow(math.sin(theta / 2), 3) /
        (3 * (theta - math.sin(theta)));
    return (segment, r - fromCentre);
  }
}

/// A bar (or bar group) at distance [y] from the compressed fibre.
class SectionBar {
  final double y;
  final double area;
  const SectionBar(this.y, this.area);
}

/// Reinforced section under axial force and uniaxial bending.
///
/// Strain compatibility with the rectangular block over 0.8·x at fc,
/// elastic–plastic steel. Pivot B (εcu = 3.5‰ at the compressed fibre)
/// while x ≤ depth; pivot C (2‰ at 3/7 of the depth) once the section is
/// fully compressed (EC2 6.1(5), BAEL A.4.3.3). The steel strain limit of
/// pivot A is not applied, which only affects sections in tension.
/// Moments are taken about mid-depth.
class SectionNM {
  final ConcreteShape shape;
  final List<SectionBar> bars;
  final double fc;
  final double fyd;

  SectionNM({
    required this.shape,
    required this.bars,
    required this.fc,
    required this.fyd,
  });

  static const _epsC2 = 0.002;

  double get _h => shape.depth;

  double _strainAt(double x, double y) {
    if (x <= _h) return Concrete.epsCu * (x - y) / x;
    final yc = (1 - _epsC2 / Concrete.epsCu) * _h;
    return _epsC2 * (x - y) / (x - yc);
  }

  double _steel(double eps) =>
      (RebarSteel.es * eps).clamp(-fyd, fyd).toDouble();

  /// (N, M) for neutral-axis depth x (mm), in N and N·mm.
  (double, double) forces(double x) {
    final (ac, yc) = shape.compressed(math.min(0.8 * x, _h));
    var n = fc * ac;
    var m = n * (_h / 2 - yc);
    for (final b in bars) {
      final f = b.area * _steel(_strainAt(x, b.y));
      n += f;
      m += f * (_h / 2 - b.y);
    }
    return (n, m);
  }

  double get steelArea => bars.fold(0.0, (s, b) => s + b.area);

  /// Maximum axial resistance (whole section at 2‰), kN.
  double get nMax => (fc * shape.area + steelArea * _steel(_epsC2)) / 1e3;

  /// Interaction curve from small x to full compression.
  List<NMPoint> curve({int steps = 60}) {
    final pts = <NMPoint>[];
    for (var i = 0; i <= steps; i++) {
      final x = 0.02 * _h * math.pow(1000, i / steps);
      final (n, m) = forces(x);
      pts.add(NMPoint(n / 1e3, m / 1e6));
    }
    pts.add(NMPoint(nMax, 0));
    return pts;
  }

  /// Moment resistance (kN·m) at axial load [nEd] (kN, compression +),
  /// or null when nEd is outside the curve.
  double? momentResistance(double nEd) {
    final target = nEd * 1e3;
    double lo = 0.01 * _h, hi = 50 * _h;
    if (target < forces(lo).$1) return null;
    if (target > nMax * 1e3) return null;
    final (nHi, mHi) = forces(hi);
    if (target > nHi) {
      final t = (target - nHi) / (nMax * 1e3 - nHi);
      return mHi * (1 - t) / 1e6;
    }
    for (var k = 0; k < 80; k++) {
      final mid = 0.5 * (lo + hi);
      if (forces(mid).$1 < target) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return forces(0.5 * (lo + hi)).$2 / 1e6;
  }
}

/// Rectangular section b × h (mm) with two symmetric steel layers of
/// [asPerFace] mm² each at [d2] mm from the faces.
class RectSectionNM extends SectionNM {
  RectSectionNM({
    required double b,
    required double h,
    required double d2,
    required double asPerFace,
    required super.fc,
    required super.fyd,
  }) : super(
         shape: RectShape(b, h),
         bars: [SectionBar(d2, asPerFace), SectionBar(h - d2, asPerFace)],
       );
}
