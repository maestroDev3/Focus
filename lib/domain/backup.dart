import 'clock.dart';
import 'daily_goal.dart';
import 'focus_label.dart';
import 'focus_session.dart';
import 'label_repository.dart';
import 'pomodoro.dart';
import 'session_repository.dart';
import 'settings_repository.dart';

/// Everything needed to restore Focus on another phone.
class Backup {
  const Backup({
    required this.createdAt,
    required this.sessions,
    required this.labels,
    required this.pomodoro,
    required this.dailyGoal,
  });

  final DateTime createdAt;
  final List<FocusSession> sessions;
  final List<FocusLabel> labels;
  final PomodoroSettings pomodoro;
  final DailyGoal dailyGoal;

  @override
  bool operator ==(Object other) =>
      other is Backup &&
      other.createdAt == createdAt &&
      _listEquals(other.sessions, sessions) &&
      _listEquals(other.labels, labels) &&
      other.pomodoro == pomodoro &&
      other.dailyGoal == dailyGoal;

  @override
  int get hashCode => Object.hash(
    createdAt,
    Object.hashAll(sessions),
    Object.hashAll(labels),
    pomodoro,
    dailyGoal,
  );
}

/// Collects all data into a [Backup] and restores one by replacing the data.
class BackupService {
  BackupService({
    required this._sessions,
    required this._labels,
    required this._settings,
    required this._clock,
  });

  final SessionRepository _sessions;
  final LabelRepository _labels;
  final SettingsRepository _settings;
  final Clock _clock;

  Future<Backup> create() async => Backup(
    createdAt: _clock(),
    sessions: await _sessions.watchFinished().first,
    labels: await _labels.watchLabels().first,
    pomodoro: await _settings.loadPomodoro(),
    dailyGoal: await _settings.loadDailyGoal(),
  );

  /// Replaces sessions, labels and settings with the content of [backup].
  Future<void> restore(Backup backup) async {
    await _sessions.replaceFinished(backup.sessions);
    await _labels.replaceAll(backup.labels);
    await _settings.savePomodoro(backup.pomodoro);
    await _settings.saveDailyGoal(backup.dailyGoal);
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
