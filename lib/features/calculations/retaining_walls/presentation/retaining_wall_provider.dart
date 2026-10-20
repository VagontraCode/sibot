import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot_engine/sibot_engine.dart';

final retainingWallStateProvider =
    NotifierProvider.family<WallNotifier, DesignFormState<WallDesign>, String>(
      WallNotifier.new,
    );

class WallNotifier extends DesignFormNotifier<WallDesign> {
  WallNotifier(super.projectId);

  @override
  Map<String, double?> get initialValues => {
    'stemHeight': null,
    'baseThickness': null,
    'toe': null,
    'heel': null,
    'stemTop': 0.2,
    'stemBottom': null,
    'gammaSoil': 18,
    'phi': 30,
    'surcharge': 10,
    'qAdm': null,
    'cover': 40,
    'fck': 25,
    'fyk': 500,
  };

  @override
  List<String> get requiredKeys => const [
    'stemHeight',
    'baseThickness',
    'toe',
    'heel',
    'stemTop',
    'stemBottom',
    'gammaSoil',
    'phi',
    'surcharge',
    'qAdm',
    'cover',
    'fck',
    'fyk',
  ];

  WallInput _input(DesignFormState<WallDesign> s) => WallInput(
    code: s.code,
    stemHeight: s['stemHeight'] ?? 0,
    baseThickness: s['baseThickness'] ?? 0,
    toe: s['toe'] ?? 0,
    heel: s['heel'] ?? 0,
    stemTop: s['stemTop'] ?? 0.2,
    stemBottom: s['stemBottom'] ?? 0,
    soilWeight: s['gammaSoil'] ?? 18,
    phi: s['phi'] ?? 30,
    surcharge: s['surcharge'] ?? 0,
    qAllowable: s['qAdm'] ?? 0,
    cover: s['cover'] ?? 40,
    fck: s['fck'] ?? 25,
    fyk: s['fyk'] ?? 500,
  );

  /// Fills the geometry with typical proportions for the stem height.
  void presize() {
    final h = state['stemHeight'];
    if (h == null || h <= 0) {
      state = state.copyWith(problem: const FormProblem('stemHeight'));
      return;
    }
    final p = presizeWall(_input(state));
    setAll({
      'baseThickness': p.baseThickness,
      'toe': p.toe,
      'heel': p.heel,
      'stemTop': p.stemTop,
      'stemBottom': p.stemBottom,
    });
  }

  @override
  WallDesign compute(DesignFormState<WallDesign> s) => designWall(_input(s));

  @override
  Future<String> persist(DesignFormState<WallDesign> s, WallDesign r) async {
    final id = IdService.generateCalculationId();
    await save(
      id,
      RetainingWallCalculation(
        id: id,
        projectId: projectId,
        name: 'Wall H=${s['stemHeight']}',
        height: s['stemHeight']!,
        soilDensity: s['gammaSoil']!,
        frictionAngle: s['phi']!,
        concrete: s['fck']!,
        steel: s['fyk']!,
        createdAt: DateTime.now(),
        isValid: r.ok,
        metadata: flatMetadata(s, {
          'fsOverturning': r.fsOverturning,
          'fsSliding': r.fsSliding,
          'pressure': r.pressure,
          'stemBars': r.stemBars?.toString(),
        }),
      ),
    );
    return id;
  }
}
