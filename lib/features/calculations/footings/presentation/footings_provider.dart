import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot_engine/sibot_engine.dart';

final footingStateProvider =
    NotifierProvider.family<
      FootingNotifier,
      DesignFormState<FootingDesign>,
      String
    >(FootingNotifier.new);

class FootingNotifier extends DesignFormNotifier<FootingDesign> {
  FootingNotifier(super.projectId);

  @override
  Map<String, double?> get initialValues => {
    'a': null,
    'b': null,
    'g': null,
    'q': null,
    'mg': 0,
    'mq': 0,
    'qAdm': null,
    'depth': 1.0,
    'gammaSoil': 18,
    'cover': 50,
    'fck': 25,
    'fyk': 500,
  };

  @override
  List<String> get requiredKeys => const [
    'a',
    'b',
    'g',
    'q',
    'mg',
    'mq',
    'qAdm',
    'depth',
    'gammaSoil',
    'cover',
    'fck',
    'fyk',
  ];

  @override
  FootingDesign compute(DesignFormState<FootingDesign> s) => designFooting(
    FootingInput(
      code: s.code,
      a: s['a']!,
      b: s['b']!,
      g: s['g']!,
      q: s['q']!,
      mg: s['mg']!,
      mq: s['mq']!,
      qAllowable: s['qAdm']!,
      depth: s['depth']!,
      soilWeight: s['gammaSoil']!,
      cover: s['cover']!,
      fck: s['fck']!,
      fyk: s['fyk']!,
    ),
  );

  @override
  Future<String> persist(
    DesignFormState<FootingDesign> s,
    FootingDesign r,
  ) async {
    final id = IdService.generateCalculationId();
    final now = DateTime.now();
    await save(
      id,
      FootingCalculation(
        id: id,
        projectId: projectId,
        name:
            'Footing ${r.lengthA.toStringAsFixed(2)}×${r.widthB.toStringAsFixed(2)}',
        columnLoad: s['g']! + s['q']!,
        columnMoment: s['mg']! + s['mq']!,
        soilBearingCapacity: s['qAdm']!,
        soilDensity: s['gammaSoil']!,
        concrete: s['fck']!,
        steel: s['fyk']!,
        footing: 'isolated',
        code: s.code == DesignCode.bael ? 'bael99' : 'eurocode',
        requiredArea: r.area,
        footingLength: r.lengthA,
        footingWidth: r.widthB,
        footingDepth: r.h,
        reinforcementRatio: r.asA / (r.widthB * 1000 * r.d),
        createdAt: now,
        updatedAt: now,
        isValid: r.ok,
        metadata: flatMetadata(s, {
          'pressure': r.pressure,
          'barsA': r.barsA?.toString(),
          'barsB': r.barsB?.toString(),
        }),
      ),
    );
    return id;
  }
}
