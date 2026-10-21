import '../core.dart';

import 'model.dart';

/// ψ0 and ψ2 for a variable action type (EN 1990 Table A1.1: imposed
/// loads in dwellings/offices, snow below 1000 m, wind).
(double, double) psiFactors(LoadType t) => switch (t) {
  LoadType.imposed => (0.7, 0.3),
  LoadType.snow => (0.5, 0.0),
  LoadType.wind => (0.6, 0.0),
  LoadType.permanent => (1.0, 1.0),
};

/// Generates the usual combinations for the load cases.
///
/// EC2 / EN 1990: ULS 6.10 with each variable action leading in turn
/// (1.35G + 1.5Qk,1 + 1.5ψ0Qk,i), plus 1.0G + 1.5W for wind uplift;
/// SLS characteristic and quasi-permanent.
/// BAEL (A.3.3, annexe D): 1.35G + 1.5Q1 + 1.3ψ0Qi (ψ0 = 0.77),
/// G + 1.5W; ELS G + Q.
List<Combination> generateCombinations(List<LoadCase> cases, DesignCode code) =>
    combinationsFor([for (final c in cases) (c.name, c.type)], code);

/// Same as [generateCombinations] from case names and types, for any model.
List<Combination> combinationsFor(
  List<(String, LoadType)> cases,
  DesignCode code,
) {
  final perm = [
    for (var i = 0; i < cases.length; i++)
      if (cases[i].$2 == LoadType.permanent) i,
  ];
  final variable = [
    for (var i = 0; i < cases.length; i++)
      if (cases[i].$2 != LoadType.permanent) i,
  ];
  final out = <Combination>[];
  String label(int i) => cases[i].$1;

  Map<int, double> base(double g) => {for (final i in perm) i: g};

  if (variable.isEmpty) {
    out.add(Combination('ULS 1.35G', CombinationKind.uls, base(1.35)));
    out.add(Combination('SLS G', CombinationKind.slsCharacteristic, base(1.0)));
    return out;
  }

  for (final lead in variable) {
    final f = base(1.35);
    f[lead] = 1.5;
    for (final o in variable) {
      if (o == lead) continue;
      f[o] = code == DesignCode.ec2
          ? 1.5 * psiFactors(cases[o].$2).$1
          : 1.3 * 0.77;
    }
    out.add(
      Combination('ULS 1.35G + 1.5 ${label(lead)}', CombinationKind.uls, f),
    );
  }
  // Wind with favourable permanent actions (uplift, overturning).
  for (final w in variable.where((i) => cases[i].$2 == LoadType.wind)) {
    final f = base(1.0);
    f[w] = 1.5;
    out.add(Combination('ULS G + 1.5 ${label(w)}', CombinationKind.uls, f));
  }

  // SLS characteristic: G + Qk,1 + ψ0·Qk,i (BAEL: G + Q).
  for (final lead in variable) {
    final f = base(1.0);
    f[lead] = 1.0;
    for (final o in variable) {
      if (o == lead) continue;
      f[o] = code == DesignCode.ec2 ? psiFactors(cases[o].$2).$1 : 0.77;
    }
    out.add(
      Combination(
        'SLS G + ${label(lead)}',
        CombinationKind.slsCharacteristic,
        f,
      ),
    );
  }
  if (code == DesignCode.ec2) {
    final f = base(1.0);
    for (final o in variable) {
      final psi2 = psiFactors(cases[o].$2).$2;
      if (psi2 > 0) f[o] = psi2;
    }
    out.add(Combination('SLS QP', CombinationKind.slsQuasiPermanent, f));
  }
  return out;
}
