import 'package:flutter/widgets.dart';
import 'package:sibot/l10n/app_localizations.dart';

export 'package:sibot/l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Locale name for intl date/number formatting (e.g. "fr").
  String get localeName => AppLocalizations.of(this).localeName;
}

extension L10nLabels on AppLocalizations {
  String projectStatus(String status) => switch (status) {
    'active' => statusActive,
    'completed' => statusCompleted,
    'archived' => statusArchived,
    _ => status,
  };

  String priority(String p) => switch (p) {
    'high' => priorityHigh,
    'medium' => priorityMedium,
    'low' => priorityLow,
    _ => p,
  };

  String relativeDate(DateTime d, String Function(DateTime) absolute) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return timeJustNow;
    if (diff.inHours < 1) return timeMinutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return timeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return timeDaysAgo(diff.inDays);
    return absolute(d);
  }
}
