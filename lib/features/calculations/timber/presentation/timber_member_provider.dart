import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot_engine/sibot_engine.dart';

final timberMemberStateProvider =
    NotifierProvider.family<
      TimberMemberNotifier,
      DesignFormState<TimberMemberResult>,
      String
    >(TimberMemberNotifier.new);

class TimberMemberNotifier extends DesignFormNotifier<TimberMemberResult> {
  TimberMemberNotifier(super.projectId);

  @override
  Map<String, double?> get initialValues => {
    'b': null,
    'h': null,
    'length': null,
    'nEd': 0,
    'myEd': 0,
    'vEd': 0,
    'ky': 1,
    'kz': 1,
    'kLT': 1,
    'gk': 0,
    'qk': 0,
    'psi2': 0.3,
  };

  @override
  Map<String, String> get initialOptions => {
    'class': 'C24',
    'duration': LoadDuration.mediumTerm.name,
    'service': '1',
  };

  @override
  List<String> get requiredKeys => [
    'b',
    'h',
    'length',
    'nEd',
    'myEd',
    'vEd',
    'ky',
    'kz',
    'kLT',
    'gk',
    'qk',
    'psi2',
  ];

  @override
  TimberMemberResult compute(DesignFormState<TimberMemberResult> s) =>
      designTimberMember(
        TimberMemberInput(
          timber: timberClasses[s.options['class']]!,
          b: s['b']!,
          h: s['h']!,
          length: s['length']!,
          nEd: s['nEd']!,
          myEd: s['myEd']!,
          vEd: s['vEd']!,
          ky: s['ky']!,
          kz: s['kz']!,
          kLT: s['kLT']!,
          duration: LoadDuration.values.byName(s.options['duration']!),
          serviceClass: int.parse(s.options['service']!),
          gk: s['gk']!,
          qk: s['qk']!,
          psi2: s['psi2']!,
        ),
      );

  @override
  Future<String> saveResult(
    DesignFormState<TimberMemberResult> s,
    TimberMemberResult r,
  ) async {
    final id = IdService.generateCalculationId();
    final worst = r.checks.isEmpty
        ? null
        : r.checks.reduce((a, b) => a.ratio >= b.ratio ? a : b);
    await save(
      id,
      ModuleCalculation(
        id: id,
        projectId: projectId,
        moduleId: 'timber-member',
        name: '${s['b']!.round()}×${s['h']!.round()} ${s.options['class']}',
        createdAt: DateTime.now(),
        isValid: r.ok,
        metadata: flatMetadata(s, {
          'kmod': r.kmod,
          'maxRatio': worst != null && worst.ratio.isFinite
              ? worst.ratio
              : null,
          'governing': worst?.kind.name,
        }),
      ),
    );
    return id;
  }
}
