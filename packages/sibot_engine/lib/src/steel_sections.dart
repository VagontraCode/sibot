import 'dart:math' as math;

import 'steel_profiles.dart';

/// Doubly symmetric rolled I / H section. Dimensions in mm; derived
/// properties in mm-based units (mm², mm⁴, mm³, mm⁶).
class ISteelSection implements SteelProfile {
  @override
  final String name;
  final double h;
  final double b;
  final double tw;
  final double tf;
  final double r;

  const ISteelSection(this.name, this.h, this.b, this.tw, this.tf, this.r);

  double get _hw => h - 2 * tf;

  /// Area including root fillets.
  @override
  double get area => 2 * b * tf + _hw * tw + (4 - math.pi) * r * r;

  /// Second moment about the major axis.
  @override
  double get iy =>
      (b * h * h * h - (b - tw) * math.pow(_hw, 3)) / 12 +
      0.03 * math.pow(r, 4) +
      0.2146 * r * r * math.pow(_hw - 0.4468 * r, 2);

  /// Second moment about the minor axis.
  @override
  double get iz =>
      (2 * tf * b * b * b + _hw * tw * tw * tw) / 12 +
      0.03 * math.pow(r, 4) +
      0.2146 * r * r * math.pow(tw + 0.4468 * r, 2);

  @override
  double get welY => 2 * iy / h;
  @override
  double get welZ => 2 * iz / b;

  /// Plastic moduli including fillets.
  @override
  double get wplY =>
      tw * h * h / 4 +
      (b - tw) * (h - tf) * tf +
      (4 - math.pi) / 2 * r * r * (h - 2 * tf) +
      (3 * math.pi - 10) / 3 * r * r * r;

  @override
  double get wplZ =>
      b * b * tf / 2 +
      _hw * tw * tw / 4 +
      r * r * r * (10 / 3 - math.pi) +
      (2 - math.pi / 2) * tw * r * r;

  /// Shear area for loads parallel to the web (EN 1993-1-1 6.2.6(3)a).
  double get avz => math.max(area - 2 * b * tf + (tw + 2 * r) * tf, _hw * tw);

  /// St Venant torsion constant including the fillets (EN 10365 /
  /// SCI P363 formula) and warping constant.
  @override
  double get it {
    final alpha =
        -0.042 +
        0.2204 * tw / tf +
        0.1355 * r / tf -
        0.0865 * r * tw / (tf * tf) -
        0.0725 * tw * tw / (tf * tf);
    final d = (math.pow(tf + r, 2) + tw * (r + tw / 4)) / (2 * r + tf);
    return 2 / 3 * b * math.pow(tf, 3) +
        _hw * math.pow(tw, 3) / 3 +
        2 * alpha * math.pow(d, 4) -
        0.420 * math.pow(tf, 4);
  }

  double get iw => iz * math.pow(h - tf, 2) / 4;

  double get iRadiusY => math.sqrt(iy / area);
  double get iRadiusZ => math.sqrt(iz / area);

  /// Mass per metre, kg/m (7850 kg/m³).
  @override
  double get mass => area * 7850e-6;
}

const _ipe = <(String, double, double, double, double, double)>[
  ('IPE 80', 80, 46, 3.8, 5.2, 5),
  ('IPE 100', 100, 55, 4.1, 5.7, 7),
  ('IPE 120', 120, 64, 4.4, 6.3, 7),
  ('IPE 140', 140, 73, 4.7, 6.9, 7),
  ('IPE 160', 160, 82, 5.0, 7.4, 9),
  ('IPE 180', 180, 91, 5.3, 8.0, 9),
  ('IPE 200', 200, 100, 5.6, 8.5, 12),
  ('IPE 220', 220, 110, 5.9, 9.2, 12),
  ('IPE 240', 240, 120, 6.2, 9.8, 15),
  ('IPE 270', 270, 135, 6.6, 10.2, 15),
  ('IPE 300', 300, 150, 7.1, 10.7, 15),
  ('IPE 330', 330, 160, 7.5, 11.5, 18),
  ('IPE 360', 360, 170, 8.0, 12.7, 18),
  ('IPE 400', 400, 180, 8.6, 13.5, 21),
  ('IPE 450', 450, 190, 9.4, 14.6, 21),
  ('IPE 500', 500, 200, 10.2, 16.0, 21),
  ('IPE 550', 550, 210, 11.1, 17.2, 24),
  ('IPE 600', 600, 220, 12.0, 19.0, 24),
];

const _hea = <(String, double, double, double, double, double)>[
  ('HEA 100', 96, 100, 5.0, 8.0, 12),
  ('HEA 120', 114, 120, 5.0, 8.0, 12),
  ('HEA 140', 133, 140, 5.5, 8.5, 12),
  ('HEA 160', 152, 160, 6.0, 9.0, 15),
  ('HEA 180', 171, 180, 6.0, 9.5, 15),
  ('HEA 200', 190, 200, 6.5, 10.0, 18),
  ('HEA 220', 210, 220, 7.0, 11.0, 18),
  ('HEA 240', 230, 240, 7.5, 12.0, 21),
  ('HEA 260', 250, 260, 7.5, 12.5, 24),
  ('HEA 280', 270, 280, 8.0, 13.0, 24),
  ('HEA 300', 290, 300, 8.5, 14.0, 27),
  ('HEA 320', 310, 300, 9.0, 15.5, 27),
  ('HEA 340', 330, 300, 9.5, 16.5, 27),
  ('HEA 360', 350, 300, 10.0, 17.5, 27),
  ('HEA 400', 390, 300, 11.0, 19.0, 27),
  ('HEA 450', 440, 300, 11.5, 21.0, 27),
  ('HEA 500', 490, 300, 12.0, 23.0, 27),
];

const _heb = <(String, double, double, double, double, double)>[
  ('HEB 100', 100, 100, 6.0, 10.0, 12),
  ('HEB 120', 120, 120, 6.5, 11.0, 12),
  ('HEB 140', 140, 140, 7.0, 12.0, 12),
  ('HEB 160', 160, 160, 8.0, 13.0, 15),
  ('HEB 180', 180, 180, 8.5, 14.0, 15),
  ('HEB 200', 200, 200, 9.0, 15.0, 18),
  ('HEB 220', 220, 220, 9.5, 16.0, 18),
  ('HEB 240', 240, 240, 10.0, 17.0, 21),
  ('HEB 260', 260, 260, 10.0, 17.5, 24),
  ('HEB 280', 280, 280, 10.5, 18.0, 24),
  ('HEB 300', 300, 300, 11.0, 19.0, 27),
  ('HEB 320', 320, 300, 11.5, 20.5, 27),
  ('HEB 340', 340, 300, 12.0, 21.5, 27),
  ('HEB 360', 360, 300, 12.5, 22.5, 27),
  ('HEB 400', 400, 300, 13.5, 24.0, 27),
  ('HEB 450', 450, 300, 14.0, 26.0, 27),
  ('HEB 500', 500, 300, 14.5, 28.0, 27),
];

/// All library profiles by name, in series order.
final Map<String, ISteelSection> steelSections = {
  for (final s in [..._ipe, ..._hea, ..._heb])
    s.$1: ISteelSection(s.$1, s.$2, s.$3, s.$4, s.$5, s.$6),
  ...hemSections,
};

/// Structural steel grades (EN 10025-2), fy for t ≤ 40 mm and t > 40 mm.
const steelGrades = <String, (double, double)>{
  'S235': (235, 215),
  'S275': (275, 255),
  'S355': (355, 335),
};
