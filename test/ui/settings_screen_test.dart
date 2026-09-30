import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/pomodoro.dart';
import 'package:focus_timer/ui/settings_screen.dart';

import '../support/fake_settings_repository.dart';
import '../support/pump_app.dart';

void main() {
  group('SettingsScreen', () {
    Future<FakeSettingsRepository> pumpSettings(
      WidgetTester tester, [
      PomodoroSettings pomodoro = const PomodoroSettings(),
    ]) async {
      final repository = FakeSettingsRepository(pomodoro);
      await tester.pumpApp(SettingsScreen(settings: repository));
      await tester.pump();
      return repository;
    }

    testWidgets('shows the stored values', (tester) async {
      await pumpSettings(
        tester,
        const PomodoroSettings(
          focus: Duration(minutes: 50),
          shortBreak: Duration(minutes: 10),
          longBreak: Duration(minutes: 30),
          sessionsBeforeLongBreak: 3,
        ),
      );

      expect(find.text('50 min'), findsOneWidget);
      expect(find.text('10 min'), findsOneWidget);
      expect(find.text('30 min'), findsOneWidget);
      expect(find.text('3 sessions'), findsOneWidget);
    });

    testWidgets('increases the focus duration and saves it', (tester) async {
      final repository = await pumpSettings(tester);

      await tester.tap(find.byKey(const Key('focus-increase')));
      await tester.pump();

      expect(find.text('30 min'), findsOneWidget);
      expect(repository.pomodoro.focus, const Duration(minutes: 30));
    });

    testWidgets('does nothing below the minimum', (tester) async {
      final repository = await pumpSettings(
        tester,
        const PomodoroSettings(shortBreak: Duration(minutes: 1)),
      );

      await tester.tap(find.byKey(const Key('shortBreak-decrease')));
      await tester.pump();

      expect(find.text('1 min'), findsOneWidget);
      expect(repository.pomodoro.shortBreak, const Duration(minutes: 1));
    });

    testWidgets('labels the steppers for screen readers', (tester) async {
      await pumpSettings(tester);

      expect(find.byTooltip('Increase Focus'), findsOneWidget);
      expect(find.byTooltip('Decrease Long break after'), findsOneWidget);
    });
  });
}
