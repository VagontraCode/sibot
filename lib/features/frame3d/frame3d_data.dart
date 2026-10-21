import 'dart:convert';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// A saved 3D building model: its generator parameters.
class Frame3DRecord {
  final String id;
  final String projectId;
  final String name;
  final DateTime updatedAt;
  final BuildingParams params;

  const Frame3DRecord({
    required this.id,
    required this.projectId,
    required this.name,
    required this.updatedAt,
    required this.params,
  });

  Frame3DRecord copyWith({String? name, BuildingParams? params}) =>
      Frame3DRecord(
        id: id,
        projectId: projectId,
        name: name ?? this.name,
        updatedAt: DateTime.now(),
        params: params ?? this.params,
      );

  Map<String, dynamic> toStored() => {
    'id': id,
    'projectId': projectId,
    'name': name,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'params': jsonEncode(params.toJson()),
  };

  static Frame3DRecord? fromStored(Object? v) {
    if (v is! Map) return null;
    try {
      return Frame3DRecord(
        id: v['id'] as String,
        projectId: v['projectId'] as String,
        name: v['name'] as String,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(v['updatedAt'] as int),
        params: BuildingParams.fromJson(
          Map<String, dynamic>.from(jsonDecode(v['params'] as String) as Map),
        ),
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

/// Everything computed for a model, sent back from an isolate.
class Frame3DOutput {
  final Model3D model;
  final List<Combination> combinations;
  final List<Frame3DResult> results;
  final List<Mode> modes;
  final List<double> totalMass;

  /// Critical load factor and buckled shape for the first ULS
  /// combination (null without compression).
  final double? alphaCr;
  final List<List<double>>? bucklingShape;
  final String? error;

  const Frame3DOutput({
    required this.model,
    this.combinations = const [],
    this.results = const [],
    this.modes = const [],
    this.totalMass = const [0, 0, 0],
    this.alphaCr,
    this.bucklingShape,
    this.error,
  });

  int? get firstUls {
    for (var i = 0; i < combinations.length; i++) {
      if (combinations[i].kind == CombinationKind.uls) return i;
    }
    return null;
  }
}

// Modal masses: tributary floor areas × (g + 0.3 q) plus self-weight
// (EN 1998-1 3.2.4 with ψE = 0.3).

Frame3DOutput runFrame3d(BuildingParams params, DesignCode code) {
  final model = buildingFrame(params);
  try {
    final an = Frame3DAnalysis(model);
    final cases = an.solveAll();
    final combos = combinationsFor([
      for (final c in model.cases) (c.name, c.type),
    ], code);
    final results = [
      for (final c in combos)
        c.factors.entries
            .map((e) => cases[e.key].scaled(e.value))
            .reduce((a, b) => a.plus(b)),
    ];
    final modal = modalAnalysis(
      model,
      options: ModalOptions(
        modes: 12,
        nodeMasses: buildingNodeMasses(params, model),
      ),
    );
    double? alpha;
    List<List<double>>? shape;
    final uls = combos.indexWhere((c) => c.kind == CombinationKind.uls);
    if (uls >= 0) {
      final withUls = withCase(model, combinedCase(model, combos[uls].factors));
      final b = Frame3DAnalysis(withUls).bucklingFactor(model.cases.length);
      if (b != null) (alpha, shape) = b;
    }
    return Frame3DOutput(
      model: model,
      combinations: combos,
      results: results,
      modes: modal.modes,
      totalMass: modal.totalMass,
      alphaCr: alpha,
      bucklingShape: shape,
    );
  } on ModelError catch (e) {
    return Frame3DOutput(model: model, error: e.problem.name);
  }
}

final frame3dAnalysisProvider =
    FutureProvider.family<Frame3DOutput, (String, DesignCode)>((ref, key) {
      final (json, code) = key;
      return Isolate.run(() => runFrame3d(_decode(json), code));
    });

/// Second-order result of one combination.
Frame3DResult runPDelta(BuildingParams params, Map<int, double> factors) {
  final model = buildingFrame(params);
  final m = withCase(model, combinedCase(model, factors));
  return Frame3DAnalysis(m).pDeltaCase(model.cases.length);
}

final frame3dPDeltaProvider =
    FutureProvider.family<Frame3DResult, (String, int, DesignCode)>((ref, key) {
      final (json, combo, code) = key;
      return Isolate.run(() {
        final params = _decode(json);
        final model = buildingFrame(params);
        final combos = combinationsFor([
          for (final c in model.cases) (c.name, c.type),
        ], code);
        return runPDelta(params, combos[combo].factors);
      });
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
  });

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
      other.site == site;

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
  );
}

/// Spectrum runs (one per direction) and the response to display.
class SeismicOutput {
  final List<SpectrumResult> runs;
  final Frame3DResult envelope;
  const SeismicOutput(this.runs, this.envelope);
}

SeismicOutput runSpectrum(BuildingParams params, SpectrumRequest r) {
  final model = buildingFrame(params);
  final modal = modalAnalysis(
    model,
    options: ModalOptions(
      modes: 12,
      nodeMasses: buildingNodeMasses(params, model),
    ),
  );
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
      final (json, request) = key;
      return Isolate.run(() => runSpectrum(_decode(json), request));
    });

/// Provider key of a model: its parameters as JSON (value equality).
String paramsKey(BuildingParams p) => jsonEncode(p.toJson());

BuildingParams _decode(String json) =>
    BuildingParams.fromJson(Map<String, dynamic>.from(jsonDecode(json) as Map));
