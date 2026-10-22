import 'dart:convert';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// A saved 3D model: the generator parameters and, once edited, the
/// edited model itself.
class Frame3DRecord {
  final String id;
  final String projectId;
  final String name;
  final DateTime updatedAt;
  final BuildingParams params;

  /// Edited model (null while the model is the generated building).
  final Model3D? custom;

  /// Lumped seismic masses (t) carried over from the generator; dropped
  /// when the nodes change.
  final List<double>? masses;

  /// A free model (drawn from scratch, a 2D frame or an import): it has
  /// no generator to go back to; [params] only carry the rigid-floor
  /// setting.
  final bool free;

  /// The user's analyses (null = [defaultAnalyses]).
  final List<AnalysisSpec>? savedAnalyses;

  List<AnalysisSpec> get analyses => savedAnalyses ?? defaultAnalyses;

  const Frame3DRecord({
    required this.id,
    required this.projectId,
    required this.name,
    required this.updatedAt,
    required this.params,
    this.custom,
    this.masses,
    this.free = false,
    this.savedAnalyses,
  });

  /// The same record with another list of analyses.
  Frame3DRecord withAnalyses(List<AnalysisSpec> list) => Frame3DRecord(
    id: id,
    projectId: projectId,
    name: name,
    updatedAt: DateTime.now(),
    params: params,
    custom: custom,
    masses: masses,
    free: free,
    savedAnalyses: list,
  );

  /// A free model starting from [model].
  factory Frame3DRecord.free({
    required String id,
    required String projectId,
    required String name,
    required Model3D model,
    bool rigidFloors = false,
  }) => Frame3DRecord(
    id: id,
    projectId: projectId,
    name: name,
    updatedAt: DateTime.now(),
    params: BuildingParams(
      spansX: const [5],
      spansY: const [5],
      storeyHeights: const [3],
      column: Section3D.rectangle(300, 300),
      beam: Section3D.rectangle(250, 500),
      rigidFloors: rigidFloors,
    ),
    custom: model,
    free: true,
  );

  /// The same record with rigid floors switched on or off (the model is
  /// kept).
  Frame3DRecord withRigidFloors(bool on) {
    final p = params;
    return Frame3DRecord(
      id: id,
      projectId: projectId,
      name: name,
      updatedAt: DateTime.now(),
      params: BuildingParams(
        spansX: p.spansX,
        spansY: p.spansY,
        storeyHeights: p.storeyHeights,
        column: p.column,
        beam: p.beam,
        g: p.g,
        q: p.q,
        facade: p.facade,
        rigidFloors: on,
      ),
      custom: custom,
      masses: masses,
      free: free,
      savedAnalyses: savedAnalyses,
    );
  }

  /// The model to analyse.
  Model3D get model => custom ?? buildingFrame(params);

  Frame3DRecord copyWith({String? name, BuildingParams? params}) =>
      Frame3DRecord(
        id: id,
        projectId: projectId,
        name: name ?? this.name,
        updatedAt: DateTime.now(),
        params: params ?? this.params,
        // New parameters regenerate the building.
        custom: params == null ? custom : null,
        masses: params == null ? masses : null,
        free: params == null && free,
        savedAnalyses: savedAnalyses,
      );

  /// The record with an edited model; masses are kept only while the
  /// node count is unchanged.
  Frame3DRecord withModel(Model3D m) {
    final previous = masses ?? (custom == null ? _generatedMasses() : null);
    return Frame3DRecord(
      id: id,
      projectId: projectId,
      name: name,
      updatedAt: DateTime.now(),
      params: params,
      custom: m,
      masses: previous != null && previous.length == m.nodes.length
          ? previous
          : null,
      free: free,
      savedAnalyses: savedAnalyses,
    );
  }

  List<double> _generatedMasses() =>
      buildingNodeMasses(params, buildingFrame(params));

