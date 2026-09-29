import 'package:flutter/material.dart';

/// Elegant serif for large numbers and headings.
const displayFontFamily = 'CormorantGaramond';

/// Clean geometric sans for all other text.
const textFontFamily = 'Jost';

/// Builds the Material 3 theme for [brightness]: “Noir & Champagne” in dark
/// mode and its “Ivory” counterpart in light mode, sharing one typography.
ThemeData focusTheme(Brightness brightness) {
  final colors = switch (brightness) {
    Brightness.dark => _noir,
    Brightness.light => _ivory,
  };
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: textFontFamily,
    colorScheme: colors,
    scaffoldBackgroundColor: colors.surface,
  );
  final buttonStyle = ButtonStyle(
    shape: const WidgetStatePropertyAll(StadiumBorder()),
    minimumSize: const WidgetStatePropertyAll(Size(64, 56)),
    textStyle: const WidgetStatePropertyAll(
      TextStyle(
        fontFamily: textFontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: 2,
      ),
    ),
  );

  return base.copyWith(
    textTheme: _withDisplayFont(base.textTheme),
    filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: buttonStyle.copyWith(
        side: WidgetStatePropertyAll(BorderSide(color: colors.outline)),
      ),
    ),
  );
}

/// Deep warm black with champagne gold as the single accent.
final _noir = _palette(
  brightness: Brightness.dark,
  surface: const Color(0xFF0E0D0B),
  container: const Color(0xFF181613),
  outline: const Color(0xFF3A342B),
  onSurface: const Color(0xFFF2EDE4),
  onSurfaceVariant: const Color(0xFFA89F90),
  primary: const Color(0xFFC9A96E),
  onPrimary: const Color(0xFF14110C),
);

/// Warm ivory paper with a deeper gold that stays readable on light ground.
final _ivory = _palette(
  brightness: Brightness.light,
  surface: const Color(0xFFF6F1E8),
  container: const Color(0xFFFFFCF6),
  outline: const Color(0xFFDDD3C2),
  onSurface: const Color(0xFF1C1B19),
  onSurfaceVariant: const Color(0xFF6B645A),
  primary: const Color(0xFF8A6A32),
  onPrimary: const Color(0xFFFBF6EE),
);

/// Starts from a scheme seeded with [primary] for the less visible roles and
/// pins every role the design specifies.
ColorScheme _palette({
  required Brightness brightness,
  required Color surface,
  required Color container,
  required Color outline,
  required Color onSurface,
  required Color onSurfaceVariant,
  required Color primary,
  required Color onPrimary,
}) {
  return ColorScheme.fromSeed(
    seedColor: primary,
    brightness: brightness,
  ).copyWith(
    primary: primary,
    onPrimary: onPrimary,
    surface: surface,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceVariant,
    surfaceContainerLowest: surface,
    surfaceContainerLow: container,
    surfaceContainer: container,
    surfaceContainerHigh: container,
    surfaceContainerHighest: container,
    outline: outline,
    outlineVariant: outline,
  );
}

/// Switches the display and headline styles to the light serif face.
TextTheme _withDisplayFont(TextTheme text) {
  TextStyle? serif(TextStyle? style) => style?.copyWith(
    fontFamily: displayFontFamily,
    fontWeight: FontWeight.w300,
    fontVariations: const [FontVariation.weight(300)],
  );

  return text.copyWith(
    displayLarge: serif(text.displayLarge),
    displayMedium: serif(text.displayMedium),
    displaySmall: serif(text.displaySmall),
    headlineLarge: serif(text.headlineLarge),
    headlineMedium: serif(text.headlineMedium),
    headlineSmall: serif(text.headlineSmall),
  );
}
