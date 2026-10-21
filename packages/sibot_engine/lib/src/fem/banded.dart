import 'dart:math' as math;
import 'dart:typed_data';

/// Symmetric positive-definite banded matrix stored by rows: row i holds
/// columns i … i + bandwidth (upper half).
class BandedMatrix {
  final int n;
  final int bandwidth;
  final Float64List _data;

  BandedMatrix(this.n, this.bandwidth)
    : _data = Float64List(n * (bandwidth + 1));

  int _index(int i, int j) => i * (bandwidth + 1) + (j - i);

  /// Adds [v] at (i, j); only the upper part (j ≥ i) is stored.
  void add(int i, int j, double v) {
    if (j < i) {
      final t = i;
      i = j;
      j = t;
    }
    if (j - i > bandwidth) {
      throw StateError('Entry ($i, $j) outside the band $bandwidth');
    }
    _data[_index(i, j)] += v;
  }

  double get(int i, int j) {
    if (j < i) {
      final t = i;
      i = j;
      j = t;
    }
    if (j - i > bandwidth) return 0;
    return _data[_index(i, j)];
  }

  /// In-place Cholesky factorisation K = Uᵀ·U. Throws
  /// [SingularStiffness] with the offending equation when the matrix is
  /// not positive definite (an unstable structure).
  void factorize() {
    final b = bandwidth;
    // Reference scale for the pivot test.
    var scale = 0.0;
    for (var i = 0; i < n; i++) {
      scale = math.max(scale, _data[_index(i, i)].abs());
    }
    final tiny = scale * 1e-12;
    for (var i = 0; i < n; i++) {
      final jMin = math.max(0, i - b);
      var d = _data[_index(i, i)];
      for (var k = jMin; k < i; k++) {
        final u = _data[_index(k, i)];
        d -= u * u;
      }
      if (d <= tiny) throw SingularStiffness(i);
      final diag = math.sqrt(d);
      _data[_index(i, i)] = diag;
      final jMax = math.min(n - 1, i + b);
      for (var j = i + 1; j <= jMax; j++) {
        var s = _data[_index(i, j)];
        final kMin = math.max(0, j - b);
        for (var k = math.max(jMin, kMin); k < i; k++) {
          s -= _data[_index(k, i)] * _data[_index(k, j)];
        }
        _data[_index(i, j)] = s / diag;
      }
    }
  }

  /// Solves K·x = rhs after [factorize]; returns x.
  Float64List solve(Float64List rhs) {
    final b = bandwidth;
    final y = Float64List.fromList(rhs);
    // Forward: Uᵀ·y = rhs
    for (var i = 0; i < n; i++) {
      var s = y[i];
      for (var k = math.max(0, i - b); k < i; k++) {
        s -= _data[_index(k, i)] * y[k];
      }
      y[i] = s / _data[_index(i, i)];
    }
    // Backward: U·x = y
    for (var i = n - 1; i >= 0; i--) {
      var s = y[i];
      final jMax = math.min(n - 1, i + b);
      for (var j = i + 1; j <= jMax; j++) {
        s -= _data[_index(i, j)] * y[j];
      }
      y[i] = s / _data[_index(i, i)];
    }
    return y;
  }
}

class SingularStiffness implements Exception {
  /// Equation number where the pivot vanished.
  final int equation;
  const SingularStiffness(this.equation);

  @override
  String toString() => 'SingularStiffness(equation $equation)';
}

/// Reverse Cuthill–McKee ordering of nodes connected by [edges].
/// Returns new index for each node.
List<int> reverseCuthillMcKee(int nodeCount, List<(int, int)> edges) {
  final adj = List.generate(nodeCount, (_) => <int>{});
  for (final (a, b) in edges) {
    if (a == b) continue;
    adj[a].add(b);
    adj[b].add(a);
  }
  final visited = List.filled(nodeCount, false);
  final order = <int>[];
  while (order.length < nodeCount) {
    // Start each component at an unvisited node of minimum degree.
    var start = -1;
    for (var i = 0; i < nodeCount; i++) {
      if (!visited[i] && (start < 0 || adj[i].length < adj[start].length)) {
        start = i;
      }
    }
    final queue = [start];
    visited[start] = true;
    var head = 0;
    while (head < queue.length) {
      final v = queue[head++];
      order.add(v);
      final next = adj[v].where((w) => !visited[w]).toList()
        ..sort((a, b) => adj[a].length.compareTo(adj[b].length));
      for (final w in next) {
        visited[w] = true;
        queue.add(w);
      }
    }
  }
  final newIndex = List.filled(nodeCount, 0);
  for (var k = 0; k < nodeCount; k++) {
    newIndex[order[nodeCount - 1 - k]] = k;
  }
  return newIndex;
}
