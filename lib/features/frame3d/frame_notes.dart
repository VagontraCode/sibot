import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:sibot/core/note/calc_note.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/calculations/shared/note_extract.dart';
import 'package:sibot/features/frame/frame_providers.dart';
import 'package:sibot/features/frame3d/frame3d_data.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// Renders and shares a note; returns false on failure.
Future<bool> shareNote(BuildContext context, CalcNote note) async {
  final l = context.l10n;
  try {
    final bytes = await renderNote(
      note,
      noteLabels(l),
      dateText: DateFormat.yMMMd(context.localeName).add_Hm().format(note.date),
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Sibot - ${note.title}.pdf',
    );
    return true;
  } catch (e, st) {
    LoggerService.e('Frame note failed: $e', e, st);
    return false;
  }
}

String _type(AppLocalizations l, LoadType t) => switch (t) {
  LoadType.permanent => l.f3dTypePermanent,
  LoadType.imposed => l.f3dTypeImposed,
  LoadType.snow => l.f3dTypeSnow,
  LoadType.wind => l.f3dTypeWind,
};

/// Note of a 3D model: model, combinations, ULS envelope per member,
/// modes, buckling and (when run) the seismic analysis.
CalcNote frame3dNote(
  BuildContext context, {
  required Frame3DRecord record,
  required Frame3DOutput out,
  NoteImage? view,
  SeismicOutput? seismic,
}) {
  final l = context.l10n;
  final m = out.model;
  String f(double v, [int? dp]) => fmt(context, v, dp);
  final uls = [
    for (var i = 0; i < out.combinations.length; i++)
      if (out.combinations[i].kind == CombinationKind.uls) out.results[i],
  ];
  return CalcNote(
    title: record.name,
    subtitle: l.modFrame3d,
    date: DateTime.now(),
    inputs: [
      NoteSection(l.f3dTabModel, [
        NoteRow(l.f3dNodesMembers, '${m.nodes.length} / ${m.elements.length}'),
        NoteRow(
          l.f3dRigidFloors,
          m.diaphragms.isEmpty ? '—' : '${m.diaphragms.length}',
        ),
        if (out.totalMass[0] > 0)
          NoteRow(l.f3dSeismicMass, f(out.totalMass[0], 0), unit: 't'),
      ]),
      NoteSection(l.f3dSections, [
        for (final s in m.sections)
          NoteRow(
            s.name,
            'A ${f(s.area * 1e4, 1)} cm² · Iy ${f(s.iy * 1e8, 0)} cm⁴',
          ),
      ]),
      NoteSection(l.f3dLoadCase, [
        for (final c in m.cases)
          NoteRow(
            c.name,
            [
              _type(l, c.type),
              if (c.selfWeight) l.noteSelfWeight,
              l.noteLoadCount(c.nodal.length + c.member.length),
            ].join(' · '),
          ),
      ]),
    ],
    results: [
      ?view,
      NoteTable(l.noteCombinations, [
        for (final c in out.combinations)
          NoteRow(
            c.name,
            c.factors.entries
                .map((e) => '${f(e.value, 2)}·${m.cases[e.key].name}')
                .join(' + '),
          ),
      ]),
      if (uls.isNotEmpty)
        NoteTable(l.noteEnvelope, [
          for (var e = 0; e < m.elements.length; e++)
            () {
              final env = MemberEnvelope3D.of(m, e, uls);
              return NoteRow(
                '${l.frameMemberTitle(e + 1)} · ${m.sections[m.elements[e].section].name}',
                'My ${f(env.mySagging, 0)}/−${f(env.myHogging, 0)} · '
                    'Mz ${f(env.mzMax, 0)} · N −${f(env.nCompression, 0)}',
              );
            }(),
        ]),
      if (out.modes.isNotEmpty)
        NoteTable(l.f3dTabModes, [
          for (var k = 0; k < out.modes.length; k++)
            NoteRow(
              l.f3dModeN(k + 1),
              'T ${f(out.modes[k].period, 3)} s · '
              'X ${f(out.modes[k].massRatio[0] * 100, 1)} % · '
              'Y ${f(out.modes[k].massRatio[1] * 100, 1)} %',
            ),
        ]),
      if (out.alphaCr != null)
        NoteBanner(
          l.f3dAlphaCr(f(out.alphaCr!, 2)),
          message: out.alphaCr! >= 10
              ? l.f3dAlphaFirstOrder
              : (out.alphaCr! >= 3 ? l.f3dAlphaSecondOrder : l.f3dAlphaTooLow),
          ok: out.alphaCr! >= 10 ? true : (out.alphaCr! >= 3 ? null : false),
        ),
      if (seismic != null)
        for (final run in seismic.runs)
          NoteBanner(
            l.f3dBaseShearDir(
              run.direction == 0 ? 'X' : 'Y',
              f(run.baseShear, 0),
            ),
            message: l.f3dSpectrumMass(f(run.massRatio * 100, 1)),
            ok: run.enoughModes,
          ),
      NoteText([l.f3dModelNote]),
    ],
  );
}

/// Note of a 2D frame: model, combinations and ULS envelope per member.
CalcNote frame2dNote(
  BuildContext context, {
  required String name,
  required Model2D model,
  required FrameAnalysisOutput out,
  NoteImage? view,
}) {
  final l = context.l10n;
  String f(double v, [int? dp]) => fmt(context, v, dp);
  double hi(List<(double, double)> v) => v.map((p) => p.$2).reduce(math.max);
  double lo(List<(double, double)> v) => v.map((p) => p.$1).reduce(math.min);
  return CalcNote(
    title: name,
    subtitle: l.modFrame2d,
    date: DateTime.now(),
    inputs: [
      NoteSection(l.f3dTabModel, [
        NoteRow(
          l.f3dNodesMembers,
          '${model.nodes.length} / ${model.elements.length}',
        ),
      ]),
      NoteSection(l.f3dSections, [
        for (final s in model.sections)
          NoteRow(
            s.name,
            'A ${f(s.area * 1e4, 1)} cm² · I ${f(s.inertia * 1e8, 0)} cm⁴',
          ),
      ]),
      NoteSection(l.f3dLoadCase, [
        for (final c in model.cases)
          NoteRow(
            c.name,
            [
              _type(l, c.type),
              if (c.selfWeight) l.noteSelfWeight,
              l.noteLoadCount(
                c.nodal.length + c.distributed.length + c.point.length,
              ),
            ].join(' · '),
          ),
      ]),
    ],
    results: [
      ?view,
      NoteTable(l.noteCombinations, [
        for (final c in out.combinations)
          NoteRow(
            c.name,
            c.factors.entries
                .map((e) => '${f(e.value, 2)}·${model.cases[e.key].name}')
                .join(' + '),
          ),
      ]),
      if (out.envelopeM.isNotEmpty)
        NoteTable(l.noteEnvelope, [
          for (var e = 0; e < model.elements.length; e++)
            NoteRow(
              '${l.frameMemberTitle(e + 1)} · ${model.sections[model.elements[e].section].name}',
              'M ${f(hi(out.envelopeM[e]), 0)}/${f(lo(out.envelopeM[e]), 0)} · '
                  'V ${f(math.max(hi(out.envelopeV[e]).abs(), lo(out.envelopeV[e]).abs()), 0)} · '
                  'N ${f(lo(out.envelopeN[e]), 0)}/${f(hi(out.envelopeN[e]), 0)}',
            ),
        ]),
    ],
  );
}
