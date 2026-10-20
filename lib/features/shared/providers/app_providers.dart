import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sibot/core/models/entities.dart';
import 'package:sibot/core/services/core_services.dart';

// ============ PROJECT PROVIDERS ============

final projectsProvider =
    StateNotifierProvider<ProjectNotifier, AsyncValue<List<Project>>>((ref) {
      return ProjectNotifier();
    });

class ProjectNotifier extends StateNotifier<AsyncValue<List<Project>>> {
  ProjectNotifier() : super(const AsyncValue.loading()) {
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final box = HiveService.getBox(HiveService.projectsBox);
      final projects = box.values.cast<Project>().toList();
      state = AsyncValue.data(projects);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addProject(Project project) async {
    try {
      final box = HiveService.getBox(HiveService.projectsBox);
      await box.put(project.id, project);
      await _loadProjects();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProject(Project project) async {
    try {
      final box = HiveService.getBox(HiveService.projectsBox);
      await box.put(project.id, project);
      await _loadProjects();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      final box = HiveService.getBox(HiveService.projectsBox);
      await box.delete(projectId);
      await _loadProjects();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
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
    StateNotifierProvider<
      FootingCalculationNotifier,
      AsyncValue<List<FootingCalculation>>
    >((ref) {
      return FootingCalculationNotifier();
    });

class FootingCalculationNotifier
    extends StateNotifier<AsyncValue<List<FootingCalculation>>> {
  FootingCalculationNotifier() : super(const AsyncValue.loading()) {
    _loadCalculations();
  }

  Future<void> _loadCalculations() async {
    try {
      final box = HiveService.getBox(HiveService.calculationsBox);
      final calculations = box.values.whereType<FootingCalculation>().toList();
      state = AsyncValue.data(calculations);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCalculation(FootingCalculation calc) async {
    try {
      final box = HiveService.getBox(HiveService.calculationsBox);
      await box.put(calc.id, calc);
      await _loadCalculations();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateCalculation(FootingCalculation calc) async {
    try {
      final box = HiveService.getBox(HiveService.calculationsBox);
      await box.put(calc.id, calc);
      await _loadCalculations();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCalculation(String calcId) async {
    try {
      final box = HiveService.getBox(HiveService.calculationsBox);
      await box.delete(calcId);
      await _loadCalculations();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
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

final selectedProjectIdProvider = StateProvider<String?>((ref) => null);

// ============ FIELD MANAGEMENT PROVIDERS ============

final photoLogsProvider =
    StateNotifierProvider.family<
      PhotoLogNotifier,
      AsyncValue<List<PhotoLog>>,
      String
    >((ref, projectId) {
      return PhotoLogNotifier(projectId);
    });

class PhotoLogNotifier extends StateNotifier<AsyncValue<List<PhotoLog>>> {
  final String projectId;
  PhotoLogNotifier(this.projectId) : super(const AsyncValue.loading()) {
    _loadPhotoLogs();
  }

  Future<void> _loadPhotoLogs() async {
    try {
      final box = HiveService.getBox(HiveService.photoLogsBox);
      final logs = box.values
          .whereType<PhotoLog>()
          .where((log) => log.projectId == projectId)
          .toList();
      state = AsyncValue.data(logs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addPhotoLog(PhotoLog log) async {
    try {
      final box = HiveService.getBox(HiveService.photoLogsBox);
      await box.put(log.id, log);
      await _loadPhotoLogs();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deletePhotoLog(String logId) async {
    try {
      final box = HiveService.getBox(HiveService.photoLogsBox);
      await box.delete(logId);
      await _loadPhotoLogs();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final dailyReportsProvider =
    StateNotifierProvider.family<
      DailyReportNotifier,
      AsyncValue<List<DailyReport>>,
      String
    >((ref, projectId) {
      return DailyReportNotifier(projectId);
    });

class DailyReportNotifier extends StateNotifier<AsyncValue<List<DailyReport>>> {
  final String projectId;
  DailyReportNotifier(this.projectId) : super(const AsyncValue.loading()) {
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final box = HiveService.getBox(HiveService.dailyReportsBox);
      final reports = box.values
          .whereType<DailyReport>()
          .where((report) => report.projectId == projectId)
          .toList();
      state = AsyncValue.data(reports);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addReport(DailyReport report) async {
    try {
      final box = HiveService.getBox(HiveService.dailyReportsBox);
      await box.put(report.id, report);
      await _loadReports();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final punchListProvider =
    StateNotifierProvider.family<
      PunchListNotifier,
      AsyncValue<List<PunchListItem>>,
      String
    >((ref, projectId) {
      return PunchListNotifier(projectId);
    });

class PunchListNotifier extends StateNotifier<AsyncValue<List<PunchListItem>>> {
  final String projectId;
  PunchListNotifier(this.projectId) : super(const AsyncValue.loading()) {
    _loadPunchList();
  }

  Future<void> _loadPunchList() async {
    try {
      final box = HiveService.getBox(HiveService.punchListBox);
      final items = box.values
          .whereType<PunchListItem>()
          .where((item) => item.projectId == projectId)
          .toList();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addItem(PunchListItem item) async {
    try {
      final box = HiveService.getBox(HiveService.punchListBox);
      await box.put(item.id, item);
      await _loadPunchList();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateItem(PunchListItem item) async {
    try {
      final box = HiveService.getBox(HiveService.punchListBox);
      await box.put(item.id, item);
      await _loadPunchList();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      final box = HiveService.getBox(HiveService.punchListBox);
      await box.delete(itemId);
      await _loadPunchList();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ============ SETTINGS PROVIDERS ============

final defaultCodeProvider = StateProvider<String>((ref) {
  return SettingsService.getDefaultCode();
});

final languageProvider = StateProvider<String>((ref) {
  return SettingsService.getLanguage();
});

final unitSystemProvider = StateProvider<String>((ref) {
  return SettingsService.getUnitSystem();
});
