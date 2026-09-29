import 'package:flutter/material.dart';

/// The single calm accent color that both themes are derived from.
const focusSeedColor = Color(0xFF2F5D57);

/// Builds the Material 3 theme for [brightness] from [focusSeedColor], so
/// light and dark mode always share one consistent palette.
ThemeData focusTheme(Brightness brightness) => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: focusSeedColor,
    brightness: brightness,
  ),
);
