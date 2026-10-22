import 'dart:math' as math;

import 'steel_sections.dart';

/// Properties common to every steel profile (mm-based units: mm², mm⁴,
/// mm³). y is the major axis.
abstract interface class SteelProfile {
  String get name;
  double get area;
  double get iy;
  double get iz;
  double get it;
  double get welY;
  double get welZ;
  double get wplY;
  double get wplZ;

  /// Mass per metre, kg/m.
  double get mass;
}

/// Second moment and plastic modulus about the horizontal axis of a
/// doubly symmetric shape given by its width at height y (|y| ≤ h/2),
/// by Simpson integration.
(double, double) _integrate(double h, double Function(double y) width) {
  const n = 4000;
  final dy = h / n;
  var i = 0.0, s = 0.0;
  for (var k = 0; k <= n; k++) {
    final y = -h / 2 + k * dy;
    final w = width(y);
    final c = k == 0 || k == n ? 1.0 : (k.isOdd ? 4.0 : 2.0);
    i += c * w * y * y;
    s += c * w * y.abs();
  }
  return (i * dy / 3, s * dy / 3);
}

/// Width at height y of a rounded rectangle b × h with corner radius r.
double _roundedWidth(double b, double h, double r, double y) {
  final a = y.abs();
  if (a > h / 2) return 0;
  if (a <= h / 2 - r) return b;
  final d = a - (h / 2 - r);
  return b - 2 * r + 2 * math.sqrt(math.max(0, r * r - d * d));
}

/// Hot-finished hollow section (EN 10210): circular (CHS, [b] = 0) or
/// rectangular (RHS/SHS) with outer corner radius 1.5 t, inner t.
class HollowSection implements SteelProfile {
  @override
  final String name;

  /// Outside depth h (CHS: diameter), width b (CHS: 0), thickness t, mm.
  final double h;
  final double b;
  final double t;

  late final double _iy, _iz, _wply, _wplz;

  HollowSection.circular(this.name, double d, this.t) : h = d, b = 0 {
    final di = d - 2 * t;
    _iy = _iz = math.pi * (math.pow(d, 4) - math.pow(di, 4)) / 64;
    _wply = _wplz = (math.pow(d, 3) - math.pow(di, 3)) / 6;
  }

  HollowSection.rectangular(this.name, this.h, this.b, this.t) {
    final ro = 1.5 * t, ri = t;
    double wy(double y) =>
        _roundedWidth(b, h, ro, y) - _roundedWidth(b - 2 * t, h - 2 * t, ri, y);
    double wz(double z) =>
        _roundedWidth(h, b, ro, z) - _roundedWidth(h - 2 * t, b - 2 * t, ri, z);
    final (iy, wply) = _integrate(h, wy);
    final (iz, wplz) = _integrate(b, wz);
    _iy = iy;
    _wply = wply;
    _iz = iz;
    _wplz = wplz;
  }

  bool get circular => b == 0;

  @override
  double get area => circular
      ? math.pi * (h * h - math.pow(h - 2 * t, 2)) / 4
      : 2 * t * (b + h - 2 * t) - (4 - math.pi) * (2.25 * t * t - t * t);

  @override
  double get iy => _iy;
  @override
  double get iz => _iz;
  @override
  double get welY => 2 * iy / h;
  @override
  double get welZ => 2 * iz / (circular ? h : b);
  @override
  double get wplY => _wply;
  @override
  double get wplZ => _wplz;

  /// Torsion constant: 2I for a tube, Bredt with rounded corners for
  /// rectangles (EN 10210-2 Annex B).
  @override
  double get it {
    if (circular) return 2 * iy;
    final rc = 1.25 * t;
    final am = (b - t) * (h - t) - rc * rc * (4 - math.pi);
    final p = 2 * ((b - t) + (h - t)) - 2 * rc * (4 - math.pi);
    return 4 * am * am * t / p;
  }

  /// Shear area parallel to the depth (EN 1993-1-1 6.2.6(3)).
  double get avz => circular ? 2 * area / math.pi : area * h / (b + h);

  double get iRadiusY => math.sqrt(iy / area);
  double get iRadiusZ => math.sqrt(iz / area);

