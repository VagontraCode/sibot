import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot_engine/sibot_engine.dart';

final slopeStateProvider =
    NotifierProvider.family<
      SlopeNotifier,
      DesignFormState<SlopeResult>,
      String
    >(SlopeNotifier.new);

class SlopeNotifier extends DesignFormNotifier<SlopeResult> {
  SlopeNotifier(super.projectId);

  @override
  Map<String, double?> get initialValues => {
    'height': null,
    'angle': null,
    'gamma': 19,
    'cohesion': null,
    'phi': null,
    'ru': 0,
    'surcharge': 0,
    'maxDepth': null,
  };

  @override
  List<String> get requiredKeys => [
    'height',
    'angle',
    'gamma',
    'cohesion',
    'phi',
    'ru',
    'surcharge',
  ];

  @override
  SlopeResult compute(DesignFormState<SlopeResult> s) =>
      analyseSlope(_input(s));

  // Thousands of trial circles: run off the UI thread.
  @override
  Future<SlopeResult> computeAsync(DesignFormState<SlopeResult> s) =>
      _slopeInIsolate(_input(s));

  SlopeInput _input(DesignFormState<SlopeResult> s) => (SlopeInput(
    height: s['height']!,
    angle: s['angle']!,
    gamma: s['gamma']!,
    cohesion: s['cohesion']!,
    phi: s['phi']!,
    ru: s['ru']!,
    surcharge: s['surcharge']!,
    maxDepth: s['maxDepth'],
  ));

  @override
  Future<String> saveResult(
    DesignFormState<SlopeResult> s,
    SlopeResult r,
  ) async {
    final id = IdService.generateCalculationId();
    await save(
      id,
      ModuleCalculation(
        id: id,
        projectId: projectId,
        moduleId: 'slope',
        name: 'F = ${r.factor.toStringAsFixed(2)}',
        createdAt: DateTime.now(),
        isValid: r.ok,
        metadata: flatMetadata(s, {
          'factor': r.factor,
          'factorEc7': r.factorEc7,
          'xc': r.circle.xc,
          'yc': r.circle.yc,
          'r': r.circle.r,
        }),
      ),
    );
    return id;
  }
}

Future<SlopeResult> _slopeInIsolate(SlopeInput input) =>
    Isolate.run(() => analyseSlope(input));
