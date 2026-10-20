import 'package:flutter/widgets.dart';

/// Spacing scale (4 pt grid).
abstract final class Gap {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

abstract final class Radii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

/// Window size classes (Material 3 guidance).
enum WindowSize { compact, medium, expanded }

abstract final class Breakpoints {
  static const double medium = 600;
  static const double expanded = 900;
  static const double large = 1200;

  /// Maximum width of a page's content column on large tablets.
  static const double contentMax = 1180;

  static WindowSize of(double width) {
    if (width >= expanded) return WindowSize.expanded;
    if (width >= medium) return WindowSize.medium;
    return WindowSize.compact;
  }
}

extension WindowSizeContext on BuildContext {
  WindowSize get windowSize => Breakpoints.of(MediaQuery.sizeOf(this).width);
  bool get isCompact => windowSize == WindowSize.compact;
}

/// Horizontal page gutter for a given content width.
double pageGutter(double width) {
  if (width >= Breakpoints.expanded) return Gap.xxl;
  if (width >= Breakpoints.medium) return Gap.xl;
  return Gap.lg;
}