  @override
  double get mass => area * 7850e-6;
}

/// Hot-rolled channel (UPN), parallel-flange approximation: properties
/// within about 2 % of the tables (tapered flanges ignored). For frame
/// analysis only.
class ChannelSection implements SteelProfile {
  @override
  final String name;
  final double h, b, tw, tf;
  ChannelSection(this.name, this.h, this.b, this.tw, this.tf);

  @override
  double get area => 2 * b * tf + (h - 2 * tf) * tw;
  @override
  double get iy => (b * h * h * h - (b - tw) * math.pow(h - 2 * tf, 3)) / 12;

  /// Distance of the centroid from the back of the web.
  double get e => (2 * b * tf * b / 2 + (h - 2 * tf) * tw * tw / 2) / area;

  @override
  double get iz {
    final web = (h - 2 * tf) * tw;
    return 2 * (tf * b * b * b / 12 + b * tf * math.pow(b / 2 - e, 2)) +
        (h - 2 * tf) * tw * tw * tw / 12 +
        web * math.pow(tw / 2 - e, 2);
  }

  @override
  double get it => (2 * b * math.pow(tf, 3) + (h - tf) * math.pow(tw, 3)) / 3;
  @override
  double get welY => 2 * iy / h;
  @override
  double get welZ => iz / (b - e);
  @override
  double get wplY => tw * math.pow(h - 2 * tf, 2) / 4 + b * tf * (h - tf);
  @override
  double get wplZ => welZ * 1.2;
  @override
  double get mass => area * 7850e-6;
}

/// Equal-leg angle b × t (root radius ignored), properties about the
/// axes parallel to the legs. For frame analysis (trusses) only.
class AngleSection implements SteelProfile {
  @override
  final String name;
  final double b, t;
  AngleSection(this.name, this.b, this.t);

  @override
  double get area => t * (2 * b - t);

  /// Centroid distance from the back of each leg.
  double get e => (b * t * t / 2 + (b - t) * t * (t + (b - t) / 2)) / area;

  @override
  double get iy {
    final l1 = b * t * t * t / 12 + b * t * math.pow(t / 2 - e, 2);
    final l2 =
        t * math.pow(b - t, 3) / 12 +
        (b - t) * t * math.pow(t + (b - t) / 2 - e, 2);
    return l1 + l2;
  }

  @override
  double get iz => iy;
  @override
  double get it => 2 * b * t * t * t / 3;
  @override
  double get welY => iy / (b - e);
  @override
  double get welZ => welY;
  @override
  double get wplY => welY * 1.5;
  @override
  double get wplZ => wplY;
  @override
  double get mass => area * 7850e-6;
}

const _hem = <(String, double, double, double, double, double)>[
  ('HEM 100', 120, 106, 12, 20, 12),
  ('HEM 120', 140, 126, 12.5, 21, 12),
  ('HEM 140', 160, 146, 13, 22, 12),
  ('HEM 160', 180, 166, 14, 23, 15),
  ('HEM 180', 200, 186, 14.5, 24, 15),
  ('HEM 200', 220, 206, 15, 25, 18),
  ('HEM 220', 240, 226, 15.5, 26, 18),
  ('HEM 240', 270, 248, 18, 32, 21),
  ('HEM 260', 290, 268, 18, 32.5, 24),
  ('HEM 280', 310, 288, 18.5, 33, 24),
  ('HEM 300', 340, 310, 21, 39, 27),
  ('HEM 320', 359, 309, 21, 40, 27),
  ('HEM 340', 377, 309, 21, 40, 27),
  ('HEM 360', 395, 308, 21, 40, 27),
  ('HEM 400', 432, 307, 21, 40, 27),
  ('HEM 450', 478, 307, 21, 40, 27),
  ('HEM 500', 524, 306, 21, 40, 27),
];

/// HEM profiles (I sections, EC3 design like IPE/HEA/HEB).
final Map<String, ISteelSection> hemSections = {
  for (final s in _hem) s.$1: ISteelSection(s.$1, s.$2, s.$3, s.$4, s.$5, s.$6),
};

