import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/services/core_services.dart';
import 'package:sibot_engine/sibot_engine.dart';

/// A saved frame model with its metadata.
class FrameModelRecord {
  final String id;
  final String projectId;
  final String name;
  final DateTime updatedAt;
  final Model2D model;

  const FrameModelRecord({
    required this.id,
    required this.projectId,
    required this.name,
    required this.updatedAt,
    required this.model,
  });

  FrameModelRecord copyWith({String? name, Model2D? model}) => FrameModelRecord(
    id: id,
    projectId: projectId,
    name: name ?? this.name,
    updatedAt: DateTime.now(),
    model: model ?? this.model,
  );

  Map<String, dynamic> toStored() => {
    'id': id,
    'projectId': projectId,
    'name': name,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    // Stored as a string: Hive keeps it intact whatever its nesting.
    'model': jsonEncode(model.toJson()),
  };

  static FrameModelRecord? fromStored(Object? v) {
    if (v is! Map) return null;
    try {
      return FrameModelRecord(
        id: v['id'] as String,
        projectId: v['projectId'] as String,
        name: v['name'] as String,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(v['updatedAt'] as int),
        model: Model2D.fromJson(
          Map<String, dynamic>.from(jsonDecode(v['model'] as String) as Map),
        ),
      );
    } catch (e) {
      LoggerService.w('Unreadable frame model: $e');
      return null;
    }
  }
}

class FrameRepository {
  static dynamic get _box => HiveService.getBox(HiveService.frameModelsBox);

  static List<FrameModelRecord> forProject(String projectId) {
    final out = <FrameModelRecord>[];
    for (final v in _box.values) {
      final r = FrameModelRecord.fromStored(v);
      if (r != null && r.projectId == projectId) out.add(r);
    }
    out.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return out;
  }

  static FrameModelRecord? get(String id) =>
      FrameModelRecord.fromStored(_box.get(id));

  static Future<void> save(FrameModelRecord r) => _box.put(r.id, r.toStored());

  static Future<void> delete(String id) => _box.delete(id);

  static Stream<void> watch() =>
      (HiveService.getBox(HiveService.frameModelsBox)).watch().map((_) {});
}

/// Frame models of a project, newest first; updates live.
final frameModelsProvider =
    StreamProvider.family<List<FrameModelRecord>, String>((
      ref,
      projectId,
    ) async* {
      yield FrameRepository.forProject(projectId);
      await for (final _ in FrameRepository.watch()) {
        yield FrameRepository.forProject(projectId);
      }
    });
