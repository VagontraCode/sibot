import 'package:flutter/material.dart';
import 'package:sibot/config/theme.dart';
import 'package:sibot/ui/tokens.dart';

enum Tone { neutral, primary, success, warning, danger }

extension ToneColors on Tone {
  Color fg(BuildContext context) => switch (this) {
    Tone.neutral => context.colors.onSurfaceVariant,
    Tone.primary => context.colors.primary,
    Tone.success => context.appColors.success,
    Tone.warning => context.appColors.warning,
    Tone.danger => context.appColors.danger,
  };

  Color bg(BuildContext context) => switch (this) {
    Tone.neutral => context.colors.surfaceContainerHigh,
    Tone.primary => context.colors.primaryContainer,
    Tone.success => context.appColors.successContainer,
    Tone.warning => context.appColors.warningContainer,
    Tone.danger => context.appColors.dangerContainer,
  };
}

/// Bordered surface card with optional tap.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Gap.lg),
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Gap.xl, bottom: Gap.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: context.text.bodySmall),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Tone tone;
  final IconData? icon;

  const StatusPill(
    this.label, {
    super.key,
    this.tone = Tone.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fg = tone.fg(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.bg(context),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: context.text.labelSmall?.copyWith(
              color: fg,
              fontSize: 10,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded square holding an icon, tinted by tone.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Tone tone;
  final double size;

  const IconBadge(
    this.icon, {
    super.key,
    this.tone = Tone.primary,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.bg(context),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, size: size * 0.5, color: tone.fg(context)),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: context.colors.onSurfaceVariant),
              const Spacer(),
              if (onTap != null)
                Icon(
                  Icons.arrow_outward,
                  size: 16,
                  color: context.colors.onSurfaceVariant,
                ),
            ],
          ),
          const SizedBox(height: Gap.lg),
          Text(
            value,
            style: AppTheme.mono(
              context,
              size: 26,
            ).copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.5),
          ),
          const SizedBox(height: 2),
          Text(label, style: context.text.bodySmall),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(
        horizontal: Gap.xl,
        vertical: Gap.xxl,
      ),
      child: Column(
        children: [
          IconBadge(icon, tone: Tone.neutral, size: 52),
          const SizedBox(height: Gap.lg),
          Text(
            title,
            style: context.text.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            const SizedBox(height: Gap.xs),
            Text(
              message!,
              style: context.text.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[const SizedBox(height: Gap.xl), action!],
        ],
      ),
    );
  }
}

/// Lays out tiles in a responsive grid without lazy building (for short lists).
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minTileWidth;
  final double spacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 160,
    this.spacing = Gap.md,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = ((c.maxWidth + spacing) / (minTileWidth + spacing))
            .floor()
            .clamp(1, children.isEmpty ? 1 : children.length.clamp(1, 6));
        final w = (c.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: w, child: child),
          ],
        );
      },
    );
  }
}

/// Two panes side by side on wide screens, stacked on narrow ones.
class AdaptiveSplit extends StatelessWidget {
  final Widget primary;
  final Widget secondary;
  final int primaryFlex;
  final int secondaryFlex;
  final double breakpoint;

  const AdaptiveSplit({
    super.key,
    required this.primary,
    required this.secondary,
    this.primaryFlex = 5,
    this.secondaryFlex = 6,
    this.breakpoint = 820,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              primary,
              const SizedBox(height: Gap.xl),
              secondary,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: primaryFlex, child: primary),
            const SizedBox(width: Gap.xl),
            Expanded(flex: secondaryFlex, child: secondary),
          ],
        );
      },
    );
  }
}

/// Initials avatar with a stable colour derived from the name.
class ProjectAvatar extends StatelessWidget {
  final String name;
  final double size;

  const ProjectAvatar(this.name, {super.key, this.size = 44});

  static const _hues = [222.0, 262.0, 190.0, 152.0, 28.0, 340.0];

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final initials = parts.isEmpty
        ? '?'
        : parts.take(2).map((p) => p[0].toUpperCase()).join();
    final hue = _hues[trimmed.hashCode.abs() % _hues.length];
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = HSLColor.fromAHSL(1, hue, 0.7, dark ? 0.22 : 0.93).toColor();
    final fg = HSLColor.fromAHSL(1, hue, 0.65, dark ? 0.78 : 0.38).toColor();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Text(
        initials,
        style: context.text.titleMedium?.copyWith(
          color: fg,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}
