import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/calculations/shared/design_ui.dart';
import 'package:sibot/features/modules/module_registry.dart';
import 'package:sibot/features/tools/tools_providers.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';

// ======================= BEARING & SETTLEMENT =======================

class BearingPage extends ConsumerWidget {
  final String projectId;
  const BearingPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(bearingStateProvider(projectId));
    final n = ref.read(bearingStateProvider(projectId).notifier);
    final l = context.l10n;
    final r = s.result;
    final undrained = s.options['drainage'] == 'undrained';

    final labels = {
      'b': l.bearingWidth,
      'bEff': l.bearingWidth,
      'l': l.bearingLength,
      'lEff': l.bearingLength,
      'depth': l.footingDepthInput,
      'g': l.loadPermanentPoint,
      'q': l.loadVariablePoint,
      'cohesion': l.soilCohesion,
      'phi': l.soilPhi,
      'cu': l.soilCu,
      'gammaSoil': l.footingUnitWeight,
      'youngModulus': l.soilModulus,
      'poisson': l.soilPoisson,
    };
    Widget field(String key, String unit, [String? hint]) => FormNumber(
      state: s,
      notifier: n,
      field: key,
      label: labels[key]!,
      unit: unit,
      hint: hint,
    );

    return CalculatorScaffold(
      title: l.modBearing,
      subtitle: l.bearingSubtitle,
      module: moduleByRoute('bearing'),
      onCalculate: n.calculate,
      error: s.problem == null ? null : problemMessage(l, s.problem!, labels),
      resultKey: s.runId,
      inputs: [
        FormSection(
          title: l.footingDimensions,
          icon: Icons.crop_free_rounded,
          children: [
            FieldRow(children: [field('b', 'm', '2'), field('l', 'm', '2')]),
            field('depth', 'm'),
            FieldRow(
              children: [field('g', 'kN', '600'), field('q', 'kN', '200')],
            ),
            Text(l.bearingLoadNote, style: context.text.bodySmall),
          ],
        ),
        FormSection(
          title: l.footingSoil,
          icon: Icons.terrain_outlined,
          children: [
            ChoiceField<String>(
              label: l.soilDrainage,
              value: s.options['drainage']!,
              options: {'drained': l.soilDrained, 'undrained': l.soilUndrained},
              onChanged: (v) => n.setOption('drainage', v),
            ),
            if (undrained)
              field('cu', 'kPa', '50')
            else
              FieldRow(children: [field('cohesion', 'kPa'), field('phi', '°')]),
            field('gammaSoil', 'kN/m³'),
            FieldRow(
              children: [field('youngModulus', 'MPa'), field('poisson', '')],
            ),
          ],
        ),
      ],
      results: r == null
          ? null
          : [
              VerdictBanner(checks: r.checks),
              ResultCard(
                title: l.bearingResistance,
                icon: Icons.terrain_outlined,
                rows: [
                  if (r.factors != null)
                    ResultRow(
                      label: l.bearingFactors,
                      symbol: 'Nq / Nc / Nγ',
                      value:
                          '${fmt(context, r.factors!.nq, 1)} / ${fmt(context, r.factors!.nc, 1)} / ${fmt(context, r.factors!.ngamma, 1)}',
                    ),
                  ResultRow(
                    label: l.bearingUltimate,
                    symbol: 'qult',
                    value: fmt(context, r.qUlt),
                    unit: 'kPa',
                  ),
                  ResultRow(
                    label: l.bearingDesignResistance,
                    symbol: 'qRd',
                    value: fmt(context, r.qRd),
                    unit: 'kPa',
                    emphasize: true,
                  ),
                  ResultRow(
                    label: l.bearingDesignPressure,
                    symbol: 'qEd',
                    value: fmt(context, r.qEd),
                    unit: 'kPa',
                    emphasize: true,
                  ),
                ],
              ),
              ResultCard(
                title: l.bearingSettlement,
                icon: Icons.vertical_align_bottom_rounded,
                rows: [
                  ResultRow(
                    label: l.bearingServicePressure,
                    symbol: 'q',
                    value: fmt(context, r.qSls),
                    unit: 'kPa',
                  ),
                  ResultRow(
                    label: l.bearingSettlement,
                    symbol: 's',
                    value: fmt(context, r.settlement, 1),
                    unit: 'mm',
                    emphasize: true,
                  ),
                ],
              ),
              ChecksCard(checks: r.checks),
              NotesCard(notes: [l.noteSoilEc7, l.noteSettlementEstimate]),
            ],
    );
  }
}

