import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/note/calc_note.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot/features/calculations/shared/note_extract.dart';
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

  /// Runs the calculation; a returned future shows a spinner until done.
  final FutureOr<void> Function()? onCalculate;
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
  final List<GlobalKey> _keys = [];
  bool _exporting = false;
  bool _running = false;

  Future<void> _calculate() async {
    final f = widget.onCalculate;
    if (f == null || _running) return;
    setState(() => _running = true);
    try {
      await f();
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  List<GlobalKey> _keysFor(int n) {
    while (_keys.length < n) {
      _keys.add(GlobalKey());
    }
    return _keys;
  }

  String? _projectName() {
    try {
      final id = GoRouterState.of(context).pathParameters['projectId'];
      if (id == null) return null;
      final p = HiveService.getBox(HiveService.projectsBox).get(id);
      return p is Project ? p.name : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _export() async {
    final results = widget.results;
    if (results == null || _exporting) return;
    setState(() => _exporting = true);
    final l = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final note = await collectNote(
        context,
        title: widget.title,
        subtitle: widget.subtitle,
        project: _projectName(),
        inputs: widget.inputs,
        results: results,
        keys: _keysFor(results.length),
      );
      if (!mounted) return;
      final bytes = await renderNote(
        note,
        noteLabels(l),
        dateText: DateFormat.yMMMd(
          context.localeName,
        ).add_Hm().format(note.date),
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Sibot - ${widget.title}.pdf',
      );
    } catch (e, st) {
      LoggerService.e('Calculation note failed: $e', e, st);
      messenger?.showSnackBar(SnackBar(content: Text(l.noteFailed)));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

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
          onPressed: widget.isLoading || _running || widget.onCalculate == null
              ? null
              : _calculate,
          icon: widget.isLoading || _running
              ? SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.colors.onPrimary,
                  ),
                )
              : const Icon(Icons.play_arrow_rounded),
          label: Text(
            widget.isLoading || _running ? l.calcCalculating : l.calcCalculate,
          ),
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
            RepaintBoundary(
              key: _keysFor(widget.results!.length)[i],
              child: widget.results![i],
            ),
          ],
        if (widget.results != null) ...[
          const SizedBox(height: Gap.md),
          OutlinedButton.icon(
            onPressed: _exporting ? null : _export,
            icon: _exporting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            label: Text(l.noteExport),
          ),
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
