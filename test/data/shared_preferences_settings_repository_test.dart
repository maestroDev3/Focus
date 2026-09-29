import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/shared_preferences_settings_repository.dart';
import 'package:focus_timer/domain/pomodoro.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesSettingsRepository', () {
    test('returns the defaults without stored data', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = SharedPreferencesSettingsRepository(
        await SharedPreferences.getInstance(),
      );

      expect(await repository.loadPomodoro(), const PomodoroSettings());
    });

    test('loads saved settings in a new instance', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      const custom = PomodoroSettings(
        focus: Duration(minutes: 50),
        shortBreak: Duration(minutes: 10),
        longBreak: Duration(minutes: 30),
        sessionsBeforeLongBreak: 3,
      );

      await SharedPreferencesSettingsRepository(preferences).savePomodoro(custom);

      expect(
        await SharedPreferencesSettingsRepository(preferences).loadPomodoro(),
        custom,
      );
    });

    test('rejects an unknown stored version', () async {
      SharedPreferences.setMockInitialValues({
        'settings.pomodoro.v1': '{"v":2}',
      });
      final repository = SharedPreferencesSettingsRepository(
        await SharedPreferences.getInstance(),
      );

      expect(repository.loadPomodoro(), throwsFormatException);
    });
  });
}
