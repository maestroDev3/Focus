import '../domain/backup.dart';
import '../domain/daily_goal.dart';
import '../domain/focus_label.dart';
import '../domain/pomodoro.dart';
import 'session_codec.dart';

/// Version of the backup file format.
const backupFormatVersion = 1;

/// Converts [backup] into one JSON document.
Map<String, Object?> encodeBackup(Backup backup) => {
  'focusBackup': backupFormatVersion,
  'createdAt': backup.createdAt.microsecondsSinceEpoch,
  'sessions': [for (final session in backup.sessions) encodeSession(session)],
  'labels': [
    for (final label in backup.labels) {'id': label.id, 'name': label.name},
  ],
  'pomodoro': {
    'focusMinutes': backup.pomodoro.focus.inMinutes,
    'shortBreakMinutes': backup.pomodoro.shortBreak.inMinutes,
    'longBreakMinutes': backup.pomodoro.longBreak.inMinutes,
    'sessionsBeforeLongBreak': backup.pomodoro.sessionsBeforeLongBreak,
  },
  'dailyGoalMinutes': backup.dailyGoal.minutes,
};

/// Reads a document written by [encodeBackup]; anything else – unknown
/// versions, missing or malformed fields – throws [FormatException].
Backup decodeBackup(Map<String, Object?> json) {
  if (json['focusBackup'] != backupFormatVersion) {
    throw const FormatException('This is not a supported Focus backup.');
  }
  try {
    return switch (json) {
      {
        'createdAt': final int createdAt,
        'sessions': final List<Object?> sessions,
        'labels': final List<Object?> labels,
        'pomodoro': {
          'focusMinutes': final int focus,
          'shortBreakMinutes': final int shortBreak,
          'longBreakMinutes': final int longBreak,
          'sessionsBeforeLongBreak': final int sessionsBeforeLongBreak,
        },
        'dailyGoalMinutes': final int dailyGoalMinutes,
      } =>
        Backup(
          createdAt: DateTime.fromMicrosecondsSinceEpoch(createdAt),
          sessions: [
            for (final session in sessions)
              decodeSession(session as Map<String, Object?>),
          ],
          labels: [
            for (final label in labels)
              switch (label) {
                {'id': final String id, 'name': final String name} =>
                  FocusLabel(id: id, name: name),
                _ => throw FormatException('Malformed label: $label'),
              },
          ],
          pomodoro: PomodoroSettings(
            focus: Duration(minutes: focus),
            shortBreak: Duration(minutes: shortBreak),
            longBreak: Duration(minutes: longBreak),
            sessionsBeforeLongBreak: sessionsBeforeLongBreak,
          ).validate(),
          dailyGoal: DailyGoal.validated(dailyGoalMinutes),
        ),
      _ => throw const FormatException('The backup is incomplete.'),
    };
  } on TypeError catch (error) {
    throw FormatException('Malformed backup: $error');
  } on ArgumentError catch (error) {
    throw FormatException('Invalid backup values: $error');
  }
}
