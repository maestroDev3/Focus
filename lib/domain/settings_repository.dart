import 'pomodoro.dart';

/// Stores the user's settings.
abstract interface class SettingsRepository {
  /// The saved Pomodoro rhythm, or the defaults if none was saved.
  Future<PomodoroSettings> loadPomodoro();

  Future<void> savePomodoro(PomodoroSettings settings);

  /// Id of the label chosen for the next session, or null.
  Future<String?> loadSelectedLabelId();

  Future<void> saveSelectedLabelId(String? id);
}
