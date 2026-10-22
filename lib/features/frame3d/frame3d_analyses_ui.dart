import 'package:flutter/material.dart';
import 'package:sibot/features/calculations/loads/presentation/seismic_provider.dart'
    show frenchZones;
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// Returned by [showAnalysisSettings] when the user deletes the analysis.
const deletedAnalysis = AnalysisSpec(id: '-', kind: AnalysisKind.static);

/// Returned by [showCombinationEditor] when the user deletes it.
const deletedCombination = Combination('-', CombinationKind.uls, {});

/// Settings of one analysis; returns the edited spec, [deletedAnalysis],
/// or null when cancelled.
Future<AnalysisSpec?> showAnalysisSettings(
  BuildContext context, {
  required AnalysisSpec spec,
  required List<Combination> combinations,
  bool canDelete = false,
}) => showModalBottomSheet<AnalysisSpec>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 680),
  builder: (_) => _AnalysisSettings(
    spec: spec,
    combinations: combinations,
    canDelete: canDelete,
  ),
);

class _AnalysisSettings extends StatefulWidget {
  final AnalysisSpec spec;
  final List<Combination> combinations;
  final bool canDelete;
  const _AnalysisSettings({
    required this.spec,
    required this.combinations,
    required this.canDelete,
  });

  @override
  State<_AnalysisSettings> createState() => _AnalysisSettingsState();
}

class _AnalysisSettingsState extends State<_AnalysisSettings> {
  late final _name = TextEditingController(text: widget.spec.name);
  late AnalysisSpec _s = widget.spec;
  late double? _modes = widget.spec.modes.toDouble();
  late double? _agR = widget.spec.agR;
  late double? _q = widget.spec.q;
  String _zone = 'custom';
  Ps92Zone _psZone = Ps92Zone.ib;
  String _psClass = 'C';

