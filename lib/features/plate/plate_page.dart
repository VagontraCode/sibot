import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/frame3d/frame3d_view.dart' show heat;
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';
import 'package:sibot_engine/sibot_engine.dart';
import 'plate_provider.dart';

/// Quantities shown on the contour map.
enum PlateField { w, mx, my, mxy, asBx, asBy, asTx, asTy, soil }

class PlatePage extends ConsumerWidget {
  final String projectId;
  const PlatePage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(plateStateProvider(projectId));
    final n = ref.read(plateStateProvider(projectId).notifier);
    final l = context.l10n;
    final raft = s.options['mode'] == 'raft';

    final labels = {
      'lx': 'Lx',
      'ly': 'Ly',
      't': l.plateThickness,
      'g': l.plateG,
      'q': l.plateQ,
      'k': l.plateSubgrade,
      'mesh': l.plateMesh,
      'fck': l.calcConcreteFck,
      'fyk': l.calcSteelFyk,
      'cover': l.calcCover,
      'columns': l.plateColumns,
      'points': l.platePointLoads,
      'support': l.plateSupports,
      'nx': l.plateMesh,
      'ny': l.plateMesh,
    };
    Widget field(String key, String unit, {String? hint}) => FormNumber(
      state: s,
      notifier: n,
      field: key,
      label: labels[key]!,
      unit: unit,
      hint: hint,
    );
    Widget edge(String key, String label) => PickerField<String>(
      key: ValueKey('$key-${s.options[key]}'),
      label: label,
      value: s.options[key]!,
      options: {
        EdgeSupport.free.name: l.f3dSupportFree,
        EdgeSupport.simple.name: l.plateSimple,
        EdgeSupport.fixed.name: l.f3dSupportFixed,
      },
      onChanged: (v) => n.setOption(key, v),
    );

    return CalculatorScaffold(
      title: l.modPlate,
      subtitle: l.plateSubtitle,
      module: moduleByRoute('plate'),
      onCalculate: n.calculate,
      error: s.problem == null ? null : problemMessage(l, s.problem!, labels),
      resultKey: s.runId,
      inputs: [
        FormSection(
          title: l.footingDesignBasis,
          icon: Icons.rule_rounded,
          children: [
            CodeChoice(value: s.code, onChanged: n.setCode),
            ChoiceField<String>(
              label: l.plateType,
              value: s.options['mode']!,
              options: {'slab': l.plateSlab, 'raft': l.plateRaft},
              onChanged: n.setMode,
            ),
          ],
        ),
        FormSection(
          title: l.plateGeometry,
          icon: Icons.grid_4x4_rounded,
          children: [
            FieldRow(
              children: [
                field('lx', 'm', hint: '6'),
                field('ly', 'm', hint: '5'),
                field('t', 'mm', hint: '200'),
              ],
            ),
            FieldRow(
              children: [edge('left', 'x = 0'), edge('right', 'x = Lx')],
            ),
            FieldRow(
              children: [edge('bottom', 'y = 0'), edge('top', 'y = Ly')],
            ),
            _TextOption(
              label: l.plateColumns,
              hint: '0.2,0.2  5.8,0.2',
              value: s.options['columns']!,
              onChanged: (v) => n.setOption('columns', v),
            ),
            Text(l.plateColumnsHelp, style: context.text.bodySmall),
          ],
        ),
        FormSection(
          title: l.plateLoads,
          icon: Icons.south_rounded,
          children: [
            FieldRow(children: [field('g', 'kPa'), field('q', 'kPa')]),
            _TextOption(
              label: l.platePointLoads,
              hint: '3,2.5,400',
              value: s.options['points']!,
              onChanged: (v) => n.setOption('points', v),
            ),
            if (raft) field('k', 'kN/m³'),
            Text(
              raft ? l.plateRaftHelp : l.plateLoadsHelp,
              style: context.text.bodySmall,
            ),
          ],
        ),
        FormSection(
          title: l.calcMaterials,
          icon: Icons.science_outlined,
          children: [
            FieldRow(children: [field('fck', 'MPa'), field('fyk', 'MPa')]),
            FieldRow(children: [field('cover', 'mm'), field('mesh', '')]),
          ],
        ),
      ],
      results: s.result == null ? null : _results(context, s.result!),
    );
  }

  List<Widget> _results(BuildContext context, PlateDesign r) {
    final l = context.l10n;
    final raft = r.input.subgrade > 0;
    double max(Float64List v) => v.reduce(math.max);
    double min(Float64List v) => v.reduce(math.min);
    final wMax = max(r.sls.w);
    final span = math.min(r.input.lx, r.input.ly);
    final asMax = [
      max(r.steel.bottomX),
      max(r.steel.bottomY),
      max(r.steel.topX),
      max(r.steel.topY),
    ];
    String bars(double as) {
      final need = math.max(as, r.steel.minimum);
      final b = chooseSpacing(need, math.min(250, 2 * r.input.t));
      return b == null ? '—' : 'Ø${b.diameter} @ ${b.spacing}';
    }

    return [
      ResultCard(
        title: l.plateSummary,
        icon: Icons.insights_rounded,
        rows: [
          ResultRow(
            label: l.plateMaxDeflection,
            symbol: 'w (G + Q)',
            value: fmt(context, wMax * 1000, 1),
            unit: 'mm',
            emphasize: true,
          ),
          if (!raft && wMax > 0)
            ResultRow(
              label: l.plateSpanRatio,
              symbol: 'L / w',
              value: 'L/${(span / wMax).round()}',
            ),
          if (raft)
            ResultRow(
              label: l.plateSoilPressure,
              symbol: 'k · w',
              value: fmt(context, r.input.subgrade * wMax, 0),
              unit: 'kPa',
              emphasize: true,
            ),
          ResultRow(
            label: l.plateMomentsX,
            symbol: 'Mx+ / Mx−',
            value:
                '${fmt(context, max(r.uls.mx))} / ${fmt(context, min(r.uls.mx))}',
            unit: 'kN·m/m',
          ),
          ResultRow(
            label: l.plateMomentsY,
            symbol: 'My+ / My−',
            value:
                '${fmt(context, max(r.uls.my))} / ${fmt(context, min(r.uls.my))}',
            unit: 'kN·m/m',
          ),
          ResultRow(
            label: l.plateTwist,
            symbol: '|Mxy|',
            value: fmt(context, math.max(max(r.uls.mxy), -min(r.uls.mxy))),
            unit: 'kN·m/m',
          ),
          for (final (i, c) in r.uls.columnReactions.indexed)
            ResultRow(
              label: l.plateColumnN(i + 1),
              symbol: 'R ULS',
              value: fmt(context, c, 0),
              unit: 'kN',
            ),
        ],
      ),
      PlateContour(design: r),
      ResultCard(
        title: l.plateReinforcement,
        icon: Icons.grid_on_rounded,
        rows: [
          for (final (i, label) in [
            l.plateBottomX,
            l.plateBottomY,
            l.plateTopX,
            l.plateTopY,
          ].indexed)
            ResultRow(
              label: label,
              symbol: '${fmt(context, asMax[i], 0)} mm²/m',
              value: bars(asMax[i]),
              emphasize: true,
            ),
          ResultRow(
            label: l.plateMinimum,
            symbol: 'As,min',
            value: fmt(context, r.steel.minimum, 0),
            unit: 'mm²/m',
          ),
        ],
      ),
      NotesCard(notes: [l.plateNoteScope]),
    ];
  }
}

