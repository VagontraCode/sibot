import 'dart:math' as math;
import 'dart:typed_data';

import 'analysis3d.dart';
import 'model3d.dart';

const gravity = 9.81;

/// Where the vibrating mass comes from.
class ModalOptions {
  /// Number of modes wanted.
  final int modes;

  /// Load cases converted to mass with a factor, e.g. EC8 G + ψE,i·Q:
  /// {0: 1.0, 1: 0.3}. Downward loads (and the case's self-weight) are
  /// divided by g. When empty, the members' self-weight is used.
  final Map<int, double> massCases;

  const ModalOptions({this.modes = 6, this.massCases = const {}});
}

class Mode {
  final double omega;

  /// Shape per node (6 values), scaled so the largest translation is 1.
  final List<List<double>> shape;

  /// Participation factors and effective masses (t) in X, Y, Z.
  final List<double> participation;
  final List<double> effectiveMass;

  /// Effective mass as a fraction of the total mass, per direction.
  final List<double> massRatio;

  /// Mass-normalised eigenvector over the equations (for spectra).
  final Float64List vector;

  const Mode({
    required this.omega,
    required this.shape,
    required this.participation,
    required this.effectiveMass,
    required this.massRatio,
    required this.vector,
  });

  double get frequency => omega / (2 * math.pi);
  double get period => 2 * math.pi / omega;
}

class ModalResult {
  final List<Mode> modes;

  /// Total mass on free DOFs per direction, t.
  final List<double> totalMass;

  /// Lumped translational mass per node, t.
  final List<double> nodeMass;

  /// Iterations used by the subspace solver.
  final int iterations;

  /// The static analysis whose factorised stiffness was used.
  final Frame3DAnalysis analysis;

  const ModalResult(
    this.modes,
    this.totalMass,
    this.nodeMass,
    this.iterations,
    this.analysis,
  );

  /// Cumulative mass ratio per direction over all computed modes.
  List<double> get cumulativeRatio => [
    for (var d = 0; d < 3; d++) modes.fold(0.0, (s, m) => s + m.massRatio[d]),
  ];
}

/// Lumped translational masses per node (t).
List<double> lumpedMasses(
  Model3D model,
  Frame3DAnalysis analysis,
  ModalOptions o,
) {
  final m = List.filled(model.nodes.length, 0.0);
  final lengths = analysis.lengths;
  void selfWeight(double factor) {
    for (var i = 0; i < model.elements.length; i++) {
      final e = model.elements[i];
      final s = model.sections[e.section];
      final half = factor * s.unitWeight * s.area * lengths[i] / gravity / 2;
      m[e.n1] += half;
      m[e.n2] += half;
    }
  }

  if (o.massCases.isEmpty) {
    selfWeight(1);
    return m;
  }
  for (final entry in o.massCases.entries) {
    if (entry.key < 0 || entry.key >= model.cases.length) continue;
    final c = model.cases[entry.key];
    final f = entry.value;
    if (c.selfWeight) selfWeight(f);
    for (final p in c.nodal) {
      if (p.node >= 0 && p.node < m.length && p.fz < 0) {
        m[p.node] += -f * p.fz / gravity;
      }
    }
    for (final q in c.member) {
      if (q.local || q.qz >= 0) continue;
      if (q.element < 0 || q.element >= model.elements.length) continue;
      final e = model.elements[q.element];
      final half = -f * q.qz * lengths[q.element] / gravity / 2;
      m[e.n1] += half;
      m[e.n2] += half;
    }
  }
  return m;
}

