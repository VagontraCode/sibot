import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/core/services/core_services.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => switch (SettingsService.getTheme()) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await SettingsService.setTheme(mode.name);
  }

  /// Cycles system → light → dark.
  Future<void> cycle() => set(switch (state) {
    ThemeMode.system => ThemeMode.light,
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark => ThemeMode.system,
  });
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// App language: null follows the device.
class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() => switch (SettingsService.getLanguage()) {
    'en' => const Locale('en'),
    'fr' => const Locale('fr'),
    _ => null,
  };

  Future<void> set(Locale? locale) async {
    state = locale;
    await SettingsService.setLanguage(locale?.languageCode ?? 'system');
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

/// Design code used by default in design modules: 'eurocode' or 'bael99'.
class DefaultCodeNotifier extends Notifier<String> {
  @override
  String build() => SettingsService.getDefaultCode();

  Future<void> set(String code) async {
    state = code;
    await SettingsService.setDefaultCode(code);
  }
}

final defaultDesignCodeProvider = NotifierProvider<DefaultCodeNotifier, String>(
  DefaultCodeNotifier.new,
);
