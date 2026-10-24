// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'package:flutter/material.dart';

/// Material 3 themes and the user-selectable accent palette.
///
/// The default "Graphite" accent gives the app its monochrome look: near-white
/// canvas, soft gray cards with thin outlines, black actions and a dark pill
/// for the selected navigation item. Every other accent keeps the same shapes
/// and typography with a tinted palette.
class AppTheme {
  AppTheme._();

  /// Swatch of the monochrome look. Keep in sync with
  /// `UserProfile.defaultAccentColor`.
  static const Color graphite = Color(0xFF2B2B2B);

  static const Color defaultAccent = graphite;

  static const Map<String, Color> accentColors = {
    'Graphite': graphite,
    'Violet': Color(0xFF6750A4),
    'Red': Color(0xFFB3261E),
    'Amber': Color(0xFF985900),
    'Cocoa': Color(0xFFB08968),
    'Green': Color(0xFF2E6B4F),
    'Teal': Color(0xFF007C83),
    'Blue': Color(0xFF1565C0),
  };

  /// Corner radius shared by cards and the surfaces that echo them.
  static const double cardRadius = 28;

  static bool _isGraphite(Color color) =>
      color.toARGB32() == graphite.toARGB32();

  static ThemeData light({
    Color seedColor = defaultAccent,
    ColorScheme? dynamicScheme,
  }) {
    final scheme = dynamicScheme ??
        (_isGraphite(seedColor)
            ? _graphiteScheme(Brightness.light)
            : ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.light,
              ));
    return _build(scheme, Brightness.light);
  }

  static ThemeData dark({
    Color seedColor = defaultAccent,
    ColorScheme? dynamicScheme,
    bool amoledBlack = false,
  }) {
    var scheme = dynamicScheme ??
        (_isGraphite(seedColor)
            ? _graphiteScheme(Brightness.dark)
            : ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.dark,
              ));
    if (amoledBlack) {
      scheme = scheme.copyWith(
        surface: Colors.black,
        surfaceDim: Colors.black,
        surfaceBright: Colors.black,
        surfaceContainerLowest: Colors.black,
        surfaceContainerLow: Colors.black,
        surfaceContainer: Colors.black,
        surfaceContainerHigh: Colors.black,
        surfaceContainerHighest: Colors.black,
      );
    }
    return _build(scheme, Brightness.dark);
  }

  /// Pure grayscale palette, tuned by hand on top of Flutter's monochrome
  /// scheme so surfaces, outlines and the inverse (dark pill) colours match
  /// the design rather than the generated tones.
  static ColorScheme _graphiteScheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: graphite,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
    );
    if (brightness == Brightness.light) {
      return base.copyWith(
        primary: const Color(0xFF111111),
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFD9D9D9),
        onPrimaryContainer: const Color(0xFF111111),
        secondary: const Color(0xFF3A3A3A),
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFDCDCDC),
        onSecondaryContainer: const Color(0xFF111111),
        surface: const Color(0xFFFAFAFA),
        onSurface: const Color(0xFF111111),
        onSurfaceVariant: const Color(0xFF5E5E5E),
        surfaceDim: const Color(0xFFEDEDED),
        surfaceBright: Colors.white,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFF6F6F6),
        surfaceContainer: const Color(0xFFF1F1F1),
        surfaceContainerHigh: const Color(0xFFEBEBEB),
        surfaceContainerHighest: const Color(0xFFE3E3E3),
        outline: const Color(0xFF777777),
        outlineVariant: const Color(0xFFD8D8D8),
        inverseSurface: const Color(0xFF3A3A3A),
        onInverseSurface: const Color(0xFFF5F5F5),
        inversePrimary: const Color(0xFFD9D9D9),
        surfaceTint: Colors.transparent,
      );
    }
    return base.copyWith(
      primary: const Color(0xFFF2F2F2),
      onPrimary: const Color(0xFF111111),
      primaryContainer: const Color(0xFF3A3A3A),
      onPrimaryContainer: const Color(0xFFF2F2F2),
      secondary: const Color(0xFFD0D0D0),
      onSecondary: const Color(0xFF111111),
      secondaryContainer: const Color(0xFF383838),
      onSecondaryContainer: const Color(0xFFF2F2F2),
      surface: const Color(0xFF111111),
      onSurface: const Color(0xFFF2F2F2),
      onSurfaceVariant: const Color(0xFFA8A8A8),
      surfaceDim: const Color(0xFF0B0B0B),
      surfaceBright: const Color(0xFF2A2A2A),
      surfaceContainerLowest: const Color(0xFF0B0B0B),
      surfaceContainerLow: const Color(0xFF161616),
      surfaceContainer: const Color(0xFF1B1B1B),
      surfaceContainerHigh: const Color(0xFF232323),
      surfaceContainerHighest: const Color(0xFF2C2C2C),
      outline: const Color(0xFF8A8A8A),
      outlineVariant: const Color(0xFF3A3A3A),
      inverseSurface: const Color(0xFFEDEDED),
      onInverseSurface: const Color(0xFF111111),
      inversePrimary: const Color(0xFF3A3A3A),
      surfaceTint: Colors.transparent,
    );
  }

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final outline = BorderSide(color: scheme.outlineVariant);
    final baseText = Typography.englishLike2018.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final textTheme = baseText.copyWith(
      headlineLarge: baseText.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
      ),
      headlineMedium: baseText.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
      headlineSmall: baseText.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      titleMedium: baseText.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: outline,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: scheme.onSurface,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          selectedForegroundColor: scheme.onSecondaryContainer,
          selectedBackgroundColor: scheme.secondaryContainer,
          side: BorderSide(color: scheme.outline),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: outline,
        backgroundColor: Colors.transparent,
        selectedColor: scheme.secondaryContainer,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
      ),
      textTheme: textTheme,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
  }
}
