import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot_engine/sibot_engine.dart';

final steelMemberStateProvider =
    NotifierProvider.family<
      SteelMemberNotifier,
      DesignFormState<SteelMemberResult>,
      String
    >(SteelMemberNotifier.new);

/// Series the EC3 member design covers (I, H and hollow sections).
const designSeries = ['IPE', 'HEA', 'HEB', 'HEM', 'CHS', 'SHS', 'RHS'];

List<String> profilesOf(String series) => profilesOfSeries(series);

class SteelMemberNotifier extends DesignFormNotifier<SteelMemberResult> {
  SteelMemberNotifier(super.projectId);

  @override
  Map<String, double?> get initialValues => {
    'length': null,
    'nEd': 0,
    'myEd': null,
    'mzEd': 0,
    'vEd': 0,
    'ky': 1,
    'kz': 1,
    'kLT': 1,
    'psi': 1,
  };

  @override
  Map<String, String> get initialOptions => {
    'series': 'IPE',
    'profile': 'IPE 300',
    'grade': 'S275',
    'shape': MomentShape.udl.name,
  };

  @override
  List<String> get requiredKeys => [
    'length',
    'nEd',
    'myEd',
    'vEd',
    'ky',
    'kz',
    'kLT',
    if (state.options['shape'] == MomentShape.linear.name) 'psi',
  ];

  void setSeries(String series) {
    final current = state.options['profile']!.split(' ').last;
    final sizes = profilesOf(series);
    final same = '$series $current';
    setOption('series', series);
    setOption(
      'profile',
      sizes.contains(same) ? same : sizes[sizes.length ~/ 2],
    );
  }

  SteelMemberInput inputFor(
    DesignFormState<SteelMemberResult> s,
    SteelProfile p,
  ) => SteelMemberInput(
    section: p,
    grade: s.options['grade']!,
    length: s['length']!,
    nEd: s['nEd']!,
    myEd: s['myEd']!,
    mzEd: s['mzEd'] ?? 0,
    vEd: s['vEd']!,
    ky: s['ky']!,
    kz: s['kz']!,
    kLT: s['kLT']!,
    shape: MomentShape.values.byName(s.options['shape']!),
    psi: s['psi'] ?? 1,
  );

  /// Lightest profile of the selected series passing every check.
  SteelProfile? lightest() {
    final s = state;
    if (requiredKeys.any((k) => s[k] == null)) return null;
    try {
      return lightestSteelSection(s.options['series']!, (p) => inputFor(s, p));
    } on InputError {
      return null;
    }
  }

  void useProfile(String name) {
    setOption('profile', name);
    calculate();
  }

  @override
  SteelMemberResult compute(DesignFormState<SteelMemberResult> s) =>
      designSteelMember(inputFor(s, steelProfiles[s.options['profile']]!));

  @override
  Future<String> saveResult(
    DesignFormState<SteelMemberResult> s,
    SteelMemberResult r,
  ) async {
    final id = IdService.generateCalculationId();
    final worst = r.checks.reduce((a, b) => a.ratio >= b.ratio ? a : b);
    await save(
      id,
      ModuleCalculation(
        id: id,
        projectId: projectId,
        moduleId: 'steel-member',
        name: '${s.options['profile']} ${s.options['grade']}',
        createdAt: DateTime.now(),
        isValid: r.ok,
        metadata: flatMetadata(s, {
          'class': r.sectionClass,
          'mbRd': r.mbRd,
          'nbRd': r.chiZ * r.nPlRd,
          'maxRatio': worst.ratio.isFinite ? worst.ratio : null,
          'governing': worst.kind.name,
        }),
      ),
    );
    return id;
  }
}
