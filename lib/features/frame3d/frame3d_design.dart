import 'package:flutter/material.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// Opens the design of a 3D member from the envelope of [results]
/// (ULS combinations, plus seismic situations when [seismic] is true).
Future<void> showMember3DDesign(
  BuildContext context, {
  required Model3D model,
  required int index,
  required List<Frame3DResult> results,
  bool seismic = false,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 720),
  builder: (_) => _Member3DSheet(
    model: model,
    index: index,
    envelope: MemberEnvelope3D.of(model, index, results),
    seismic: seismic,
  ),
);

class _Member3DSheet extends StatefulWidget {
  final Model3D model;
  final int index;
  final MemberEnvelope3D envelope;
  final bool seismic;
  const _Member3DSheet({
    required this.model,
    required this.index,
    required this.envelope,
    required this.seismic,
  });

  @override
  State<_Member3DSheet> createState() => _Member3DSheetState();
}

class _Member3DSheetState extends State<_Member3DSheet> {
  late bool _asColumn = widget.envelope.vertical;
  DesignCode _code = defaultDesignCode();
  double? _fck = 25, _fyk = 500, _cover = 30, _l0Factor = 1.0;
  String _grade = 'S275';
  double? _ky = 1, _kz = 1, _kLT = 1;

  Section3D get _section =>
      widget.model.sections[widget.model.elements[widget.index].section];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = widget.envelope;
    final s = _section;
    final steel =
        s.profile != null &&
        steelProfiles[s.profile] != null &&
        steelDesignable(steelProfiles[s.profile]!);
    final concrete = !steel && s.b != null && s.h != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Gap.xl,
        0,
        Gap.xl,
        Gap.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${l.frameMemberTitle(widget.index + 1)} — ${s.name}',
              style: context.text.headlineSmall,
            ),
            const SizedBox(height: Gap.xs),
            Text(
              widget.seismic ? l.f3dDesignSeismic : l.f3dDesignStatic,
              style: context.text.bodySmall,
            ),
            const SizedBox(height: Gap.lg),
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
                if (f.nTension > 0)
                  ResultRow(
                    label: l.memberTension,
                    symbol: 'N',
                    value: fmt(context, f.nTension),
                    unit: 'kN',
                  ),
              ],
            ),
            const SizedBox(height: Gap.md),
            if (steel)
              _steel(context, f, steelProfiles[s.profile]!)
            else if (concrete)
              _concrete(context, f, s)
            else
              StatusBanner(
                tone: Tone.warning,
                title: l.memberUnsupportedSection,
                message: l.memberUnsupportedSectionMsg,
              ),
          ],
        ),
      ),
    );
  }

  Widget _error(BuildContext context, InputError e) {
    final l = context.l10n;
    return StatusBanner(
      tone: Tone.danger,
      title: l.calcCheckInputs,
      message: problemMessage(l, FormProblem(e.field, e.problem), {
        'fck': l.calcConcreteFck,
        'fyk': l.calcSteelFyk,
        'cover': l.calcCover,
        'nEd': l.memberCompression,
        'ky': 'ky',
        'kz': 'kz',
        'kLT': 'kLT',
        'length': l.steelLength,
      }),
    );
  }

  Widget _concrete(BuildContext context, MemberEnvelope3D f, Section3D s) {
    final l = context.l10n;
    final inputs = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CodeChoice(value: _code, onChanged: (c) => setState(() => _code = c)),
        const SizedBox(height: Gap.md),
        ChoiceField<bool>(
          label: l.memberDesignAs,
          value: _asColumn,
          options: {false: l.modBeam, true: l.modColumn},
          onChanged: (v) => setState(() => _asColumn = v),
        ),
        const SizedBox(height: Gap.md),
        FieldRow(
          children: [
            NumberField(
              label: l.calcConcreteFck,
              unit: 'MPa',
              value: _fck,
              onChanged: (v) => setState(() => _fck = v),
            ),
            NumberField(
              label: l.calcSteelFyk,
              unit: 'MPa',
              value: _fyk,
              onChanged: (v) => setState(() => _fyk = v),
            ),
          ],
        ),
        const SizedBox(height: Gap.md),
        FieldRow(
          children: [
            NumberField(
              label: l.calcCover,
              unit: 'mm',
              value: _cover,
              onChanged: (v) => setState(() => _cover = v),
            ),
            if (_asColumn)
              NumberField(
                label: l.memberBucklingFactor,
                value: _l0Factor,
                onChanged: (v) => setState(() => _l0Factor = v),
              ),
          ],
        ),
      ],
    );

    Widget results;
    try {
      if ((_fck ?? 0) <= 0) {
        throw const InputError(InputProblem.notPositive, 'fck');
      }
      if ((_fyk ?? 0) <= 0) {
        throw const InputError(InputProblem.notPositive, 'fyk');
      }
      if ((_cover ?? 0) <= 0) {
        throw const InputError(InputProblem.notPositive, 'cover');
      }
      if (_asColumn) {
        if (f.nCompression <= 0) {
          throw const InputError(InputProblem.notPositive, 'nEd');
        }
        final r = designColumn(
          ColumnInput(
            code: _code,
            b: s.b!,
            h: s.h!,
            l0: f.length * (_l0Factor ?? 1),
            nEd: f.nCompression,
            m0Ed: f.myMax,
            m0EdB: f.mzMax,
            cover: _cover!,
            fck: _fck!,
            fyk: _fyk!,
          ),
        );
        results = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VerdictBanner(checks: r.checks),
            const SizedBox(height: Gap.md),
            ResultCard(
              title: l.footingReinforcement,
              icon: Icons.grid_on_rounded,
              rows: [
                ResultRow(
                  label: l.checkSlenderness,
                  symbol: 'λ',
                  value: fmt(context, r.slenderness, 1),
                ),
                ResultRow(
                  label: l.columnLongitudinalBars,
                  value: r.bars?.toString() ?? '—',
                  emphasize: true,
                ),
                ResultRow(
                  label: l.resultLinks,
                  value: 'Ø${r.linkDiameter} @ ${r.linkSpacing}',
                ),
              ],
            ),
            const SizedBox(height: Gap.md),
            ChecksCard(checks: r.checks),
          ],
        );
      } else {
        final r = designBeamSection(
          BeamSectionInput(
            code: _code,
            b: s.b!,
            h: s.h!,
            mSagging: f.mySagging,
            mHogging: f.myHogging,
            vEd: f.vzMax,
            cover: _cover!,
            fck: _fck!,
            fyk: _fyk!,
          ),
        );
        results = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VerdictBanner(checks: r.checks),
            const SizedBox(height: Gap.md),
            ResultCard(
              title: l.footingReinforcement,
              icon: Icons.grid_on_rounded,
              rows: [
                ResultRow(
                  label: l.resultBottomBars,
                  symbol: '${fmt(context, r.asBottom, 0)} mm²',
                  value: r.bottomBars?.toString() ?? '—',
                  emphasize: true,
                ),
                ResultRow(
                  label: l.resultTopBars,
                  symbol: '${fmt(context, r.asTop, 0)} mm²',
                  value: r.topBars?.toString() ?? '—',
                  emphasize: true,
                ),
                ResultRow(
                  label: l.resultLinks,
                  value: r.shear.links?.toString() ?? '—',
                ),
              ],
            ),
            const SizedBox(height: Gap.md),
            ChecksCard(checks: r.checks),
            if (f.mzMax > 0.1 * f.myMax ||
                f.nCompression > 0.1 * s.area * 1e3 * (_fck ?? 25)) ...[
              const SizedBox(height: Gap.sm),
              StatusBanner(
                tone: Tone.warning,
                title: l.f3dBeamExtraForces,
                message: l.f3dBeamExtraForcesMsg,
              ),
            ],
          ],
        );
      }
    } on InputError catch (e) {
      results = _error(context, e);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        inputs,
        const SizedBox(height: Gap.lg),
        results,
      ],
    );
  }

  Widget _steel(BuildContext context, MemberEnvelope3D f, SteelProfile p) {
    final l = context.l10n;
    final inputs = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PickerField<String>(
          label: l.steelGrade,
          value: _grade,
          options: {for (final g in steelGrades.keys) g: g},
          onChanged: (v) => setState(() => _grade = v),
        ),
        const SizedBox(height: Gap.md),
        FieldRow(
          children: [
            NumberField(
              label: 'ky',
              value: _ky,
              onChanged: (v) => setState(() => _ky = v),
            ),
            NumberField(
              label: 'kz',
              value: _kz,
              onChanged: (v) => setState(() => _kz = v),
            ),
            NumberField(
              label: 'kLT',
              value: _kLT,
              onChanged: (v) => setState(() => _kLT = v),
            ),
          ],
        ),
        const SizedBox(height: Gap.sm),
        Text(l.steelBucklingNote, style: context.text.bodySmall),
      ],
    );
    Widget results;
    try {
      final r = designSteelMember(
        SteelMemberInput(
          section: p,
          grade: _grade,
          length: f.length,
          nEd: f.nCompression > 0 ? f.nCompression : -f.nTension,
          myEd: f.myMax,
          mzEd: f.mzMax,
          vEd: f.vzMax,
          ky: _ky ?? 0,
          kz: _kz ?? 0,
          kLT: _kLT ?? 0,
        ),
      );
      results = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VerdictBanner(checks: r.checks),
          const SizedBox(height: Gap.md),
          ResultCard(
            title: l.steelStability,
            icon: Icons.unfold_more_rounded,
            rows: [
              ResultRow(
                label: l.steelClass,
                symbol: 'fy = ${fmt(context, r.fy, 0)} MPa',
                value: '${r.sectionClass}',
              ),
              ResultRow(
                label: l.steelLtbResistance,
                symbol: 'Mb,Rd',
                value: fmt(context, r.mbRd),
                unit: 'kN·m',
                emphasize: true,
              ),
              ResultRow(
                label: l.steelFlexuralZ,
                symbol: 'χz · Npl,Rd',
                value: fmt(context, r.chiZ * r.nPlRd),
                unit: 'kN',
              ),
            ],
          ),
          const SizedBox(height: Gap.md),
          ChecksCard(checks: r.checks),
          const SizedBox(height: Gap.sm),
          Text(l.memberSteelNote, style: context.text.bodySmall),
        ],
      );
    } on InputError catch (e) {
      results = _error(context, e);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        inputs,
        const SizedBox(height: Gap.lg),
        results,
      ],
    );
  }
}
