import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';

// ============ PROJECT PROVIDERS ============

final projectsProvider = AsyncNotifierProvider<ProjectNotifier, List<Project>>(
  ProjectNotifier.new,
);

class ProjectNotifier extends AsyncNotifier<List<Project>> {
  dynamic get _box => HiveService.getBox(HiveService.projectsBox);

  List<Project> _read() => (_box.values as Iterable).cast<Project>().toList();

  @override
  Future<List<Project>> build() async => _read();

  Future<void> _write(Future<void> Function() action) async {
    state = await AsyncValue.guard(() async {
      await action();
      return _read();
    });
  }

  Future<void> addProject(Project project) =>
      _write(() => _box.put(project.id, project));

  Future<void> updateProject(Project project) =>
      _write(() => _box.put(project.id, project));

  Future<void> deleteProject(String projectId) =>
      _write(() => _box.delete(projectId));
}

final projectByIdProvider = FutureProvider.family<Project?, String>((
  ref,
  projectId,
) async {
  final box = HiveService.getBox(HiveService.projectsBox);
  return box.get(projectId) as Project?;
});

// ============ CALCULATION PROVIDERS ============

final footingCalculationsProvider =
    AsyncNotifierProvider<FootingCalculationNotifier, List<FootingCalculation>>(
      FootingCalculationNotifier.new,
    );

class FootingCalculationNotifier
    extends AsyncNotifier<List<FootingCalculation>> {
  dynamic get _box => HiveService.getBox(HiveService.calculationsBox);

  List<FootingCalculation> _read() =>
      (_box.values as Iterable).whereType<FootingCalculation>().toList();

  @override
  Future<List<FootingCalculation>> build() async => _read();

  Future<void> _write(Future<void> Function() action) async {
    state = await AsyncValue.guard(() async {
      await action();
      return _read();
    });
  }

  Future<void> addCalculation(FootingCalculation calc) =>
      _write(() => _box.put(calc.id, calc));

  Future<void> updateCalculation(FootingCalculation calc) =>
      _write(() => _box.put(calc.id, calc));

  Future<void> deleteCalculation(String calcId) =>
      _write(() => _box.delete(calcId));
}

final projectCalculationsProvider =
    FutureProvider.family<List<FootingCalculation>, String>((
      ref,
      projectId,
    ) async {
      final box = HiveService.getBox(HiveService.calculationsBox);
      return box.values
          .whereType<FootingCalculation>()
          .where((c) => c.projectId == projectId)
          .toList();
    });

final projectBeamCalculationsProvider =
    FutureProvider.family<List<BeamCalculation>, String>((
      ref,
      projectId,
    ) async {
      final box = HiveService.getBox(HiveService.calculationsBox);
      return box.values
          .whereType<BeamCalculation>()
          .where((c) => c.projectId == projectId)
          .toList();
    });

/// Project chosen in the field hub.
final selectedProjectIdProvider =
    NotifierProvider<SelectedProjectNotifier, String?>(
      SelectedProjectNotifier.new,
    );

class SelectedProjectNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

// ============ FIELD MANAGEMENT PROVIDERS ============

/// Items of one project stored in a Hive box, with add/update/delete.
abstract class _ProjectBoxNotifier<T> extends AsyncNotifier<List<T>> {
  _ProjectBoxNotifier(this.projectId);
  final String projectId;

  String get boxName;
  String projectOf(T item);
  String idOf(T item);

  dynamic get _box => HiveService.getBox(boxName);

  List<T> _read() => (_box.values as Iterable)
      .whereType<T>()
      .where((t) => projectOf(t) == projectId)
      .toList();

  @override
  Future<List<T>> build() async => _read();

  Future<void> _write(Future<void> Function() action) async {
    state = await AsyncValue.guard(() async {
      await action();
      return _read();
    });
  }

  Future<void> _put(T item) => _write(() => _box.put(idOf(item), item));
  Future<void> _delete(String id) => _write(() => _box.delete(id));
}

final photoLogsProvider =
    AsyncNotifierProvider.family<PhotoLogNotifier, List<PhotoLog>, String>(
      PhotoLogNotifier.new,
    );

class PhotoLogNotifier extends _ProjectBoxNotifier<PhotoLog> {
  PhotoLogNotifier(super.projectId);

  @override
  String get boxName => HiveService.photoLogsBox;
  @override
  String projectOf(PhotoLog item) => item.projectId;
  @override
  String idOf(PhotoLog item) => item.id;

  Future<void> addPhotoLog(PhotoLog log) => _put(log);
  Future<void> deletePhotoLog(String logId) => _delete(logId);
}

final dailyReportsProvider =
    AsyncNotifierProvider.family<
      DailyReportNotifier,
      List<DailyReport>,
      String
    >(DailyReportNotifier.new);

class DailyReportNotifier extends _ProjectBoxNotifier<DailyReport> {
  DailyReportNotifier(super.projectId);

  @override
  String get boxName => HiveService.dailyReportsBox;
  @override
  String projectOf(DailyReport item) => item.projectId;
  @override
  String idOf(DailyReport item) => item.id;

  Future<void> addReport(DailyReport report) => _put(report);
}

final punchListProvider =
    AsyncNotifierProvider.family<
      PunchListNotifier,
      List<PunchListItem>,
      String
    >(PunchListNotifier.new);

class PunchListNotifier extends _ProjectBoxNotifier<PunchListItem> {
  PunchListNotifier(super.projectId);

  @override
  String get boxName => HiveService.punchListBox;
  @override
  String projectOf(PunchListItem item) => item.projectId;
  @override
  String idOf(PunchListItem item) => item.id;

  Future<void> addItem(PunchListItem item) => _put(item);
  Future<void> updateItem(PunchListItem item) => _put(item);
  Future<void> deleteItem(String itemId) => _delete(itemId);
}