  @override
  void initState() {
    super.initState();
    for (final e in frenchZones.entries) {
      if ((e.value - _s.agR).abs() < 1e-9) _zone = '${e.key}';
    }
    // Recover the PS92 zone and class of the stored acceleration.
    for (final z in Ps92Zone.values) {
      for (final c in const ['B', 'C', 'D']) {
        if ((ps92NominalAcceleration(z, c) - _s.aN).abs() < 1e-9) {
          _psZone = z;
          _psClass = c;
        }
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  AnalysisSpec? _result() {
    final modes = (_modes ?? 12).round();
    if (modes < 1 || modes > 60) return null;
    if (_s.kind == AnalysisKind.spectrum) {
      if ((_q ?? 0) < 1) return null;
      if (!_s.ps92 && (_agR ?? 0) <= 0) return null;
    }
    return _s.copyWith(
      name: _name.text.trim(),
      modes: modes,
      agR: _agR,
      q: _q,
      aN: ps92NominalAcceleration(_psZone, _psClass),
      type1: _zone == '5' || (_zone == 'custom' && _s.type1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = _s;
    final combos = widget.combinations;
    final single =
        s.kind == AnalysisKind.buckling || s.kind == AnalysisKind.pDelta;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Settings scroll; the actions stay in view.
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.f3dAnalysisSettings, style: context.text.titleLarge),
                  const SizedBox(height: Gap.md),
                  TextField(
                    controller: _name,
                    decoration: InputDecoration(labelText: l.f3dAnalysisName),
                  ),
                  const SizedBox(height: Gap.md),
                  if (s.kind == AnalysisKind.static) ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.f3dAllCombinations),
                      value: s.combinations == null,
                      onChanged: (v) => setState(
                        () => _s = v
                            ? s.copyWith(allCombinations: true)
                            : s.copyWith(
                                combinations: [
                                  for (var i = 0; i < combos.length; i++) i,
                                ],
                              ),
                      ),
                    ),
                    if (s.combinations != null)
                      Wrap(
                        spacing: Gap.xs,
                        runSpacing: Gap.xs,
                        children: [
                          for (var i = 0; i < combos.length; i++)
                            FilterChip(
                              label: Text(combos[i].name),
                              selected: s.combinations!.contains(i),
                              onSelected: (v) => setState(() {
                                final next = {...s.combinations!};
                                v ? next.add(i) : next.remove(i);
                                _s = s.copyWith(
                                  combinations: next.toList()..sort(),
                                );
                              }),
                            ),
                        ],
                      ),
                  ],
                  if (single && combos.isNotEmpty)
                    PickerField<int>(
                      label: l.f3dCombination,
                      value: s.combinationIn(combos) ?? 0,
                      options: {
                        for (var i = 0; i < combos.length; i++)
                          i: combos[i].name,
                      },
                      onChanged: (v) =>
                          setState(() => _s = s.copyWith(combinations: [v])),
                    ),
                  if (s.kind == AnalysisKind.modal ||
                      s.kind == AnalysisKind.spectrum)
                    NumberField(
                      label: l.f3dModeCount,
                      value: _modes,
                      onChanged: (v) => _modes = v,
                    ),
                  if (s.kind == AnalysisKind.spectrum) ...[
                    const SizedBox(height: Gap.md),
                    ChoiceField<bool>(
                      label: l.footingCode,
                      value: s.ps92,
                      options: const {false: 'EN 1998-1', true: 'PS92'},
                      onChanged: (v) =>
                          setState(() => _s = s.copyWith(ps92: v)),
                    ),
                    const SizedBox(height: Gap.md),
                    if (s.ps92) ...[
                      FieldRow(
                        children: [
                          PickerField<Ps92Zone>(
                            label: l.f3dPs92Zone,
                            value: _psZone,
                            options: const {
                              Ps92Zone.ia: 'Ia',
                              Ps92Zone.ib: 'Ib',
                              Ps92Zone.ii: 'II',
                              Ps92Zone.iii: 'III',
                            },
                            onChanged: (v) => setState(() => _psZone = v),
                          ),
                          PickerField<String>(
                            label: l.f3dPs92Class,
                            value: _psClass,
                            options: const {'B': 'B', 'C': 'C', 'D': 'D'},
                            onChanged: (v) => setState(() => _psClass = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: Gap.md),
                      ChoiceField<Ps92Site>(
                        label: l.f3dPs92Site,
                        value: s.site,
                        options: {
                          for (final v in Ps92Site.values)
                            v: v.name.toUpperCase(),
                        },
                        onChanged: (v) =>
                            setState(() => _s = s.copyWith(site: v)),
                      ),
                      const SizedBox(height: Gap.sm),
                      Text(
                        l.f3dPs92Note(
                          fmt(
                            context,
                            ps92NominalAcceleration(_psZone, _psClass),
                            1,
                          ),
                        ),
                        style: context.text.bodySmall,
                      ),
                    ] else ...[
                      PickerField<String>(
                        key: ValueKey('zone-$_zone'),
                        label: l.seismicZone,
                        value: _zone,
                        options: {
                          'custom': l.seismicZoneCustom,
                          for (final z in frenchZones.entries)
                            '${z.key}': l.seismicZoneN(
                              z.key,
                              fmt(context, z.value, 1),
                            ),
                        },
                        onChanged: (v) => setState(() {
                          _zone = v;
                          final n = int.tryParse(v);
                          if (n != null) _agR = frenchZones[n];
                        }),
                      ),
                      const SizedBox(height: Gap.md),
                      NumberField(
                        key: ValueKey('ag-$_zone'),
                        label: l.seismicAgR,
                        unit: 'm/s²',
                        value: _agR,
                        onChanged: (v) => _agR = v,
                      ),
                      const SizedBox(height: Gap.md),
                      ChoiceField<GroundType>(
                        label: l.seismicGround,
                        value: s.ground,
                        options: {
                          for (final g in GroundType.values)
                            g: g.name.toUpperCase(),
                        },
                        onChanged: (v) =>
                            setState(() => _s = s.copyWith(ground: v)),
                      ),
                      const SizedBox(height: Gap.md),
                      ChoiceField<int>(
                        label: l.seismicImportance,
                        value: s.importance,
                        options: const {1: 'I', 2: 'II', 3: 'III', 4: 'IV'},
                        onChanged: (v) =>
                            setState(() => _s = s.copyWith(importance: v)),
                      ),
                    ],
                    const SizedBox(height: Gap.md),
                    NumberField(
                      label: l.seismicQ,
                      value: _q,
                      onChanged: (v) => _q = v,
                    ),
                    const SizedBox(height: Gap.md),
                    ChoiceField<int>(
                      label: l.f3dDirection,
                      value: s.direction,
                      options: {0: 'X', 1: 'Y', 2: l.f3dBothDirections},
                      onChanged: (v) =>
                          setState(() => _s = s.copyWith(direction: v)),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.f3dAccidentalTorsion),
                      subtitle: Text(l.f3dAccidentalTorsionHelp),
                      value: s.torsion,
                      onChanged: (v) =>
                          setState(() => _s = s.copyWith(torsion: v)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: Row(
              children: [
                if (widget.canDelete)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: context.appColors.danger,
                    ),
                    onPressed: () => Navigator.pop(context, deletedAnalysis),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(l.commonDelete),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.commonCancel),
                ),
                const SizedBox(width: Gap.sm),
                FilledButton(
                  onPressed: () {
                    final r = _result();
                    if (r != null) Navigator.pop(context, r);
                  },
                  child: Text(l.commonSave),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Name, kind and factors of one combination; returns the combination,
/// [deletedCombination], or null when cancelled.
Future<Combination?> showCombinationEditor(
  BuildContext context, {
  required List<String> cases,
  Combination? initial,
  bool canDelete = false,
}) => showModalBottomSheet<Combination>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 680),
  builder: (_) =>
      _CombinationEditor(cases: cases, initial: initial, canDelete: canDelete),
);

class _CombinationEditor extends StatefulWidget {
  final List<String> cases;
  final Combination? initial;
  final bool canDelete;
  const _CombinationEditor({
    required this.cases,
    required this.initial,
    required this.canDelete,
  });

  @override
  State<_CombinationEditor> createState() => _CombinationEditorState();
}

class _CombinationEditorState extends State<_CombinationEditor> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late CombinationKind _kind = widget.initial?.kind ?? CombinationKind.uls;
  late final List<double?> _f = [
    for (var i = 0; i < widget.cases.length; i++) widget.initial?.factors[i],
  ];
  bool _invalid = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Settings scroll; the actions stay in view.
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.f3dComboEdit, style: context.text.titleLarge),
                  const SizedBox(height: Gap.md),
                  TextField(
                    controller: _name,
                    decoration: InputDecoration(labelText: l.f3dComboName),
                  ),
                  const SizedBox(height: Gap.md),
                  ChoiceField<CombinationKind>(
                    label: l.f3dComboKind,
                    value: _kind,
                    options: {
                      CombinationKind.uls: l.f3dComboUls,
                      CombinationKind.slsCharacteristic: l.f3dComboSlsChar,
                      CombinationKind.slsQuasiPermanent: l.f3dComboSlsQp,
                    },
                    onChanged: (v) => setState(() => _kind = v),
                  ),
                  const SizedBox(height: Gap.md),
                  Text(l.f3dComboFactors, style: context.text.labelLarge),
                  const SizedBox(height: Gap.xs),
                  for (var i = 0; i < widget.cases.length; i += 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Gap.sm),
                      child: FieldRow(
                        children: [
                          for (
                            var k = i;
                            k < i + 2 && k < widget.cases.length;
                            k++
                          )
                            NumberField(
                              label: widget.cases[k],
                              value: _f[k],
                              allowNegative: true,
                              onChanged: (v) => _f[k] = v,
                            ),
                          if (i + 1 >= widget.cases.length)
                            const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  Text(l.f3dComboFactorsHelp, style: context.text.bodySmall),
                  if (_invalid) ...[
                    const SizedBox(height: Gap.sm),
                    StatusBanner(tone: Tone.danger, title: l.f3dComboInvalid),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: Row(
              children: [
                if (widget.canDelete)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: context.appColors.danger,
                    ),
                    onPressed: () => Navigator.pop(context, deletedCombination),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(l.commonDelete),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.commonCancel),
                ),
                const SizedBox(width: Gap.sm),
                FilledButton(
                  onPressed: () {
                    final factors = {
                      for (var i = 0; i < _f.length; i++)
                        if ((_f[i] ?? 0) != 0) i: _f[i]!,
                    };
                    final name = _name.text.trim();
                    if (factors.isEmpty || name.isEmpty) {
                      setState(() => _invalid = true);
                      return;
                    }
                    Navigator.pop(context, Combination(name, _kind, factors));
                  },
                  child: Text(l.commonSave),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
