import 'dart:math' as math;

import 'core.dart';

/// Septic tank sizing: liquid volume = daily flow × retention time +
/// sludge accumulated between emptyings, with the DTU 64.1 (France)
/// minimum for houses when the number of main rooms is given.
class SepticInput {
  /// Number of users.
  final int users;

  /// Wastewater per user, L/day.
  final double flowPerUser;

  /// Hydraulic retention time, days.
  final double retentionDays;

  /// Sludge and scum accumulation, L per user per year, and the
  /// emptying interval, years.
  final double sludgeRate;
  final double emptyingYears;

  /// Liquid depth and freeboard, m; length-to-width ratio.
  final double liquidDepth;
  final double freeboard;
  final double ratio;

  /// Main rooms of a house (DTU 64.1); null = not a house.
  final int? rooms;

  const SepticInput({
    required this.users,
    this.flowPerUser = 100,
    this.retentionDays = 1,
    this.sludgeRate = 40,
    this.emptyingYears = 2,
    this.liquidDepth = 1.5,
    this.freeboard = 0.3,
    this.ratio = 2,
    this.rooms,
  });
}

class SepticResult {
  /// Volumes, m³.
  final double settlingVolume;
  final double sludgeVolume;
  final double requiredVolume;

  /// DTU 64.1 minimum (null when not applicable).
  final double? dtuMinimum;
  final double volume;

  /// Inside dimensions, m (rounded up to 5 cm), and compartments.
  final double length;
  final double width;
  final double totalDepth;
  final double firstCompartment;
  final double secondCompartment;

  /// Liquid volume provided by the rounded dimensions, m³.
  final double providedVolume;

  const SepticResult({
    required this.settlingVolume,
    required this.sludgeVolume,
    required this.requiredVolume,
    required this.dtuMinimum,
    required this.volume,
    required this.length,
    required this.width,
    required this.totalDepth,
    required this.firstCompartment,
    required this.secondCompartment,
    required this.providedVolume,
  });
}

double _ceil5(double v) => (v / 0.05 - 1e-9).ceil() * 0.05;

SepticResult sizeSepticTank(SepticInput i) {
  if (i.users < 1) throw const InputError(InputProblem.notPositive, 'users');
  requirePositive(i.flowPerUser, 'flowPerUser');
  requirePositive(i.retentionDays, 'retentionDays');
  requireRange(i.sludgeRate, 0, 200, 'sludgeRate');
  requireRange(i.emptyingYears, 0, 20, 'emptyingYears');
  requireRange(i.liquidDepth, 0.8, 3, 'liquidDepth');
  requireRange(i.freeboard, 0, 1, 'freeboard');
  requireRange(i.ratio, 1, 4, 'ratio');
  if (i.rooms != null && i.rooms! < 1) {
    throw const InputError(InputProblem.notPositive, 'rooms');
  }

  final settling = i.users * i.flowPerUser * i.retentionDays / 1e3;
  final sludge = i.users * i.sludgeRate * i.emptyingYears / 1e3;
  final required = settling + sludge;
  // DTU 64.1: 3 m³ up to 5 main rooms, + 1 m³ per additional room.
  final dtu = i.rooms == null ? null : 3.0 + math.max(0, i.rooms! - 5);
  final volume = math.max(required, dtu ?? 0);

  final area = volume / i.liquidDepth;
  final width = _ceil5(math.sqrt(area / i.ratio));
  final length = _ceil5(area / width);
  final first = _ceil5(length * 2 / 3);
  return SepticResult(
    settlingVolume: settling,
    sludgeVolume: sludge,
    requiredVolume: required,
    dtuMinimum: dtu,
    volume: volume,
    length: length,
    width: width,
    totalDepth: i.liquidDepth + i.freeboard,
    firstCompartment: first,
    secondCompartment: length - first,
    providedVolume: length * width * i.liquidDepth,
  );
}
