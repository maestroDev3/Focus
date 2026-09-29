import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/clock.dart';

void main() {
  group('dayOf', () {
    test('returns UTC midnight with the same calendar date', () {
      final day = dayOf(DateTime(2026, 9, 29, 14, 35, 12, 250));

      expect(day, DateTime.utc(2026, 9, 29));
      expect(day.isUtc, isTrue);
    });

    test('returns the same day for the first and last minute of a day', () {
      expect(
        dayOf(DateTime(2026, 9, 29, 0, 0)),
        dayOf(DateTime(2026, 9, 29, 23, 59)),
      );
    });

    test('returns different days across midnight', () {
      expect(
        dayOf(DateTime(2026, 9, 29, 23, 59)),
        isNot(dayOf(DateTime(2026, 9, 30, 0, 0))),
      );
    });

    test('keeps consecutive days exactly one day apart across DST', () {
      // Daylight saving time ends in Europe on 2026-10-25.
      final before = dayOf(DateTime(2026, 10, 25, 12));
      final after = dayOf(DateTime(2026, 10, 26, 12));

      expect(after.difference(before), const Duration(days: 1));
    });
  });

  group('Clock', () {
    test('can be injected as a fixed time', () {
      final now = DateTime(2026, 9, 29, 8, 30);
      DateTime fixed() => now;
      final Clock clock = fixed;

      expect(clock(), now);
    });
  });

  group('domain layer', () {
    test('does not import Flutter', () {
      final dartFiles = Directory('lib/domain')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      expect(dartFiles, isNotEmpty);
      for (final file in dartFiles) {
        expect(
          file.readAsStringSync(),
          isNot(contains('package:flutter')),
          reason: '${file.path} must stay pure Dart',
        );
      }
    });
  });
}
