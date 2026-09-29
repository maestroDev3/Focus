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

    test('differs only in brightness between light and dark', () {
      expect(focusTheme(Brightness.light).brightness, Brightness.light);
      expect(focusTheme(Brightness.dark).brightness, Brightness.dark);
    });
  });

  group('focusTheme colors', () {
    test('uses the Noir & Champagne palette in dark mode', () {
      final colors = focusTheme(Brightness.dark).colorScheme;

      expect(colors.surface, const Color(0xFF0E0D0B));
      expect(colors.surfaceContainer, const Color(0xFF181613));
      expect(colors.outline, const Color(0xFF3A342B));
      expect(colors.onSurface, const Color(0xFFF2EDE4));
      expect(colors.onSurfaceVariant, const Color(0xFFA89F90));
      expect(colors.primary, const Color(0xFFC9A96E));
      expect(colors.onPrimary, const Color(0xFF14110C));
    });

    test('uses the Ivory palette in light mode', () {
      final colors = focusTheme(Brightness.light).colorScheme;

      expect(colors.surface, const Color(0xFFF6F1E8));
      expect(colors.surfaceContainer, const Color(0xFFFFFCF6));
      expect(colors.outline, const Color(0xFFDDD3C2));
      expect(colors.onSurface, const Color(0xFF1C1B19));
      expect(colors.onSurfaceVariant, const Color(0xFF6B645A));
      expect(colors.primary, const Color(0xFF8A6A32));
      expect(colors.onPrimary, const Color(0xFFFBF6EE));
    });

    for (final brightness in Brightness.values) {
      test('keeps text contrast at least 4.5:1 ($brightness)', () {
        final colors = focusTheme(brightness).colorScheme;

        expect(contrast(colors.onSurface, colors.surface), greaterThan(4.5));
        expect(
          contrast(colors.onSurfaceVariant, colors.surface),
          greaterThan(4.5),
        );
        expect(contrast(colors.onPrimary, colors.primary), greaterThan(4.5));
      });

      test('shapes buttons as tall pills ($brightness)', () {
        final theme = focusTheme(brightness);
        final styles = [
          theme.filledButtonTheme.style,
          theme.outlinedButtonTheme.style,
        ];

        for (final style in styles) {
          expect(style?.shape?.resolve({}), isA<StadiumBorder>());
          expect(style?.minimumSize?.resolve({})?.height, 56);
        }
      });
    }
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
        'assets/fonts/CormorantGaramond-Variable.ttf',
        'assets/fonts/Jost-Variable.ttf',
        'assets/fonts/OFL-CormorantGaramond.txt',
        'assets/fonts/OFL-Jost.txt',
      ]) {
        expect(File(path).existsSync(), isTrue, reason: '$path missing');
      }
    });
  });
}

/// WCAG contrast ratio between two colors.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (light, dark) = la > lb ? (la, lb) : (lb, la);
  return (light + 0.05) / (dark + 0.05);
}
