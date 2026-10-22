import 'package:flutter/material.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// Returned by [showGroupSettings] when the user deletes the group.
const deletedGroup = DesignGroup(
  id: '-',
  name: '-',
  members: [],
  material: DesignMaterial.concrete,
);

String materialLabel(AppLocalizations l, DesignMaterial m) => switch (m) {
  DesignMaterial.concrete => l.catConcrete,
  DesignMaterial.steel => l.catSteel,
  DesignMaterial.timber => l.catTimber,
};

/// Default name of an automatic group.
String autoGroupName(AppLocalizations l, DesignMaterial m, MemberKind k) =>
    '${materialLabel(l, m)} · ${switch (k) {
      MemberKind.column => l.f3dSelectColumns,
      MemberKind.beam => l.f3dSelectBeams,
      MemberKind.brace => l.f3dSelectBraces,
    }}';

/// Members, material and settings of a design group; returns the edited
/// group, [deletedGroup], or null when cancelled. [selection] is the
/// multi-selection of the Edit tab.
Future<DesignGroup?> showGroupSettings(
  BuildContext context, {
  required DesignGroup group,
  required Model3D model,
  Set<int> selection = const {},
  bool canDelete = false,
}) => showModalBottomSheet<DesignGroup>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 680),
  builder: (_) => _GroupSettings(
    group: group,
    model: model,
    selection: selection,
    canDelete: canDelete,
  ),
);

class _GroupSettings extends StatefulWidget {
  final DesignGroup group;
  final Model3D model;
  final Set<int> selection;
  final bool canDelete;
  const _GroupSettings({
    required this.group,
    required this.model,
    required this.selection,
    required this.canDelete,
  });

  @override
  State<_GroupSettings> createState() => _GroupSettingsState();
}

