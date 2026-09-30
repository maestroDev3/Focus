import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/daily_goal.dart';
import 'package:focus_timer/domain/focus_session.dart';
import 'package:focus_timer/domain/streak.dart';

void main() {
  final goal = DailyGoal.validated(60);
  final today = DateTime(2026, 9, 30, 20);

  /// One 60 minute session (goal reached) on each given day of September.
  List<FocusSession> reachedOn(List<int> days, {int minutes = 60}) => [
    for (final day in days)
      FocusSession(
        start: DateTime(2026, 9, day, 9),
        planned: Duration(minutes: minutes),
      ).complete(),
  ];

  group('currentStreak', () {
    test('counts the last days including today', () {
      expect(currentStreak(reachedOn([28, 29, 30]), goal, today: today), 3);
    });

    test('does not break before today is over', () {
      expect(currentStreak(reachedOn([28, 29]), goal, today: today), 2);
    });

    test('resets after a day without the goal', () {
      expect(
        currentStreak(reachedOn([26, 27, 29, 30]), goal, today: today),
        2,
      );
    });

    test('is zero when yesterday and today missed the goal', () {
      expect(currentStreak(reachedOn([27, 28]), goal, today: today), 0);
    });

    test('needs the full goal on a day', () {
      expect(
        currentStreak(reachedOn([29, 30], minutes: 59), goal, today: today),
        0,
      );
    });

    test('adds up several sessions of a day', () {
      final sessions = [
        ...reachedOn([30], minutes: 30),
        FocusSession(
          start: DateTime(2026, 9, 30, 14),
          planned: const Duration(minutes: 30),
        ).complete(),
      ];

      expect(currentStreak(sessions, goal, today: today), 1);
    });

    test('is not shifted by the end of daylight saving time', () {
      final autumn = [
        for (final day in [24, 25, 26])
          FocusSession(
            start: DateTime(2026, 10, day, 9),
            planned: const Duration(minutes: 60),
          ).complete(),
      ];

      expect(
        currentStreak(autumn, goal, today: DateTime(2026, 10, 26, 20)),
        3,
      );
    });
  });

  group('bestStreak', () {
    test('returns the longest run in the history', () {
      expect(bestStreak(reachedOn([1, 2, 5, 6, 7, 8, 20, 30]), goal), 4);
    });

    test('is zero without reached days', () {
      expect(bestStreak(const [], goal), 0);
    });
  });
}