// ======================== SECTION PROPERTIES ========================

class SectionsPage extends ConsumerWidget {
  final String projectId;
  const SectionsPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sectionStateProvider(projectId));
    final n = ref.read(sectionStateProvider(projectId).notifier);
    final l = context.l10n;
    final r = s.result;
    final shape = s.options['shape']!;

    final labels = {
      'b': l.sectionWidth,
      'h': l.sectionHeight,
      'd': l.columnDiameter,
      't': l.sectionThickness,
      'tf': l.sectionFlange,
      'tw': l.sectionWeb,
    };
    Widget field(String key, [String? hint]) => FormNumber(
      state: s,
      notifier: n,
      field: key,
      label: labels[key]!,
      unit: 'mm',
      hint: hint,
    );

    final shapes = {
      'rect': l.sectionRect,
      'circle': l.sectionCircle,
      'hollow': l.sectionHollow,
      'i': l.sectionI,
      't': l.sectionT,
    };

    return CalculatorScaffold(
      title: l.modSections,
      subtitle: l.sectionsSubtitle,
      module: moduleByRoute('sections'),
      onCalculate: n.calculate,
      error: s.problem == null ? null : problemMessage(l, s.problem!, labels),
      resultKey: s.runId,
      inputs: [
        FormSection(
          title: l.sectionShape,
          icon: Icons.crop_square,
          children: [
            Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.sm,
              children: [
                for (final e in shapes.entries)
                  ChoiceChip(
                    label: Text(e.value),
                    selected: shape == e.key,
                    showCheckmark: false,
                    onSelected: (_) => n.setOption('shape', e.key),
                  ),
              ],
            ),
            if (shape == 'circle')
              field('d', '400')
            else
              FieldRow(children: [field('b', '300'), field('h', '600')]),
            if (shape == 'hollow') field('t', '10'),
            if (shape == 'i' || shape == 't')
              FieldRow(children: [field('tf', '15'), field('tw', '10')]),
            _ShapeSketch(shape: shape, values: s.values),
          ],
        ),
      ],
      results: r == null
          ? null
          : [
              ResultCard(
                title: l.sectionResults,
                icon: Icons.straighten,
                rows: [
                  ResultRow(
                    label: l.sectionArea,
                    symbol: 'A',
                    value: fmt(context, r.area / 100, 2),
                    unit: 'cm²',
                    emphasize: true,
                  ),
                  ResultRow(
                    label: l.sectionCentroid,
                    symbol: 'yG',
                    value: fmt(context, r.centroid, 1),
                    unit: 'mm',
                  ),
                  ResultRow(
                    label: l.sectionInertiaY,
                    symbol: 'Iy',
                    value: fmt(context, r.iy / 1e4, 0),
                    unit: 'cm⁴',
                    emphasize: true,
                  ),
                  ResultRow(
                    label: l.sectionInertiaZ,
                    symbol: 'Iz',
                    value: fmt(context, r.iz / 1e4, 0),
                    unit: 'cm⁴',
                  ),
                  ResultRow(
                    label: l.sectionWelTop,
                    symbol: 'Wel,sup',
                    value: fmt(context, r.welTop / 1e3, 1),
                    unit: 'cm³',
                  ),
                  ResultRow(
                    label: l.sectionWelBottom,
                    symbol: 'Wel,inf',
                    value: fmt(context, r.welBottom / 1e3, 1),
                    unit: 'cm³',
                  ),
                  ResultRow(
                    label: l.sectionWpl,
                    symbol: 'Wpl,y',
                    value: fmt(context, r.wpl / 1e3, 1),
                    unit: 'cm³',
                  ),
                  ResultRow(
                    label: l.sectionRadii,
                    symbol: 'iy / iz',
                    value:
                        '${fmt(context, r.iRadiusY / 10, 2)} / ${fmt(context, r.iRadiusZ / 10, 2)}',
                    unit: 'cm',
                  ),
                ],
              ),
              if (shape == 'i') NotesCard(notes: [l.noteSectionNoFillets]),
            ],
    );
  }
}