  /// Back to the generated building (free models stay as they are).
  Frame3DRecord regenerated() => free
      ? this
      : Frame3DRecord(
          id: id,
          projectId: projectId,
          name: name,
          updatedAt: DateTime.now(),
          params: params,
          savedAnalyses: savedAnalyses,
        );

  Map<String, dynamic> toStored() => {
    'id': id,
    'projectId': projectId,
    'name': name,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'params': jsonEncode(params.toJson()),
    if (custom != null) 'model': jsonEncode(custom!.toJson()),
    if (masses != null) 'masses': masses,
    if (free) 'free': true,
    if (savedAnalyses != null)
      'analyses': jsonEncode([for (final a in savedAnalyses!) a.toJson()]),
  };

  static Frame3DRecord? fromStored(Object? v) {
    if (v is! Map) return null;
    try {
      final model = v['model'] as String?;
      return Frame3DRecord(
        id: v['id'] as String,
        projectId: v['projectId'] as String,
        name: v['name'] as String,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(v['updatedAt'] as int),
        params: BuildingParams.fromJson(
          Map<String, dynamic>.from(jsonDecode(v['params'] as String) as Map),
        ),
        custom: model == null
            ? null
            : Model3D.fromJson(
                Map<String, dynamic>.from(jsonDecode(model) as Map),
              ),
        masses: (v['masses'] as List?)
            ?.map((e) => (e as num).toDouble())
            .toList(),
        free: v['free'] as bool? ?? false,
        savedAnalyses: v['analyses'] == null
            ? null
            : [
                for (final a in jsonDecode(v['analyses'] as String) as List)
                  AnalysisSpec.fromJson(Map<String, dynamic>.from(a as Map)),
              ],
      );
    } catch (e) {
      LoggerService.w('Unreadable 3D model: $e');
      return null;
    }
  }
}

class Frame3DRepository {
  static dynamic get _box => HiveService.getBox(HiveService.frame3dModelsBox);

  static List<Frame3DRecord> forProject(String projectId) {
    final out = <Frame3DRecord>[];
    for (final v in _box.values) {
      final r = Frame3DRecord.fromStored(v);
      if (r != null && r.projectId == projectId) out.add(r);
    }
    out.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return out;
  }

  static Frame3DRecord? get(String id) =>
      Frame3DRecord.fromStored(_box.get(id));

  static Future<void> save(Frame3DRecord r) => _box.put(r.id, r.toStored());

  static Future<void> delete(String id) => _box.delete(id);

  static Stream<void> watch() => (_box).watch().map((_) {});
}

final frame3dModelsProvider =
    StreamProvider.family<List<Frame3DRecord>, String>((ref, projectId) async* {
      yield Frame3DRepository.forProject(projectId);
      await for (final _ in Frame3DRepository.watch()) {
        yield Frame3DRepository.forProject(projectId);
      }
    });

final frame3dRecordProvider = StreamProvider.family<Frame3DRecord?, String>((
  ref,
  id,
) async* {
  yield Frame3DRepository.get(id);
  await for (final _ in Frame3DRepository.watch()) {
    yield Frame3DRepository.get(id);
  }
});

/// What an isolate analyses, as JSON (value equality for provider keys).
String sourceKey(Frame3DRecord r) => jsonEncode({
  'p': r.params.toJson(),
  if (r.custom != null) 'm': r.custom!.toJson(),
  if (r.masses != null) 'mass': r.masses,
});

