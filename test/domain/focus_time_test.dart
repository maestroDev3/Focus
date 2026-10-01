import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/focus_time.dart';

void main() {
  const weekdays = {1, 2, 3, 4, 5};
  FocusTime morning({String id = 'a', Set<int> days = weekdays}) => FocusTime(
    id: id,
    weekdays: days,
    startMinute: 9 * 60,
    endMinute: 12 * 60,
  );

  // 2026-09-30 is a Wednesday, 2026-10-02 a Friday, 2026-10-03 a Saturday.
  DateTime wednesday(int hour, [int minute = 0]) =>
      DateTime(2026, 9, 30, hour, minute);

  group('FocusTime', () {
    test('rejects an end before the start', () {
      expect(
        () => FocusTime(
          id: 'a',
          weekdays: weekdays,
          startMinute: 600,
          endMinute: 540,
        ),
        throwsArgumentError,
      );
    });

    test('rejects focus times without weekday or shorter than 15 minutes', () {
      expect(
        () => FocusTime(
          id: 'a',
          weekdays: const {},
          startMinute: 540,
          endMinute: 720,
        ),
        throwsArgumentError,
      );
      expect(
        () => FocusTime(
          id: 'a',
          weekdays: weekdays,
          startMinute: 540,
          endMinute: 554,
        ),
        throwsArgumentError,
      );
      expect(
        () => FocusTime(
          id: 'a',
          weekdays: const {8},
          startMinute: 540,
          endMinute: 720,
        ),
        throwsArgumentError,
      );
    });
  });

  group('activeFocusTime', () {
    test('finds the focus time running now', () {
      expect(activeFocusTime([morning()], wednesday(10)), morning());
    });

    test('is null at the end, before the start and on other days', () {
      expect(activeFocusTime([morning()], wednesday(12)), isNull);
      expect(activeFocusTime([morning()], wednesday(8, 59)), isNull);
      expect(activeFocusTime([morning()], DateTime(2026, 10, 3, 10)), isNull);
    });
  });

  group('nextFocusTimeStart', () {
    test('is later today before the start', () {
      expect(nextFocusTimeStart([morning()], wednesday(8)), wednesday(9));
    });

    test('skips the weekend', () {
      expect(
        nextFocusTimeStart([morning()], DateTime(2026, 10, 2, 13)),
        DateTime(2026, 10, 5, 9),
      );
    });

    test('is null without focus times', () {
      expect(nextFocusTimeStart(const [], wednesday(8)), isNull);
    });
  });

  group('overlaps', () {
    test('needs a shared weekday and intersecting times', () {
      FocusTime at(int start, int end, Set<int> days) => FocusTime(
        id: 'b',
        weekdays: days,
        startMinute: start,
        endMinute: end,
      );

      expect(overlaps(morning(), at(11 * 60, 13 * 60, {3})), isTrue);
      expect(overlaps(morning(), at(12 * 60, 13 * 60, {3})), isFalse);
      expect(overlaps(morning(), at(10 * 60, 11 * 60, {6, 7})), isFalse);
    });
  });
}
