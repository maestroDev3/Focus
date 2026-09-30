import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/clock.dart';
import 'package:focus_timer/domain/focus_session.dart';
import 'package:focus_timer/domain/statistics.dart';

void main() {
  FocusSession completed(DateTime start, {int minutes = 25}) => FocusSession(
    start: start,
    planned: Duration(minutes: minutes),
  ).complete();

  group('focusByDay', () {
    test('sums focus per day and keeps empty days at zero', () {
      final sessions = [
        completed(DateTime(2026, 9, 28, 9)),
        completed(DateTime(2026, 9, 28, 11)),
        completed(DateTime(2026, 9, 30, 9), minutes: 50),
      ];

      expect(
        focusByDay(
          sessions,
          from: DateTime(2026, 9, 28),
          to: DateTime(2026, 9, 30),
        ),
        {
          dayOf(DateTime(2026, 9, 28)): const Duration(minutes: 50),
          dayOf(DateTime(2026, 9, 29)): Duration.zero,
          dayOf(DateTime(2026, 9, 30)): const Duration(minutes: 50),
        },
      );
    });

    test('counts a session for the day it ended', () {
      final lateNight = completed(DateTime(2026, 9, 29, 23, 50));

      final days = focusByDay(
        [lateNight],
        from: DateTime(2026, 9, 29),
        to: DateTime(2026, 9, 30),
      );

      expect(days[dayOf(DateTime(2026, 9, 29))], Duration.zero);
      expect(days[dayOf(DateTime(2026, 9, 30))], const Duration(minutes: 25));
    });

    test('ignores running sessions', () {
      final running = FocusSession(
        start: DateTime(2026, 9, 30, 9),
        planned: const Duration(minutes: 25),
      );

      expect(
        focusByDay(
          [running],
          from: DateTime(2026, 9, 30),
          to: DateTime(2026, 9, 30),
        ).values.single,
        Duration.zero,
      );
    });
  });

  group('weekFocus', () {
    test('covers Monday to Sunday of the current week', () {
      final sessions = [
        completed(DateTime(2026, 9, 27, 9)),
        completed(DateTime(2026, 9, 28, 9)),
        completed(DateTime(2026, 10, 4, 9)),
        completed(DateTime(2026, 10, 5, 9)),
      ];

      final week = weekFocus(sessions, today: DateTime(2026, 9, 30, 12));

      expect(week, hasLength(7));
      expect(week.first, const Duration(minutes: 25));
      expect(week.last, const Duration(minutes: 25));
      expect(week.sublist(1, 6), everyElement(Duration.zero));
    });

    test('starts the week on Monday', () {
      final monday = dayOf(DateTime(2026, 9, 28));

      expect(weekStart(DateTime(2026, 9, 30, 12)), monday);
      expect(weekStart(DateTime(2026, 10, 4, 23)), monday);
      expect(weekStart(DateTime(2026, 9, 28)), monday);
    });
  });
}