String _n(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

final Map<String, HollowSection> hollowSections = {
  for (final (d, t) in const [
    (48.3, 3.2),
    (60.3, 4.0),
    (76.1, 4.0),
    (88.9, 5.0),
    (114.3, 5.0),
    (139.7, 6.3),
    (168.3, 8.0),
    (219.1, 8.0),
    (273.0, 10.0),
    (323.9, 10.0),
  ])
    'CHS ${_n(d)}×${_n(t)}': HollowSection.circular(
      'CHS ${_n(d)}×${_n(t)}',
      d,
      t,
    ),
  for (final (a, t) in const [
    (50.0, 4.0),
    (60.0, 4.0),
    (70.0, 5.0),
    (80.0, 5.0),
    (90.0, 6.3),
    (100.0, 5.0),
    (100.0, 6.3),
    (120.0, 6.3),
    (140.0, 8.0),
    (160.0, 8.0),
    (200.0, 10.0),
    (250.0, 10.0),
    (300.0, 12.5),
  ])
    'SHS ${_n(a)}×${_n(t)}': HollowSection.rectangular(
      'SHS ${_n(a)}×${_n(t)}',
      a,
      a,
      t,
    ),
  for (final (h, b, t) in const [
    (100.0, 50.0, 5.0),
    (120.0, 60.0, 5.0),
    (150.0, 100.0, 6.3),
    (160.0, 80.0, 6.3),
    (200.0, 100.0, 8.0),
    (250.0, 150.0, 10.0),
    (300.0, 200.0, 10.0),
  ])
    'RHS ${_n(h)}×${_n(b)}×${_n(t)}': HollowSection.rectangular(
      'RHS ${_n(h)}×${_n(b)}×${_n(t)}',
      h,
      b,
      t,
    ),
};

final Map<String, SteelProfile> _others = {
  for (final (n, h, b, tw, tf) in const [
    ('UPN 80', 80.0, 45.0, 6.0, 8.0),
    ('UPN 100', 100.0, 50.0, 6.0, 8.5),
    ('UPN 120', 120.0, 55.0, 7.0, 9.0),
    ('UPN 140', 140.0, 60.0, 7.0, 10.0),
    ('UPN 160', 160.0, 65.0, 7.5, 10.5),
    ('UPN 180', 180.0, 70.0, 8.0, 11.0),
    ('UPN 200', 200.0, 75.0, 8.5, 11.5),
    ('UPN 220', 220.0, 80.0, 9.0, 12.5),
    ('UPN 240', 240.0, 85.0, 9.5, 13.0),
    ('UPN 260', 260.0, 90.0, 10.0, 14.0),
    ('UPN 280', 280.0, 95.0, 10.0, 15.0),
    ('UPN 300', 300.0, 100.0, 10.0, 16.0),
  ])
    n: ChannelSection(n, h, b, tw, tf),
  for (final (b, t) in const [
    (50.0, 5.0),
    (60.0, 6.0),
    (70.0, 7.0),
    (80.0, 8.0),
    (90.0, 9.0),
    (100.0, 10.0),
    (120.0, 12.0),
    (150.0, 15.0),
  ])
    'L ${_n(b)}×${_n(b)}×${_n(t)}': AngleSection(
      'L ${_n(b)}×${_n(b)}×${_n(t)}',
      b,
      t,
    ),
};

/// Every library profile by name, in series order: IPE, HEA, HEB, HEM,
/// CHS, SHS, RHS, UPN, L.
final Map<String, SteelProfile> steelProfiles = {
  ...steelSections,
  ...hollowSections,
  ..._others,
};

/// Profile series names.
const steelSeries = [
  'IPE',
  'HEA',
  'HEB',
  'HEM',
  'CHS',
  'SHS',
  'RHS',
  'UPN',
  'L',
];

/// Profiles of a series, in size order.
List<String> profilesOfSeries(String series) => [
  for (final n in steelProfiles.keys)
    if (n.startsWith('$series ')) n,
];

/// Whether the EC3 member design covers this profile.
bool steelDesignable(SteelProfile p) =>
    p is ISteelSection || p is HollowSection;
