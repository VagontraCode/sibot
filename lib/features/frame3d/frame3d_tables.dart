import 'package:flutter/material.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/exchange/exchange.dart';
import 'package:sibot/features/frame3d/frame3d_data.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';

enum _Table { reactions, displacements, members }

/// Tables of reactions, displacements and member forces for any
/// combination or load case, with CSV export.
class Frame3DTablesPage extends StatefulWidget {
  final String modelName;
  final Frame3DOutput out;
  const Frame3DTablesPage({
    super.key,
    required this.modelName,
    required this.out,
  });

  @override
  State<Frame3DTablesPage> createState() => _Frame3DTablesPageState();
}

class _Frame3DTablesPageState extends State<Frame3DTablesPage> {
  _Table _table = _Table.reactions;

  /// Combination index, or −1 − case index for a load case.
  int _source = 0;

  /// Rows shown on screen (the CSV holds them all).
  static const _shown = 300;

  Frame3DResult get _result {
    final o = widget.out;
    if (_source >= 0) return o.results[_source];
    return o.caseResults[-1 - _source];
  }

  String get _sourceName {
    final o = widget.out;
    return _source >= 0
        ? o.combinations[_source].name
        : o.model.cases[-1 - _source].name;
  }

  ResultTable get _data => switch (_table) {
    _Table.reactions => reactionsTable(widget.out.model, _result),
    _Table.displacements => displacementsTable(widget.out.model, _result),
    _Table.members => memberForcesTable(widget.out.model, _result),
  };

  Future<void> _export() async {
    final l = context.l10n;
    final kind = switch (_table) {
      _Table.reactions => 'reactions',
      _Table.displacements => 'displacements',
      _Table.members => 'members',
    };
    final first = _table == _Table.members ? l.tablesMember : l.tablesNode;
    try {
      await shareTextFile(
        '${widget.modelName} - $kind - $_sourceName.csv',
        _data.toCsv(first: first),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.exchangeExportFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final o = widget.out;
    final t = _data;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.tablesTitle),
        actions: [
          IconButton(
            tooltip: l.tablesExport,
            onPressed: _export,
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Gap.lg),
        children: [
          PickerField<int>(
            label: l.tablesSource,
            value: _source,
            options: {
              for (var i = 0; i < o.combinations.length; i++)
                i: o.combinations[i].name,
              for (var c = 0; c < o.model.cases.length; c++)
                -1 - c: '${l.f3dLoadCase}: ${o.model.cases[c].name}',
            },
            onChanged: (v) => setState(() => _source = v),
          ),
          const SizedBox(height: Gap.md),
          SegmentedButton<_Table>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: _Table.reactions,
                label: Text(l.tablesReactions),
              ),
              ButtonSegment(
                value: _Table.displacements,
                label: Text(l.tablesDisplacements),
              ),
              ButtonSegment(value: _Table.members, label: Text(l.tablesForces)),
            ],
            selected: {_table},
            onSelectionChanged: (s) => setState(() => _table = s.first),
          ),
          const SizedBox(height: Gap.md),
          if (t.length > _shown)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.sm),
              child: Text(
                l.tablesTruncated(_shown, t.length),
                style: context.text.bodySmall,
              ),
            ),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 36,
                columnSpacing: 18,
                columns: [
                  DataColumn(
                    label: Text(
                      _table == _Table.members ? l.tablesMember : l.tablesNode,
                    ),
                  ),
                  for (final c in t.columns)
                    DataColumn(label: Text(c), numeric: true),
                ],
                rows: [
                  for (var i = 0; i < t.length && i < _shown; i++)
                    DataRow(
                      cells: [
                        DataCell(Text(t.labels[i])),
                        for (final v in t.rows[i])
                          DataCell(
                            Text(
                              fmt(context, v, 2),
                              style: AppTheme.mono(context, size: 13),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Gap.md),
          Text(l.tablesNote, style: context.text.bodySmall),
        ],
      ),
    );
  }
}
