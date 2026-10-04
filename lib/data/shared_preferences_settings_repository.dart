import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/daily_goal.dart';
import '../domain/pomodoro.dart';
import '../domain/settings_repository.dart';

/// Stores settings as versioned JSON in shared preferences.
class SharedPreferencesSettingsRepository implements SettingsRepository {
  SharedPreferencesSettingsRepository(this._preferences);

  static const pomodoroKey = 'settings.pomodoro.v1';
  static const selectedLabelKey = 'settings.selectedLabel.v1';
  static const dailyGoalKey = 'settings.goal.v1';

  /// Read by the native countdown as `flutter.settings.lockScreen.v1`.
  static const lockScreenKey = 'settings.lockScreen.v1';
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

  @override
  Future<String?> loadSelectedLabelId() async =>
      _preferences.getString(selectedLabelKey);

  @override
  Future<void> saveSelectedLabelId(String? id) async {
    if (id == null) {
      await _preferences.remove(selectedLabelKey);
    } else {
      await _preferences.setString(selectedLabelKey, id);
    }
  }

  @override
  Future<DailyGoal> loadDailyGoal() async {
    final stored = _preferences.getString(dailyGoalKey);
    if (stored == null) return const DailyGoal();
    return switch (jsonDecode(stored)) {
      {'v': _version, 'minutes': final int minutes} => DailyGoal.validated(
        minutes,
      ),
      _ => throw FormatException('Unknown daily goal: $stored'),
    };
  }

  @override
  Future<void> saveDailyGoal(DailyGoal goal) async {
    await _preferences.setString(
      dailyGoalKey,
      jsonEncode({'v': _version, 'minutes': goal.minutes}),
    );
  }

  @override
  Future<bool> loadShowOnLockScreen() async =>
      _preferences.getBool(lockScreenKey) ?? true;

  @override
  Future<void> saveShowOnLockScreen(bool show) async {
    await _preferences.setBool(lockScreenKey, show);
  }
}
