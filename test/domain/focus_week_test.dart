import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/focus_time.dart';
import 'package:focus_timer/domain/focus_week.dart';

void main() {
  group('FocusWeek', () {
    test('spreads a range over its weekdays', () {
      final week = FocusWeek.from([
        FocusTime(
          id: 'morning',
          weekdays: {DateTime.monday, DateTime.wednesday},
          startMinute: 9 * 60,
          endMinute: 12 * 60,
          blockListId: 'deep-work',
        ),
      ]);

      for (final weekday in [DateTime.monday, DateTime.wednesday]) {
        final entries = week.entriesOn(weekday);
        expect(entries, hasLength(1));
        expect(entries.single.focusTimeId, 'morning');
        expect(entries.single.blockListId, 'deep-work');
        expect(entries.single.startMinute, 9 * 60);
        expect(entries.single.endMinute, 12 * 60);
      }
      expect(week.entriesOn(DateTime.tuesday), isEmpty);
    });

    test('sorts a day by start, then end, then id', () {
      final week = FocusWeek.from([
        FocusTime(
          id: 'late',
          weekdays: {DateTime.friday},
          startMinute: 16 * 60,
          endMinute: 17 * 60,
        ),
        FocusTime(
          id: 'long',
          weekdays: {DateTime.friday},
          startMinute: 9 * 60,
          endMinute: 12 * 60,
        ),
        FocusTime(
          id: 'short',
          weekdays: {DateTime.friday},
          startMinute: 9 * 60,
          endMinute: 10 * 60,
        ),
      ]);

      expect(week.entriesOn(DateTime.friday).map((entry) => entry.focusTimeId), [
        'short',
        'long',
        'late',
      ]);
    });

    test('lays overlapping entries out in columns', () {
      final week = FocusWeek.from([
        FocusTime(
          id: 'first',
          weekdays: {DateTime.monday},
          startMinute: 9 * 60,
          endMinute: 11 * 60,
        ),
        FocusTime(
          id: 'second',
          weekdays: {DateTime.monday},
          startMinute: 10 * 60,
          endMinute: 12 * 60,
        ),
        FocusTime(
          id: 'alone',
          weekdays: {DateTime.monday},
          startMinute: 12 * 60,
          endMinute: 13 * 60,
        ),
      ]);

      final entries = week.entriesOn(DateTime.monday);
      final first = entries.singleWhere((e) => e.focusTimeId == 'first');
      final second = entries.singleWhere((e) => e.focusTimeId == 'second');
      final alone = entries.singleWhere((e) => e.focusTimeId == 'alone');
      expect(first.columns, 2);
      expect(second.columns, 2);
      expect(first.column, isNot(second.column));
      expect(alone.columns, 1);
      expect(alone.column, 0);
    });

    test('is empty without focus times', () {
      expect(FocusWeek.from(const []).isEmpty, isTrue);
      expect(
        FocusWeek.from([
          FocusTime(
            id: 'one',
            weekdays: {DateTime.monday},
            startMinute: 9 * 60,
            endMinute: 10 * 60,
          ),
        ]).isEmpty,
        isFalse,
      );
    });

    test('covers the entries with one padded hour, clamped to the day', () {
      final padded = FocusWeek.from([
        FocusTime(
          id: 'morning',
          weekdays: {DateTime.monday},
          startMinute: 9 * 60 + 30,
          endMinute: 12 * 60,
        ),
      ]);
      expect(padded.firstHour, 8);
      expect(padded.lastHour, 13);

      final clamped = FocusWeek.from([
        FocusTime(
          id: 'edges',
          weekdays: {DateTime.monday},
          startMinute: 0,
          endMinute: 60,
        ),
        FocusTime(
          id: 'night',
          weekdays: {DateTime.tuesday},
          startMinute: 23 * 60,
          endMinute: 24 * 60,
        ),
      ]);
      expect(clamped.firstHour, 0);
      expect(clamped.lastHour, 24);
    });

    test('falls back to office hours for an empty week', () {
      final week = FocusWeek.from(const []);

      expect(week.firstHour, 8);
      expect(week.lastHour, 18);
    });
  });

  group('FocusWeekNow', () {
    test('knows today and the minute of the day', () {
      // 2026-10-28 is a Wednesday.
      final now = FocusWeekNow.at(DateTime(2026, 10, 28, 9, 30));

      expect(now.weekday, DateTime.wednesday);
      expect(now.minuteOfDay, 9 * 60 + 30);
    });

    test('covers the edges of the day', () {
      expect(FocusWeekNow.at(DateTime(2026, 10, 28)).minuteOfDay, 0);
      expect(
        FocusWeekNow.at(DateTime(2026, 10, 28, 23, 59)).minuteOfDay,
        23 * 60 + 59,
      );
    });

    test('reports only the running entry active', () {
      final week = FocusWeek.from([
        FocusTime(
          id: 'morning',
          weekdays: {DateTime.wednesday},
          startMinute: 9 * 60,
          endMinute: 12 * 60,
        ),
      ]);
      final entry = week.entriesOn(DateTime.wednesday).single;

      expect(
        FocusWeekNow.at(DateTime(2026, 10, 28, 10)).isActive(entry),
        isTrue,
      );
      expect(
        FocusWeekNow.at(DateTime(2026, 10, 28, 12)).isActive(entry),
        isFalse,
      );
      // Same minutes, but a Tuesday.
      expect(
        FocusWeekNow.at(DateTime(2026, 10, 27, 10)).isActive(entry),
        isFalse,
      );
    });
  });

  group('suggestedFocusTimeRange', () {
    test('suggests the pressed full hour on that weekday', () {
      final range = suggestedFocusTimeRange(
        weekday: DateTime.tuesday,
        minuteOfDay: 9 * 60 + 25,
      );

      expect(range.weekdays, {DateTime.tuesday});
      expect(range.startMinute, 9 * 60);
      expect(range.endMinute, 10 * 60);
    });

    test('stays within the day near midnight', () {
      final range = suggestedFocusTimeRange(
        weekday: DateTime.sunday,
        minuteOfDay: 23 * 60 + 40,
      );

      expect(range.startMinute, 23 * 60);
      expect(range.endMinute, FocusTime.minutesPerDay);
      expect(
        range.endMinute - range.startMinute,
        greaterThanOrEqualTo(FocusTime.minLengthMinutes),
      );
    });
  });
}
