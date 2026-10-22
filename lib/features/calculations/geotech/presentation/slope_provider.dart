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

/// Optional lower layers: top elevation, γ, c and φ per layer.
const slopeLayerKeys = [
  ['l1Top', 'l1Gamma', 'l1C', 'l1Phi'],
  ['l2Top', 'l2Gamma', 'l2C', 'l2Phi'],
];

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
    'waterLevel': null,
    for (final k in slopeLayerKeys.expand((l) => l)) k: null,
  };

  @override
  Map<String, String> get initialOptions => {'method': 'bishop'};

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
  SlopeResult compute(DesignFormState<SlopeResult> s) {
    final (input, method) = _input(s);
    return analyseSlope(input, method: method);
  }

  // Thousands of trial surfaces: run off the UI thread.
  @override
  Future<SlopeResult> computeAsync(DesignFormState<SlopeResult> s) {
    final (input, method) = _input(s);
    return _slopeInIsolate(input, method);
  }

  (SlopeInput, SlopeMethod) _input(DesignFormState<SlopeResult> s) {
    final layers = <SoilLayer>[];
    for (final [top, gamma, c, phi] in slopeLayerKeys) {
      if (s[top] == null) continue;
      // A layer needs its strength; γ defaults to the top soil's.
      if (s[c] == null) throw InputError(InputProblem.notPositive, c);
      if (s[phi] == null) throw InputError(InputProblem.notPositive, phi);
      layers.add(
        SoilLayer(
          top: s[top]!,
          gamma: s[gamma] ?? s['gamma']!,
          cohesion: s[c]!,
          phi: s[phi]!,
        ),
      );
    }
    return (
      SlopeInput(
        height: s['height']!,
        angle: s['angle']!,
        gamma: s['gamma']!,
        cohesion: s['cohesion']!,
        phi: s['phi']!,
        ru: s['ru']!,
        surcharge: s['surcharge']!,
        maxDepth: s['maxDepth'],
        waterLevel: s['waterLevel'],
        layers: layers,
      ),
      s.options['method'] == 'janbu' ? SlopeMethod.janbu : SlopeMethod.bishop,
    );
  }

  @override
  Future<String> saveResult(
    DesignFormState<SlopeResult> s,
    SlopeResult r,
  ) async {
    final id = IdService.generateCalculationId();
    final c = r.circle;
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
          'xc': ?c?.xc,
          'yc': ?c?.yc,
          'r': ?c?.r,
          if (c == null) 'f0': r.f0,
        }),
      ),
    );
    return id;
  }
}

Future<SlopeResult> _slopeInIsolate(SlopeInput input, SlopeMethod method) =>
    Isolate.run(() => analyseSlope(input, method: method));
