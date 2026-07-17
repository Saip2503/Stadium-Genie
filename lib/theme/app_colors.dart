import 'package:flutter/material.dart';

/// App color palette derived directly from Stitch UI Design tokens.
class AppColors {
  // Brand Main Colors
  static const primary = Color(0xFF0050CB);
  static const primaryContainer = Color(0xFF0066FF); // Electric Blue Accent
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFFF8F7FF);

  static const secondary = Color(0xFF006E2A);
  static const secondaryContainer = Color(0xFF5CFD80); // Emerald Green Accent
  static const onSecondaryContainer = Color(0xFF00732C);

  static const tertiary = Color(0xFFA33200);
  static const tertiaryContainer = Color(0xFFCC4204); // Warning Orange Accent

  // Light Mode Surfaces
  static const background = Color(0xFFFAF8FF);
  static const onBackground = Color(0xFF191B24);
  static const surface = Color(0xFFFAF8FF);
  static const onSurface = Color(0xFF191B24);

  static const surfaceContainer = Color(0xFFECEDFA);
  static const surfaceContainerHigh = Color(0xFFE6E7F4);
  static const surfaceContainerHighest = Color(0xFFE1E2EE);
  static const surfaceVariant = Color(0xFFE1E2EE);
  static const onSurfaceVariant = Color(0xFF424656);

  static const outline = Color(0xFF727687);
  static const outlineVariant = Color(0xFFC2C6D8);
  static const error = Color(0xFFBA1A1A);

  // Dark / Night Mode Surfaces (Based on Inverse Surface tokens)
  static const darkBackground = Color(0xFF0A0E1A);
  static const darkOnBackground = Color(0xFFEFF0FD);
  static const darkSurface = Color(0xFF121829);
  static const darkOnSurface = Color(0xFFEFF0FD);

  static const darkSurfaceContainer = Color(0xFF1B2236);
  static const darkSurfaceContainerHigh = Color(0xFF242E4A);
  static const darkSurfaceContainerHighest = Color(0xFF2D3B5C);
  static const darkSurfaceVariant = Color(0xFF2D3B5C);
  static const darkOnSurfaceVariant = Color(0xFFA5B2D0);

  static const darkOutline = Color(0xFF536285);
  static const darkOutlineVariant = Color(0xFF384563);

  /// Helper to get colors based on brightness state
  static Color getBackground(bool isDark) =>
      isDark ? darkBackground : background;
  static Color getOnBackground(bool isDark) =>
      isDark ? darkOnBackground : onBackground;
  static Color getSurface(bool isDark) => isDark ? darkSurface : surface;
  static Color getOnSurface(bool isDark) => isDark ? darkOnSurface : onSurface;
  static Color getSurfaceContainer(bool isDark) =>
      isDark ? darkSurfaceContainer : surfaceContainer;
  static Color getSurfaceContainerHigh(bool isDark) =>
      isDark ? darkSurfaceContainerHigh : surfaceContainerHigh;
  static Color getOnSurfaceVariant(bool isDark) =>
      isDark ? darkOnSurfaceVariant : onSurfaceVariant;
  static Color getOutline(bool isDark) => isDark ? darkOutline : outline;
  static Color getOutlineVariant(bool isDark) =>
      isDark ? darkOutlineVariant : outlineVariant;
}