class _TextOption extends StatefulWidget {
  final String label;
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;
  const _TextOption({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_TextOption> createState() => _TextOptionState();
}

class _TextOptionState extends State<_TextOption> {
  late final _c = TextEditingController(text: widget.value);
  final _focus = FocusNode();

  @override
  void didUpdateWidget(_TextOption old) {
    super.didUpdateWidget(old);
    // Follow external changes, never while the user is typing.
    if (!_focus.hasFocus && widget.value != _c.text) _c.text = widget.value;
  }

  @override
  void dispose() {
    _focus.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: context.text.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _c,
          focusNode: _focus,
          style: AppTheme.mono(context, size: 14),
          decoration: InputDecoration(hintText: widget.hint),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}

/// Coloured map of a plate quantity with its range and a probe.
class PlateContour extends StatefulWidget {
  final PlateDesign design;
  const PlateContour({super.key, required this.design});

  @override
  State<PlateContour> createState() => _PlateContourState();
}

class _PlateContourState extends State<PlateContour> {
  PlateField _field = PlateField.mx;
  int? _probe;

  Float64List _values(PlateField f) {
    final d = widget.design;
    return switch (f) {
      PlateField.w => Float64List.fromList([for (final v in d.sls.w) v * 1000]),
      PlateField.mx => d.uls.mx,
      PlateField.my => d.uls.my,
      PlateField.mxy => d.uls.mxy,
      PlateField.asBx => d.steel.bottomX,
      PlateField.asBy => d.steel.bottomY,
      PlateField.asTx => d.steel.topX,
      PlateField.asTy => d.steel.topY,
      PlateField.soil => Float64List.fromList([
        for (var i = 0; i < d.sls.nodeCount; i++) d.soilPressure(i),
      ]),
    };
  }

  String _unit(PlateField f) => switch (f) {
    PlateField.w => 'mm',
    PlateField.mx || PlateField.my || PlateField.mxy => 'kN·m/m',
    PlateField.soil => 'kPa',
    _ => 'mm²/m',
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final d = widget.design;
    final values = _values(_field);
    final options = {
      PlateField.w: l.plateFieldW,
      PlateField.mx: 'Mx',
      PlateField.my: 'My',
      PlateField.mxy: 'Mxy',
      PlateField.asBx: l.plateBottomX,
      PlateField.asBy: l.plateBottomY,
      PlateField.asTx: l.plateTopX,
      PlateField.asTy: l.plateTopY,
      if (d.input.subgrade > 0) PlateField.soil: l.plateSoilPressure,
    };
    final probe = _probe;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PickerField<PlateField>(
            label: l.plateShow,
            value: _field,
            options: options,
            onChanged: (v) => setState(() => _field = v),
          ),
          const SizedBox(height: Gap.md),
          AspectRatio(
            aspectRatio: math.max(0.6, math.min(2.2, d.input.lx / d.input.ly)),
            child: LayoutBuilder(
              builder: (context, box) => GestureDetector(
                onTapDown: (e) {
                  final p = e.localPosition;
                  final i = (p.dx / box.maxWidth * d.uls.nx).round().clamp(
                    0,
                    d.uls.nx,
                  );
                  final j = ((1 - p.dy / box.maxHeight) * d.uls.ny)
                      .round()
                      .clamp(0, d.uls.ny);
                  setState(() => _probe = d.uls.node(i, j));
                },
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _ContourPainter(
                    d,
                    values,
                    probe,
                    edge: context.colors.outline,
                    column: context.colors.onSurface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Gap.sm),
          Row(
            children: [
              Text(
                fmt(context, values.reduce(math.min), 1),
                style: AppTheme.mono(context, size: 12),
              ),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [for (var i = 0; i <= 3; i++) heat(i / 3)],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Gap.sm),
              Text(
                '${fmt(context, values.reduce(math.max), 1)} ${_unit(_field)}',
                style: AppTheme.mono(context, size: 12),
              ),
            ],
          ),
          if (probe != null) ...[
            const SizedBox(height: Gap.sm),
            Text(
              l.plateProbe(
                fmt(context, (probe % (d.uls.nx + 1)) * d.uls.dx, 2),
                fmt(context, (probe ~/ (d.uls.nx + 1)) * d.uls.dy, 2),
                '${fmt(context, values[probe], 2)} ${_unit(_field)}',
              ),
              style: context.text.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _ContourPainter extends CustomPainter {
  final PlateDesign d;
  final Float64List v;
  final int? probe;
  final Color edge, column;
  _ContourPainter(
    this.d,
    this.v,
    this.probe, {
    required this.edge,
    required this.column,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r = d.uls;
    final lo = v.reduce(math.min), hi = v.reduce(math.max);
    final span = hi - lo == 0 ? 1.0 : hi - lo;
    final cw = size.width / r.nx, ch = size.height / r.ny;
    Offset at(int i, int j) => Offset(i * cw, size.height - j * ch);
    // Each element split into four triangles around its centre for a
    // smoother map.
    for (var j = 0; j < r.ny; j++) {
      for (var i = 0; i < r.nx; i++) {
        final corners = [(i, j), (i + 1, j), (i + 1, j + 1), (i, j + 1)];
        final vals = [for (final (a, b) in corners) v[r.node(a, b)]];
        final centre = vals.reduce((a, b) => a + b) / 4;
        final c = (at(i, j) + at(i + 1, j + 1)) / 2;
        for (var k = 0; k < 4; k++) {
          final p1 = at(corners[k].$1, corners[k].$2);
          final p2 = at(corners[(k + 1) % 4].$1, corners[(k + 1) % 4].$2);
          final value = (vals[k] + vals[(k + 1) % 4] + centre) / 3;
          canvas.drawPath(
            Path()
              ..moveTo(p1.dx, p1.dy)
              ..lineTo(p2.dx, p2.dy)
              ..lineTo(c.dx, c.dy)
              ..close(),
            Paint()
              ..color = heat((value - lo) / span)
              ..isAntiAlias = false,
          );
        }
      }
    }
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Supported edges drawn thicker.
    final heavy = Paint()
      ..color = column
      ..strokeWidth = 4;
    final input = d.input;
    if (input.left != EdgeSupport.free) {
      canvas.drawLine(Offset.zero, Offset(0, size.height), heavy);
    }
    if (input.right != EdgeSupport.free) {
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width, size.height),
        heavy,
      );
    }
    if (input.bottom != EdgeSupport.free) {
      canvas.drawLine(
        Offset(0, size.height),
        Offset(size.width, size.height),
        heavy,
      );
    }
    if (input.top != EdgeSupport.free) {
      canvas.drawLine(Offset.zero, Offset(size.width, 0), heavy);
    }
    for (final (x, y) in input.columns) {
      final p = Offset(
        x / input.lx * size.width,
        size.height - y / input.ly * size.height,
      );
      canvas.drawRect(
        Rect.fromCenter(center: p, width: 9, height: 9),
        Paint()..color = column,
      );
    }
    final pr = probe;
    if (pr != null) {
      final p = at(pr % (r.nx + 1), pr ~/ (r.nx + 1));
      canvas.drawCircle(
        p,
        6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_ContourPainter o) => o.v != v || o.probe != probe;
}
