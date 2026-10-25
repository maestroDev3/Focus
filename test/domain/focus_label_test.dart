import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/focus_label.dart';

void main() {
  group('FocusLabel', () {
    test('trims the name', () {
      expect(FocusLabel(id: 'l1', name: '  Study ').name, 'Study');
    });

    test('rejects empty names', () {
      expect(() => FocusLabel(id: 'l1', name: '   '), throwsArgumentError);
    });

    test('rejects names longer than 30 characters', () {
      expect(FocusLabel(id: 'l1', name: 'a' * 30).name, hasLength(30));
      expect(() => FocusLabel(id: 'l1', name: 'a' * 31), throwsArgumentError);
    });

    test('compares by id and name', () {
      expect(
        FocusLabel(id: 'l1', name: 'Study'),
        FocusLabel(id: 'l1', name: 'Study'),
      );
      expect(
        FocusLabel(id: 'l1', name: 'Study'),
        isNot(FocusLabel(id: 'l2', name: 'Study')),
      );
    });

    test('has no goal by default', () {
      expect(FocusLabel(id: 'l1', name: 'Study').goal, isNull);
    });

    test('accepts a goal of 1 to 999 whole hours', () {
      expect(
        FocusLabel(id: 'l1', name: 'Exam', goal: const Duration(hours: 1)).goal,
        const Duration(hours: 1),
      );
      expect(
        FocusLabel(
          id: 'l1',
          name: 'Exam',
          goal: const Duration(hours: 999),
        ).goal,
        const Duration(hours: 999),
      );
    });

    test('rejects goals outside 1–999 hours or not in whole hours', () {
      for (final goal in const [
        Duration.zero,
        Duration(hours: 1000),
        Duration(minutes: 90),
      ]) {
        expect(
          () => FocusLabel(id: 'l1', name: 'Exam', goal: goal),
          throwsArgumentError,
        );
      }
    });

    test('sets and clears the goal, keeping id and name', () {
      final label = FocusLabel(id: 'l1', name: 'Exam');

      final withGoal = label.withGoal(const Duration(hours: 20));

      expect(withGoal.goal, const Duration(hours: 20));
      expect(withGoal.name, 'Exam');
      expect(withGoal.withGoal(null).goal, isNull);
    });

    test('compares the goal too', () {
      expect(
        FocusLabel(id: 'l1', name: 'Exam', goal: const Duration(hours: 20)),
        isNot(FocusLabel(id: 'l1', name: 'Exam')),
      );
    });

    test('accepts a weekly goal of 1 to 168 whole hours', () {
      final label = FocusLabel(
        id: 'l1',
        name: 'Uni',
        weeklyGoal: const Duration(hours: 5),
      );

      expect(label.weeklyGoal, const Duration(hours: 5));
      for (final goal in const [
        Duration.zero,
        Duration(hours: 169),
        Duration(minutes: 90),
      ]) {
        expect(
          () => FocusLabel(id: 'l1', name: 'Uni', weeklyGoal: goal),
          throwsArgumentError,
        );
      }
    });

    test('sets the weekly goal independently of the total goal', () {
      final label = FocusLabel(
        id: 'l1',
        name: 'Uni',
        goal: const Duration(hours: 20),
      ).withWeeklyGoal(const Duration(hours: 5));

      expect(label.goal, const Duration(hours: 20));
      expect(label.weeklyGoal, const Duration(hours: 5));
      expect(label.withGoal(null).weeklyGoal, const Duration(hours: 5));
      expect(label.withWeeklyGoal(null).weeklyGoal, isNull);
      expect(label, isNot(label.withWeeklyGoal(null)));
    });
  });
}
