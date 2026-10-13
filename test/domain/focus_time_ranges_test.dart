import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/focus_time.dart';

void main() {
  // Mon, Tue, Wed, Fri 07:00–10:00 and Sat 07:00–12:00.
  final morning = FocusTime.withRanges(
    id: 'focus-time-1',
    ranges: [
      FocusTimeRange(weekdays: const {1, 2, 3, 5}, startMinute: 420, endMinute: 600),
      FocusTimeRange(weekdays: const {6}, startMinute: 420, endMinute: 720),
    ],
  );
  // 2026-10-16 is a Friday, 2026-10-17 a Saturday.
  final friday11 = DateTime(2026, 10, 16, 11);
  final saturday11 = DateTime(2026, 10, 17, 11);

  group('FocusTime with several ranges', () {
    test('is active in each of its ranges', () {
      expect(morning.isActiveAt(DateTime(2026, 10, 16, 8)), isTrue);
      expect(morning.isActiveAt(saturday11), isTrue);
      expect(morning.isActiveAt(friday11), isFalse);
      expect(morning.isActiveAt(DateTime(2026, 10, 15, 8)), isFalse);
    });

    test('names the range that runs', () {
      expect(morning.activeRange(saturday11)?.endMinute, 720);
      expect(morning.activeRange(DateTime(2026, 10, 16, 8))?.endMinute, 600);
      expect(morning.activeRange(friday11), isNull);
    });

    test('keeps the one-range shortcut', () {
      final time = FocusTime(
        id: 'focus-time-2',
        weekdays: const {1},
        startMinute: 540,
        endMinute: 720,
      );

      expect(time.ranges, [
        FocusTimeRange(weekdays: const {1}, startMinute: 540, endMinute: 720),
      ]);
    });

    test('needs at least one range', () {
      expect(
        () => FocusTime.withRanges(id: 'x', ranges: const []),
        throwsArgumentError,
      );
    });

    test('rejects ranges that overlap each other', () {
      expect(
        () => FocusTime.withRanges(
          id: 'x',
          ranges: [
            FocusTimeRange(weekdays: const {6}, startMinute: 420, endMinute: 720),
            FocusTimeRange(weekdays: const {6, 7}, startMinute: 600, endMinute: 660),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group('across focus times', () {
    test('finds an overlap in any pair of ranges', () {
      final saturdayNoon = FocusTime(
        id: 'focus-time-3',
        weekdays: const {6},
        startMinute: 660,
        endMinute: 780,
      );
      final thursday = FocusTime(
        id: 'focus-time-4',
        weekdays: const {4},
        startMinute: 420,
        endMinute: 600,
      );

      expect(overlaps(morning, saturdayNoon), isTrue);
      expect(overlaps(morning, thursday), isFalse);
    });

    test('the active focus time is found by any range', () {
      expect(activeFocusTime([morning], saturday11), morning);
      expect(activeFocusTime([morning], friday11), isNull);
    });

    test('the next start is the next range start', () {
      expect(
        nextFocusTimeStart([morning], friday11),
        DateTime(2026, 10, 17, 7),
      );
    });
  });
}
