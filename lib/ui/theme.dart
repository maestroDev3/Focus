import 'package:flutter/material.dart';

/// The single calm accent color that both themes are derived from.
const focusSeedColor = Color(0xFF2F5D57);

/// Elegant serif for large numbers and headings.
const displayFontFamily = 'CormorantGaramond';

/// Clean geometric sans for all other text.
const textFontFamily = 'Jost';

/// Builds the Material 3 theme for [brightness], so light and dark mode
/// always share one consistent palette and typography.
ThemeData focusTheme(Brightness brightness) {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: textFontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: focusSeedColor,
      brightness: brightness,
    ),
  );
  return base.copyWith(textTheme: _withDisplayFont(base.textTheme));
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
