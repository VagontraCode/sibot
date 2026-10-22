import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// Result is a [FootingDesign], [StripFootingDesign] or
/// [CombinedFootingDesign] depending on the selected type.
final footingStateProvider =
    NotifierProvider.family<FootingNotifier, DesignFormState<Object>, String>(
      FootingNotifier.new,
    );

class FootingNotifier extends DesignFormNotifier<Object> {
  FootingNotifier(super.projectId);

  @override
  Map<String, double?> get initialValues => {
    // Isolated / strip
    'a': null,
    'b': null,
    'g': null,
    'q': null,
    'mg': 0,
    'mq': 0,
    // Combined
    'a1': null,
    'b1': null,
    'a2': null,
    'b2': null,
    'spacing': null,
    'g1': null,
    'q1': null,
    'g2': null,
    'q2': null,
    // Soil
    'qAdm': null,
    'cohesion': 0,
    'phi': 30,
    'cu': null,
    'depth': 1.0,
    'gammaSoil': 18,
    'cover': 50,
    'fck': 25,
    'fyk': 500,
  };

  @override
  Map<String, String> get initialOptions => {
    'type': 'isolated',
    'bearing': 'allowable',
    'drainage': 'drained',
    'optimise': 'no',
  };

  String get _type => state.options['type']!;
  bool get _soilMode => state.options['bearing'] == 'soil';

  @override
  List<String> get requiredKeys => [
    ...switch (_type) {
      'strip' => ['a', 'g', 'q', 'mg', 'mq'],
      'combined' => ['a1', 'b1', 'a2', 'b2', 'spacing', 'g1', 'q1', 'g2', 'q2'],
      _ => ['a', 'b', 'g', 'q', 'mg', 'mq'],
    },
    if (!_soilMode) 'qAdm',
    if (_soilMode && state.options['drainage'] == 'undrained') 'cu',
    if (_soilMode && state.options['drainage'] != 'undrained') ...[
      'cohesion',
      'phi',
    ],
    'depth',
    'gammaSoil',
    'cover',
    'fck',
    'fyk',
  ];

  Soil? _soil(DesignFormState<Object> s) {
    if (s.options['bearing'] != 'soil') return null;
    return s.options['drainage'] == 'undrained'
        ? Soil(gamma: s['gammaSoil']!, cu: s['cu']!)
        : Soil(
            cohesion: s['cohesion']!,
            phi: s['phi']!,
            gamma: s['gammaSoil']!,
          );
  }

  @override
  Object compute(DesignFormState<Object> s) {
    final soil = _soil(s);
    final qAdm = soil == null ? s['qAdm']! : 0.0;
    switch (s.options['type']) {
      case 'strip':
        return designStripFooting(
          StripFootingInput(
            code: s.code,
            wall: s['a']!,
            g: s['g']!,
            q: s['q']!,
            mg: s['mg']!,
            mq: s['mq']!,
            qAllowable: qAdm,
            soil: soil,
            depth: s['depth']!,
            soilWeight: s['gammaSoil']!,
            cover: s['cover']!,
            fck: s['fck']!,
            fyk: s['fyk']!,
          ),
        );
      case 'combined':
        return designCombinedFooting(
          CombinedFootingInput(
            code: s.code,
            a1: s['a1']!,
            b1: s['b1']!,
            a2: s['a2']!,
            b2: s['b2']!,
            spacing: s['spacing']!,
            g1: s['g1']!,
            q1: s['q1']!,
            g2: s['g2']!,
            q2: s['q2']!,
            qAllowable: qAdm,
            soil: soil,
            depth: s['depth']!,
            soilWeight: s['gammaSoil']!,
            cover: s['cover']!,
            fck: s['fck']!,
            fyk: s['fyk']!,
            optimiseWidth: s.options['optimise'] == 'yes',
          ),
        );
      default:
        return designFooting(
          FootingInput(
            code: s.code,
            a: s['a']!,
            b: s['b']!,
            g: s['g']!,
            q: s['q']!,
            mg: s['mg']!,
            mq: s['mq']!,
            qAllowable: qAdm,
            soil: soil,
            depth: s['depth']!,
            soilWeight: s['gammaSoil']!,
            cover: s['cover']!,
            fck: s['fck']!,
            fyk: s['fyk']!,
          ),
        );
    }
  }

  @override
  Future<String> saveResult(DesignFormState<Object> s, Object r) async {
    final id = IdService.generateCalculationId();
    final now = DateTime.now();
    final (type, length, width, h, ok, load) = switch (r) {
      FootingDesign f => (
        'isolated',
        f.lengthA,
        f.widthB,
        f.h,
        f.ok,
        s['g']! + s['q']!,
      ),
      StripFootingDesign f => (
        'strip',
        1.0,
        f.width,
        f.h,
        f.ok,
        s['g']! + s['q']!,
      ),
      CombinedFootingDesign f => (
        'combined',
        f.length,
        f.width,
        f.h,
        f.ok,
        s['g1']! + s['q1']! + s['g2']! + s['q2']!,
      ),
      _ => throw StateError('Unknown footing result'),
    };
    await save(
      id,
      FootingCalculation(
        id: id,
        projectId: projectId,
        name:
            'Footing ($type) ${length.toStringAsFixed(2)}×${width.toStringAsFixed(2)}',
        columnLoad: load,
        columnMoment: (s['mg'] ?? 0) + (s['mq'] ?? 0),
        soilBearingCapacity: s['qAdm'] ?? 0,
        soilDensity: s['gammaSoil']!,
        concrete: s['fck']!,
        steel: s['fyk']!,
        footing: type,
        code: s.code == DesignCode.bael ? 'bael99' : 'eurocode',
        requiredArea: length * width,
        footingLength: length,
        footingWidth: width,
        footingDepth: h,
        createdAt: now,
        updatedAt: now,
        isValid: ok,
        metadata: flatMetadata(s, {}),
      ),
    );
    return id;
  }
}
