import 'package:flutter/material.dart';
import 'package:sibot/config/theme.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/tokens.dart';
import 'package:sibot/ui/widgets/app_page.dart';
import 'package:sibot/ui/widgets/results.dart';
import 'package:sibot/ui/widgets/surfaces.dart';

/// Layout shared by all design modules: inputs on the left and results on
/// the right on tablets; stacked on phones, scrolling to results after a run.
class CalculatorScaffold extends StatefulWidget {
  final String title;
  final String? subtitle;
  final EngModule? module;
  final List<Widget> inputs;
  final VoidCallback? onCalculate;
  final bool isLoading;
  final String? error;

  /// Result widgets; null until the first calculation.
  final List<Widget>? results;

  /// Changes whenever a new result is produced (e.g. calculation id).
  final Object? resultKey;

  const CalculatorScaffold({
    super.key,
    required this.title,
    required this.inputs,
    required this.onCalculate,
    this.subtitle,
    this.module,
    this.isLoading = false,
    this.error,
    this.results,
    this.resultKey,
  });

  @override
  State<CalculatorScaffold> createState() => _CalculatorScaffoldState();
}

class _CalculatorScaffoldState extends State<CalculatorScaffold> {
  final _resultsAnchor = GlobalKey();

  @override
  void didUpdateWidget(CalculatorScaffold old) {
    super.didUpdateWidget(old);
    final newResult =
        widget.resultKey != null && widget.resultKey != old.resultKey;
    if ((newResult || (widget.error != null && old.error == null)) &&
        context.isCompact) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _resultsAnchor.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: 0.05,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final category = widget.module?.category.label(l);

    final inputs = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.inputs.length; i++) ...[
          if (i > 0) const SizedBox(height: Gap.md),
          widget.inputs[i],
        ],
        const SizedBox(height: Gap.lg),
        FilledButton.icon(
          onPressed: widget.isLoading ? null : widget.onCalculate,
          icon: widget.isLoading
              ? SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.colors.onPrimary,
                  ),
                )
              : const Icon(Icons.play_arrow_rounded),
          label: Text(widget.isLoading ? l.calcCalculating : l.calcCalculate),
        ),
      ],
    );

    final results = Column(
      key: _resultsAnchor,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.error != null) ...[
          StatusBanner(
            tone: Tone.danger,
            title: l.calcCheckInputs,
            message: widget.error,
          ),
          const SizedBox(height: Gap.md),
        ],
        if (widget.results == null)
          const ResultsPlaceholder()
        else
          for (var i = 0; i < widget.results!.length; i++) ...[
            if (i > 0) const SizedBox(height: Gap.md),
            widget.results![i],
          ],
      ],
    );

    return AppPage(
      title: widget.title,
      eyebrow: category,
      subtitle: widget.subtitle,
      children: [
        if (widget.module?.status == ModuleStatus.beta) ...[
          const BetaNotice(),
          const SizedBox(height: Gap.xl),
        ],
        AdaptiveSplit(primary: inputs, secondary: results),
      ],
    );
  }
}
