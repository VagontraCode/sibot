import 'dart:math' as math;

import 'materials.dart';

/// Point on an N–M interaction curve: N in kN (compression positive),
/// M in kN·m.
class NMPoint {
  final double n;
  final double m;
  const NMPoint(this.n, this.m);
}

/// Rectangular section b × h (mm) with two symmetric steel layers of
/// [asPerFace] mm² each at [d2] mm from the faces, bending about the
/// axis parallel to b.
///
/// Strain compatibility with the rectangular block over 0.8·x at fc,
/// elastic–plastic steel. Pivot B (εcu = 3.5‰ at the compressed face)
/// while x ≤ h; pivot C (2‰ at 3h/7) once the whole section is in
/// compression (EC2 6.1(5), BAEL A.4.3.3).
class RectSectionNM {
  final double b;
  final double h;
  final double d2;
  final double asPerFace;
  final double fc;
  final double fyd;

  RectSectionNM({
    required this.b,
    required this.h,
    required this.d2,
    required this.asPerFace,
    required this.fc,
    required this.fyd,
  });

  static const _epsC2 = 0.002;

  double _strainAt(double x, double y) {
    if (x <= h) return Concrete.epsCu * (x - y) / x;
    final yc = (1 - _epsC2 / Concrete.epsCu) * h;
    return _epsC2 * (x - y) / (x - yc);
  }

  double _steel(double eps) =>
      (RebarSteel.es * eps).clamp(-fyd, fyd).toDouble();

  /// (N, M) for neutral-axis depth x (mm), in N and N·mm.
  (double, double) forces(double x) {
    final block = math.min(0.8 * x, h);
    var n = fc * b * block;
    var m = n * (h / 2 - block / 2);
    for (final y in [d2, h - d2]) {
      final f = asPerFace * _steel(_strainAt(x, y));
      n += f;
      m += f * (h / 2 - y);
    }
    return (n, m);
  }

  /// Maximum axial resistance (whole section at 2‰), kN.
  double get nMax {
    final sigma = _steel(_epsC2);
    return (fc * b * h + 2 * asPerFace * sigma) / 1e3;
  }

  /// Interaction curve from small x to full compression.
  List<NMPoint> curve({int steps = 60}) {
    final pts = <NMPoint>[];
    for (var i = 0; i <= steps; i++) {
      // Geometric spacing from 0.02h to 20h.
      final x = 0.02 * h * math.pow(1000, i / steps);
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
    double lo = 0.01 * h, hi = 50 * h;
    final (nLo, _) = forces(lo);
    if (target < nLo) return null;
    if (target > nMax * 1e3) return null;
    if (target > forces(hi).$1) {
      // Between the largest x tried and pure compression: interpolate.
      final (nHi, mHi) = forces(hi);
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
