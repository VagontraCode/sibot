import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/calculations/shared/diagrams.dart';
import 'package:sibot/features/frame/frame_providers.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// ULS design forces of a member taken from the envelope.
class MemberForces {
  final double length;
  final bool vertical;
  final double mSagging;
  final double mHogging;
  final double vMax;

  /// Largest compression (positive) and tension (positive), kN.
  final double nCompression;
  final double nTension;

  const MemberForces({
    required this.length,
    required this.vertical,
    required this.mSagging,
    required this.mHogging,
    required this.vMax,
    required this.nCompression,
    required this.nTension,
  });

  double get mAbs => math.max(mSagging, mHogging);

  static MemberForces? from(Model2D m, FrameAnalysisOutput out, int k) {
    if (out.envelopeM.isEmpty || k >= out.envelopeM.length) return null;
    final e = m.elements[k];
    final a = m.nodes[e.n1], b = m.nodes[e.n2];
    final l = math.sqrt(math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2));
    double hi(List<(double, double)> v) => v.map((p) => p.$2).reduce(math.max);
    double lo(List<(double, double)> v) => v.map((p) => p.$1).reduce(math.min);
    return MemberForces(
      length: l,
      vertical: (b.y - a.y).abs() > (b.x - a.x).abs(),
      mSagging: math.max(0, hi(out.envelopeM[k])),
      mHogging: math.max(0, -lo(out.envelopeM[k])),
      vMax: math.max(hi(out.envelopeV[k]).abs(), lo(out.envelopeV[k]).abs()),
      nCompression: math.max(0, -lo(out.envelopeN[k])),
      nTension: math.max(0, hi(out.envelopeN[k])),
    );
  }
}

Future<void> showMemberDesign(
  BuildContext context, {
  required Model2D model,
  required FrameAnalysisOutput output,
  required int index,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 720),
    builder: (_) =>
        _MemberDesignSheet(model: model, output: output, index: index),
  );
}

class _MemberDesignSheet extends StatefulWidget {
  final Model2D model;
  final FrameAnalysisOutput output;
  final int index;
  const _MemberDesignSheet({
    required this.model,
    required this.output,
    required this.index,
  });

  @override
  State<_MemberDesignSheet> createState() => _MemberDesignSheetState();
}

class _MemberDesignSheetState extends State<_MemberDesignSheet> {
  late final MemberForces? _f = MemberForces.from(
    widget.model,
    widget.output,
    widget.index,
  );
  late bool _asColumn = _f?.vertical ?? false;
  DesignCode _code = defaultDesignCode();
  double? _fyk = 500, _cover = 30, _l0Factor = 1.0;

  FrameSection get _section =>
      widget.model.sections[widget.model.elements[widget.index].section];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = _f;
    final sec = _section;
    Widget body;
    if (f == null) {
      body = StatusBanner(tone: Tone.warning, title: l.memberNoEnvelope);
    } else if (sec.material != SectionMaterial.concrete ||
        sec.b == null ||
        sec.h == null) {
      body = StatusBanner(
        tone: Tone.warning,
        title: l.memberUnsupportedSection,
        message: l.memberUnsupportedSectionMsg,
      );
    } else {
      body = _concrete(context, f, sec);
    }

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
              '${l.frameMemberTitle(widget.index + 1)} — ${sec.name}',
              style: context.text.headlineSmall,
            ),
            const SizedBox(height: Gap.xs),
            Text(l.memberDesignSubtitle, style: context.text.bodySmall),
            const SizedBox(height: Gap.lg),
            if (f != null)
              ResultCard(
                title: l.memberEnvelopeForces,
                icon: Icons.insights_rounded,
                rows: [
                  ResultRow(
                    label: l.frameMaxSagging,
                    symbol: 'M+',
                    value: fmt(context, f.mSagging),
                    unit: 'kN·m',
                  ),
                  ResultRow(
                    label: l.frameMaxHogging,
                    symbol: 'M−',
                    value: fmt(context, f.mHogging),
                    unit: 'kN·m',
                  ),
                  ResultRow(
                    label: l.frameMaxShear,
                    symbol: 'V',
                    value: fmt(context, f.vMax),
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
            body,
          ],
        ),
      ),
    );
  }

  Widget _concrete(BuildContext context, MemberForces f, FrameSection sec) {
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
              label: l.calcSteelFyk,
              unit: 'MPa',
              value: _fyk,
              onChanged: (v) => setState(() => _fyk = v),
            ),
            NumberField(
              label: l.calcCover,
              unit: 'mm',
              value: _cover,
              onChanged: (v) => setState(() => _cover = v),
            ),
          ],
        ),
        if (_asColumn) ...[
          const SizedBox(height: Gap.md),
          NumberField(
            label: l.memberBucklingFactor,
            value: _l0Factor,
            helper: l.memberBucklingFactorHelp,
            onChanged: (v) => setState(() => _l0Factor = v),
          ),
        ],
      ],
    );

    Widget results;
    try {
      if ((_fyk ?? 0) <= 0 || (_cover ?? 0) <= 0) {
        throw const InputError(InputProblem.notPositive, 'fyk');
      }
      if (_asColumn) {
        if (f.nCompression <= 0) {
          throw const InputError(InputProblem.notPositive, 'nEd');
        }
        final r = designColumn(
          ColumnInput(
            code: _code,
            b: sec.b!,
            h: sec.h!,
            l0: f.length * (_l0Factor ?? 1),
            nEd: f.nCompression,
            m0Ed: f.mAbs,
            cover: _cover!,
            fck: sec.fck ?? 25,
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
            b: sec.b!,
            h: sec.h!,
            mSagging: f.mSagging,
            mHogging: f.mHogging,
            vEd: f.vMax,
            cover: _cover!,
            fck: sec.fck ?? 25,
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
                  emphasize: true,
                ),
              ],
            ),
            const SizedBox(height: Gap.md),
            SectionSketch(
              b: sec.b!,
              h: sec.h!,
              cover: _cover!,
              linkDiameter: r.shear.links?.diameter ?? 8,
              bottom: r.bottomBars,
              top: r.topBars,
            ),
            const SizedBox(height: Gap.md),
            ChecksCard(checks: r.checks),
            const SizedBox(height: Gap.sm),
            Text(l.memberBeamNote, style: context.text.bodySmall),
          ],
        );
      }
    } on InputError catch (e) {
      results = StatusBanner(
        tone: Tone.danger,
        title: l.calcCheckInputs,
        message: problemMessage(l, FormProblem(e.field, e.problem), {
          'fyk': l.calcSteelFyk,
          'nEd': l.memberCompression,
          'cover': l.calcCover,
        }),
      );
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
