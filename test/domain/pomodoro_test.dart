import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/pomodoro.dart';

void main() {
  const defaults = PomodoroSettings();

  group('PomodoroSettings', () {
    test('defaults to 25 / 5 / 15 minutes and 4 sessions', () {
      expect(defaults.focus, const Duration(minutes: 25));
      expect(defaults.shortBreak, const Duration(minutes: 5));
      expect(defaults.longBreak, const Duration(minutes: 15));
      expect(defaults.sessionsBeforeLongBreak, 4);
    });

    test('rejects durations below one minute', () {
      expect(
        () => PomodoroSettings(focus: const Duration(seconds: 59)).validate(),
        throwsArgumentError,
      );
      expect(
        () => defaults.copyWith(shortBreak: Duration.zero),
        throwsArgumentError,
      );
      expect(
        () => defaults.copyWith(longBreak: const Duration(seconds: 30)),
        throwsArgumentError,
      );
    });

    test('rejects fewer than one session before a long break', () {
      expect(
        () => defaults.copyWith(sessionsBeforeLongBreak: 0),
        throwsArgumentError,
      );
    });

    test('copies with changed values', () {
      final changed = defaults.copyWith(focus: const Duration(minutes: 50));

      expect(changed.focus, const Duration(minutes: 50));
      expect(changed.shortBreak, defaults.shortBreak);
      expect(changed, isNot(defaults));
      expect(changed, defaults.copyWith(focus: const Duration(minutes: 50)));
    });
  });

  group('breakAfter', () {
    BreakKind after(int completed, [PomodoroSettings settings = defaults]) =>
        breakAfter(completedToday: completed, settings: settings);

    test('is short after the first three sessions and long after the 4th', () {
      expect(after(1), BreakKind.short);
      expect(after(2), BreakKind.short);
      expect(after(3), BreakKind.short);
      expect(after(4), BreakKind.long);
    });

    test('starts a new cycle after a long break', () {
      expect(after(5), BreakKind.short);
      expect(after(8), BreakKind.long);
    });

    test('follows a custom number of sessions', () {
      final settings = defaults.copyWith(sessionsBeforeLongBreak: 2);

      expect(after(1, settings), BreakKind.short);
      expect(after(2, settings), BreakKind.long);
      expect(after(3, settings), BreakKind.short);
      expect(after(4, settings), BreakKind.long);
    });
  });

  group('breakDuration', () {
    test('returns the configured short or long duration', () {
      expect(
        breakDuration(BreakKind.short, defaults),
        const Duration(minutes: 5),
      );
      expect(
        breakDuration(BreakKind.long, defaults),
        const Duration(minutes: 15),
      );
    });
  });

  group('PomodoroSettings.step', () {
    test('changes the focus duration in 5 minute steps', () {
      expect(
        defaults.step(PomodoroField.focus, up: true).focus,
        const Duration(minutes: 30),
      );
      expect(
        defaults.step(PomodoroField.focus, up: false).focus,
        const Duration(minutes: 20),
      );
    });

    test('changes breaks by one minute and sessions by one', () {
      expect(
        defaults.step(PomodoroField.shortBreak, up: true).shortBreak,
        const Duration(minutes: 6),
      );
      expect(
        defaults.step(PomodoroField.longBreak, up: false).longBreak,
        const Duration(minutes: 14),
      );
      expect(
        defaults
            .step(PomodoroField.sessionsBeforeLongBreak, up: true)
            .sessionsBeforeLongBreak,
        5,
      );
    });

    test('goes from 5 minutes focus down to the 1 minute minimum', () {
      final five = defaults.copyWith(focus: const Duration(minutes: 5));

      expect(
        five.step(PomodoroField.focus, up: false).focus,
        const Duration(minutes: 1),
      );
    });

    test('stays within the limits', () {
      final minimum = defaults.copyWith(
        focus: const Duration(minutes: 1),
        shortBreak: const Duration(minutes: 1),
        sessionsBeforeLongBreak: 2,
      );
      final maximum = defaults.copyWith(
        focus: const Duration(minutes: 180),
        longBreak: const Duration(minutes: 60),
        sessionsBeforeLongBreak: 8,
      );

      expect(minimum.step(PomodoroField.focus, up: false), minimum);
      expect(minimum.step(PomodoroField.shortBreak, up: false), minimum);
      expect(
        minimum.step(PomodoroField.sessionsBeforeLongBreak, up: false),
        minimum,
      );
      expect(maximum.step(PomodoroField.focus, up: true), maximum);
      expect(maximum.step(PomodoroField.longBreak, up: true), maximum);
      expect(
        maximum.step(PomodoroField.sessionsBeforeLongBreak, up: true),
        maximum,
      );
    });
  });

  group('PomodoroSettings.withValue', () {
    test('sets the field to the typed value', () {
      expect(
        defaults.withValue(PomodoroField.focus, 2).focus,
        const Duration(minutes: 2),
      );
      expect(
        defaults.withValue(PomodoroField.longBreak, 25).longBreak,
        const Duration(minutes: 25),
      );
      expect(
        defaults
            .withValue(PomodoroField.sessionsBeforeLongBreak, 6)
            .sessionsBeforeLongBreak,
        6,
      );
    });

    test('clamps values outside the limits', () {
      expect(
        defaults.withValue(PomodoroField.focus, 500).focus,
        const Duration(minutes: 180),
      );
      expect(
        defaults.withValue(PomodoroField.shortBreak, 0).shortBreak,
        const Duration(minutes: 1),
      );
      expect(
        defaults
            .withValue(PomodoroField.sessionsBeforeLongBreak, 1)
            .sessionsBeforeLongBreak,
        2,
      );
    });
  });
}
