import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot_engine/sibot_engine.dart';

final pileCapStateProvider =
    NotifierProvider.family<
      PileCapNotifier,
      DesignFormState<PileCapResult>,
      String
    >(PileCapNotifier.new);

class PileCapNotifier extends DesignFormNotifier<PileCapResult> {
  PileCapNotifier(super.projectId);

  @override
  Map<String, double?> get initialValues => {
    'nEd': null,
    'spacing': null,
    'pileDiameter': null,
    'column': null,
    'h': null,
    'cover': 50,
    'edge': 150,
    'fck': 25,
    'fyk': 500,
    'columnB': null,
    'mx': 0,
    'my': 0,
    'pileCapacity': null,
  };

  @override
  Map<String, String> get initialOptions => {'piles': '4'};

  @override
  List<String> get requiredKeys => [
    'nEd',
    'spacing',
    'pileDiameter',
    'column',
    'h',
    'cover',
    'edge',
    'fck',
    'fyk',
  ];

  /// Sets the depth to the middle of the 45°–55° range of the last result.
  void useSuggestedDepth() {
    final r = state.result;
    if (r == null) return;
    set('h', ((r.hMin + r.hMax) / 2 / 50).ceil() * 50.0);
    calculate();
  }

  @override
  PileCapResult compute(DesignFormState<PileCapResult> s) => designPileCap(
    PileCapInput(
      code: s.code,
      nEd: s['nEd']!,
      piles: int.parse(s.options['piles']!),
      spacing: s['spacing']!,
      pileDiameter: s['pileDiameter']!,
      column: s['column']!,
      columnB: s['columnB'],
      mx: s['mx'] ?? 0,
      my: s['my'] ?? 0,
      pileCapacity: s['pileCapacity'],
      h: s['h']!,
      cover: s['cover']!,
      edge: s['edge']!,
      fck: s['fck']!,
      fyk: s['fyk']!,
    ),
  );

  @override
  Future<String> saveResult(
    DesignFormState<PileCapResult> s,
    PileCapResult r,
  ) async {
    final id = IdService.generateCalculationId();
    await save(
      id,
      ModuleCalculation(
        id: id,
        projectId: projectId,
        moduleId: 'pile-cap',
        name: '${s.options['piles']} piles · h ${s['h']!.round()}',
        createdAt: DateTime.now(),
        isValid: r.ok,
        metadata: flatMetadata(s, {
          'theta': r.theta,
          'asTie': r.asTie,
          'bars': r.bars?.toString(),
          'reaction': r.reaction,
        }),
      ),
    );
    return id;
  }
}
