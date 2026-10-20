import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sibot/features/calculations/shared/design_form.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// Formats an engineering value in the app locale with sensible digits.
String fmt(BuildContext context, double v, [int? digits]) {
  if (v.isNaN || v.isInfinite) return '—';
  final a = v.abs();
  final dp =
      digits ??
      (a >= 100
          ? 0
          : a >= 10
          ? 1
          : a >= 1
          ? 2
          : 3);
  return NumberFormat.decimalPatternDigits(
    locale: context.localeName,
    decimalDigits: dp,
  ).format(v);
}

String checkLabel(AppLocalizations l, CheckKind k) => switch (k) {
  CheckKind.bendingSteel => l.checkBendingSteel,
  CheckKind.minSteel => l.checkMinSteel,
  CheckKind.maxSteel => l.checkMaxSteel,
  CheckKind.barSpacing => l.checkBarSpacing,
  CheckKind.shearCrushing => l.checkShearConcrete,
  CheckKind.shearLinks => l.checkShearLinks,
  CheckKind.linkSpacing => l.checkLinkSpacing,
  CheckKind.deflection => l.checkDeflection,
  CheckKind.slenderness => l.checkSlenderness,
  CheckKind.axialBending => l.checkAxialBending,
  CheckKind.bearingPressure => l.checkBearing,
  CheckKind.punching => l.checkPunching,
  CheckKind.overturning => l.checkOverturning,
  CheckKind.sliding => l.checkSliding,
  CheckKind.baseEccentricity => l.checkEccentricity,
};

/// Message for an input problem, using the page's field labels.
String problemMessage(
  AppLocalizations l,
  FormProblem p,
  Map<String, String> labels,
) {
  final field = labels[p.field] ?? p.field;
  return switch (p.problem) {
    null => l.problemMissing(field),
    InputProblem.notPositive => l.problemNotPositive(field),
    InputProblem.outOfRange => l.problemOutOfRange(field),
    InputProblem.inconsistentGeometry => l.problemGeometry(field),
  };
}

/// Overall verdict above the results.
class VerdictBanner extends StatelessWidget {
  final List<Check> checks;
  const VerdictBanner({super.key, required this.checks});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final failing = checks.where((c) => !c.ok).length;
    final worst = checks.isEmpty
        ? 0.0
        : checks.map((c) => c.ratio).reduce(math.max);
    return StatusBanner(
      tone: failing == 0 ? Tone.success : Tone.danger,
      title: failing == 0 ? l.verdictOk : l.verdictFail(failing),
      message: l.verdictUtilisation(
        worst.isFinite ? fmt(context, worst * 100, 0) : '∞',
      ),
    );
  }
}

/// Card listing every check with its utilisation bar, RSA style.
class ChecksCard extends StatelessWidget {
  final List<Check> checks;
  const ChecksCard({super.key, required this.checks});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.fact_check_outlined,
                size: 18,
                color: context.colors.primary,
              ),
              const SizedBox(width: Gap.sm),
              Text(l.checksTitle, style: context.text.titleMedium),
            ],
          ),
          const SizedBox(height: Gap.sm),
          for (var i = 0; i < checks.length; i++) ...[
            if (i > 0) const Divider(),
            _CheckRow(check: checks[i]),
          ],
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final Check check;
  const _CheckRow({required this.check});

  @override
  Widget build(BuildContext context) {
    final c = check;
    final ratio = c.ratio;
    final color = !c.ok
        ? context.appColors.danger
        : ratio > 0.9
        ? context.appColors.warning
        : context.appColors.success;
    final unit = c.unit.isEmpty ? '' : ' ${c.unit}';
    final relation = c.ok ? '≤' : '>';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checkLabel(context.l10n, c.kind),
                      style: context.text.bodyMedium,
                    ),
                    Text(c.clause, style: context.text.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: Gap.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    ratio.isFinite ? fmt(context, ratio, 2) : '∞',
                    style: AppTheme.mono(
                      context,
                      size: 15,
                      color: color,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${fmt(context, c.demand)} $relation '
                    '${fmt(context, c.capacity)}$unit',
                    style: AppTheme.mono(
                      context,
                      size: 11.5,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio.isFinite ? ratio.clamp(0.0, 1.0) : 1,
              minHeight: 5,
              color: color,
              backgroundColor: context.colors.surfaceContainerHigh,
            ),
          ),
        ],
      ),
    );
  }
}

/// Plain informational notes under the results.
class NotesCard extends StatelessWidget {
  final List<String> notes;
  const NotesCard({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final n in notes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: context.colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: Gap.sm),
                  Expanded(child: Text(n, style: context.text.bodySmall)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Code selector shared by every module.
class CodeChoice extends StatelessWidget {
  final DesignCode value;
  final ValueChanged<DesignCode> onChanged;

  const CodeChoice({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ChoiceField<DesignCode>(
      label: l.footingCode,
      value: value,
      options: {DesignCode.ec2: 'Eurocode 2', DesignCode.bael: 'BAEL 91/99'},
      onChanged: onChanged,
    );
  }
}

/// Number field bound to a [DesignFormNotifier] key.
class FormNumber extends StatelessWidget {
  final DesignFormState<Object?> state;
  final DesignFormNotifier<Object?> notifier;
  final String field;
  final String label;
  final String? unit;
  final String? hint;

  const FormNumber({
    super.key,
    required this.state,
    required this.notifier,
    required this.field,
    required this.label,
    this.unit,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return NumberField(
      label: label,
      unit: unit,
      hint: hint,
      value: state[field],
      onChanged: (v) => notifier.set(field, v),
    );
  }
}
