import 'dart:math' as math;

/// Standard bar diameters, mm.
const barDiameters = [8, 10, 12, 14, 16, 20, 25, 32];

double barArea(int diameter) => math.pi * diameter * diameter / 4;

/// A group of identical bars in one layer.
class BarSet {
  final int count;
  final int diameter;

  const BarSet(this.count, this.diameter);

  double get area => count * barArea(diameter);

  @override
  String toString() => '$count Ø$diameter';
}

/// Bars at a regular spacing per metre width (slabs, footings).
class BarSpacing {
  final int diameter;

  /// Centre-to-centre spacing, mm.
  final int spacing;

  const BarSpacing(this.diameter, this.spacing);

  /// Area per metre width, mm²/m.
  double get areaPerMetre => barArea(diameter) * 1000 / spacing;

  @override
  String toString() => 'Ø$diameter @ $spacing';
}

/// Minimum clear distance between bars, mm: max(φ, dg + 5, 20) with
/// aggregate size dg = 20 mm (EC2 8.2(2); BAEL A.7.2.8 is similar).
double minClearSpacing(int diameter) => math.max(diameter.toDouble(), 25);

/// Chooses a single layer of bars with area ≥ [required] that fits in
/// [width] (mm, between the inside faces of the links). Picks the
/// combination with the least excess area; null if nothing fits.
BarSet? chooseBars(
  double required,
  double width, {
  int minCount = 2,
  int maxCount = 8,
  List<int> diameters = barDiameters,
}) {
  BarSet? best;
  for (final d in diameters) {
    final n = math.max(minCount, (required / barArea(d) - 1e-9).ceil());
    if (n > maxCount) continue;
    final clear = n > 1 ? (width - n * d) / (n - 1) : width - d;
    if (clear < minClearSpacing(d)) continue;
    final set = BarSet(n, d);
    if (best == null ||
        set.area < best.area - 1e-6 ||
        ((set.area - best.area).abs() < 1e-6 && n < best.count)) {
      best = set;
    }
  }
  return best;
}

/// Chooses bars at a spacing giving ≥ [requiredPerMetre] mm²/m with
/// spacing ≤ [maxSpacing] mm. Spacings are multiples of 25 mm.
BarSpacing? chooseSpacing(
  double requiredPerMetre,
  double maxSpacing, {
  List<int> diameters = const [8, 10, 12, 14, 16, 20, 25],
  int minSpacing = 100,
}) {
  BarSpacing? best;
  for (final d in diameters) {
    final raw = barArea(d) * 1000 / requiredPerMetre;
    var s = (math.min(raw, maxSpacing) / 25).floor() * 25;
    if (s > 300) s = 300;
    if (s < minSpacing) continue;
    final candidate = BarSpacing(d, s);
    if (best == null || candidate.areaPerMetre < best.areaPerMetre - 1e-6) {
      best = candidate;
    }
  }
  return best;
}
