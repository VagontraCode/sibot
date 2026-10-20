import 'dart:math' as math;

import 'core.dart';
import 'rebar.dart';

/// Concrete mix by volume of fresh concrete (per m³). Defaults are a
/// common site dosage (350 kg/m³ of cement, 400 L sand, 800 L gravel,
/// 175 L water); the user should adjust them to the mix design.
class ConcreteMix {
  final double cementKg;
  final double sandLitres;
  final double gravelLitres;
  final double waterLitres;

  const ConcreteMix({
    this.cementKg = 350,
    this.sandLitres = 400,
    this.gravelLitres = 800,
    this.waterLitres = 175,
  });
}

class ConcreteQuantity {
  final double volume;
  final double cementKg;
  final int cementBags;
  final double sandM3;
  final double gravelM3;
  final double waterLitres;

  const ConcreteQuantity({
    required this.volume,
    required this.cementKg,
    required this.cementBags,
    required this.sandM3,
    required this.gravelM3,
    required this.waterLitres,
  });
}

/// Materials for [count] elements of L × W × H (m), plus [wastePercent].
ConcreteQuantity concreteQuantity({
  required double length,
  required double width,
  required double height,
  int count = 1,
  double wastePercent = 5,
  ConcreteMix mix = const ConcreteMix(),
  double bagKg = 50,
}) {
  requirePositive(length, 'length');
  requirePositive(width, 'width');
  requirePositive(height, 'height');
  if (count < 1) throw const InputError(InputProblem.notPositive, 'count');
  requireRange(wastePercent, 0, 50, 'waste');
  final v = length * width * height * count * (1 + wastePercent / 100);
  final cement = mix.cementKg * v;
  return ConcreteQuantity(
    volume: v,
    cementKg: cement,
    cementBags: (cement / bagKg - 1e-9).ceil(),
    sandM3: mix.sandLitres * v / 1000,
    gravelM3: mix.gravelLitres * v / 1000,
    waterLitres: mix.waterLitres * v,
  );
}

/// Mass of steel per metre for a bar diameter (7850 kg/m³), kg/m.
double barMassPerMetre(int diameter) => barArea(diameter) * 7850e-6;

class RebarQuantity {
  /// Total length (m) and mass (kg) including laps.
  final double length;
  final double mass;

  /// Commercial bars of [stockLength] needed.
  final int stockBars;

  const RebarQuantity(this.length, this.mass, this.stockBars);
}

/// [count] bars of Ø[diameter], each [barLength] m, with [lapPercent]
/// allowance for laps and waste; stock bars of [stockLength] m.
RebarQuantity rebarQuantity({
  required int diameter,
  required int count,
  required double barLength,
  double lapPercent = 10,
  double stockLength = 12,
}) {
  requirePositive(diameter.toDouble(), 'diameter');
  if (count < 1) throw const InputError(InputProblem.notPositive, 'count');
  requirePositive(barLength, 'barLength');
  requireRange(lapPercent, 0, 50, 'lap');
  final total = count * barLength * (1 + lapPercent / 100);
  // Bars longer than a stock bar are lapped; shorter ones are cut from
  // stock bars without mixing pieces of different bars.
  final int stock;
  if (barLength >= stockLength) {
    stock = (total / stockLength - 1e-9).ceil();
  } else {
    final perStock = math.max(1, (stockLength / barLength).floor());
    stock = (count / perStock - 1e-9).ceil();
  }
  return RebarQuantity(total, total * barMassPerMetre(diameter), stock);
}

/// Formwork area of [count] rectangular elements: the two sides
/// L × H plus, when [includeEnds], the two ends W × H, plus the soffit
/// L × W when [includeSoffit] (beams, slabs), m².
double formworkArea({
  required double length,
  required double width,
  required double height,
  int count = 1,
  bool includeEnds = true,
  bool includeSoffit = false,
}) {
  requirePositive(length, 'length');
  requirePositive(width, 'width');
  requirePositive(height, 'height');
  final one =
      2 * length * height +
      (includeEnds ? 2 * width * height : 0) +
      (includeSoffit ? length * width : 0);
  return one * count;
}
