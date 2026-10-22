import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// ULS and SLS plate results with the reinforcement.
class PlateDesign {
  final PlateInput input;
  final PlateResult uls;
  final PlateResult sls;
  final PlateReinforcement steel;
  final double fck;

  const PlateDesign({
    required this.input,
    required this.uls,
    required this.sls,
    required this.steel,
    required this.fck,
  });

  /// Soil pressure under a raft (SLS), kPa, per node.
  double soilPressure(int node) => input.subgrade * sls.w[node];
}

/// Parses "x,y x,y" (or ';'-separated) into pairs, and "x,y,P" triples.
List<List<double>>? parseTuples(String text, int size) {
  final out = <List<double>>[];
  for (final part in text.split(RegExp(r'[;\s]+'))) {
    if (part.trim().isEmpty) continue;
    final v = part.split(',').map((s) => double.tryParse(s.trim())).toList();
    if (v.length != size || v.any((x) => x == null)) return null;
    out.add(v.cast<double>());
  }
  return out;
}

final plateStateProvider =
    NotifierProvider.family<
      PlateNotifier,
      DesignFormState<PlateDesign>,
      String
    >(PlateNotifier.new);

class PlateNotifier extends DesignFormNotifier<PlateDesign> {
  PlateNotifier(super.projectId);

  @override
  Map<String, double?> get initialValues => {
    'lx': null,
    'ly': null,
    't': null,
    'g': 1.5,
    'q': 2.5,
    'k': 20000,
    'mesh': 16,
    'fck': 25,
    'fyk': 500,
    'cover': 25,
  };

  @override
  Map<String, String> get initialOptions => {
    'mode': 'slab',
    'left': EdgeSupport.simple.name,
    'right': EdgeSupport.simple.name,
    'bottom': EdgeSupport.simple.name,
    'top': EdgeSupport.simple.name,
    'columns': '',
    'points': '',
  };

  @override
  List<String> get requiredKeys => [
    'lx',
    'ly',
    't',
    'g',
    'q',
    if (state.options['mode'] == 'raft') 'k',
    'mesh',
    'fck',
    'fyk',
    'cover',
  ];

  void setMode(String mode) {
    setOption('mode', mode);
    // A raft rests on the soil: free edges by default.
    final edge = mode == 'raft' ? EdgeSupport.free : EdgeSupport.simple;
    for (final e in ['left', 'right', 'bottom', 'top']) {
      setOption(e, edge.name);
    }
  }

  @override
  PlateDesign compute(DesignFormState<PlateDesign> s) =>
      plateDesign(s.values, s.options, s.code);

  // Meshes up to 40 × 40: run off the UI thread.
  @override
  Future<PlateDesign> computeAsync(DesignFormState<PlateDesign> s) =>
      _plateInIsolate(s.values, s.options, s.code);

  @override
  Future<String> saveResult(
    DesignFormState<PlateDesign> s,
    PlateDesign r,
  ) async {
    final id = IdService.generateCalculationId();
    double max(List<double> v) => v.reduce((a, b) => a > b ? a : b);
    await save(
      id,
      ModuleCalculation(
        id: id,
        projectId: projectId,
        moduleId: 'plate',
        name:
            '${s['lx']} × ${s['ly']} m · ${s['t']!.round()} mm (${s.options['mode']})',
        createdAt: DateTime.now(),
        isValid: true,
        metadata: flatMetadata(s, {
          'wMax': max(r.sls.w) * 1000,
          'asBx': max(r.steel.bottomX),
          'asBy': max(r.steel.bottomY),
          'asTx': max(r.steel.topX),
          'asTy': max(r.steel.topY),
        }),
      ),
    );
    return id;
  }
}

Future<PlateDesign> _plateInIsolate(
  Map<String, double?> values,
  Map<String, String> options,
  DesignCode code,
) => Isolate.run(() => plateDesign(values, options, code));

/// ULS and SLS plate analyses and reinforcement from the form values.
PlateDesign plateDesign(
  Map<String, double?> values,
  Map<String, String> options,
  DesignCode code,
) {
  double? v(String k) => values[k];
  final raft = options['mode'] == 'raft';
  final columns = parseTuples(options['columns']!, 2);
  if (columns == null) {
    throw const InputError(InputProblem.outOfRange, 'columns');
  }
  final points = parseTuples(options['points']!, 3);
  if (points == null) {
    throw const InputError(InputProblem.outOfRange, 'points');
  }
  final lx = v('lx')!, ly = v('ly')!, t = v('t')!;
  for (final c in [...columns, ...points]) {
    if (c[0] < 0 || c[0] > lx || c[1] < 0 || c[1] > ly) {
      throw InputError(
        InputProblem.outOfRange,
        c.length == 2 ? 'columns' : 'points',
      );
    }
  }
  final mesh = v('mesh')!.round();
  requireRange(mesh.toDouble(), 4, 40, 'mesh');
  // Mesh: [mesh] elements along the longer side, square-ish elements.
  final longer = lx >= ly ? lx : ly;
  final size = longer / mesh;
  final nx = (lx / size).round().clamp(2, 40);
  final ny = (ly / size).round().clamp(2, 40);
  final fck = v('fck')!;
  final concrete = Concrete(code, fck);
  EdgeSupport edge(String k) => EdgeSupport.values.byName(options[k]!);
  final base = PlateInput(
    lx: lx,
    ly: ly,
    t: t,
    e: concrete.ecm,
    nu: 0.2,
    nx: nx,
    ny: ny,
    left: edge('left'),
    right: edge('right'),
    bottom: edge('bottom'),
    top: edge('top'),
    columns: [for (final c in columns) (c[0], c[1])],
    subgrade: raft ? v('k')! : 0,
  );
  final selfWeight = 25 * t / 1000;
  final g = v('g')! + selfWeight, q = v('q')!;
  // Point loads are characteristic permanent loads (e.g. columns on a
  // raft).
  List<PlatePointLoad> pts(double f) => [
    for (final p in points) PlatePointLoad(p[0], p[1], f * p[2]),
  ];
  // ULS and SLS on one factorisation.
  final results = analysePlateCases(base, [
    (1.35 * g + 1.5 * q, pts(1.35)),
    (g + q, pts(1)),
  ]);
  final uls = results[0], sls = results[1];
  final steel = plateReinforcement(
    uls,
    code: code,
    t: t,
    fck: fck,
    fyk: v('fyk')!,
    cover: v('cover')!,
  );
  return PlateDesign(input: base, uls: uls, sls: sls, steel: steel, fck: fck);
}
