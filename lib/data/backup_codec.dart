import '../domain/backup.dart';
import '../domain/blocking.dart';
import '../domain/daily_goal.dart';
import '../domain/focus_label.dart';
import '../domain/focus_time.dart';
import '../domain/focus_time_repository.dart';
import '../domain/named_block_list.dart';
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
  // Optional since #96; older backups have no blocking data.
  if (backup.blocking case final blocking?)
    'blocking': _encodeBlocking(blocking),
};

Map<String, Object?> _encodeBlocking(BlockingBackup blocking) => {
  'defaultList': blocking.defaultList.packageNames.toList()..sort(),
  'lists': [
    for (final list in blocking.lists)
      {
        'id': list.id,
        'name': list.name,
        'packages': list.apps.packageNames.toList()..sort(),
      },
  ],
  'focusTimes': [
    for (final time in blocking.focusTimes)
      {
        'id': time.id,
        'weekdays': time.weekdays.toList()..sort(),
        'start': time.startMinute,
        'end': time.endMinute,
        'blockList': ?time.blockListId,
      },
  ],
};

BlockingBackup? _decodeBlocking(Object? json) {
  if (json == null) return null;
  final blocking = switch (json) {
    {
      'defaultList': final List<Object?> defaultList,
      'lists': final List<Object?> lists,
      'focusTimes': final List<Object?> times,
    } =>
      BlockingBackup(
        defaultList: BlockList(defaultList.cast<String>().toSet()),
        lists: [
          for (final item in lists)
            switch (item) {
              {
                'id': final String id,
                'name': final String name,
                'packages': final List<Object?> packages,
              } =>
                NamedBlockList(
                  id: id,
                  name: name,
                  apps: BlockList(packages.cast<String>().toSet()),
                ),
              _ => throw FormatException('Malformed block list: $item'),
            },
        ],
        focusTimes: [
          for (final item in times)
            switch (item) {
              {
                'id': final String id,
                'weekdays': final List<Object?> weekdays,
                'start': final int start,
                'end': final int end,
              } =>
                FocusTime(
                  id: id,
                  weekdays: weekdays.cast<int>().toSet(),
                  startMinute: start,
                  endMinute: end,
                  blockListId: (item as Map)['blockList'] as String?,
                ),
              _ => throw FormatException('Malformed focus time: $item'),
            },
        ],
      ),
    _ => throw const FormatException('Malformed blocking data.'),
  };
  final listIds = {for (final list in blocking.lists) list.id};
  for (final (index, time) in blocking.focusTimes.indexed) {
    if (time.blockListId case final id? when !listIds.contains(id)) {
      throw FormatException('Focus time ${time.id} uses unknown list $id.');
    }
    checkNoOverlap(blocking.focusTimes.sublist(0, index), time);
  }
  return blocking;
}

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
          blocking: _decodeBlocking(json['blocking']),
        ),
      _ => throw const FormatException('The backup is incomplete.'),
    };
  } on TypeError catch (error) {
    throw FormatException('Malformed backup: $error');
  } on ArgumentError catch (error) {
    throw FormatException('Invalid backup values: $error');
  }
}
