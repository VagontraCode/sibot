import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibot/features/shared/providers/settings_providers.dart';
import 'package:sibot/l10n/l10n.dart';
import 'package:sibot/ui/ui.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locale = ref.watch(localeProvider);
    final theme = ref.watch(themeModeProvider);
    final code = ref.watch(defaultDesignCodeProvider);

    return AppPage(
      title: l.settingsTitle,
      subtitle: l.settingsSubtitle,
      maxWidth: 720,
      children: [
        SurfaceCard(
          padding: const EdgeInsets.all(Gap.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChoiceField<String>(
                label: l.settingsLanguage,
                value: locale?.languageCode ?? 'system',
                options: {
                  'system': l.settingsLanguageSystem,
                  'en': 'English',
                  'fr': 'Français',
                },
                onChanged: (v) => ref
                    .read(localeProvider.notifier)
                    .set(v == 'system' ? null : Locale(v)),
              ),
              const SizedBox(height: Gap.xl),
              ChoiceField<ThemeMode>(
                label: l.settingsTheme,
                value: theme,
                options: {
                  ThemeMode.system: l.settingsThemeSystem,
                  ThemeMode.light: l.settingsThemeLight,
                  ThemeMode.dark: l.settingsThemeDark,
                },
                onChanged: (v) => ref.read(themeModeProvider.notifier).set(v),
              ),
              const SizedBox(height: Gap.xl),
              ChoiceField<String>(
                label: l.settingsDefaultCode,
                value: code,
                options: {'eurocode': l.codeEurocode, 'bael99': l.codeBael},
                onChanged: (v) =>
                    ref.read(defaultDesignCodeProvider.notifier).set(v),
              ),
              const SizedBox(height: Gap.sm),
              Text(l.settingsDefaultCodeHelp, style: context.text.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
