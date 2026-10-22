import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot_engine/sibot_engine.dart';

final timberConnectionStateProvider =
    NotifierProvider.family<
      TimberConnectionNotifier,
      DesignFormState<DowelConnectionResult>,
      String
    >(TimberConnectionNotifier.new);

class TimberConnectionNotifier
    extends DesignFormNotifier<DowelConnectionResult> {
  TimberConnectionNotifier(super.projectId);

  @override
  Map<String, double?> get initialValues => {
    'd': null,
    't1': null,
    't2': null,
    'angle2': 0,
    'perRow': 1,
    'rows': 1,
    'a1': 0,
    'fEd': null,
  };

  @override
  Map<String, String> get initialOptions => {
    'class': 'C24',
    'grade': '4.6',
    'duration': LoadDuration.mediumTerm.name,
    'service': '1',
  };

  @override
  List<String> get requiredKeys => [
    'd',
    't1',
    't2',
    'angle2',
    'perRow',
    'rows',
    'a1',
    'fEd',
  ];

  @override
  DowelConnectionResult compute(DesignFormState<DowelConnectionResult> s) =>
      designDowelConnection(
        DowelConnectionInput(
          timber: timberClasses[s.options['class']]!,
          d: s['d']!,
          fuk: s.options['grade'] == '8.8' ? 800 : 400,
          t1: s['t1']!,
          t2: s['t2']!,
          angle2: s['angle2']!,
          perRow: s['perRow']!.round(),
          rows: s['rows']!.round(),
          a1: s['a1']!,
          fEd: s['fEd']!,
          duration: LoadDuration.values.byName(s.options['duration']!),
          serviceClass: int.parse(s.options['service']!),
        ),
      );

  @override
  Future<String> saveResult(
    DesignFormState<DowelConnectionResult> s,
    DowelConnectionResult r,
  ) async {
    final id = IdService.generateCalculationId();
    final n = s['perRow']!.round() * s['rows']!.round();
    await save(
      id,
      ModuleCalculation(
        id: id,
        projectId: projectId,
        moduleId: 'timber-connection',
        name: '$n × Ø${s['d']!.round()} ${s.options['class']}',
        createdAt: DateTime.now(),
        isValid: r.ok,
        metadata: flatMetadata(s, {
          'fvRd': r.fvRd,
          'capacity': r.capacity,
          'mode': r.governing,
        }),
      ),
    );
    return id;
  }
}
