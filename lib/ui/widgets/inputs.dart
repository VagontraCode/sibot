import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sibot/config/theme.dart';
import 'package:sibot/ui/tokens.dart';
import 'package:sibot/ui/widgets/surfaces.dart';

/// Parses a number typed with either a dot or a comma as decimal separator.
double? parseNumber(String text) {
  final t = text.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

String formatInput(double? v) {
  if (v == null) return '';
  return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

/// Numeric input with a unit suffix. Owns its controller so typing never
/// loses the cursor, and accepts "2,5" as well as "2.5".
class NumberField extends StatefulWidget {
  final String label;
  final String? unit;
  final String? hint;
  final String? helper;
  final double? value;
  final ValueChanged<double?> onChanged;
  final bool allowNegative;
  final TextInputAction textInputAction;

  const NumberField({
    super.key,
    required this.label,
    required this.onChanged,
    this.unit,
    this.hint,
    this.helper,
    this.value,
    this.allowNegative = false,
    this.textInputAction = TextInputAction.next,
  });

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  late final TextEditingController _ctrl = TextEditingController(
    text: formatInput(widget.value),
  );
  final FocusNode _focus = FocusNode();

  @override
  void didUpdateWidget(NumberField old) {
    super.didUpdateWidget(old);
    // Sync only when the value changes from outside (e.g. a preset), never
    // while the user is typing.
    if (!_focus.hasFocus &&
        old.value != widget.value &&
        widget.value != parseNumber(_ctrl.text)) {
      _ctrl.text = formatInput(widget.value);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Label sits above the field (up to two lines) so long labels, e.g. in
    // French, are never truncated in half-width fields.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.text.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        _field(context),
      ],
    );
  }

  Widget _field(BuildContext context) {
    return TextField(
      controller: _ctrl,
      focusNode: _focus,
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: widget.allowNegative,
      ),
      textInputAction: widget.textInputAction,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(widget.allowNegative ? r'[0-9.,\-]' : r'[0-9.,]'),
        ),
      ],
      style: AppTheme.mono(context, size: 15),
      decoration: InputDecoration(
        hintText: widget.hint,
        helperText: widget.helper,
        suffixText: widget.unit,
      ),
      onChanged: (t) => widget.onChanged(parseNumber(t)),
    );
  }
}

/// Card grouping related inputs under a title.
class FormSection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;

  const FormSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.lg),
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
          const SizedBox(height: Gap.lg),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: Gap.md),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Fields side by side, bottom-aligned so inputs line up even when one
/// label wraps onto two lines.
class FieldRow extends StatelessWidget {
  final List<Widget> children;
  const FieldRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: Gap.md),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

/// Labelled segmented choice.
class ChoiceField<T> extends StatelessWidget {
  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  const ChoiceField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: context.text.labelMedium),
        const SizedBox(height: Gap.sm),
        SegmentedButton<T>(
          showSelectedIcon: false,
          segments: [
            for (final e in options.entries)
              ButtonSegment(value: e.key, label: Text(e.value)),
          ],
          selected: {value},
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      ],
    );
  }
}
