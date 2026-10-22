import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot_engine/sibot_engine.dart';

final beamSectionStateProvider =
    NotifierProvider.family<
      BeamSectionNotifier,
      DesignFormState<BeamSectionDesign>,
      String
    >(BeamSectionNotifier.new);

/// Rectangular RC beam section designed for given ULS forces (e.g. the
/// envelope of a member of a frame model).
class BeamSectionNotifier extends DesignFormNotifier<BeamSectionDesign> {
  BeamSectionNotifier(super.projectId);

  @override
  Map<String, double?> get initialValues => {
    'b': null,
    'h': null,
    'mSag': 0,
    'mHog': 0,
    'vEd': 0,
    'cover': 30,
    'fck': 25,
    'fyk': 500,
  };

  @override
  List<String> get requiredKeys => const [
    'b',
    'h',
    'mSag',
    'mHog',
    'vEd',
    'cover',
    'fck',
    'fyk',
  ];

  @override
  BeamSectionDesign compute(DesignFormState<BeamSectionDesign> s) =>
      designBeamSection(
        BeamSectionInput(
          code: s.code,
          b: s['b']!,
          h: s['h']!,
          mSagging: s['mSag']!,
          mHogging: s['mHog']!,
          vEd: s['vEd']!,
          cover: s['cover']!,
          fck: s['fck']!,
          fyk: s['fyk']!,
        ),
      );

  @override
  Future<String> saveResult(
    DesignFormState<BeamSectionDesign> s,
    BeamSectionDesign r,
  ) async {
    final id = IdService.generateCalculationId();
    await save(
      id,
      ModuleCalculation(
        id: id,
        projectId: projectId,
        moduleId: 'beam-section',
        name: 'Section ${s['b']!.round()}×${s['h']!.round()}',
        createdAt: DateTime.now(),
        isValid: r.ok,
        metadata: flatMetadata(s, {
          'asBottom': r.asBottom,
          'asTop': r.asTop,
          'bottomBars': r.bottomBars?.toString(),
          'topBars': r.topBars?.toString(),
          'links': r.shear.links?.toString(),
        }),
      ),
    );
    return id;
  }
}
