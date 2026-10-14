import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/ambient.dart';
import '../domain/blocking.dart';
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
  static const mindfulKey = 'settings.mindful.v1';
  static const mindfulPauseKey = 'settings.mindfulPause.v1';
  static const ambientKey = 'settings.ambient.v1';
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

  @override
  Future<bool> loadMindfulOpening() async =>
      _preferences.getBool(mindfulKey) ?? false;

  @override
  Future<void> saveMindfulOpening(bool on) async {
    await _preferences.setBool(mindfulKey, on);
  }

  @override
  Future<Duration> loadMindfulPause() async {
    final pause = Duration(seconds: _preferences.getInt(mindfulPauseKey) ?? 0);
    return mindfulPauseOptions.contains(pause) ? pause : mindfulPause;
  }

  @override
  Future<void> saveMindfulPause(Duration pause) async {
    if (!mindfulPauseOptions.contains(pause)) {
      throw ArgumentError.value(pause, 'pause', 'is not a pause option');
    }
    await _preferences.setInt(mindfulPauseKey, pause.inSeconds);
  }

  @override
  Future<AmbientChoice> loadAmbient() async {
    final stored = _preferences.getString(ambientKey);
    if (stored == null) return AmbientChoice.initial;
    return switch (jsonDecode(stored)) {
      {'v': _version, 'sound': final String sound, 'volume': final num volume}
          when volume >= 0 && volume <= 1 =>
        AmbientChoice(
          sound: AmbientSound.values.asNameMap()[sound] ?? AmbientSound.off,
          volume: volume.toDouble(),
        ),
      _ => AmbientChoice.initial,
    };
  }

  @override
  Future<void> saveAmbient(AmbientChoice choice) async {
    await _preferences.setString(
      ambientKey,
      jsonEncode({
        'v': _version,
        'sound': choice.sound.name,
        'volume': choice.volume,
      }),
    );
  }
}
