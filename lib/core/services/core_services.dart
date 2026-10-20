import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../models/entities.dart';

/// Hive database service for local storage
class HiveService {
  static const String projectsBox = 'projects';
  static const String calculationsBox = 'calculations';
  static const String photoLogsBox = 'photoLogs';
  static const String dailyReportsBox = 'dailyReports';
  static const String punchListBox = 'punchList';
  static const String settingsBox = 'settings';

  static Future<void> init() async {
    try {
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ProjectAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(FootingCalculationAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(PhotoLogAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(DailyReportAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(PunchListItemAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(BeamCalculationAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(ColumnCalculationAdapter());
      }
      if (!Hive.isAdapterRegistered(7)) {
        Hive.registerAdapter(SlabCalculationAdapter());
      }
      if (!Hive.isAdapterRegistered(8)) {
        Hive.registerAdapter(RetainingWallCalculationAdapter());
      }

      // Delete potentially corrupted boxes (do this once to fix the error)
      // Comment these out after first successful run
      await Hive.deleteBoxFromDisk(calculationsBox);

      // Open boxes
      await Hive.openBox(projectsBox);
      await Hive.openBox(calculationsBox);
      await Hive.openBox(photoLogsBox);
      await Hive.openBox(dailyReportsBox);
      await Hive.openBox(punchListBox);
      await Hive.openBox(settingsBox);

      LoggerService.instance.i('Hive initialized successfully');
    } catch (e, stackTrace) {
      LoggerService.instance.e(
        'Hive initialization failed: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static Future<void> clearAllData() async {
    await Hive.deleteBoxFromDisk(projectsBox);
    await Hive.deleteBoxFromDisk(calculationsBox);
    await Hive.deleteBoxFromDisk(photoLogsBox);
    await Hive.deleteBoxFromDisk(dailyReportsBox);
    await Hive.deleteBoxFromDisk(punchListBox);
    await Hive.deleteBoxFromDisk(settingsBox);
  }

  static Box<dynamic> getBox(String boxName) {
    return Hive.box(boxName);
  }
}

/// Logging service
class LoggerService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
  );

  static Logger get instance => _logger;

  static void init() {
    _logger.i('Logger initialized');
  }

  static void t(String message) => _logger.t(message);
  static void d(String message) => _logger.d(message);
  static void i(String message) => _logger.i(message);
  static void w(String message) => _logger.w(message);
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}

/// ID generation service
class IdService {
  static const _uuid = Uuid();

  static String generateId() => _uuid.v4();

  static String generateProjectId() => 'PRJ_${_uuid.v4().substring(0, 8)}';

  static String generateCalculationId() => 'CALC_${_uuid.v4().substring(0, 8)}';

  static String generatePhotoId() => 'PHO_${_uuid.v4().substring(0, 8)}';

  static String generateReportId() => 'REP_${_uuid.v4().substring(0, 8)}';
}

/// Settings and preferences service
class SettingsService {
  static const String _languageKey = 'language';
  static const String _themeKey = 'theme';
  static const String _unitSystemKey = 'unitSystem';
  static const String _defaultCodeKey = 'defaultCode';

  static Future<void> setLanguage(String language) async {
    final box = HiveService.getBox(HiveService.settingsBox);
    await box.put(_languageKey, language);
  }

  static String getLanguage() {
    final box = HiveService.getBox(HiveService.settingsBox);
    return box.get(_languageKey, defaultValue: 'en');
  }

  static Future<void> setTheme(String theme) async {
    final box = HiveService.getBox(HiveService.settingsBox);
    await box.put(_themeKey, theme);
  }

  static String getTheme() {
    final box = HiveService.getBox(HiveService.settingsBox);
    return box.get(_themeKey, defaultValue: 'system');
  }

  static Future<void> setUnitSystem(String system) async {
    final box = HiveService.getBox(HiveService.settingsBox);
    await box.put(_unitSystemKey, system);
  }

  static String getUnitSystem() {
    final box = HiveService.getBox(HiveService.settingsBox);
    return box.get(_unitSystemKey, defaultValue: 'metric');
  }

  static Future<void> setDefaultCode(String code) async {
    final box = HiveService.getBox(HiveService.settingsBox);
    await box.put(_defaultCodeKey, code);
  }

  static String getDefaultCode() {
    final box = HiveService.getBox(HiveService.settingsBox);
    return box.get(_defaultCodeKey, defaultValue: 'eurocode');
  }
}