/// Model and modal options decoded from a [sourceKey].
(Model3D, ModalOptions) _source(String key, {int modes = 12}) {
  final j = Map<String, dynamic>.from(jsonDecode(key) as Map);
  final params = BuildingParams.fromJson(
    Map<String, dynamic>.from(j['p'] as Map),
  );
  final custom = j['m'] == null
      ? null
      : Model3D.fromJson(Map<String, dynamic>.from(j['m'] as Map));
  final model = custom ?? buildingFrame(params);
  final stored = (j['mass'] as List?)
      ?.map((e) => (e as num).toDouble())
      .toList();
  // Generated buildings: tributary floor areas × (g + 0.3 q) plus
  // self-weight; edited models: stored masses while the nodes are
  // unchanged, else the load cases with ψ2 factors (EN 1998-1 3.2.4).
  final masses = custom == null
      ? buildingNodeMasses(params, model)
      : (stored != null && stored.length == model.nodes.length ? stored : null);
  return (
    model,
    ModalOptions(
      modes: modes,
      nodeMasses: masses,
      massCases: masses == null ? model.seismicMassFactors() : const {},
    ),
  );
}

/// Everything computed for a model, sent back from an isolate.
class Frame3DOutput {
  final Model3D model;
  final List<Combination> combinations;
  final List<Frame3DResult> results;

  /// Results of the load cases themselves.
  final List<Frame3DResult> caseResults;
  final List<Mode> modes;
  final List<double> totalMass;

  /// Critical load factor and buckled shape for the first ULS
  /// combination (null without compression).
  final double? alphaCr;
  final List<List<double>>? bucklingShape;

  /// Whether the buckling analysis has run (αcr may still be null when
  /// nothing is compressed).
  final bool bucklingDone;
  final String? error;

  const Frame3DOutput({
    required this.model,
    this.combinations = const [],
    this.results = const [],
    this.caseResults = const [],
    this.modes = const [],
    this.totalMass = const [0, 0, 0],
    this.alphaCr,
    this.bucklingShape,
    this.bucklingDone = false,
    this.error,
  });

  /// This output with modal and buckling results merged in.
  Frame3DOutput merged({ModalOutput? modal, BucklingOutput? buckling}) =>
      Frame3DOutput(
        model: model,
        combinations: combinations,
        results: results,
        caseResults: caseResults,
        modes: modal?.modes ?? modes,
        totalMass: modal?.totalMass ?? totalMass,
        alphaCr: buckling == null ? alphaCr : buckling.alpha,
        bucklingShape: buckling == null ? bucklingShape : buckling.shape,
        bucklingDone: buckling != null || bucklingDone,
        error: error,
      );

  int? get firstUls {
    for (var i = 0; i < combinations.length; i++) {
      if (combinations[i].kind == CombinationKind.uls) return i;
    }
    return null;
  }

  /// Quasi-permanent forces Σ G + ψ2 Q for the seismic situation.
  Frame3DResult? get quasiPermanent {
    Frame3DResult? out;
    for (final e in model.seismicMassFactors().entries) {
      if (e.key >= caseResults.length) continue;
      final r = caseResults[e.key].scaled(e.value);
      out = out == null ? r : out.plus(r);
    }
    return out;
  }
}

Frame3DOutput runFrame3d(String key, DesignCode code) {
  final (model, _) = _source(key);
  try {
    final an = Frame3DAnalysis(model);
    final cases = an.solveAll();
    final combos = combinationsOf(model, code);
    final results = [
      for (final c in combos)
        if (!combinationValid(model, c))
          cases.first.scaled(0)
        else
          c.factors.entries
              .map((e) => cases[e.key].scaled(e.value))
              .reduce((a, b) => a.plus(b)),
    ];
    // Modes and buckling are computed on demand (separate providers).
    return Frame3DOutput(
      model: model,
      combinations: combos,
      results: results,
      caseResults: cases,
    );
  } on ModelError catch (e) {
    return Frame3DOutput(
      model: model,
      error: '${e.problem.name}${e.index == null ? '' : ' (${e.index! + 1})'}',
    );
  }
}

final frame3dAnalysisProvider =
    FutureProvider.family<Frame3DOutput, (String, DesignCode)>((ref, key) {
      final (source, code) = key;
      return Isolate.run(() => runFrame3d(source, code));
    });

