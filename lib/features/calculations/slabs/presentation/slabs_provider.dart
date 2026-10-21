import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot_engine/sibot_engine.dart';

final slabStateProvider =
    NotifierProvider.family<SlabNotifier, DesignFormState<SlabDesign>, String>(
      SlabNotifier.new,
    );

class SlabNotifier extends DesignFormNotifier<SlabDesign> {
  SlabNotifier(super.projectId);

  @override
  Map<String, double?> get initialValues => {
    'lx': null,
    'ly': null,
    'h': null,
    'g': null,
    'q': null,
    'cover': 25,
    'fck': 25,
    'fyk': 500,
    'punchLoad': null,
    'punchC1': 300,
    'punchC2': 300,
  };

  @override
  Map<String, String> get initialOptions => {
    'type': 'oneWay',
    'support': 'simple',
    'punchType': 'column',
  };

  @override
  List<String> get requiredKeys => [
    'lx',
    if (state.options['type'] == 'twoWay') 'ly',
    'h',
    'g',
    'q',
    'cover',
    'fck',
    'fyk',
  ];

  @override
  SlabDesign compute(DesignFormState<SlabDesign> s) => designSlab(
    SlabInput(
      code: s.code,
      lx: s['lx']!,
      ly: s.options['type'] == 'twoWay' ? s['ly'] : null,
      h: s['h']!,
      g: s['g']!,
      q: s['q']!,
      cover: s['cover']!,
      support: s.options['support'] == 'continuous'
          ? SlabSupport.continuous
          : SlabSupport.simplySupported,
      fck: s['fck']!,
      fyk: s['fyk']!,
      punchLoad: s['punchLoad'],
      punchC1: s['punchC1'] ?? 300,
      punchC2: s['punchC2'] ?? 300,
      punchBeta: s.options['punchType'] == 'load' ? 1.0 : 1.15,
    ),
  );

  @override
  Future<String> saveResult(DesignFormState<SlabDesign> s, SlabDesign r) async {
    final id = IdService.generateCalculationId();
    await save(
      id,
      SlabCalculation(
        id: id,
        projectId: projectId,
        name: 'Slab h=${s['h']!.round()}',
        span: s['lx']!,
        load: r.wUls,
        concrete: s['fck']!,
        steel: s['fyk']!,
        createdAt: DateTime.now(),
        isValid: r.ok,
        metadata: flatMetadata(s, {
          'mx': r.x.mSpan,
          'my': r.y.mSpan,
          'barsX': r.x.barsSpan?.toString(),
          'barsY': r.y.barsSpan?.toString(),
        }),
      ),
    );
    return id;
  }
}
