import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sibot/config/theme.dart';
import 'package:sibot/ui/tokens.dart';

/// Standard page: pinned app bar whose title fades in on scroll, a large
/// header, and a centred content column that is capped on tablets.
class AppPage extends StatefulWidget {
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? headerTrailing;
  final List<Widget> children;
  final Widget? floatingActionButton;
  final double maxWidth;

  /// Replaces the default header (eyebrow/title/subtitle).
  final Widget? header;

  const AppPage({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.actions = const [],
    this.headerTrailing,
    this.children = const [],
    this.floatingActionButton,
    this.maxWidth = Breakpoints.contentMax,
    this.header,
  });

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  bool _collapsed = false;

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    final collapsed = n.metrics.pixels > 36;
    if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      floatingActionButton: widget.floatingActionButton,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final side = math.max(
            pageGutter(constraints.maxWidth),
            (constraints.maxWidth - widget.maxWidth) / 2,
          );

          return NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  titleSpacing: Navigator.of(context).canPop() ? 0 : side,
                  title: AnimatedOpacity(
                    opacity: _collapsed ? 1 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: Text(widget.title),
                  ),
                  actions: [
                    ...widget.actions,
                    SizedBox(width: math.max(Gap.sm, side - Gap.md)),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: AnimatedOpacity(
                      opacity: _collapsed ? 1 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: const Divider(),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(side, Gap.xs, side, Gap.xl),
                  sliver: SliverToBoxAdapter(
                    child:
                        widget.header ??
                        PageHeader(
                          title: widget.title,
                          eyebrow: widget.eyebrow,
                          subtitle: widget.subtitle,
                          trailing: widget.headerTrailing,
                        ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    side,
                    0,
                    side,
                    Gap.xxxl + bottomInset + 56,
                  ),
                  sliver: SliverList.list(children: widget.children),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? trailing;

  const PageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final big = !context.isCompact;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.primary,
                  ),
                ),
                const SizedBox(height: Gap.sm),
              ],
              Text(
                title,
                style: big
                    ? context.text.displaySmall
                    : context.text.headlineLarge,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: Gap.sm),
                Text(
                  subtitle!,
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: Gap.lg), trailing!],
      ],
    );
  }
}
