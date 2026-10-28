import 'ambient.dart';
import 'background_style.dart';
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

  /// Whether the countdown may be promoted to an Android 16 Live Update
  /// (status bar chip; the notification then uses the system template).
  /// Off by default: the large remaining time wins (decision 2026-10-27).
  Future<bool> loadLiveUpdate();

  Future<void> saveLiveUpdate(bool on);

  /// Whether paused apps open after a breathing pause outside sessions and
  /// focus times; off unless switched on.
  Future<bool> loadMindfulOpening();

  Future<void> saveMindfulOpening(bool on);

  /// How long the breathing pause lasts: one of `mindfulPauseOptions`,
  /// `mindfulPause` unless chosen otherwise.
  Future<Duration> loadMindfulPause();

  Future<void> saveMindfulPause(Duration pause);

  /// The ambient sound and volume; [AmbientChoice.initial] until chosen.
  Future<AmbientChoice> loadAmbient();

  Future<void> saveAmbient(AmbientChoice choice);

  /// The background behind the main screens; [BackgroundStyle.initial]
  /// until chosen.
  Future<BackgroundStyle> loadBackground();

  Future<void> saveBackground(BackgroundStyle style);
}
