import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

final septicStateProvider =
    NotifierProvider.family<
      SepticNotifier,
      DesignFormState<SepticResult>,
      String
    >(SepticNotifier.new);

class SepticNotifier extends DesignFormNotifier<SepticResult> {
  SepticNotifier(super.projectId);

  @override
  Map<String, double?> get initialValues => {
    'users': null,
    'flow': 100,
    'retention': 1,
    'sludge': 40,
    'years': 2,
    'depth': 1.5,
    'freeboard': 0.3,
    'ratio': 2,
    'rooms': null,
  };

  @override
  List<String> get requiredKeys => [
    'users',
    'flow',
    'retention',
    'sludge',
    'years',
    'depth',
    'freeboard',
    'ratio',
  ];

  @override
  SepticResult compute(DesignFormState<SepticResult> s) {
    final users = s['users']!;
    if (users != users.roundToDouble()) {
      throw const InputError(InputProblem.outOfRange, 'users');
    }
    final rooms = s['rooms'];
    return sizeSepticTank(
      SepticInput(
        users: users.round(),
        flowPerUser: s['flow']!,
        retentionDays: s['retention']!,
        sludgeRate: s['sludge']!,
        emptyingYears: s['years']!,
        liquidDepth: s['depth']!,
        freeboard: s['freeboard']!,
        ratio: s['ratio']!,
        rooms: rooms?.round(),
      ),
    );
  }

  @override
  Future<String> saveResult(
    DesignFormState<SepticResult> s,
    SepticResult r,
  ) async {
    final id = IdService.generateCalculationId();
    await save(
      id,
      ModuleCalculation(
        id: id,
        projectId: projectId,
        moduleId: 'septic',
        name: '${r.volume.toStringAsFixed(1)} m³',
        createdAt: DateTime.now(),
        isValid: true,
        metadata: flatMetadata(s, {
          'volume': r.volume,
          'length': r.length,
          'width': r.width,
        }),
      ),
    );
    return id;
  }
}

class SepticPage extends ConsumerWidget {
  final String projectId;
  const SepticPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(septicStateProvider(projectId));
    final n = ref.read(septicStateProvider(projectId).notifier);
    final l = context.l10n;

    final labels = {
      'users': l.septicUsers,
      'flow': l.septicFlow,
      'flowPerUser': l.septicFlow,
      'retention': l.septicRetention,
      'retentionDays': l.septicRetention,
      'sludge': l.septicSludge,
      'sludgeRate': l.septicSludge,
      'years': l.septicYears,
      'emptyingYears': l.septicYears,
      'depth': l.septicDepth,
      'liquidDepth': l.septicDepth,
      'freeboard': l.septicFreeboard,
      'ratio': l.septicRatio,
      'rooms': l.septicRooms,
    };
    Widget field(String key, String unit, {String? hint}) => FormNumber(
      state: s,
      notifier: n,
      field: key,
      label: labels[key]!,
      unit: unit,
      hint: hint,
    );

    return CalculatorScaffold(
      title: l.modSeptic,
      subtitle: l.septicSubtitle,
      module: moduleByRoute('septic'),
      onCalculate: n.calculate,
      error: s.problem == null ? null : problemMessage(l, s.problem!, labels),
      resultKey: s.runId,
      inputs: [
        FormSection(
          title: l.septicUse,
          icon: Icons.groups_rounded,
          children: [
            FieldRow(
              children: [
                field('users', '', hint: '10'),
                field('rooms', ''),
              ],
            ),
            FieldRow(children: [field('flow', 'L/d'), field('retention', 'd')]),
            FieldRow(children: [field('sludge', 'L/yr'), field('years', 'yr')]),
            Text(l.septicUseNote, style: context.text.bodySmall),
          ],
        ),
        FormSection(
          title: l.septicShape,
          icon: Icons.crop_landscape_rounded,
          children: [
            FieldRow(
              children: [
                field('depth', 'm'),
                field('freeboard', 'm'),
                field('ratio', ''),
              ],
            ),
          ],
        ),
      ],
      results: s.result == null ? null : _results(context, s.result!),
    );
  }

  List<Widget> _results(BuildContext context, SepticResult r) {
    final l = context.l10n;
    String f2(double v) => fmt(context, v, 2);
    return [
      StatusBanner(
        tone: Tone.success,
        title: l.septicVolume(f2(r.volume)),
        message: l.septicDims(f2(r.length), f2(r.width), f2(r.totalDepth)),
      ),
      ResultCard(
        title: l.septicVolumes,
        icon: Icons.water_drop_outlined,
        rows: [
          ResultRow(
            label: l.septicSettling,
            value: f2(r.settlingVolume),
            unit: 'm³',
          ),
          ResultRow(
            label: l.septicSludgeVolume,
            value: f2(r.sludgeVolume),
            unit: 'm³',
          ),
          if (r.dtuMinimum != null)
            ResultRow(
              label: l.septicDtuMin,
              value: f2(r.dtuMinimum!),
              unit: 'm³',
            ),
          ResultRow(
            label: l.septicProvided,
            value: f2(r.providedVolume),
            unit: 'm³',
            emphasize: true,
          ),
        ],
      ),
      ResultCard(
        title: l.septicLayout,
        icon: Icons.straighten,
        rows: [
          ResultRow(
            label: l.septicInside,
            symbol: 'L × B × H',
            value: '${f2(r.length)} × ${f2(r.width)} × ${f2(r.totalDepth)}',
            unit: 'm',
            emphasize: true,
          ),
          ResultRow(
            label: l.septicCompartments,
            symbol: '2/3 · 1/3',
            value: '${f2(r.firstCompartment)} + ${f2(r.secondCompartment)}',
            unit: 'm',
          ),
        ],
      ),
      NotesCard(notes: [l.septicNoteScope]),
    ];
  }
}
