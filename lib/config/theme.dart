import 'package:flutter/material.dart';
import 'package:sibot/ui/tokens.dart';

/// Semantic colours that Material's ColorScheme doesn't cover.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color danger;
  final Color dangerContainer;
  final Color grid;
  final Color accent;

  const AppColors({
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.danger,
    required this.dangerContainer,
    required this.grid,
    required this.accent,
  });

  static const light = AppColors(
    success: Color(0xFF0F8A5F),
    successContainer: Color(0xFFE3F5EC),
    warning: Color(0xFFB86E00),
    warningContainer: Color(0xFFFFF1DB),
    danger: Color(0xFFD03535),
    dangerContainer: Color(0xFFFDE8E8),
    grid: Color(0x142F5BFF),
    accent: Color(0xFFF5A524),
  );

  static const dark = AppColors(
    success: Color(0xFF3DD598),
    successContainer: Color(0xFF0E2E22),
    warning: Color(0xFFFFB648),
    warningContainer: Color(0xFF33240C),
    danger: Color(0xFFFF6B6B),
    dangerContainer: Color(0xFF3A1416),
    grid: Color(0x1A7C9CFF),
    accent: Color(0xFFFFB648),
  );

  @override
  AppColors copyWith({
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? danger,
    Color? dangerContainer,
    Color? grid,
    Color? accent,
  }) {
    return AppColors(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      grid: grid ?? this.grid,
      accent: accent ?? this.accent,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      grid: Color.lerp(grid, other.grid, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}

class AppTheme {
  static const fontFamily = 'Inter';
  static const monoFamily = 'JetBrainsMono';

  /// Style for engineering values: monospaced, tabular figures.
  static TextStyle mono(BuildContext context, {double? size, Color? color}) {
    return TextStyle(
      fontFamily: monoFamily,
      fontSize: size ?? 14,
      fontWeight: FontWeight.w500,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static final lightTheme = _build(
    Brightness.light,
    const _Palette(
      primary: Color(0xFF2F5BFF),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE6ECFF),
      onPrimaryContainer: Color(0xFF0E2A99),
      background: Color(0xFFF5F6F8),
      surface: Colors.white,
      surfaceLow: Color(0xFFF0F2F5),
      surfaceHigh: Color(0xFFE9ECF1),
      ink: Color(0xFF0D1321),
      inkMuted: Color(0xFF5A6476),
      outline: Color(0xFFD5DAE2),
      outlineSoft: Color(0xFFE6E9EF),
      error: Color(0xFFD03535),
    ),
    AppColors.light,
  );

  static final darkTheme = _build(
    Brightness.dark,
    const _Palette(
      primary: Color(0xFF7C9CFF),
      onPrimary: Color(0xFF071233),
      primaryContainer: Color(0xFF1C2A5C),
      onPrimaryContainer: Color(0xFFDCE4FF),
      background: Color(0xFF090C12),
      surface: Color(0xFF10141C),
      surfaceLow: Color(0xFF151A24),
      surfaceHigh: Color(0xFF1C2230),
      ink: Color(0xFFE9EDF4),
      inkMuted: Color(0xFF94A0B4),
      outline: Color(0xFF2A3142),
      outlineSoft: Color(0xFF1F2533),
      error: Color(0xFFFF6B6B),
    ),
    AppColors.dark,
  );

  static ThemeData _build(Brightness b, _Palette p, AppColors app) {
    final scheme = ColorScheme.fromSeed(seedColor: p.primary, brightness: b)
        .copyWith(
          primary: p.primary,
          onPrimary: p.onPrimary,
          primaryContainer: p.primaryContainer,
          onPrimaryContainer: p.onPrimaryContainer,
          secondary: p.inkMuted,
          tertiary: app.accent,
          surface: p.surface,
          onSurface: p.ink,
          onSurfaceVariant: p.inkMuted,
          surfaceContainerLowest: p.surface,
          surfaceContainerLow: p.surfaceLow,
          surfaceContainer: p.surfaceLow,
          surfaceContainerHigh: p.surfaceHigh,
          surfaceContainerHighest: p.surfaceHigh,
          outline: p.outline,
          outlineVariant: p.outlineSoft,
          error: p.error,
        );

    final text = _textTheme(p.ink, p.inkMuted);
    final roundedMd = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.md),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      dividerColor: p.outlineSoft,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      extensions: [app],
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        foregroundColor: p.ink,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: p.outlineSoft),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: p.outlineSoft,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceLow,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Gap.lg,
          vertical: 14,
        ),
        labelStyle: text.bodyMedium?.copyWith(color: p.inkMuted),
        floatingLabelStyle: text.bodySmall?.copyWith(
          color: p.primary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: text.bodyMedium?.copyWith(
          color: p.inkMuted.withValues(alpha: 0.6),
        ),
        suffixStyle: text.bodyMedium?.copyWith(color: p.inkMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: p.outlineSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: p.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: p.error, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
          shape: roundedMd,
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          shape: roundedMd,
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
          foregroundColor: p.ink,
          side: BorderSide(color: p.outline),
          shape: roundedMd,
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: roundedMd,
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: p.ink),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          minimumSize: const Size(0, 44),
          backgroundColor: p.surfaceLow,
          foregroundColor: p.inkMuted,
          selectedBackgroundColor: p.primaryContainer,
          selectedForegroundColor: p.onPrimaryContainer,
          side: BorderSide(color: p.outlineSoft),
          shape: roundedMd,
          textStyle: text.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceLow,
        side: BorderSide(color: p.outlineSoft),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        labelStyle: text.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
      ),
      listTileTheme: ListTileThemeData(
        shape: roundedMd,
        iconColor: p.inkMuted,
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: Gap.lg),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.primaryContainer,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 22,
            color: s.contains(WidgetState.selected)
                ? p.onPrimaryContainer
                : p.inkMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelSmall?.copyWith(
            fontSize: 11.5,
            color: s.contains(WidgetState.selected) ? p.ink : p.inkMuted,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        selectedIconTheme: IconThemeData(color: p.onPrimaryContainer, size: 22),
        unselectedIconTheme: IconThemeData(color: p.inkMuted, size: 22),
        selectedLabelTextStyle: text.labelMedium?.copyWith(
          color: p.ink,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: text.labelMedium?.copyWith(color: p.inkMuted),
        labelType: NavigationRailLabelType.all,
        groupAlignment: -1,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.ink,
        unselectedLabelColor: p.inkMuted,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
        indicatorColor: p.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: p.outlineSoft,
        tabAlignment: TabAlignment.start,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
        ),
        titleTextStyle: text.headlineSmall,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: p.background),
        shape: roundedMd,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.surfaceHigh,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: p.inkMuted,
        collapsedIconColor: p.inkMuted,
      ),
    );
  }

  static TextTheme _textTheme(Color ink, Color muted) {
    TextStyle s(
      double size,
      FontWeight w,
      Color c, {
      double ls = 0,
      double? h,
    }) => TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: w,
      color: c,
      letterSpacing: ls,
      height: h,
    );

    return TextTheme(
      displayLarge: s(44, FontWeight.w700, ink, ls: -1.4, h: 1.1),
      displayMedium: s(36, FontWeight.w700, ink, ls: -1.1, h: 1.1),
      displaySmall: s(30, FontWeight.w700, ink, ls: -0.9, h: 1.15),
      headlineLarge: s(28, FontWeight.w700, ink, ls: -0.8, h: 1.2),
      headlineMedium: s(24, FontWeight.w700, ink, ls: -0.6, h: 1.2),
      headlineSmall: s(20, FontWeight.w600, ink, ls: -0.4, h: 1.25),
      titleLarge: s(18, FontWeight.w600, ink, ls: -0.3, h: 1.3),
      titleMedium: s(15, FontWeight.w600, ink, ls: -0.1, h: 1.35),
      titleSmall: s(13, FontWeight.w600, ink, h: 1.35),
      bodyLarge: s(16, FontWeight.w400, ink, h: 1.5),
      bodyMedium: s(14, FontWeight.w400, ink, h: 1.45),
      bodySmall: s(12.5, FontWeight.w400, muted, h: 1.4),
      labelLarge: s(14, FontWeight.w600, ink, ls: -0.1),
      labelMedium: s(12.5, FontWeight.w500, ink),
      labelSmall: s(11, FontWeight.w600, muted, ls: 0.6),
    );
  }
}

class _Palette {
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color background;
  final Color surface;
  final Color surfaceLow;
  final Color surfaceHigh;
  final Color ink;
  final Color inkMuted;
  final Color outline;
  final Color outlineSoft;
  final Color error;

  const _Palette({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.background,
    required this.surface,
    required this.surfaceLow,
    required this.surfaceHigh,
    required this.ink,
    required this.inkMuted,
    required this.outline,
    required this.outlineSoft,
    required this.error,
  });
}
