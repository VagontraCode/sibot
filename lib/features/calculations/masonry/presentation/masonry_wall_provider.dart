import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot_engine/sibot_engine.dart';

final masonryWallStateProvider =
    NotifierProvider.family<
      MasonryWallNotifier,
      DesignFormState<MasonryWallResult>,
      String
    >(MasonryWallNotifier.new);

class MasonryWallNotifier extends DesignFormNotifier<MasonryWallResult> {
  MasonryWallNotifier(super.projectId);

  @override
  Map<String, double?> get initialValues => {
    'fb': 20,
    'fm': 10,
    't': null,
    'height': null,
    'nEd': null,
    'eTop': 0,
    'eBottom': 0,
    'gammaM': 2.5,
    'otherLeaf': 0,
    'lateralLoad': 0,
    'concentratedLoad': 0,
    'bearingLength': 0,
    'bearingWidth': 0,
    'edgeDistance': 0,
  };

  @override
  Map<String, String> get initialOptions => {
    'unit': MasonryUnit.clayGroup1.name,
    'rho': '0.75',
  };

  @override
  List<String> get requiredKeys => [
    'fb',
    'fm',
    't',
    'height',
    'nEd',
    'eTop',
    'eBottom',
    'gammaM',
  ];

  @override
  MasonryWallResult compute(DesignFormState<MasonryWallResult> s) =>
      designMasonryWall(
        MasonryWallInput(
          unit: MasonryUnit.values.byName(s.options['unit']!),
          fb: s['fb']!,
          fm: s['fm']!,
          t: s['t']!,
          height: s['height']!,
          rhoN: double.parse(s.options['rho']!),
          nEd: s['nEd']!,
          eTop: s['eTop']!,
          eBottom: s['eBottom']!,
          gammaM: s['gammaM']!,
          otherLeaf: s['otherLeaf'] ?? 0,
          lateralLoad: s['lateralLoad'] ?? 0,
          concentratedLoad: s['concentratedLoad'] ?? 0,
          bearingLength: s['bearingLength'] ?? 0,
          bearingWidth: s['bearingWidth'] ?? 0,
          edgeDistance: s['edgeDistance'] ?? 0,
        ),
      );

  @override
  Future<String> saveResult(
    DesignFormState<MasonryWallResult> s,
    MasonryWallResult r,
  ) async {
    final id = IdService.generateCalculationId();
    await save(
      id,
      ModuleCalculation(
        id: id,
        projectId: projectId,
        moduleId: 'masonry-wall',
        name: 'Wall t = ${s['t']!.round()} mm',
        createdAt: DateTime.now(),
        isValid: r.ok,
        metadata: flatMetadata(s, {
          'fk': r.fk,
          'nRd': r.nRd,
          'slenderness': r.slenderness,
        }),
      ),
    );
    return id;
  }
}
