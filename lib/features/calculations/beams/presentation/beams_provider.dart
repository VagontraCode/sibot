import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot_engine/sibot_engine.dart';

final beamStateProvider =
    NotifierProvider.family<BeamNotifier, DesignFormState<BeamDesign>, String>(
      BeamNotifier.new,
    );

class BeamNotifier extends DesignFormNotifier<BeamDesign> {
  BeamNotifier(super.projectId);

  @override
  Map<String, double?> get initialValues => {
    'span': null,
    'b': null,
    'h': null,
    'g': null,
    'q': null,
    'cover': 30,
    'fck': 25,
    'fyk': 500,
    'psi2': 0.3,
    'wmax': 0.3,
  };

  @override
  Map<String, String> get initialOptions => {
    'support': 'simple',
    'cracking': 'slight',
  };

  @override
  List<String> get requiredKeys => const [
    'span',
    'b',
    'h',
    'g',
    'q',
    'cover',
    'fck',
    'fyk',
  ];

  @override
  BeamDesign compute(DesignFormState<BeamDesign> s) => designBeam(
    BeamInput(
      code: s.code,
      support: s.options['support'] == 'cantilever'
          ? BeamSupport.cantilever
          : BeamSupport.simplySupported,
      span: s['span']!,
      b: s['b']!,
      h: s['h']!,
      g: s['g']!,
      q: s['q']!,
      cover: s['cover']!,
      fck: s['fck']!,
      fyk: s['fyk']!,
      psi2: s['psi2'] ?? 0.3,
      crackLimit: s['wmax'] ?? 0.3,
      baelCracking: BaelCracking.values.byName(s.options['cracking']!),
    ),
  );

  @override
  Future<String> saveResult(DesignFormState<BeamDesign> s, BeamDesign r) async {
    final id = IdService.generateCalculationId();
    await save(
      id,
      BeamCalculation(
        id: id,
        projectId: projectId,
        name: 'Beam ${s['b']!.round()}×${s['h']!.round()}',
        span: s['span']!,
        load: r.wUls,
        width: s['b']!,
        depth: s['h']!,
        concrete: s['fck']!,
        steel: s['fyk']!,
        createdAt: DateTime.now(),
        isValid: r.ok,
        metadata: flatMetadata(s, {
          'mEd': r.mEd,
          'vEd': r.vEd,
          'asReq': r.bending.asTension,
          'bars': r.tensionBars?.toString(),
          'links': r.shear.links?.toString(),
          'maxRatio': r.maxRatio,
        }),
      ),
    );
    return id;
  }
}
