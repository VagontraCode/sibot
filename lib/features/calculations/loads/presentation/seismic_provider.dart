import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot_engine/sibot_engine.dart';

final seismicStateProvider =
    NotifierProvider.family<
      SeismicNotifier,
      DesignFormState<SeismicResult>,
      String
    >(SeismicNotifier.new);

/// agR (m/s²) of the French seismic zones (décret 2010-1255).
const frenchZones = {1: 0.4, 2: 0.7, 3: 1.1, 4: 1.6, 5: 3.0};

class SeismicNotifier extends DesignFormNotifier<SeismicResult> {
  SeismicNotifier(super.projectId);

  @override
  Map<String, double?> get initialValues => {
    'agR': null,
    'q': 1.5,
    'storeys': null,
    'storeyHeight': 3,
    'mass': null,
    'roofMass': null,
    'period': null,
  };

  @override
  Map<String, String> get initialOptions => {
    'zone': 'custom',
    'importance': '2',
    'ground': GroundType.b.name,
    'type': '2',
    'system': PeriodSystem.concreteFrame.name,
  };

  @override
  List<String> get requiredKeys => [
    'agR',
    'q',
    'storeys',
    'storeyHeight',
    'mass',
  ];

  /// Applies a French zone: agR and spectrum type (type 1 in zone 5).
  void setZone(String zone) {
    setOption('zone', zone);
    final n = int.tryParse(zone);
    if (n == null) return;
    set('agR', frenchZones[n]);
    setOption('type', n == 5 ? '1' : '2');
  }

  @override
  SeismicResult compute(DesignFormState<SeismicResult> s) {
    final n = s['storeys']!;
    if (n < 1 || n > 60 || n != n.roundToDouble()) {
      throw const InputError(InputProblem.outOfRange, 'storeys');
    }
    final count = n.round();
    final h = s['storeyHeight']!;
    requirePositive(h, 'storeyHeight');
    final mass = s['mass']!;
    final roof = s['roofMass'] ?? mass;
    return lateralForceMethod(
      SeismicInput(
        agR: s['agR']!,
        importanceClass: int.parse(s.options['importance']!),
        ground: GroundType.values.byName(s.options['ground']!),
        type1: s.options['type'] == '1',
        q: s['q']!,
        system: PeriodSystem.values.byName(s.options['system']!),
        masses: [for (var k = 1; k <= count; k++) k == count ? roof : mass],
        heights: [for (var k = 1; k <= count; k++) k * h],
        period: s['period'],
      ),
    );
  }

  @override
  Future<String> saveResult(
    DesignFormState<SeismicResult> s,
    SeismicResult r,
  ) async {
    final id = IdService.generateCalculationId();
    await save(
      id,
      ModuleCalculation(
        id: id,
        projectId: projectId,
        moduleId: 'seismic',
        name: 'Fb = ${r.baseShear.round()} kN',
        createdAt: DateTime.now(),
        isValid: r.periodInRange,
        metadata: flatMetadata(s, {
          't1': r.t1,
          'sd': r.sd,
          'fb': r.baseShear,
          'mOt': r.overturning,
        }),
      ),
    );
    return id;
  }
}
