import 'dart:io';

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

  group('focusTheme typography', () {
    for (final brightness in Brightness.values) {
      test('uses Cormorant Garamond for display and headlines ($brightness)', () {
        final text = focusTheme(brightness).textTheme;
        final styles = [
          text.displayLarge,
          text.displayMedium,
          text.displaySmall,
          text.headlineLarge,
          text.headlineMedium,
          text.headlineSmall,
        ];

        for (final style in styles) {
          expect(style?.fontFamily, 'CormorantGaramond');
        }
      });

      test('uses Jost for titles, body and labels ($brightness)', () {
        final text = focusTheme(brightness).textTheme;
        final styles = [
          text.titleLarge,
          text.bodyLarge,
          text.bodyMedium,
          text.labelLarge,
        ];

        for (final style in styles) {
          expect(style?.fontFamily, 'Jost');
        }
      });
    }

    test('bundles both fonts with their licenses', () {
      for (final path in [
        'assets/fonts/CormorantGaramond[wght].ttf',
        'assets/fonts/Jost[wght].ttf',
        'assets/fonts/OFL-CormorantGaramond.txt',
        'assets/fonts/OFL-Jost.txt',
      ]) {
        expect(File(path).existsSync(), isTrue, reason: '$path missing');
      }
    });
  });
}
