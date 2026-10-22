import '../core.dart';
import '../fem/combinations.dart';
import '../fem/model.dart';
import '../seismic.dart';
import 'model3d.dart';

/// The combinations of a model: the user's own list, or the ones
/// generated from its load cases for [code].
List<Combination> combinationsOf(Model3D m, DesignCode code) =>
    m.combinations ??
    combinationsFor([for (final c in m.cases) (c.name, c.type)], code);

/// Factors that refer to load cases the model does not have, or a
/// combination without any factor.
bool combinationValid(Model3D m, Combination c) =>
    c.factors.isNotEmpty &&
    c.factors.keys.every((k) => k >= 0 && k < m.cases.length);

enum AnalysisKind { static, modal, spectrum, buckling, pDelta }

/// One analysis chosen by the user, with its settings.
class AnalysisSpec {
  /// Stable identifier (results are kept under it).
  final String id;
  final AnalysisKind kind;

  /// User label; empty = a default name from the kind.
  final String name;

  /// Static: the combinations shown (null = all). Buckling and P-Δ: the
  /// one combination analysed (first entry; null = first ULS one).
  final List<int>? combinations;

  /// Modal (and the modes used by a spectrum): number of modes.
  final int modes;

  // Spectrum settings.
  final bool ps92;
  final double agR;
  final int importance;
  final GroundType ground;
  final bool type1;
  final double q;

  /// 0 = X, 1 = Y, 2 = both (E + 0.3 E).
  final int direction;
  final bool torsion;
  final double aN;
  final Ps92Site site;

  const AnalysisSpec({
    required this.id,
    required this.kind,
    this.name = '',
    this.combinations,
    this.modes = 12,
    this.ps92 = false,
    this.agR = 1.6,
    this.importance = 2,
    this.ground = GroundType.b,
    this.type1 = false,
    this.q = 1.5,
    this.direction = 2,
    this.torsion = true,
    this.aN = 2.0,
    this.site = Ps92Site.s1,
  });

  /// The single combination of a buckling or P-Δ analysis in [all]
  /// (its index), or the first ULS one.
  int? combinationIn(List<Combination> all) {
    final c = combinations;
    if (c != null && c.isNotEmpty && c.first >= 0 && c.first < all.length) {
      return c.first;
    }
    final uls = all.indexWhere((c) => c.kind == CombinationKind.uls);
    return uls < 0 ? null : uls;
  }

  AnalysisSpec copyWith({
    String? name,
    List<int>? combinations,
    bool allCombinations = false,
    int? modes,
    bool? ps92,
    double? agR,
    int? importance,
    GroundType? ground,
    bool? type1,
    double? q,
    int? direction,
    bool? torsion,
    double? aN,
    Ps92Site? site,
  }) => AnalysisSpec(
    id: id,
    kind: kind,
    name: name ?? this.name,
    combinations: allCombinations ? null : combinations ?? this.combinations,
    modes: modes ?? this.modes,
    ps92: ps92 ?? this.ps92,
    agR: agR ?? this.agR,
    importance: importance ?? this.importance,
    ground: ground ?? this.ground,
    type1: type1 ?? this.type1,
    q: q ?? this.q,
    direction: direction ?? this.direction,
    torsion: torsion ?? this.torsion,
    aN: aN ?? this.aN,
    site: site ?? this.site,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    if (name.isNotEmpty) 'name': name,
    'combos': ?combinations,
    'modes': modes,
    if (kind == AnalysisKind.spectrum) ...{
      'ps92': ps92,
      'agR': agR,
      'imp': importance,
      'ground': ground.name,
      'type1': type1,
      'q': q,
      'dir': direction,
      'torsion': torsion,
      'aN': aN,
      'site': site.name,
    },
  };

  factory AnalysisSpec.fromJson(Map<String, dynamic> j) {
    double d(String k, double v) => (j[k] as num?)?.toDouble() ?? v;
    return AnalysisSpec(
      id: j['id'] as String,
      kind: AnalysisKind.values.byName(j['kind'] as String),
      name: j['name'] as String? ?? '',
      combinations: (j['combos'] as List?)?.cast<int>(),
      modes: j['modes'] as int? ?? 12,
      ps92: j['ps92'] as bool? ?? false,
      agR: d('agR', 1.6),
      importance: j['imp'] as int? ?? 2,
      ground: GroundType.values.byName(j['ground'] as String? ?? 'b'),
      type1: j['type1'] as bool? ?? false,
      q: d('q', 1.5),
      direction: j['dir'] as int? ?? 2,
      torsion: j['torsion'] as bool? ?? true,
      aN: d('aN', 2.0),
      site: Ps92Site.values.byName(j['site'] as String? ?? 's1'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AnalysisSpec &&
      other.toJson().toString() == toJson().toString();

  @override
  int get hashCode => toJson().toString().hashCode;
}

/// The analyses a model starts with: static (all combinations), the
/// first 12 modes and the buckling factor of the first ULS combination.
const defaultAnalyses = [
  AnalysisSpec(id: 'static', kind: AnalysisKind.static),
  AnalysisSpec(id: 'modal', kind: AnalysisKind.modal),
  AnalysisSpec(id: 'buckling', kind: AnalysisKind.buckling),
];
