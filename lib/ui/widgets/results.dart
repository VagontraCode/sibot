import 'package:flutter/material.dart';
import 'package:sibot/config/theme.dart';
import 'package:sibot/ui/tokens.dart';
import 'package:sibot/ui/widgets/surfaces.dart';

/// One result line: label (+ optional symbol) on the left, value + unit on
/// the right in monospaced figures.
class ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final String? symbol;
  final bool emphasize;

  const ResultRow({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.symbol,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final muted = context.colors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: label),
                  if (symbol != null)
                    TextSpan(
                      text: '  $symbol',
                      style: TextStyle(
                        color: muted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
              style: context.text.bodyMedium?.copyWith(
                color: emphasize ? null : muted,
              ),
            ),
          ),
          const SizedBox(width: Gap.md),
          Text(
            value,
            style: AppTheme.mono(
              context,
              size: emphasize ? 17 : 15,
            ).copyWith(fontWeight: emphasize ? FontWeight.w600 : null),
          ),
          if (unit != null) ...[
            const SizedBox(width: 6),
            Text(unit!, style: context.text.bodySmall),
          ],
        ],
      ),
    );
  }
}

class ResultCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> rows;

  const ResultCard({
    super.key,
    required this.title,
    required this.rows,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: context.colors.primary),
                const SizedBox(width: Gap.sm),
              ],
              Text(title, style: context.text.titleMedium),
            ],
          ),
          const SizedBox(height: Gap.sm),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// Coloured banner for a verdict (safe / review / unsafe) or an error.
class StatusBanner extends StatelessWidget {
  final Tone tone;
  final String title;
  final String? message;
  final IconData? icon;

  const StatusBanner({
    super.key,
    required this.tone,
    required this.title,
    this.message,
    this.icon,
  });

  IconData get _icon =>
      icon ??
      switch (tone) {
        Tone.success => Icons.check_circle_rounded,
        Tone.warning => Icons.error_rounded,
        Tone.danger => Icons.cancel_rounded,
        _ => Icons.info_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final fg = tone.fg(context);
    return Container(
      padding: const EdgeInsets.all(Gap.lg),
      decoration: BoxDecoration(
        color: tone.bg(context),
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: fg, size: 22),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.text.titleMedium?.copyWith(color: fg),
                ),
                if (message != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    message!,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown on every module whose calculations haven't passed verification.
class BetaNotice extends StatelessWidget {
  const BetaNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return const StatusBanner(
      tone: Tone.warning,
      icon: Icons.science_outlined,
      title: 'Beta: results not yet verified',
      message:
          'This module is being rewritten and checked against worked examples. '
          'Do not use these results for construction.',
    );
  }
}

/// Placeholder in the results pane before the first calculation.
class ResultsPlaceholder extends StatelessWidget {
  final String message;
  const ResultsPlaceholder({
    super.key,
    this.message = 'Fill in the parameters and tap Calculate.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Gap.xl,
        vertical: Gap.xxxl,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: context.colors.outline),
        color: context.colors.surfaceContainerLow,
      ),
      child: Column(
        children: [
          Icon(
            Icons.query_stats_rounded,
            size: 32,
            color: context.colors.onSurfaceVariant,
          ),
          const SizedBox(height: Gap.md),
          Text('Results', style: context.text.titleMedium),
          const SizedBox(height: Gap.xs),
          Text(
            message,
            style: context.text.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
