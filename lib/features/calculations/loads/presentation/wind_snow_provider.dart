import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot_engine/sibot_engine.dart';

class ClimateResult {
  final WindResult wind;
  final SnowResult snow;

  /// Wind roof zones are given for flat roofs only.
  final bool flatRoof;
  const ClimateResult(this.wind, this.snow, {required this.flatRoof});
}

final windSnowStateProvider =
    NotifierProvider.family<
      WindSnowNotifier,
      DesignFormState<ClimateResult>,
      String
    >(WindSnowNotifier.new);

class WindSnowNotifier extends DesignFormNotifier<ClimateResult> {
  WindSnowNotifier(super.projectId);

  @override
  Map<String, double?> get initialValues => {
    'vb': null,
    'h': null,
    'b': null,
    'd': null,
    'sk': null,
    'alpha1': 0,
    'alpha2': 0,
    'ce': 1.0,
  };

  @override
  Map<String, String> get initialOptions => {
    'terrain': TerrainCategory.catIII.name,
    'roof': RoofShape.flat.name,
  };

  @override
  List<String> get requiredKeys => [
    'vb',
    'h',
    'b',
    'd',
    'sk',
    if (state.options['roof'] != RoofShape.flat.name) 'alpha1',
    if (state.options['roof'] == RoofShape.duopitch.name) 'alpha2',
    'ce',
  ];

  @override
  ClimateResult compute(DesignFormState<ClimateResult> s) {
    final shape = RoofShape.values.byName(s.options['roof']!);
    return ClimateResult(
      designWind(
        vb: s['vb']!,
        terrain: TerrainCategory.values.byName(s.options['terrain']!),
        h: s['h']!,
        b: s['b']!,
        d: s['d']!,
      ),
      designSnow(
        sk: s['sk']!,
        shape: shape,
        alpha1: shape == RoofShape.flat ? 0 : s['alpha1']!,
        alpha2: shape == RoofShape.duopitch ? s['alpha2']! : 0,
        ce: s['ce']!,
      ),
      flatRoof: shape == RoofShape.flat,
    );
  }

  @override
  Future<String> saveResult(
    DesignFormState<ClimateResult> s,
    ClimateResult r,
  ) async {
    final id = IdService.generateCalculationId();
    await save(
      id,
      ModuleCalculation(
        id: id,
        projectId: projectId,
        moduleId: 'wind-snow',
        name:
            'qp ${r.wind.peak.qp.toStringAsFixed(2)} · s ${r.snow.max.toStringAsFixed(2)}',
        createdAt: DateTime.now(),
        isValid: true,
        metadata: flatMetadata(s, {
          'qp': r.wind.peak.qp,
          'ce': r.wind.peak.ce,
          'netWall': r.wind.netWall,
          'snowMax': r.snow.max,
        }),
      ),
    );
    return id;
  }
}
