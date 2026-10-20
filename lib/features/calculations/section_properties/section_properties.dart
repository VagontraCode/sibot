import 'dart:math';

class SectionPropertiesCalculator {
  static Map<String, dynamic> calculateRectangularSection({
    required double width, // mm
    required double depth, // mm
  }) {
    final area = width * depth;
    final ix = (width * depth * depth * depth) / 12;
    final iy = (depth * width * width * width) / 12;
    final rx = sqrt(ix / area);
    final ry = sqrt(iy / area);
    final zx = ix / (depth / 2);
    final zy = iy / (width / 2);

    return {
      'area': area,
      'momentOfInertiaX': ix,
      'momentOfInertiaY': iy,
      'radiusOfGyrationX': rx,
      'radiusOfGyrationY': ry,
      'sectionModulusX': zx,
      'sectionModulusY': zy,
      'perimeter': 2 * (width + depth),
    };
  }

  static Map<String, dynamic> calculateCircularSection({
    required double diameter, // mm
  }) {
    final radius = diameter / 2;
    final area = pi * radius * radius;
    final moment = (pi * diameter * diameter * diameter * diameter) / 64;
    final r = diameter / 4;
    final z = (pi * diameter * diameter * diameter) / 32;

    return {
      'area': area,
      'momentOfInertia': moment,
      'radiusOfGyration': r,
      'sectionModulus': z,
      'perimeter': pi * diameter,
    };
  }

  static Map<String, dynamic> calculateIBeamSection({
    required double webHeight, // mm
    required double flange, // mm
    required double flangeThickness, // mm
    required double webThickness, // mm
  }) {
    // Gross area
    final topFlange = flange * flangeThickness;
    final bottomFlange = flange * flangeThickness;
    final web = webThickness * (webHeight - 2 * flangeThickness);
    final area = topFlange + bottomFlange + web;

    // Centroid calculation
    final yc =
        (topFlange * (webHeight - flangeThickness / 2) +
            web * (webHeight / 2 - flangeThickness) +
            bottomFlange * (flangeThickness / 2)) /
        area;

    // Moment of inertia
    final iy =
        (flange * webHeight * webHeight * webHeight) / 12 -
        ((flange - webThickness) *
                (webHeight - 2 * flangeThickness) *
                (webHeight - 2 * flangeThickness) *
                (webHeight - 2 * flangeThickness)) /
            12;

    final section = iy / (webHeight / 2 - yc);

    return {
      'area': area,
      'centroidY': yc,
      'momentOfInertiaY': iy,
      'sectionModulus': section,
    };
  }
}
