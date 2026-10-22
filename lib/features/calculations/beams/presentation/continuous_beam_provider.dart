import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot_engine/sibot_engine.dart';

final continuousBeamStateProvider =
    NotifierProvider.family<
      ContinuousBeamNotifier,
      DesignFormState<ContinuousBeamDesign>,
      String
    >(ContinuousBeamNotifier.new);

/// Span fields; the spans end at the first empty one.
const continuousSpanKeys = [
  'span1',
  'span2',
  'span3',
  'span4',
  'span5',
  'span6',
];

class ContinuousBeamNotifier extends DesignFormNotifier<ContinuousBeamDesign> {
  ContinuousBeamNotifier(super.projectId);

  @override
  Map<String, double?> get initialValues => {
    for (final k in continuousSpanKeys) k: null,
    'b': null,
    'h': null,
    'g': null,
    'q': null,
    'cover': 30,
    'fck': 25,
    'fyk': 500,
  };

  @override
  Map<String, String> get initialOptions => {
    'selfWeight': 'yes',
    'ends': 'pinned',
  };

  @override
  List<String> get requiredKeys => [
    'span1',
    'b',
    'h',
    'g',
    'q',
    'cover',
    'fck',
    'fyk',
  ];

  List<double> _spans(DesignFormState<ContinuousBeamDesign> s) {
    final out = <double>[];
    for (final k in continuousSpanKeys) {
      final v = s[k];
      if (v == null) break;
      out.add(v);
    }
    return out;
  }

  @override
  ContinuousBeamDesign compute(DesignFormState<ContinuousBeamDesign> s) {
    final ends = s.options['ends'];
    return designContinuousBeam(
      ContinuousBeamInput(
        code: s.code,
        spans: _spans(s),
        b: s['b']!,
        h: s['h']!,
        g: s['g']!,
        q: s['q']!,
        cover: s['cover']!,
        fck: s['fck']!,
        fyk: s['fyk']!,
        includeSelfWeight: s.options['selfWeight'] == 'yes',
        fixedLeft: ends == 'fixed' || ends == 'fixedLeft',
        fixedRight: ends == 'fixed',
      ),
    );
  }

  @override
  Future<String> saveResult(
    DesignFormState<ContinuousBeamDesign> s,
    ContinuousBeamDesign r,
  ) async {
    final id = IdService.generateCalculationId();
    await save(
      id,
      ModuleCalculation(
        id: id,
        projectId: projectId,
        moduleId: 'continuous-beam',
        name:
            '${r.spans.length} × ${s['b']!.round()}×${s['h']!.round()} '
            '(${_spans(s).map((l) => l.toStringAsFixed(1)).join(' + ')} m)',
        createdAt: DateTime.now(),
        isValid: r.ok,
        metadata: flatMetadata(s, {
          'maxSupportMoment': r.supportMoments.reduce((a, b) => a > b ? a : b),
          'maxReaction': r.reactions.reduce((a, b) => a > b ? a : b),
        }),
      ),
    );
    return id;
  }
}
