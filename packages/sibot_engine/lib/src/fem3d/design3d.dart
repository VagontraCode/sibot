import 'dart:math' as math;

import 'analysis3d.dart';
import 'model3d.dart';
import 'spectrum.dart';

/// Design forces of one member over a set of results (envelope).
class MemberEnvelope3D {
  final double length;

  /// Mostly vertical member (column).
  final bool vertical;

  /// Largest positive (sagging) and negative (hogging, as a magnitude)
  /// major-axis moments, kN·m.
  final double mySagging;
  final double myHogging;

  /// Largest minor-axis moment, shears and torque magnitudes.
  final double mzMax;
  final double vzMax;
  final double vyMax;
  final double tMax;

  /// Largest compression and tension, kN (positive values).
  final double nCompression;
  final double nTension;

  const MemberEnvelope3D({
    required this.length,
    required this.vertical,
    required this.mySagging,
    required this.myHogging,
    required this.mzMax,
    required this.vzMax,
    required this.vyMax,
    required this.tMax,
    required this.nCompression,
    required this.nTension,
  });

  double get myMax => math.max(mySagging, myHogging);

  static MemberEnvelope3D of(
    Model3D m,
    int element,
    List<Frame3DResult> results,
  ) {
    final e = m.elements[element];
    final a = m.nodes[e.n1], b = m.nodes[e.n2];
    final dx = b.x - a.x, dy = b.y - a.y, dz = b.z - a.z;
    var sag = 0.0, hog = 0.0, mz = 0.0, vz = 0.0, vy = 0.0, t = 0.0;
    var comp = 0.0, tens = 0.0;
    for (final r in results) {
      for (final s in r.members[element].stations) {
        sag = math.max(sag, s.my);
        hog = math.max(hog, -s.my);
        mz = math.max(mz, s.mz.abs());
        vz = math.max(vz, s.vz.abs());
        vy = math.max(vy, s.vy.abs());
        t = math.max(t, s.t.abs());
        comp = math.max(comp, -s.n);
        tens = math.max(tens, s.n);
      }
    }
    return MemberEnvelope3D(
      length: math.sqrt(dx * dx + dy * dy + dz * dz),
      vertical: dz.abs() > math.sqrt(dx * dx + dy * dy),
      mySagging: sag,
      myHogging: hog,
      mzMax: mz,
      vzMax: vz,
      vyMax: vy,
      tMax: t,
      nCompression: comp,
      nTension: tens,
    );
  }
}

/// The two bounds of a seismic design situation: quasi-permanent static
/// forces (G + ψ2 Q) plus and minus the seismic envelope E.
List<Frame3DResult> seismicSituations(
  Frame3DResult quasiPermanent,
  Frame3DResult e,
) => [
  mapResults(quasiPermanent, e, (s, x) => s + x.abs()),
  mapResults(quasiPermanent, e, (s, x) => s - x.abs()),
];