class _GroupSettingsState extends State<_GroupSettings> {
  late final _name = TextEditingController(text: widget.group.name);
  late DesignGroup _g = widget.group;
  late final Set<int> _members = {...widget.group.members};
  late double? _fck = _g.fck, _fyk = _g.fyk, _cover = _g.cover;
  late double? _l0 = _g.l0Factor, _ky = _g.ky, _kz = _g.kz, _kLT = _g.kLT;
  late double? _defl = _g.deflectionLimit;
  bool _invalid = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  DesignGroup? _result() {
    double pos(double? v, double fallback) =>
        v == null || v <= 0 ? fallback : v;
    final name = _name.text.trim();
    if (name.isEmpty || _members.isEmpty) return null;
    return _g.copyWith(
      name: name,
      members: _members.toList()..sort(),
      fck: pos(_fck, 25),
      fyk: pos(_fyk, 500),
      cover: pos(_cover, 30),
      l0Factor: pos(_l0, 1),
      ky: pos(_ky, 1),
      kz: pos(_kz, 1),
      kLT: pos(_kLT, 1),
      deflectionLimit: pos(_defl, 250),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final m = widget.model;
    final g = _g;
    Widget n(
      String label,
      double? v,
      ValueChanged<double?> f, [
      String u = '',
    ]) => NumberField(label: label, unit: u, value: v, onChanged: f);
    void add(Iterable<int> e) => setState(() => _members.addAll(e));
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.f3dGroupSettings, style: context.text.titleLarge),
                  const SizedBox(height: Gap.md),
                  TextField(
                    controller: _name,
                    decoration: InputDecoration(labelText: l.f3dGroupName),
                  ),
                  const SizedBox(height: Gap.md),
                  ChoiceField<DesignMaterial>(
                    label: l.f3dMaterial,
                    value: g.material,
                    options: {
                      for (final x in DesignMaterial.values)
                        x: materialLabel(l, x),
                    },
                    onChanged: (v) =>
                        setState(() => _g = g.copyWith(material: v)),
                  ),
                  const SizedBox(height: Gap.md),
                  Text(
                    l.f3dGroupMembers(_members.length),
                    style: context.text.labelLarge,
                  ),
                  const SizedBox(height: Gap.xs),
                  Wrap(
                    spacing: Gap.xs,
                    runSpacing: Gap.xs,
                    children: [
                      if (widget.selection.isNotEmpty)
                        ActionChip(
                          avatar: const Icon(
                            Icons.select_all_rounded,
                            size: 16,
                          ),
                          label: Text(
                            l.f3dGroupUseSelection(widget.selection.length),
                          ),
                          onPressed: () => add(widget.selection),
                        ),
                      for (final (k, label) in [
                        (MemberKind.column, l.f3dSelectColumns),
                        (MemberKind.beam, l.f3dSelectBeams),
                        (MemberKind.brace, l.f3dSelectBraces),
                      ])
                        ActionChip(
                          label: Text('+ $label'),
                          onPressed: () => add(m.elementsOfKind(k)),
                        ),
                      for (final z in m.levels().skip(1))
                        ActionChip(
                          label: Text(
                            '+ ${l.f3dSelectLevel} ${fmt(context, z, 2)}',
                          ),
                          onPressed: () => add(m.elementsAtLevel(z)),
                        ),
                      ActionChip(
                        avatar: const Icon(Icons.clear_rounded, size: 16),
                        label: Text(l.f3dSelectClear),
                        onPressed: () => setState(_members.clear),
                      ),
                    ],
                  ),
                  const SizedBox(height: Gap.lg),
                  ...switch (g.material) {
                    DesignMaterial.concrete => [
                      CodeChoice(
                        value: g.code,
                        onChanged: (c) =>
                            setState(() => _g = g.copyWith(code: c)),
                      ),
                      const SizedBox(height: Gap.md),
                      ChoiceField<ConcreteRole>(
                        label: l.memberDesignAs,
                        value: g.role,
                        options: {
                          ConcreteRole.auto: l.f3dRoleAuto,
                          ConcreteRole.beam: l.modBeam,
                          ConcreteRole.column: l.modColumn,
                        },
                        onChanged: (v) =>
                            setState(() => _g = g.copyWith(role: v)),
                      ),
                      const SizedBox(height: Gap.md),
                      FieldRow(
                        children: [
                          n(l.calcConcreteFck, _fck, (v) => _fck = v, 'MPa'),
                          n(l.calcSteelFyk, _fyk, (v) => _fyk = v, 'MPa'),
                        ],
                      ),
                      const SizedBox(height: Gap.md),
                      FieldRow(
                        children: [
                          n(l.calcCover, _cover, (v) => _cover = v, 'mm'),
                          n(l.memberBucklingFactor, _l0, (v) => _l0 = v),
                        ],
                      ),
                    ],
                    DesignMaterial.steel => [
                      PickerField<String>(
                        label: l.steelGrade,
                        value: g.grade,
                        options: {for (final x in steelGrades.keys) x: x},
                        onChanged: (v) =>
                            setState(() => _g = g.copyWith(grade: v)),
                      ),
                      const SizedBox(height: Gap.md),
                      FieldRow(
                        children: [
                          n('ky', _ky, (v) => _ky = v),
                          n('kz', _kz, (v) => _kz = v),
                          n('kLT', _kLT, (v) => _kLT = v),
                        ],
                      ),
                      const SizedBox(height: Gap.xs),
                      Text(l.steelBucklingNote, style: context.text.bodySmall),
                    ],
                    DesignMaterial.timber => [
                      PickerField<String>(
                        label: l.timberStrengthClass,
                        value: g.timberClass,
                        options: {for (final x in timberClasses.keys) x: x},
                        onChanged: (v) =>
                            setState(() => _g = g.copyWith(timberClass: v)),
                      ),
                      const SizedBox(height: Gap.md),
                      PickerField<LoadDuration>(
                        label: l.timberDuration,
                        value: g.duration,
                        options: {
                          LoadDuration.permanent: l.timberDurPermanent,
                          LoadDuration.longTerm: l.timberDurLong,
                          LoadDuration.mediumTerm: l.timberDurMedium,
                          LoadDuration.shortTerm: l.timberDurShort,
                          LoadDuration.instantaneous: l.timberDurInstant,
                        },
                        onChanged: (v) =>
                            setState(() => _g = g.copyWith(duration: v)),
                      ),
                      const SizedBox(height: Gap.md),
                      ChoiceField<int>(
                        label: l.timberServiceClass,
                        value: g.serviceClass,
                        options: const {1: '1', 2: '2', 3: '3'},
                        onChanged: (v) =>
                            setState(() => _g = g.copyWith(serviceClass: v)),
                      ),
                      const SizedBox(height: Gap.md),
                      FieldRow(
                        children: [
                          n('ky', _ky, (v) => _ky = v),
                          n('kz', _kz, (v) => _kz = v),
                          n('kLT', _kLT, (v) => _kLT = v),
                        ],
                      ),
                    ],
                  },
                  const SizedBox(height: Gap.md),
                  n(l.f3dDeflectionLimit, _defl, (v) => _defl = v, 'L /'),
                  const SizedBox(height: Gap.xs),
                  Text(l.f3dGroupNote, style: context.text.bodySmall),
                  if (_invalid) ...[
                    const SizedBox(height: Gap.sm),
                    StatusBanner(tone: Tone.danger, title: l.f3dGroupInvalid),
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
                    onPressed: () => Navigator.pop(context, deletedGroup),
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
                    if (r == null) {
                      setState(() => _invalid = true);
                      return;
                    }
                    Navigator.pop(context, r);
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

/// Checks and forces of one designed member.
Future<void> showMemberDesignResult(
  BuildContext context, {
  required MemberDesign3D design,
  required String groupName,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 720),
  builder: (context) {
    final l = context.l10n;
    final f = design.forces;
    final err = design.error;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.frameMemberTitle(design.member + 1),
            style: context.text.headlineSmall,
          ),
          Text(
            '$groupName · ${design.asColumn ? l.modColumn : (design.material == DesignMaterial.concrete ? l.modBeam : materialLabel(l, design.material))}',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: Gap.md),
          if (err != null)
            StatusBanner(
              tone: Tone.danger,
              title: l.f3dDesignFailed,
              message: err.field == 'section'
                  ? l.memberUnsupportedSectionMsg
                  : '${err.problem.name} (${err.field})',
            )
          else ...[
            VerdictBanner(checks: design.checks),
            const SizedBox(height: Gap.md),
            ResultCard(
              title: l.f3dDesignSummary,
              icon: Icons.grid_on_rounded,
              rows: [
                ResultRow(
                  label: l.f3dUtilisation,
                  value: fmt(context, design.ratio, 2),
                  emphasize: true,
                ),
                ResultRow(label: l.f3dDesignResult, value: design.summary),
              ],
            ),
          ],
          const SizedBox(height: Gap.md),
          ResultCard(
            title: l.memberEnvelopeForces,
            icon: Icons.insights_rounded,
            rows: [
              ResultRow(
                label: l.frameMaxSagging,
                symbol: 'My+',
                value: fmt(context, f.mySagging),
                unit: 'kN·m',
              ),
              ResultRow(
                label: l.frameMaxHogging,
                symbol: 'My−',
                value: fmt(context, f.myHogging),
                unit: 'kN·m',
              ),
              ResultRow(
                label: l.f3dMinorMoment,
                symbol: 'Mz',
                value: fmt(context, f.mzMax),
                unit: 'kN·m',
              ),
              ResultRow(
                label: l.frameMaxShear,
                symbol: 'Vz',
                value: fmt(context, f.vzMax),
                unit: 'kN',
              ),
              ResultRow(
                label: l.memberCompression,
                symbol: 'N',
                value: fmt(context, f.nCompression),
                unit: 'kN',
              ),
            ],
          ),
          if (err == null) ...[
            const SizedBox(height: Gap.md),
            ChecksCard(checks: design.checks),
          ],
        ],
      ),
    );
  },
);
