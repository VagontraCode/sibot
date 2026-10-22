import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibot/features/calculations/beams/presentation/beam_section_provider.dart';
import 'package:sibot/features/calculations/columns/presentation/columns_provider.dart';
import 'package:sibot/features/calculations/footings/presentation/footings_provider.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot/features/calculations/steel/presentation/steel_member_provider.dart';
import 'package:sibot/features/calculations/timber/presentation/timber_member_provider.dart';
import 'package:sibot/features/frame3d/frame3d_data.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// Where a member's forces can be designed in detail.
enum MemberTarget { beamSection, column, steel, timber }

/// The calculator suited to member [e]: from its group when it has one,
/// else from its section and direction. Null when none fits.
MemberTarget? targetFor(
  Model3D m,
  int e,
  MemberEnvelope3D f, {
  DesignGroup? group,
}) {
  final s = m.sections[m.elements[e].section];
  final mat = group?.material ?? sectionMaterial(s);
  switch (mat) {
    case DesignMaterial.steel:
      final p = s.profile == null ? null : steelProfiles[s.profile];
      return p != null && steelDesignable(p) ? MemberTarget.steel : null;
    case DesignMaterial.timber:
      return s.b != null && s.h != null ? MemberTarget.timber : null;
    case DesignMaterial.concrete:
      if (s.b == null || s.h == null) return null;
      final column = switch (group?.role) {
        ConcreteRole.column => true,
        ConcreteRole.beam => false,
        _ => m.kindOf(e) == MemberKind.column,
      };
      return column && f.nCompression > 0
          ? MemberTarget.column
          : MemberTarget.beamSection;
    case null:
      return null;
  }
}

/// The group of member [e], if any (its first group).
DesignGroup? groupOf(Model3D m, int e) =>
    m.groups.where((g) => g.members.contains(e)).firstOrNull;

/// Opens the detailed calculator for member [e] with its envelope forces
/// over [results], linked to the model.
Future<void> designMemberIn(
  BuildContext context, {
  required Frame3DRecord record,
  required Model3D model,
  required int member,
  required List<Frame3DResult> results,
}) async {
  final f = MemberEnvelope3D.of(model, member, results);
  final g = groupOf(model, member);
  final target = targetFor(model, member, f, group: g);
  if (target == null) return;
  final c = ProviderScope.containerOf(context, listen: false);
  final pid = record.projectId;
  final s = model.sections[model.elements[member].section];
  final link = ModelLink(
    modelId: record.id,
    modelName: record.name,
    member: member,
    stamp: modelStamp(sourceKey(record)),
  );
  double r1(double v) => (v * 10).roundToDouble() / 10;
  final String route;
  switch (target) {
    case MemberTarget.beamSection:
      c
          .read(beamSectionStateProvider(pid).notifier)
          .applyLink(
            link,
            code: g?.code,
            values: {
              'b': s.b,
              'h': s.h,
              'mSag': r1(f.mySagging),
              'mHog': r1(f.myHogging),
              'vEd': r1(f.vzMax),
              if (g != null) ...{'cover': g.cover, 'fck': g.fck, 'fyk': g.fyk},
            },
          );
      route = 'beam-section';
    case MemberTarget.column:
      c
          .read(columnStateProvider(pid).notifier)
          .applyLink(
            link,
            code: g?.code,
            values: {
              'b': s.b,
              'h': s.h,
              'l0': r1(f.length * (g?.l0Factor ?? 1) * 100) / 100,
              'nEd': r1(f.nCompression),
              'm0Ed': r1(f.myMax),
              'm0EdB': r1(f.mzMax),
              if (g != null) ...{'cover': g.cover, 'fck': g.fck, 'fyk': g.fyk},
            },
          );
      route = 'column';
    case MemberTarget.steel:
      final name = s.profile!;
      final series = steelSeries.firstWhere(
        (x) => profilesOfSeries(x).contains(name),
        orElse: () => name.split(' ').first,
      );
      c
          .read(steelMemberStateProvider(pid).notifier)
          .applyLink(
            link,
            options: {'series': series, 'profile': name, 'grade': ?g?.grade},
            values: {
              'length': r1(f.length * 100) / 100,
              'nEd': r1(f.nCompression > 0 ? f.nCompression : -f.nTension),
              'myEd': r1(f.myMax),
              'mzEd': r1(f.mzMax),
              'vEd': r1(f.vzMax),
              if (g != null) ...{'ky': g.ky, 'kz': g.kz, 'kLT': g.kLT},
            },
          );
      route = 'steel-member';
    case MemberTarget.timber:
      c
          .read(timberMemberStateProvider(pid).notifier)
          .applyLink(
            link,
            options: {
              if (g != null) ...{
                'class': g.timberClass,
                'duration': g.duration.name,
                'service': '${g.serviceClass}',
              },
            },
            values: {
              'b': math.min(s.b!, s.h!),
              'h': math.max(s.b!, s.h!),
              'length': r1(f.length * 100) / 100,
              'nEd': r1(f.nCompression > 0 ? f.nCompression : -f.nTension),
              'myEd': r1(f.myMax),
              'vEd': r1(f.vzMax),
              if (g != null) ...{'ky': g.ky, 'kz': g.kz, 'kLT': g.kLT},
            },
          );
      route = 'timber-member';
  }
  if (context.mounted) await context.push('/projects/$pid/$route');
}