/// Second-order result of one combination.
Frame3DResult runPDelta(String key, int combo, DesignCode code) {
  final (model, _) = _source(key);
  final combos = combinationsOf(model, code);
  final m = withCase(model, combinedCase(model, combos[combo].factors));
  return Frame3DAnalysis(m).pDeltaCase(model.cases.length);
}

final frame3dPDeltaProvider =
    FutureProvider.family<Frame3DResult, (String, int, DesignCode)>((ref, key) {
      final (source, combo, code) = key;
      return Isolate.run(() => runPDelta(source, combo, code));
    });

/// Seismic input of the spectrum analysis.
class SpectrumRequest {
  final double agR;
  final int importance;
  final GroundType ground;
  final bool type1;
  final double q;

  /// 0 = X, 1 = Y, 2 = both combined as E + 0.3 E.
  final int direction;
  final bool torsion;

  /// PS92 instead of EN 1998-1: nominal acceleration and site class.
  final bool ps92;
  final double aN;
  final Ps92Site site;

  /// Modes of the underlying modal analysis.
  final int modes;

  const SpectrumRequest({
    required this.agR,
    required this.ground,
    this.importance = 2,
    this.type1 = false,
    this.q = 1.5,
    this.direction = 0,
    this.torsion = true,
    this.ps92 = false,
    this.aN = 0,
    this.site = Ps92Site.s1,
    this.modes = 12,
  });

  /// The request of a spectrum analysis.
  factory SpectrumRequest.of(AnalysisSpec s) => SpectrumRequest(
    agR: s.agR,
    ground: s.ground,
    importance: s.importance,
    type1: s.type1,
    q: s.q,
    direction: s.direction,
    torsion: s.torsion,
    ps92: s.ps92,
    aN: s.aN,
    site: s.site,
    modes: s.modes,
  );

  @override
  bool operator ==(Object other) =>
      other is SpectrumRequest &&
      other.agR == agR &&
      other.importance == importance &&
      other.ground == ground &&
      other.type1 == type1 &&
      other.q == q &&
      other.direction == direction &&
      other.torsion == torsion &&
      other.ps92 == ps92 &&
      other.aN == aN &&
      other.site == site &&
      other.modes == modes;

  @override
  int get hashCode => Object.hash(
    agR,
    importance,
    ground,
    type1,
    q,
    direction,
    torsion,
    ps92,
    aN,
    site,
    modes,
  );
}

/// Spectrum runs (one per direction) and the response to display.
class SeismicOutput {
  final List<SpectrumResult> runs;
  final Frame3DResult envelope;
  const SeismicOutput(this.runs, this.envelope);
}

SeismicOutput runSpectrum(String key, SpectrumRequest r) {
  final (model, options) = _source(key, modes: r.modes);
  final modal = modalAnalysis(model, options: options);
  SpectrumResult run(int d) => responseSpectrum(
    modal,
    direction: d,
    ag: r.agR * importanceFactors[r.importance]!,
    spectrum: spectrumParams(r.ground, type1: r.type1),
    q: r.q,
    accidentalTorsion: r.torsion,
    design: r.ps92 ? (t) => ps92Spectrum(t, r.aN, r.site, r.q) : null,
  );
  if (r.direction == 2) {
    final x = run(0), y = run(1);
    return SeismicOutput([x, y], combineDirections(x.combined, y.combined));
  }
  final s = run(r.direction);
  return SeismicOutput([s], s.combined);
}

final frame3dSpectrumProvider =
    FutureProvider.family<SeismicOutput, (String, SpectrumRequest)>((ref, key) {
      final (source, request) = key;
      return Isolate.run(() => runSpectrum(source, request));
    });

/// Natural modes and the vibrating mass of a model.
class ModalOutput {
  final List<Mode> modes;
  final List<double> totalMass;
  const ModalOutput(this.modes, this.totalMass);
}