/// Natural modes of a space frame by subspace iteration (Bathe) on
/// K φ = ω² M φ with lumped translational masses.
ModalResult modalAnalysis(
  Model3D model, {
  ModalOptions options = const ModalOptions(),
}) {
  final an = Frame3DAnalysis(model);
  final n = an.equations;
  final nodeMass = lumpedMasses(model, an, options);

  // Diagonal mass over the equations.
  final mDiag = Float64List(n);
  final totalMass = [0.0, 0.0, 0.0];
  for (var node = 0; node < model.nodes.length; node++) {
    for (var d = 0; d < 3; d++) {
      final eq = an.equationOf(node, d);
      if (eq >= 0) {
        mDiag[eq] = nodeMass[node];
        totalMass[d] += nodeMass[node];
      }
    }
  }
  final massDofs = [
    for (var i = 0; i < n; i++)
      if (mDiag[i] > 0) i,
  ];
  final p = math.min(options.modes, massDofs.length);
  if (p == 0) return ModalResult(const [], totalMass, nodeMass, 0, an);
  final q = math.min(math.max(2 * p, p + 8), massDofs.length);

  // Starting vectors: the mass diagonal, then unit vectors at the DOFs
  // with the largest m/k ratios.
  final kd = an.stiffnessDiagonal;
  final ranked = [...massDofs]
    ..sort((a, b) => (mDiag[b] / kd[b]).compareTo(mDiag[a] / kd[a]));
  var x = <Float64List>[
    Float64List.fromList(mDiag),
    for (var j = 0; j < q - 1; j++) Float64List(n)..[ranked[j]] = 1,
  ];

  var lambda = List.filled(q, 0.0);
  var iterations = 0;
  for (var it = 0; it < 200; it++) {
    iterations = it + 1;
    final y = [
      for (final v in x)
        Float64List.fromList([for (var i = 0; i < n; i++) mDiag[i] * v[i]]),
    ];
    final xb = [for (final v in y) an.solveVector(v)];
    final kr = List.generate(q, (_) => Float64List(q));
    final mr = List.generate(q, (_) => Float64List(q));
    for (var a = 0; a < q; a++) {
      for (var b = a; b < q; b++) {
        var sk = 0.0, sm = 0.0;
        for (var i = 0; i < n; i++) {
          sk += xb[a][i] * y[b][i];
          sm += xb[a][i] * mDiag[i] * xb[b][i];
        }
        kr[a][b] = kr[b][a] = sk;
        mr[a][b] = mr[b][a] = sm;
      }
    }
    final (vals, vecs) = _generalizedEigen(kr, mr);
    x = [
      for (var j = 0; j < q; j++)
        Float64List.fromList([
          for (var i = 0; i < n; i++)
            () {
              var s = 0.0;
              for (var a = 0; a < q; a++) {
                s += xb[a][i] * vecs[a][j];
              }
              return s;
            }(),
        ]),
    ];
    var converged = it > 0;
    for (var j = 0; j < p; j++) {
      if ((vals[j] - lambda[j]).abs() > 1e-10 * vals[j].abs()) {
        converged = false;
      }
    }
    lambda = vals;
    if (converged) break;
  }

  final modes = <Mode>[];
  for (var j = 0; j < p; j++) {
    final v = x[j];
    final shape = List.generate(model.nodes.length, (_) => List.filled(6, 0.0));
    var maxT = 0.0;
    for (var node = 0; node < model.nodes.length; node++) {
      for (var d = 0; d < 6; d++) {
        final eq = an.equationOf(node, d);
        if (eq >= 0) shape[node][d] = v[eq];
        if (d < 3) maxT = math.max(maxT, shape[node][d].abs());
      }
    }
    if (maxT > 0) {
      for (final s in shape) {
        for (var d = 0; d < 6; d++) {
          s[d] /= maxT;
        }
      }
    }
    // Γ = φᵀ M r (φ mass-normalised): effective mass Γ².
    final gamma = [0.0, 0.0, 0.0];
    for (var node = 0; node < model.nodes.length; node++) {
      for (var d = 0; d < 3; d++) {
        final eq = an.equationOf(node, d);
        if (eq >= 0) gamma[d] += mDiag[eq] * v[eq];
      }
    }
    modes.add(
      Mode(
        omega: math.sqrt(math.max(lambda[j], 0)),
        shape: shape,
        participation: gamma,
        effectiveMass: [for (final g in gamma) g * g],
        massRatio: [
          for (var d = 0; d < 3; d++)
            totalMass[d] > 0 ? gamma[d] * gamma[d] / totalMass[d] : 0,
        ],
        vector: v,
      ),
    );
  }
  return ModalResult(modes, totalMass, nodeMass, iterations, an);
}

