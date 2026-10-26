// SPDX-License-Identifier: GPL-3.0-or-later
// Smart Steps Tracker — a free and open-source step counter.

import 'package:flutter/material.dart';

/// Material 3 themes and the user-selectable accent palette.
///
/// The look follows the Flowstate design: a true-black canvas in dark mode
/// with translucent "glass" cards and hairline borders, light-weight display
/// numerals, semibold headlines, generous 24–32 dp corner radii and pill
/// shaped controls. Accent colours are applied the same way Flowstate does
/// it: the accent is lightened for dark mode and used as-is in light mode,
/// with a matching container colour and a cyan-shifted tertiary used by the
/// progress ring gradient.
class AppTheme {
  AppTheme._();

  /// Swatch of the monochrome look. Keep in sync with
  /// `UserProfile.defaultAccentColor`.
  static const Color graphite = Color(0xFF2B2B2B);

  static const Color defaultAccent = graphite;

  /// Flowstate's accent swatches plus Graphite (Stride's default) and the
  /// earlier Stride accents, so saved choices keep a visible swatch.
  static const Map<String, Color> accentColors = {
    'Graphite': graphite,
    'Violet': Color(0xFF6750A4),
    'Teal': Color(0xFF00796B),
    'Pink': Color(0xFFC2185B),
    'Green': Color(0xFF2E7D32),
    'Blue': Color(0xFF1565C0),
    'Orange': Color(0xFFEF6C00),
    'Red': Color(0xFFB3261E),
    'Cocoa': Color(0xFFB08968),
  };

  /// Corner radius shared by cards and the surfaces that echo them
  /// (Flowstate's GlassCard / `shapes.large`).
  static const double cardRadius = 28;

  /// Flowstate's shape scale.
  static const double radiusExtraSmall = 12;
  static const double radiusSmall = 16;
  static const double radiusMedium = 24;
  static const double radiusLarge = 28;
  static const double radiusExtraLarge = 32;

  /// Horizontal page padding used by every screen.
  static const double pagePadding = 20;

  /// Vertical gap between cards on a screen.
  static const double cardGap = 16;

  /// Space kept clear at the bottom of scrolling screens for the floating
  /// navigation bar.
  static const double navClearance = 136;

  /// Widest a screen's content gets on tablets, foldables and landscape.
  static const double maxContentWidth = 720;

  static bool _isGraphite(Color color) =>
      color.toARGB32() == graphite.toARGB32();

  static ThemeData light({
    Color seedColor = defaultAccent,
    ColorScheme? dynamicScheme,
  }) {
    final scheme = dynamicScheme ?? _accentScheme(seedColor, Brightness.light);
    return _build(scheme, Brightness.light);
  }

  /// Dark theme. Like Flowstate, the dark theme always keeps a black canvas
  /// with lifted surfaces for hierarchy. [amoledBlack] goes one step further
  /// and also turns the base surface pure black; without it the base surface
  /// is a very dark gray.
  static ThemeData dark({
    Color seedColor = defaultAccent,
    ColorScheme? dynamicScheme,
    bool amoledBlack = false,
  }) {
    final base = dynamicScheme ?? _accentScheme(seedColor, Brightness.dark);
    final scheme = base.copyWith(
      surface: amoledBlack ? Colors.black : const Color(0xFF0A0A0A),
      surfaceDim: Colors.black,
      surfaceBright: const Color(0xFF2A2A2A),
      surfaceContainerLowest: Colors.black,
      surfaceContainerLow: const Color(0xFF101010),
      surfaceContainer: const Color(0xFF202020),
      surfaceContainerHigh: const Color(0xFF2A2A2A),
      surfaceContainerHighest: const Color(0xFF2A2A2A),
      onSurfaceVariant: const Color(0xFFD0D0D0),
      outline: const Color(0xFF909090),
      outlineVariant: const Color(0xFF707070),
      surfaceTint: Colors.transparent,
    );
    return _build(scheme, Brightness.dark);
  }

  /// Flowstate's `accentScheme`: Material 3 roles generated from the accent,
  /// with the key accent roles set exactly as Flowstate sets them.
  static ColorScheme _accentScheme(Color accent, Brightness brightness) {
    final graphite = _isGraphite(accent);
    final base = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      dynamicSchemeVariant: graphite
          ? DynamicSchemeVariant.monochrome
          : DynamicSchemeVariant.tonalSpot,
    );
    if (brightness == Brightness.dark) {
      return base.copyWith(
        primary: Color.lerp(accent, Colors.white, graphite ? 0.9 : 0.45),
        onPrimary: Colors.black,
        primaryContainer: Color.lerp(accent,
            graphite ? Colors.white : Colors.black, graphite ? 0.12 : 0.45),
        onPrimaryContainer: Colors.white,
        secondary: Color.lerp(accent, Colors.white, 0.6),
        tertiary: Color.lerp(
            accent, graphite ? Colors.white : const Color(0xFF00E5FF), 0.5),
        surfaceTint: Colors.transparent,
      );
    }
    return base.copyWith(
      primary: graphite ? const Color(0xFF111111) : accent,
      onPrimary: Colors.white,
      primaryContainer: Color.lerp(accent, Colors.white, 0.82),
      onPrimaryContainer: Color.lerp(accent, Colors.black, 0.6),
      secondary: Color.lerp(accent, Colors.black, 0.2),
      tertiary: Color.lerp(
          accent, graphite ? Colors.black : const Color(0xFF00B8D4), 0.5),
      surfaceTint: Colors.transparent,
    );
  }

  /// Flowstate typography: Roboto (the platform sans-serif) with light
  /// display numerals, semibold headlines and a medium title.
  static TextTheme _textTheme(ColorScheme scheme) {
    final base =
        ThemeData(useMaterial3: true, colorScheme: scheme).textTheme.apply(
              bodyColor: scheme.onSurface,
              displayColor: scheme.onSurface,
            );
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w300,
        fontSize: 64,
        height: 68 / 64,
        letterSpacing: -1.5,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontWeight: FontWeight.w300,
        fontSize: 48,
        height: 52 / 48,
        letterSpacing: -1,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 36,
        height: 42 / 36,
        letterSpacing: 0,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 28,
        height: 34 / 28,
        letterSpacing: 0,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 22,
        height: 28 / 22,
      ),
    );
  }

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final textTheme = _textTheme(scheme);
    final hairline = BorderSide(
      color: dark
          ? scheme.outlineVariant
          : scheme.outlineVariant.withValues(alpha: 0.35),
    );
    final background = dark ? Colors.black : scheme.surface;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainer.withValues(alpha: dark ? 0.96 : 0.78),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: hairline,
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusExtraLarge),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(radiusExtraLarge)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: textTheme.titleSmall,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outline),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          selectedForegroundColor: scheme.onSecondaryContainer,
          selectedBackgroundColor: scheme.secondaryContainer,
          side: BorderSide(color: scheme.outline),
          shape: const StadiumBorder(),
          minimumSize: const Size(0, 44),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: Colors.transparent,
        selectedColor: scheme.secondaryContainer,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        iconColor: scheme.onSurfaceVariant,
      ),
      sliderTheme: SliderThemeData(
        inactiveTrackColor: scheme.secondaryContainer,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor:
            dark ? scheme.surfaceContainerHighest : scheme.secondaryContainer,
        linearMinHeight: 10,
        borderRadius: BorderRadius.circular(5),
      ),
      dividerTheme: DividerThemeData(
        color: dark
            ? scheme.outlineVariant.withValues(alpha: 0.6)
            : scheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        indicatorColor: scheme.primaryContainer,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(radiusExtraSmall),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
  }
}
