import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/pomodoro.dart';
import '../domain/settings_repository.dart';

/// Stores settings as versioned JSON in shared preferences.
class SharedPreferencesSettingsRepository implements SettingsRepository {
  SharedPreferencesSettingsRepository(this._preferences);

  static const pomodoroKey = 'settings.pomodoro.v1';
  static const _version = 1;

  final SharedPreferences _preferences;

  @override
  Future<PomodoroSettings> loadPomodoro() async {
    final stored = _preferences.getString(pomodoroKey);
    if (stored == null) return const PomodoroSettings();
    final json = jsonDecode(stored);
    return switch (json) {
      {
        'v': _version,
        'focusMinutes': final int focus,
        'shortBreakMinutes': final int shortBreak,
        'longBreakMinutes': final int longBreak,
        'sessionsBeforeLongBreak': final int sessions,
      } =>
        PomodoroSettings(
          focus: Duration(minutes: focus),
          shortBreak: Duration(minutes: shortBreak),
          longBreak: Duration(minutes: longBreak),
          sessionsBeforeLongBreak: sessions,
        ).validate(),
      _ => throw FormatException('Unknown Pomodoro settings: $stored'),
    };
  }

  @override
  Future<void> savePomodoro(PomodoroSettings settings) async {
    await _preferences.setString(
      pomodoroKey,
      jsonEncode({
        'v': _version,
        'focusMinutes': settings.focus.inMinutes,
        'shortBreakMinutes': settings.shortBreak.inMinutes,
        'longBreakMinutes': settings.longBreak.inMinutes,
        'sessionsBeforeLongBreak': settings.sessionsBeforeLongBreak,
      }),
    );
  }
}