/// Characteristic loads on support [node] from the load cases: Σ
/// permanent and Σ variable vertical reactions (kN), and the resultant
/// base moments of each (kN·m).
({double g, double q, double mg, double mq}) supportLoads(
  Model3D m,
  List<Frame3DResult> caseResults,
  int node,
) {
  var g = 0.0, q = 0.0, mgx = 0.0, mgy = 0.0, mqx = 0.0, mqy = 0.0;
  for (var c = 0; c < m.cases.length && c < caseResults.length; c++) {
    final r = caseResults[c].reactions[node];
    if (r == null) continue;
    if (m.cases[c].type == LoadType.permanent) {
      g += r[2];
      mgx += r[3];
      mgy += r[4];
    } else if (r[2] > 0) {
      // Only variable actions pressing on the footing.
      q += r[2];
      mqx += r[3];
      mqy += r[4];
    }
  }
  return (
    g: g,
    q: q,
    mg: math.sqrt(mgx * mgx + mgy * mgy),
    mq: math.sqrt(mqx * mqx + mqy * mqy),
  );
}

/// Opens the isolated footing under support [node] with its loads,
/// linked to the model. The column size comes from a member at the node.
Future<void> designSupportIn(
  BuildContext context, {
  required Frame3DRecord record,
  required Model3D model,
  required int node,
  required List<Frame3DResult> caseResults,
}) async {
  final c = ProviderScope.containerOf(context, listen: false);
  final pid = record.projectId;
  final loads = supportLoads(model, caseResults, node);
  Section3D? column;
  for (final e in model.elements) {
    if (e.n1 != node && e.n2 != node) continue;
    final s = model.sections[e.section];
    if (s.b != null && s.h != null) {
      column = s;
      break;
    }
  }
  double r1(double v) => (v * 10).roundToDouble() / 10;
  c
      .read(footingStateProvider(pid).notifier)
      .applyLink(
        ModelLink(
          modelId: record.id,
          modelName: record.name,
          node: node,
          stamp: modelStamp(sourceKey(record)),
        ),
        options: const {'type': 'isolated'},
        values: {
          'a': column?.b ?? 300,
          'b': column?.h ?? 300,
          'g': r1(math.max(loads.g, 0)),
          'q': r1(math.max(loads.q, 0)),
          'mg': r1(loads.mg),
          'mq': r1(loads.mq),
        },
      );
  if (context.mounted) await context.push('/projects/$pid/footing');
}

/// Where the inputs of a calculation came from; warns when the model has
/// changed since.
class ModelLinkBanner extends ConsumerWidget {
  final ModelLink link;
  final String projectId;
  final VoidCallback onUnlink;
  const ModelLinkBanner({
    super.key,
    required this.link,
    required this.projectId,
    required this.onUnlink,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final record = ref.watch(frame3dRecordProvider(link.modelId)).value;
    final changed =
        record == null || modelStamp(sourceKey(record)) != link.stamp;
    final what = link.member != null
        ? l.frameMemberTitle(link.member! + 1)
        : l.linkSupportN(link.node! + 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatusBanner(
          tone: changed ? Tone.warning : Tone.primary,
          title: l.linkFrom(link.modelName, what),
          message: record == null
              ? l.linkModelGone
              : (changed ? l.linkModelChanged : l.linkModelSame),
        ),
        Wrap(
          spacing: Gap.sm,
          children: [
            if (record != null)
              TextButton.icon(
                onPressed: () => context.push(
                  '/projects/$projectId/frame3d/${link.modelId}',
                ),
                icon: const Icon(Icons.view_in_ar_outlined),
                label: Text(l.linkOpenModel),
              ),
            TextButton.icon(
              onPressed: onUnlink,
              icon: const Icon(Icons.link_off_rounded),
              label: Text(l.linkUnlink),
            ),
          ],
        ),
      ],
    );
  }
}
