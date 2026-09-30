import 'clock.dart';
import 'daily_goal.dart';
import 'document_store.dart';
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

/// Turns a [Backup] into file text and back; throws [FormatException] for
/// text that is not a valid backup.
abstract interface class BackupCodec {
  String encode(Backup backup);

  Backup decode(String text);
}

/// Exports and imports backups as files the user picks.
class BackupFiles {
  BackupFiles({
    required this._service,
    required this._documents,
    required this._codec,
  });

  final BackupService _service;
  final DocumentStore _documents;
  final BackupCodec _codec;

  /// Saves a fresh backup; returns false if the user cancelled.
  Future<bool> export() async {
    final backup = await _service.create();
    return _documents.saveText(
      fileNameFor(backup.createdAt),
      _codec.encode(backup),
    );
  }

  /// Lets the user pick a backup file; null if cancelled. Throws
  /// [FormatException] if the file is not a Focus backup.
  Future<Backup?> pick() async {
    final text = await _documents.openText();
    return text == null ? null : _codec.decode(text);
  }

  Future<void> restore(Backup backup) => _service.restore(backup);

  /// File name like `focus-backup-2026-09-30.json`.
  static String fileNameFor(DateTime createdAt) {
    String two(int value) => value.toString().padLeft(2, '0');
    return 'focus-backup-${createdAt.year}-${two(createdAt.month)}-'
        '${two(createdAt.day)}.json';
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
