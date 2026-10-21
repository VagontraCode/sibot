import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot_engine/sibot_engine.dart';

// ======================= BEARING & SETTLEMENT =======================

final bearingStateProvider =
    NotifierProvider.family<
      BearingNotifier,
      DesignFormState<ShallowFoundationDesign>,
      String
    >(BearingNotifier.new);

class BearingNotifier extends DesignFormNotifier<ShallowFoundationDesign> {
  BearingNotifier(super.projectId);

  @override
  Map<String, double?> get initialValues => {
    'b': null,
    'l': null,
    'depth': 1.0,
    'g': null,
    'q': null,
    'cohesion': 0,
    'phi': 30,
    'cu': null,
    'gammaSoil': 18,
    'youngModulus': 20,
    'poisson': 0.3,
  };

  @override
  Map<String, String> get initialOptions => {'drainage': 'drained'};

  bool get _undrained => state.options['drainage'] == 'undrained';

  @override
  List<String> get requiredKeys => [
    'b',
    'l',
    'depth',
    'g',
    'q',
    if (_undrained) 'cu' else ...['cohesion', 'phi'],
    'gammaSoil',
    'youngModulus',
    'poisson',
  ];

  @override
  ShallowFoundationDesign compute(DesignFormState<ShallowFoundationDesign> s) =>
      designShallowFoundation(
        ShallowFoundationInput(
          b: s['b']!,
          l: s['l']!,
          depth: s['depth']!,
          g: s['g']!,
          q: s['q']!,
          soil: s.options['drainage'] == 'undrained'
              ? Soil(gamma: s['gammaSoil']!, cu: s['cu']!)
              : Soil(
                  cohesion: s['cohesion']!,
                  phi: s['phi']!,
                  gamma: s['gammaSoil']!,
                ),
          youngModulus: s['youngModulus']!,
          poisson: s['poisson']!,
        ),
      );
}

// ======================== SECTION PROPERTIES ========================

final sectionStateProvider =
    NotifierProvider.family<
      SectionNotifier,
      DesignFormState<SectionProperties>,
      String
    >(SectionNotifier.new);

class SectionNotifier extends DesignFormNotifier<SectionProperties> {
  SectionNotifier(super.projectId);

  @override
  Map<String, double?> get initialValues => {
    'b': null,
    'h': null,
    'd': null,
    't': null,
    'tf': null,
    'tw': null,
  };

  @override
  Map<String, String> get initialOptions => {'shape': 'rect'};

  @override
  List<String> get requiredKeys => switch (state.options['shape']) {
    'circle' => ['d'],
    'hollow' => ['b', 'h', 't'],
    'i' || 't' => ['b', 'h', 'tf', 'tw'],
    _ => ['b', 'h'],
  };

  @override
  SectionProperties compute(DesignFormState<SectionProperties> s) =>
      sectionProperties(switch (s.options['shape']) {
        'circle' => CircleSection(s['d']!),
        'hollow' => HollowRectangleSection(s['b']!, s['h']!, s['t']!),
        'i' => ISection(b: s['b']!, h: s['h']!, tf: s['tf']!, tw: s['tw']!),
        't' => TSection(b: s['b']!, h: s['h']!, tf: s['tf']!, tw: s['tw']!),
        _ => RectangleSection(s['b']!, s['h']!),
      });
}

// ============================ QUANTITIES ============================

class QuantitiesResult {
  final ConcreteQuantity? concrete;
  final double? formwork;
  final RebarQuantity? rebar;
  const QuantitiesResult(this.concrete, this.formwork, this.rebar);
}

final quantitiesStateProvider =
    NotifierProvider.family<
      QuantitiesNotifier,
      DesignFormState<QuantitiesResult>,
      String
    >(QuantitiesNotifier.new);

class QuantitiesNotifier extends DesignFormNotifier<QuantitiesResult> {
  QuantitiesNotifier(super.projectId);

  @override
  Map<String, double?> get initialValues => {
    'length': null,
    'width': null,
    'height': null,
    'count': 1,
    'waste': 5,
    'cement': 350,
    'sand': 400,
    'gravel': 800,
    'water': 175,
    'barDia': null,
    'barCount': null,
    'barLength': null,
    'lap': 10,
  };

  @override
  Map<String, String> get initialOptions => {'formwork': 'column'};

  /// Each part is computed when its own fields are filled.
  @override
  List<String> get requiredKeys => const [];

  bool _has(DesignFormState<QuantitiesResult> s, List<String> keys) =>
      keys.every((k) => s[k] != null);

  @override
  QuantitiesResult compute(DesignFormState<QuantitiesResult> s) {
    final element = _has(s, ['length', 'width', 'height', 'count']);
    final bars = _has(s, ['barDia', 'barCount', 'barLength']);
    if (!element && !bars) {
      throw const InputError(InputProblem.notPositive, 'length');
    }
    final count = (s['count'] ?? 1).round();
    return QuantitiesResult(
      element
          ? concreteQuantity(
              length: s['length']!,
              width: s['width']!,
              height: s['height']!,
              count: count,
              wastePercent: s['waste'] ?? 0,
              mix: ConcreteMix(
                cementKg: s['cement'] ?? 350,
                sandLitres: s['sand'] ?? 400,
                gravelLitres: s['gravel'] ?? 800,
                waterLitres: s['water'] ?? 175,
              ),
            )
          : null,
      element
          ? formworkArea(
              length: s['length']!,
              width: s['width']!,
              height: s['height']!,
              count: count,
              includeEnds: s.options['formwork'] != 'beam',
              includeSoffit: s.options['formwork'] != 'column',
            )
          : null,
      bars
          ? rebarQuantity(
              diameter: s['barDia']!.round(),
              count: s['barCount']!.round(),
              barLength: s['barLength']!,
              lapPercent: s['lap'] ?? 0,
            )
          : null,
    );
  }
}