ModalOutput runModal(String key, [int modes = 12]) {
  final (model, options) = _source(key, modes: modes);
  try {
    final r = modalAnalysis(model, options: options);
    return ModalOutput(r.modes, r.totalMass);
  } on ModelError {
    return const ModalOutput([], [0, 0, 0]);
  }
}

/// Modes are computed when first needed (Modes tab, seismic mass, note).
final frame3dModalProvider = FutureProvider.family<ModalOutput, (String, int)>((
  ref,
  key,
) {
  final (source, modes) = key;
  return Isolate.run(() => runModal(source, modes));
});

/// Critical load factor of the first ULS combination.
class BucklingOutput {
  final double? alpha;
  final List<List<double>>? shape;
  const BucklingOutput(this.alpha, this.shape);
}

BucklingOutput runBuckling(String key, DesignCode code, [int? combo]) {
  final (model, _) = _source(key);
  try {
    final combos = combinationsOf(model, code);
    final uls =
        combo ?? combos.indexWhere((c) => c.kind == CombinationKind.uls);
    if (uls < 0 || uls >= combos.length) {
      return const BucklingOutput(null, null);
    }
    if (!combinationValid(model, combos[uls])) {
      return const BucklingOutput(null, null);
    }
    final an = Frame3DAnalysis(model);
    final cases = an.solveAll();
    final result = combos[uls].factors.entries
        .map((e) => cases[e.key].scaled(e.value))
        .reduce((a, b) => a.plus(b));
    final b = an.bucklingFactorOf(result);
    return BucklingOutput(b?.$1, b?.$2);
  } on ModelError {
    return const BucklingOutput(null, null);
  }
}

final frame3dBucklingProvider =
    FutureProvider.family<BucklingOutput, (String, DesignCode, int?)>((
      ref,
      key,
    ) {
      final (source, code, combo) = key;
      return Isolate.run(() => runBuckling(source, code, combo));
    });

/// Design of every grouped member, sent back from an isolate.
class DesignOutput {
  final List<MemberDesign3D> members;

  /// Members in no group.
  final int ungrouped;
  final String? error;
  const DesignOutput(this.members, {this.ungrouped = 0, this.error});

  int get failing => members.where((m) => !m.ok).length;

  /// Ratio of each member (null = not designed), for the colour map.
  List<double?> ratios(int count) {
    final out = List<double?>.filled(count, null);
    for (final m in members) {
      if (m.member < count) out[m.member] = m.ratio;
    }
    return out;
  }
}

/// Designs the model's groups from all ULS combinations, deflections
/// under the characteristic SLS ones.
DesignOutput runDesign(String key, DesignCode code) {
  final (model, _) = _source(key);
  try {
    final an = Frame3DAnalysis(model);
    final cases = an.solveAll();
    Frame3DResult combine(Combination c) => c.factors.entries
        .map((e) => cases[e.key].scaled(e.value))
        .reduce((a, b) => a.plus(b));
    final combos = [
      for (final c in combinationsOf(model, code))
        if (combinationValid(model, c)) c,
    ];
    final uls = [
      for (final c in combos)
        if (c.kind == CombinationKind.uls) combine(c),
    ];
    final sls = [
      for (final c in combos)
        if (c.kind == CombinationKind.slsCharacteristic) combine(c),
    ];
    if (uls.isEmpty) return const DesignOutput([], error: 'uls');
    final grouped = {for (final g in model.groups) ...g.members};
    return DesignOutput(
      designGroups(model, model.groups, uls, sls),
      ungrouped:
          model.elements.length -
          grouped.where((e) => e >= 0 && e < model.elements.length).length,
    );
  } on ModelError catch (e) {
    return DesignOutput(const [], error: e.problem.name);
  }
}

final frame3dDesignProvider =
    FutureProvider.family<DesignOutput, (String, DesignCode)>((ref, key) {
      final (source, code) = key;
      return Isolate.run(() => runDesign(source, code));
    });
