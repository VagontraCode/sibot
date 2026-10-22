import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';
import 'timber_connection_provider.dart';

class TimberConnectionPage extends ConsumerWidget {
  final String projectId;
  const TimberConnectionPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(timberConnectionStateProvider(projectId));
    final n = ref.read(timberConnectionStateProvider(projectId).notifier);
    final l = context.l10n;

    final labels = {
      'd': l.connDiameter,
      't1': l.connT1,
      't2': l.connT2,
      'angle2': l.connAngle,
      'perRow': l.connPerRow,
      'rows': l.connRows,
      'a1': l.connSpacing,
      'fEd': l.connLoad,
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
      title: l.modTimberConnection,
      subtitle: l.connSubtitle,
      module: moduleByRoute('timber-connection'),
      onCalculate: n.calculate,
      error: s.problem == null ? null : problemMessage(l, s.problem!, labels),
      resultKey: s.runId,
      inputs: [
        FormSection(
          title: l.timberMaterialTitle,
          icon: Icons.forest_outlined,
          children: [
            PickerField<String>(
              label: l.timberStrengthClass,
              value: s.options['class']!,
              options: {for (final c in timberClasses.keys) c: c},
              onChanged: (v) => n.setOption('class', v),
            ),
            PickerField<String>(
              label: l.timberDuration,
              value: s.options['duration']!,
              options: {
                LoadDuration.permanent.name: l.timberDurPermanent,
                LoadDuration.longTerm.name: l.timberDurLong,
                LoadDuration.mediumTerm.name: l.timberDurMedium,
                LoadDuration.shortTerm.name: l.timberDurShort,
                LoadDuration.instantaneous.name: l.timberDurInstant,
              },
              onChanged: (v) => n.setOption('duration', v),
            ),
            ChoiceField<String>(
              label: l.timberServiceClass,
              value: s.options['service']!,
              options: const {'1': '1', '2': '2', '3': '3'},
              onChanged: (v) => n.setOption('service', v),
            ),
          ],
        ),
        FormSection(
          title: l.connFastenersTitle,
          icon: Icons.hardware_outlined,
          children: [
            ChoiceField<String>(
              label: l.connGrade,
              value: s.options['grade']!,
              options: const {'4.6': '4.6', '8.8': '8.8'},
              onChanged: (v) => n.setOption('grade', v),
            ),
            FieldRow(
              children: [
                field('d', 'mm', hint: '12'),
                field('fEd', 'kN', hint: '10'),
              ],
            ),
            FieldRow(
              children: [
                field('t1', 'mm', hint: '45'),
                field('t2', 'mm', hint: '45'),
              ],
            ),
            field('angle2', '°'),
            FieldRow(
              children: [
                field('perRow', ''),
                field('rows', ''),
                field('a1', 'mm'),
              ],
            ),
            Text(l.connNote, style: context.text.bodySmall),
          ],
        ),
      ],
      results: s.result == null ? null : _results(context, s.result!),
    );
  }

  List<Widget> _results(BuildContext context, DowelConnectionResult r) {
    final l = context.l10n;
    String f2(double v) => fmt(context, v, 2);
    const modeNames = ['a', 'b', 'c', 'd', 'e', 'f'];
    return [
      VerdictBanner(checks: r.checks),
      ResultCard(
        title: l.connResults,
        icon: Icons.hardware_outlined,
        rows: [
          ResultRow(
            label: l.connCapacity,
            symbol: 'Fv,Rd,tot',
            value: f2(r.capacity),
            unit: 'kN',
            emphasize: true,
          ),
          ResultRow(
            label: l.connPerFastener,
            symbol: 'Fv,Rd',
            value: f2(r.fvRd / 1e3),
            unit: 'kN',
          ),
          ResultRow(label: l.connMode, value: '(${modeNames[r.governing]})'),
          ResultRow(label: l.connNef, symbol: 'nef', value: f2(r.nef)),
          ResultRow(
            label: l.connEmbedment,
            symbol: 'fh,1 / fh,2',
            value: '${f2(r.fh1)} / ${f2(r.fh2)}',
            unit: 'MPa',
          ),
          ResultRow(
            label: l.connYield,
            symbol: 'My,Rk',
            value: f2(r.myRk / 1e3),
            unit: 'N·m',
          ),
        ],
      ),
      ResultCard(
        title: l.connModes,
        icon: Icons.list_alt_outlined,
        rows: [
          for (var k = 0; k < r.modes.length; k++)
            ResultRow(
              label: '(${modeNames[k]})',
              symbol: 'Fv,Rk',
              value: f2(r.modes[k] / 1e3),
              unit: 'kN',
              emphasize: k == r.governing,
            ),
        ],
      ),
      ChecksCard(checks: r.checks),
      NotesCard(notes: [l.connNoteScope]),
    ];
  }
}