/// Solves K z = λ M z for small symmetric K and positive definite M.
/// Returns eigenvalues ascending and M-orthonormal eigenvectors (columns).
(List<double>, List<List<double>>) _generalizedEigen(
  List<Float64List> k,
  List<Float64List> m,
) {
  final q = k.length;
  // Cholesky M = L Lᵀ.
  final l = List.generate(q, (_) => Float64List(q));
  for (var i = 0; i < q; i++) {
    for (var j = 0; j <= i; j++) {
      var s = m[i][j];
      for (var t = 0; t < j; t++) {
        s -= l[i][t] * l[j][t];
      }
      if (i == j) {
        l[i][i] = math.sqrt(math.max(s, 1e-300));
      } else {
        l[i][j] = s / l[j][j];
      }
    }
  }
  // C = L⁻¹ K L⁻ᵀ.
  final tmp = List.generate(q, (_) => Float64List(q)); // L⁻¹ K
  for (var c = 0; c < q; c++) {
    for (var i = 0; i < q; i++) {
      var s = k[i][c];
      for (var t = 0; t < i; t++) {
        s -= l[i][t] * tmp[t][c];
      }
      tmp[i][c] = s / l[i][i];
    }
  }
  final cMat = List.generate(q, (_) => Float64List(q));
  for (var r = 0; r < q; r++) {
    for (var i = 0; i < q; i++) {
      var s = tmp[r][i];
      for (var t = 0; t < i; t++) {
        s -= l[i][t] * cMat[r][t];
      }
      cMat[r][i] = s / l[i][i];
    }
  }
  final (vals, z) = _jacobi(cMat);
  // Back-transform: Q = L⁻ᵀ Z.
  final vecs = List.generate(q, (_) => List.filled(q, 0.0));
  for (var c = 0; c < q; c++) {
    for (var i = q - 1; i >= 0; i--) {
      var s = z[i][c];
      for (var t = i + 1; t < q; t++) {
        s -= l[t][i] * vecs[t][c];
      }
      vecs[i][c] = s / l[i][i];
    }
  }
  // Sort ascending.
  final order = List.generate(q, (i) => i)
    ..sort((a, b) => vals[a].compareTo(vals[b]));
  return (
    [for (final i in order) vals[i]],
    [
      for (var r = 0; r < q; r++) [for (final i in order) vecs[r][i]],
    ],
  );
}

/// Cyclic Jacobi eigen-decomposition of a symmetric matrix.
(List<double>, List<List<double>>) _jacobi(List<Float64List> a0) {
  final n = a0.length;
  final a = [for (final r in a0) Float64List.fromList(r)];
  final v = List.generate(
    n,
    (i) => List.generate(n, (j) => i == j ? 1.0 : 0.0),
  );
  for (var sweep = 0; sweep < 100; sweep++) {
    var off = 0.0;
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        off += a[i][j] * a[i][j];
      }
    }
    var diag = 0.0;
    for (var i = 0; i < n; i++) {
      diag += a[i][i] * a[i][i];
    }
    if (off <= 1e-30 * diag) break;
    for (var pI = 0; pI < n; pI++) {
      for (var qI = pI + 1; qI < n; qI++) {
        if (a[pI][qI].abs() < 1e-300) continue;
        final theta = (a[qI][qI] - a[pI][pI]) / (2 * a[pI][qI]);
        final t = theta.sign == 0
            ? 1.0
            : theta.sign / (theta.abs() + math.sqrt(theta * theta + 1));
        final c = 1 / math.sqrt(t * t + 1), s = t * c;
        for (var k = 0; k < n; k++) {
          final akp = a[k][pI], akq = a[k][qI];
          a[k][pI] = c * akp - s * akq;
          a[k][qI] = s * akp + c * akq;
        }
        for (var k = 0; k < n; k++) {
          final apk = a[pI][k], aqk = a[qI][k];
          a[pI][k] = c * apk - s * aqk;
          a[qI][k] = s * apk + c * aqk;
        }
        for (var k = 0; k < n; k++) {
          final vkp = v[k][pI], vkq = v[k][qI];
          v[k][pI] = c * vkp - s * vkq;
          v[k][qI] = s * vkp + c * vkq;
        }
      }
    }
  }
  return ([for (var i = 0; i < n; i++) a[i][i]], v);
}
