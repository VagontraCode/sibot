import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sibot/core/services/advance_analysis.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';

class ReferencePage extends StatelessWidget {
  const ReferencePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppPage(
      title: l.navLibrary,
      subtitle: l.librarySubtitle,
      children: [
        SectionHeader(title: l.libraryConverter),
        const _UnitConverter(),
        SectionHeader(title: l.libraryMaterials),
        const AdaptiveSplit(
          primaryFlex: 1,
          secondaryFlex: 1,
          breakpoint: 760,
          primary: _ConcreteTable(),
          secondary: _SteelTable(),
        ),
        const SizedBox(height: Gap.md),
        const _RebarTable(),
        SectionHeader(title: l.libraryCodes, subtitle: l.libraryCodesSubtitle),
        ResponsiveGrid(
          minTileWidth: 240,
          children: [
            for (final c in _codes(l))
              SurfaceCard(
                child: Row(
                  children: [
                    IconBadge(c.$3, tone: Tone.neutral, size: 38),
                    const SizedBox(width: Gap.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.$1, style: context.text.titleSmall),
                          Text(c.$2, style: context.text.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

List<(String, String, IconData)> _codes(AppLocalizations l) => [
  ('EN 1990 · EC0', l.codeEc0, Icons.rule_rounded),
  ('EN 1991 · EC1', l.codeEc1, Icons.air_rounded),
  ('EN 1992 · EC2', l.codeEc2, Icons.view_in_ar_outlined),
  ('EN 1993 · EC3', l.codeEc3, Icons.horizontal_split_outlined),
  ('EN 1995 · EC5', l.codeEc5, Icons.forest_outlined),
  ('EN 1996 · EC6', l.codeEc6, Icons.grid_view_outlined),
  ('EN 1997 · EC7', l.codeEc7, Icons.terrain_outlined),
  ('EN 1998 · EC8', l.codeEc8, Icons.waves_outlined),
  ('BAEL 91 rév. 99', l.codeBaelDesc, Icons.view_in_ar_outlined),
  ('PS 92', l.codePs92Desc, Icons.waves_outlined),
];

/// Simple table inside a card.
class _DataTableCard extends StatelessWidget {
  final String title;
  final String? source;
  final List<String> header;
  final List<List<String>> rows;

  const _DataTableCard({
    required this.title,
    required this.header,
    required this.rows,
    this.source,
  });

  @override
  Widget build(BuildContext context) {
    Widget cell(String t, {bool head = false, bool first = false}) => Expanded(
      child: Text(
        t,
        textAlign: first ? TextAlign.left : TextAlign.right,
        style: head
            ? context.text.labelSmall
            : first
            ? context.text.titleSmall
            : AppTheme.mono(context, size: 13.5),
      ),
    );

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: context.text.titleMedium),
          if (source != null) Text(source!, style: context.text.bodySmall),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              for (var i = 0; i < header.length; i++)
                cell(header[i].toUpperCase(), head: true, first: i == 0),
            ],
          ),
          const SizedBox(height: Gap.sm),
          for (final r in rows) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  for (var i = 0; i < r.length; i++) cell(r[i], first: i == 0),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConcreteTable extends StatelessWidget {
  const _ConcreteTable();

  @override
  Widget build(BuildContext context) {
    // EN 1992-1-1 Table 3.1
    final l = context.l10n;
    return _DataTableCard(
      title: l.libraryConcrete,
      source: l.libraryTable('EN 1992-1-1', '3.1'),
      header: [l.libraryColClass, 'fck MPa', 'fctm MPa', 'Ecm GPa'],
      rows: const [
        ['C20/25', '20', '2.2', '30'],
        ['C25/30', '25', '2.6', '31'],
        ['C30/37', '30', '2.9', '33'],
        ['C35/45', '35', '3.2', '34'],
        ['C40/50', '40', '3.5', '35'],
      ],
    );
  }
}

class _SteelTable extends StatelessWidget {
  const _SteelTable();

  @override
  Widget build(BuildContext context) {
    // EN 1993-1-1 Table 3.1, t ≤ 40 mm
    final l = context.l10n;
    return _DataTableCard(
      title: l.librarySteel,
      source: '${l.libraryTable('EN 1993-1-1', '3.1')} (t ≤ 40 mm)',
      header: [l.libraryColGrade, 'fy MPa', 'fu MPa'],
      rows: const [
        ['S235', '235', '360'],
        ['S275', '275', '430'],
        ['S355', '355', '490'],
        ['S450', '440', '550'],
      ],
    );
  }
}

class _RebarTable extends StatelessWidget {
  const _RebarTable();

  @override
  Widget build(BuildContext context) {
    const diameters = [6, 8, 10, 12, 14, 16, 20, 25, 32];
    final l = context.l10n;
    return _DataTableCard(
      title: l.libraryRebar,
      source: l.libraryRebarSource,
      header: ['Ø mm', l.libraryColArea, l.libraryColMass],
      rows: [
        for (final d in diameters)
          [
            '$d',
            (math.pi * d * d / 4).toStringAsFixed(1),
            (math.pi * d * d / 4 * 7850e-6).toStringAsFixed(3),
          ],
      ],
    );
  }
}

enum _Qty {
  length(['mm', 'cm', 'm', 'km', 'in', 'ft']),
  force(['N', 'kN', 'kgf', 'tonf', 'lbf']),
  pressure(['kPa', 'MPa', 'bar', 'atm']);

  String label(AppLocalizations l) => switch (this) {
    _Qty.length => l.libraryLength,
    _Qty.force => l.libraryForce,
    _Qty.pressure => l.libraryPressure,
  };

  final List<String> units;
  const _Qty(this.units);

  double convert(double v, String from, String to) => switch (this) {
    _Qty.length => UnitConverter.convertLength(v, from, to),
    _Qty.force => UnitConverter.convertForce(v, from, to),
    _Qty.pressure => UnitConverter.convertPressure(v, from, to),
  };
}

class _UnitConverter extends StatefulWidget {
  const _UnitConverter();

  @override
  State<_UnitConverter> createState() => _UnitConverterState();
}

class _UnitConverterState extends State<_UnitConverter> {
  _Qty _qty = _Qty.force;
  late String _from = _qty.units[1];
  late String _to = _qty.units[2];
  double? _value = 1;

  String _format(double v) {
    if (v == 0) return '0';
    final a = v.abs();
    if (a >= 1e6 || a < 1e-3) return v.toStringAsExponential(4);
    return v
        .toStringAsFixed(6)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  Widget _unitMenu(String value, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      key: ValueKey('${_qty.name}-$value'),
      decoration: const InputDecoration(),
      items: [
        for (final u in _qty.units) DropdownMenuItem(value: u, child: Text(u)),
      ],
      onChanged: (u) => onChanged(u!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _value == null ? null : _qty.convert(_value!, _from, _to);

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<_Qty>(
            showSelectedIcon: false,
            segments: [
              for (final q in _Qty.values)
                ButtonSegment(value: q, label: Text(q.label(context.l10n))),
            ],
            selected: {_qty},
            onSelectionChanged: (s) => setState(() {
              _qty = s.first;
              _from = _qty.units[1];
              _to = _qty.units[2];
            }),
          ),
          const SizedBox(height: Gap.lg),
          FieldRow(
            children: [
              NumberField(
                label: context.l10n.libraryValue,
                value: _value,
                allowNegative: true,
                onChanged: (v) => setState(() => _value = v),
              ),
              _unitMenu(_from, (u) => setState(() => _from = u)),
            ],
          ),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 54,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: SelectableText(
                    result == null ? '—' : _format(result),
                    style: AppTheme.mono(
                      context,
                      size: 17,
                      color: context.colors.onPrimaryContainer,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(child: _unitMenu(_to, (u) => setState(() => _to = u))),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() {
                final t = _from;
                _from = _to;
                _to = t;
              }),
              icon: const Icon(Icons.swap_vert_rounded, size: 18),
              label: Text(context.l10n.librarySwap),
            ),
          ),
        ],
      ),
    );
  }
}
