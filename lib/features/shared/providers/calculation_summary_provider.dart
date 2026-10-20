import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';

/// Type-independent view of a saved calculation, for lists.
@immutable
class CalcSummary {
  final String id;
  final String projectId;
  final String name;

  /// Id in the module registry.
  final String moduleId;
  final IconData icon;
  final bool isValid;
  final DateTime createdAt;

  const CalcSummary({
    required this.id,
    required this.projectId,
    required this.name,
    required this.moduleId,
    required this.icon,
    required this.isValid,
    required this.createdAt,
  });

  static CalcSummary? from(Object? v) => switch (v) {
    FootingCalculation c => CalcSummary(
      id: c.id,
      projectId: c.projectId,
      name: c.name,
      moduleId: 'footing',
      icon: Icons.foundation,
      isValid: c.isValid,
      createdAt: c.createdAt,
    ),
    BeamCalculation c => CalcSummary(
      id: c.id,
      projectId: c.projectId,
      name: c.name,
      moduleId: 'beam',
      icon: Icons.straighten,
      isValid: c.isValid,
      createdAt: c.createdAt,
    ),
    ColumnCalculation c => CalcSummary(
      id: c.id,
      projectId: c.projectId,
      name: c.name,
      moduleId: 'column',
      icon: Icons.view_column_outlined,
      isValid: c.isValid,
      createdAt: c.createdAt,
    ),
    SlabCalculation c => CalcSummary(
      id: c.id,
      projectId: c.projectId,
      name: c.name,
      moduleId: 'slab',
      icon: Icons.layers_outlined,
      isValid: c.isValid,
      createdAt: c.createdAt,
    ),
    RetainingWallCalculation c => CalcSummary(
      id: c.id,
      projectId: c.projectId,
      name: c.name,
      moduleId: 'retaining-wall',
      icon: Icons.stairs_outlined,
      isValid: c.isValid,
      createdAt: c.createdAt,
    ),
    _ => null,
  };
}

List<CalcSummary> _readAll() {
  final box = HiveService.getBox(HiveService.calculationsBox);
  return box.values.map(CalcSummary.from).nonNulls.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

/// All saved calculations, newest first; updates live as the box changes.
final allCalculationsProvider = StreamProvider<List<CalcSummary>>((ref) async* {
  final box = HiveService.getBox(HiveService.calculationsBox);
  yield _readAll();
  await for (final _ in box.watch()) {
    yield _readAll();
  }
});

final projectCalcSummariesProvider =
    Provider.family<AsyncValue<List<CalcSummary>>, String>((ref, projectId) {
      return ref
          .watch(allCalculationsProvider)
          .whenData(
            (all) => all.where((c) => c.projectId == projectId).toList(),
          );
    });
