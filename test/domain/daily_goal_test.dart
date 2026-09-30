import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/daily_goal.dart';
import 'package:focus_timer/domain/focus_session.dart';

void main() {
  final today = DateTime(2026, 9, 30, 20);
  FocusSession completedAt(int hour, {int minutes = 25, DateTime? day}) =>
      FocusSession(
        start: DateTime(
          (day ?? today).year,
          (day ?? today).month,
          (day ?? today).day,
          hour,
        ),
        planned: Duration(minutes: minutes),
      ).complete();

  group('DailyGoal', () {
    test('defaults to 120 minutes', () {
      expect(const DailyGoal().minutes, 120);
      expect(const DailyGoal().duration, const Duration(hours: 2));
    });

    test('accepts 10 to 720 minutes', () {
      expect(DailyGoal.validated(10).minutes, 10);
      expect(DailyGoal.validated(720).minutes, 720);
      expect(() => DailyGoal.validated(9), throwsArgumentError);
      expect(() => DailyGoal.validated(721), throwsArgumentError);
    });
  });

  group('focusedOn', () {
    test('sums completed and cancelled sessions of the day', () {
      final cancelled = FocusSession(
        start: DateTime(2026, 9, 30, 15),
        planned: const Duration(minutes: 25),
      ).cancel(DateTime(2026, 9, 30, 15, 10));

      expect(
        focusedOn(today, [completedAt(9), completedAt(11), cancelled]),
        const Duration(minutes: 60),
      );
    });

    test('ignores other days and running sessions', () {
      final yesterday = DateTime(2026, 9, 29);
      final running = FocusSession(
        start: DateTime(2026, 9, 30, 19, 50),
        planned: const Duration(minutes: 25),
      );

      expect(
        focusedOn(today, [completedAt(9, day: yesterday), running]),
        Duration.zero,
      );
    });
  });

  group('goalProgress', () {
    test('is the share of the goal reached', () {
      expect(
        goalProgress(const Duration(minutes: 60), const DailyGoal()),
        0.5,
      );
    });

    test('is capped at 1', () {
      expect(goalProgress(const Duration(hours: 5), const DailyGoal()), 1.0);
    });
  });

  group('DailyGoal.step', () {
    test('changes the goal in 10 minute steps within the limits', () {
      expect(const DailyGoal().step(up: true).minutes, 130);
      expect(const DailyGoal().step(up: false).minutes, 110);
      expect(DailyGoal.validated(10).step(up: false).minutes, 10);
      expect(DailyGoal.validated(720).step(up: true).minutes, 720);
    });
  });
}
