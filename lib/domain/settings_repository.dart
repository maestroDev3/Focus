import 'daily_goal.dart';
import 'pomodoro.dart';

/// Stores the user's settings.
abstract interface class SettingsRepository {
  /// The saved Pomodoro rhythm, or the defaults if none was saved.
  Future<PomodoroSettings> loadPomodoro();

  Future<void> savePomodoro(PomodoroSettings settings);

  /// Id of the label chosen for the next session, or null.
  Future<String?> loadSelectedLabelId();

  Future<void> saveSelectedLabelId(String? id);

  /// The saved daily focus goal, or the default of 120 minutes.
  Future<DailyGoal> loadDailyGoal();

  Future<void> saveDailyGoal(DailyGoal goal);

  /// Whether the countdown shows its label and time on the lock screen;
  /// on unless switched off.
  Future<bool> loadShowOnLockScreen();

  Future<void> saveShowOnLockScreen(bool show);
}
