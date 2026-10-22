import 'dart:math' as math;

import 'core.dart';
import 'timber.dart';

/// Bolted or dowelled timber-to-timber connection in single shear,
/// EN 1995-1-1 8.2.2 (Johansen equations 8.6) and 8.5.
class DowelConnectionInput {
  final TimberClass timber;

  /// Fastener diameter and ultimate strength (400 for 4.6, 800 for 8.8),
  /// mm and MPa.
  final double d;
  final double fuk;

  /// Thicknesses of the two members, mm.
  final double t1;
  final double t2;

  /// Angle between the load and the grain of member 2 (member 1 is
  /// loaded along the grain), degrees.
  final double angle2;

  /// Fasteners per row (parallel to the grain), number of rows and
  /// spacing along the grain a1, mm.
  final int perRow;
  final int rows;
  final double a1;

  /// Design load on the connection, kN.
  final double fEd;
  final LoadDuration duration;
  final int serviceClass;

  const DowelConnectionInput({
    required this.timber,
    required this.d,
    required this.t1,
    required this.t2,
    required this.fEd,
    this.fuk = 400,
    this.angle2 = 0,
    this.perRow = 1,
    this.rows = 1,
    this.a1 = 0,
    this.duration = LoadDuration.mediumTerm,
    this.serviceClass = 1,
  });
}

class DowelConnectionResult {
  /// Embedment strengths of members 1 and 2, MPa; yield moment, N·mm.
  final double fh1;
  final double fh2;
  final double myRk;

  /// Characteristic capacity per shear plane and fastener of each
  /// failure mode a–f, N, and the governing mode.
  final List<double> modes;
  final int governing;
  final double fvRk;
  final double fvRd;

  /// Effective number of fasteners in a row (8.34).
  final double nef;

  /// Capacity of the connection, kN.
  final double capacity;
  final List<Check> checks;
  bool get ok => checks.every((c) => c.ok);

  const DowelConnectionResult({
    required this.fh1,
    required this.fh2,
    required this.myRk,
    required this.modes,
    required this.governing,
    required this.fvRk,
    required this.fvRd,
    required this.nef,
    required this.capacity,
    required this.checks,
  });
}

DowelConnectionResult designDowelConnection(DowelConnectionInput i) {
  requireRange(i.d, 6, 30, 'd');
  requirePositive(i.t1, 't1');
  requirePositive(i.t2, 't2');
  requirePositive(i.fEd, 'fEd');
  requireRange(i.angle2, 0, 90, 'angle2');
  if (i.perRow < 1 || i.rows < 1) {
    throw const InputError(InputProblem.notPositive, 'perRow');
  }
  if (i.perRow > 1 && i.a1 < 4 * i.d) {
    // EN 1995-1-1 Table 8.4: a1 ≥ (4 + |cos α|) d for bolts.
    throw const InputError(InputProblem.outOfRange, 'a1');
  }
  final d = i.d, t1 = i.t1, t2 = i.t2;
  // Embedment strength (8.32) and its variation with the angle (8.31),
  // softwood k90 = 1.35 + 0.015 d.
  final fh0 = 0.082 * (1 - 0.01 * d) * i.timber.rhoK;
  final k90 = 1.35 + 0.015 * d;
  final a = i.angle2 * math.pi / 180;
  final fh1 = fh0;
  final fh2 = fh0 / (k90 * math.pow(math.sin(a), 2) + math.pow(math.cos(a), 2));
  final my = 0.3 * i.fuk * math.pow(d, 2.6);
  final b = fh2 / fh1;
  final r = t2 / t1;
  // Johansen modes (8.6), rope effect neglected (conservative).
  final modes = [
    fh1 * t1 * d,
    fh2 * t2 * d,
    fh1 *
        t1 *
        d /
        (1 + b) *
        (math.sqrt(b + 2 * b * b * (1 + r + r * r) + b * b * b * r * r) -
            b * (1 + r)),
    1.05 *
        fh1 *
        t1 *
        d /
        (2 + b) *
        (math.sqrt(
              2 * b * (1 + b) + 4 * b * (2 + b) * my / (fh1 * d * t1 * t1),
            ) -
            b),
    1.05 *
        fh1 *
        t2 *
        d /
        (1 + 2 * b) *
        (math.sqrt(
              2 * b * b * (1 + b) +
                  4 * b * (1 + 2 * b) * my / (fh1 * d * t2 * t2),
            ) -
            b),
    1.15 * math.sqrt(2 * b / (1 + b)) * math.sqrt(2 * my * fh1 * d),
  ];
  var governing = 0;
  for (var k = 1; k < modes.length; k++) {
    if (modes[k] < modes[governing]) governing = k;
  }
  final fvRk = modes[governing];
  const gammaM = 1.3; // connections, Table 2.3
  final kmod = timberKmod(i.duration, i.serviceClass);
  final fvRd = kmod * fvRk / gammaM;
  // Effective number in a row parallel to the grain (8.34).
  final n = i.perRow.toDouble();
  final nef = n == 1
      ? 1.0
      : math.min(n, math.pow(n, 0.9) * math.pow(i.a1 / (13 * d), 0.25));
  final capacity = i.rows * nef * fvRd / 1e3;
  return DowelConnectionResult(
    fh1: fh1,
    fh2: fh2.toDouble(),
    myRk: my.toDouble(),
    modes: [for (final m in modes) m.toDouble()],
    governing: governing,
    fvRk: fvRk.toDouble(),
    fvRd: fvRd.toDouble(),
    nef: nef.toDouble(),
    capacity: capacity.toDouble(),
    checks: [
      Check(
        kind: CheckKind.connection,
        demand: i.fEd,
        capacity: capacity.toDouble(),
        clause: 'EN 1995-1-1 8.2.2 (8.6), 8.5.1.1 (8.34)',
        unit: 'kN',
      ),
    ],
  );
}
