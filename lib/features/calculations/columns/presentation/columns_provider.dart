import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot_engine/sibot_engine.dart';

final columnStateProvider =
    NotifierProvider.family<
      ColumnNotifier,
      DesignFormState<ColumnDesign>,
      String
    >(ColumnNotifier.new);

class ColumnNotifier extends DesignFormNotifier<ColumnDesign> {
  ColumnNotifier(super.projectId);

  @override
  Map<String, double?> get initialValues => {
    'b': null,
    'h': null,
    'l0': null,
    'nEd': null,
    'm0Ed': 0,
    'm0EdB': 0,
    'cover': 30,
    'creep': 1.0,
    'fck': 25,
    'fyk': 500,
  };

  @override
  Map<String, String> get initialOptions => {'shape': 'rect'};

  @override
  List<String> get requiredKeys => [
    'b',
    if (state.options['shape'] != 'circle') 'h',
    'l0',
    'nEd',
    'm0Ed',
    'm0EdB',
    'cover',
    'fck',
    'fyk',
  ];

  @override
  ColumnDesign compute(DesignFormState<ColumnDesign> s) => designColumn(
    ColumnInput(
      code: s.code,
      b: s['b']!,
      shape: s.options['shape'] == 'circle'
          ? ColumnShape.circular
          : ColumnShape.rectangular,
      h: s.options['shape'] == 'circle' ? 0 : s['h']!,
      l0: s['l0']!,
      nEd: s['nEd']!,
      m0Ed: s['m0Ed']!,
      m0EdB: s['m0EdB']!,
      cover: s['cover']!,
      creepRatio: s['creep'] ?? 1.0,
      fck: s['fck']!,
      fyk: s['fyk']!,
    ),
  );

  @override
  Future<String> saveResult(
    DesignFormState<ColumnDesign> s,
    ColumnDesign r,
  ) async {
    final id = IdService.generateCalculationId();
    await save(
      id,
      ColumnCalculation(
        id: id,
        projectId: projectId,
        name: s.options['shape'] == 'circle'
            ? 'Column Ø${s['b']!.round()}'
            : 'Column ${s['b']!.round()}×${s['h']!.round()}',
        axialLoad: s['nEd']!,
        height: s['l0']!,
        concrete: s['fck']!,
        steel: s['fyk']!,
        createdAt: DateTime.now(),
        isValid: r.ok,
        metadata: flatMetadata(s, {
          'mEd': r.mEd,
          'lambda': r.slenderness,
          'asReq': r.asRequired.isFinite ? r.asRequired : null,
          'bars': r.bars?.toString(),
        }),
      ),
    );
    return id;
  }
}
