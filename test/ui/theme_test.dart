import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/ui/theme.dart';

void main() {
  group('focusTheme', () {
    test('uses Material 3 in light and dark', () {
      expect(focusTheme(Brightness.light).useMaterial3, isTrue);
      expect(focusTheme(Brightness.dark).useMaterial3, isTrue);
    });

    test('derives light and dark from the same seed color', () {
      for (final brightness in Brightness.values) {
        expect(
          focusTheme(brightness).colorScheme,
          ColorScheme.fromSeed(
            seedColor: focusSeedColor,
            brightness: brightness,
          ),
        );
      }
    });

    test('differs only in brightness between light and dark', () {
      expect(focusTheme(Brightness.light).brightness, Brightness.light);
      expect(focusTheme(Brightness.dark).brightness, Brightness.dark);
    });
  });
}