/// Outline of the selected section from the current inputs.
class _ShapeSketch extends StatelessWidget {
  final String shape;
  final Map<String, double?> values;
  const _ShapeSketch({required this.shape, required this.values});

  @override
  Widget build(BuildContext context) {
    final b = values['b'] ?? 0, h = values['h'] ?? 0, d = values['d'] ?? 0;
    final ok = shape == 'circle' ? d > 0 : b > 0 && h > 0;
    if (!ok) return const SizedBox.shrink();
    return SizedBox(
      height: 160,
      child: CustomPaint(
        painter: _ShapePainter(
          shape,
          values,
          context.colors.surfaceContainerHigh,
          context.colors.onSurface,
        ),
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  final String shape;
  final Map<String, double?> v;
  final Color fill;
  final Color edge;
  _ShapePainter(this.shape, this.v, this.fill, this.edge);

  @override
  void paint(Canvas canvas, Size size) {
    final fillP = Paint()..color = fill;
    final edgeP = Paint()
      ..color = edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final centre = size.center(Offset.zero);
    if (shape == 'circle') {
      final r = math.min(size.width, size.height) / 2 - 8;
      canvas.drawCircle(centre, r, fillP);
      canvas.drawCircle(centre, r, edgeP);
      return;
    }
    final b = v['b']!, h = v['h']!;
    final scale = math.min((size.width - 16) / b, (size.height - 16) / h);
    final w = b * scale, hh = h * scale;
    final left = centre.dx - w / 2, top = centre.dy - hh / 2;
    Path path;
    switch (shape) {
      case 'i' || 't':
        final tf = (v['tf'] ?? h / 10) * scale,
            tw = (v['tw'] ?? b / 10) * scale;
        final wl = centre.dx - tw / 2, wr = centre.dx + tw / 2;
        path = Path()
          ..moveTo(left, top)
          ..lineTo(left + w, top)
          ..lineTo(left + w, top + tf)
          ..lineTo(wr, top + tf);
        if (shape == 'i') {
          path
            ..lineTo(wr, top + hh - tf)
            ..lineTo(left + w, top + hh - tf)
            ..lineTo(left + w, top + hh)
            ..lineTo(left, top + hh)
            ..lineTo(left, top + hh - tf)
            ..lineTo(wl, top + hh - tf);
        } else {
          path
            ..lineTo(wr, top + hh)
            ..lineTo(wl, top + hh);
        }
        path
          ..lineTo(wl, top + tf)
          ..lineTo(left, top + tf)
          ..close();
      default:
        path = Path()..addRect(Rect.fromLTWH(left, top, w, hh));
        if (shape == 'hollow') {
          final t = (v['t'] ?? 0) * scale;
          if (t > 0 && 2 * t < math.min(w, hh)) {
            path.addRect(
              Rect.fromLTWH(left + t, top + t, w - 2 * t, hh - 2 * t),
            );
            path.fillType = PathFillType.evenOdd;
          }
        }
    }
    canvas.drawPath(path, fillP);
    canvas.drawPath(path, edgeP);
  }

  @override
  bool shouldRepaint(_ShapePainter old) => true;
}

// ============================ QUANTITIES ============================

class QuantitiesPage extends ConsumerWidget {
  final String projectId;
  const QuantitiesPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(quantitiesStateProvider(projectId));
    final n = ref.read(quantitiesStateProvider(projectId).notifier);
    final l = context.l10n;
    final r = s.result;

    final labels = {
      'length': l.qtyLength,
      'width': l.qtyWidth,
      'height': l.qtyHeight,
      'count': l.qtyCount,
      'waste': l.qtyWaste,
      'cement': l.qtyCement,
      'sand': l.qtySand,
      'gravel': l.qtyGravel,
      'water': l.qtyWater,
      'barDia': l.qtyBarDiameter,
      'diameter': l.qtyBarDiameter,
      'barCount': l.qtyBarCount,
      'barLength': l.qtyBarLength,
      'lap': l.qtyLap,
    };
    Widget field(String key, String unit, [String? hint]) => FormNumber(
      state: s,
      notifier: n,
      field: key,
      label: labels[key]!,
      unit: unit,
      hint: hint,
    );

    return CalculatorScaffold(
      title: l.modQuantities,
      subtitle: l.quantitiesSubtitle,
      module: moduleByRoute('quantities'),
      onCalculate: n.calculate,
      error: s.problem == null ? null : l.qtyNothing,
      resultKey: s.runId,
      inputs: [
        FormSection(
          title: l.qtyElements,
          icon: Icons.view_in_ar_outlined,
          children: [
            FieldRow(
              children: [field('length', 'm', '5'), field('width', 'm', '0.3')],
            ),
            FieldRow(
              children: [field('height', 'm', '0.6'), field('count', '', '1')],
            ),
            ChoiceField<String>(
              label: l.qtyFormworkType,
              value: s.options['formwork']!,
              options: {
                'column': l.qtyColumnWall,
                'beam': l.modBeam,
                'slab': l.modSlab,
              },
              onChanged: (v) => n.setOption('formwork', v),
            ),
          ],
        ),
        FormSection(
          title: l.qtyMix,
          icon: Icons.science_outlined,
          children: [
            FieldRow(
              children: [field('cement', 'kg/m³'), field('water', 'L/m³')],
            ),
            FieldRow(
              children: [field('sand', 'L/m³'), field('gravel', 'L/m³')],
            ),
            field('waste', '%'),
          ],
        ),
        FormSection(
          title: l.qtyRebar,
          icon: Icons.linear_scale_rounded,
          children: [
            FieldRow(
              children: [
                field('barDia', 'mm', '12'),
                field('barCount', '', '10'),
              ],
            ),
            FieldRow(
              children: [field('barLength', 'm', '6'), field('lap', '%')],
            ),
          ],
        ),
      ],
      results: r == null
          ? null
          : [
              if (r.concrete != null)
                ResultCard(
                  title: l.qtyConcrete,
                  icon: Icons.view_in_ar_outlined,
                  rows: [
                    ResultRow(
                      label: l.qtyVolume,
                      value: fmt(context, r.concrete!.volume, 2),
                      unit: 'm³',
                      emphasize: true,
                    ),
                    ResultRow(
                      label: l.qtyCementTotal,
                      value:
                          '${fmt(context, r.concrete!.cementKg, 0)} kg · ${l.qtyBags(r.concrete!.cementBags)}',
                      emphasize: true,
                    ),
                    ResultRow(
                      label: l.qtySandTotal,
                      value: fmt(context, r.concrete!.sandM3, 2),
                      unit: 'm³',
                    ),
                    ResultRow(
                      label: l.qtyGravelTotal,
                      value: fmt(context, r.concrete!.gravelM3, 2),
                      unit: 'm³',
                    ),
                    ResultRow(
                      label: l.qtyWaterTotal,
                      value: fmt(context, r.concrete!.waterLitres, 0),
                      unit: 'L',
                    ),
                    if (r.formwork != null)
                      ResultRow(
                        label: l.qtyFormwork,
                        value: fmt(context, r.formwork!, 2),
                        unit: 'm²',
                      ),
                  ],
                ),
              if (r.rebar != null)
                ResultCard(
                  title: l.qtyRebar,
                  icon: Icons.linear_scale_rounded,
                  rows: [
                    ResultRow(
                      label: l.qtyRebarLength,
                      value: fmt(context, r.rebar!.length, 1),
                      unit: 'm',
                    ),
                    ResultRow(
                      label: l.qtyRebarMass,
                      value: fmt(context, r.rebar!.mass, 1),
                      unit: 'kg',
                      emphasize: true,
                    ),
                    ResultRow(
                      label: l.qtyStockBars,
                      value: '${r.rebar!.stockBars}',
                      emphasize: true,
                    ),
                  ],
                ),
              NotesCard(notes: [l.noteQuantitiesMix]),
            ],
    );
  }
}
