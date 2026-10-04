import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/backup_codec.dart';
import 'package:focus_timer/domain/backup.dart';
import 'package:focus_timer/domain/blocking.dart';
import 'package:focus_timer/domain/daily_goal.dart';
import 'package:focus_timer/domain/focus_label.dart';
import 'package:focus_timer/domain/focus_time.dart';
import 'package:focus_timer/domain/named_block_list.dart';
import 'package:focus_timer/domain/pomodoro.dart';

import '../support/sample_sessions.dart';

void main() {
  final backup = Backup(
    createdAt: DateTime(2026, 9, 30, 21),
    sessions: [completedSample(), cancelledSample()],
    labels: [FocusLabel(id: 'label-1', name: 'Study')],
    pomodoro: const PomodoroSettings(focus: Duration(minutes: 50)),
    dailyGoal: DailyGoal.validated(180),
  );

  final blocking = BlockingBackup(
    defaultList: const BlockList({'com.instagram.android', 'org.telegram'}),
    lists: [
      NamedBlockList(
        id: 'list-1',
        name: 'Morning',
        apps: const BlockList({'com.whatsapp'}),
      ),
    ],
    focusTimes: [
      FocusTime(
        id: 'focus-time-1',
        weekdays: const {1, 2, 3, 4, 5},
        startMinute: 480,
        endMinute: 720,
        blockListId: 'list-1',
      ),
      FocusTime(
        id: 'focus-time-2',
        weekdays: const {1, 2, 3, 4, 5},
        startMinute: 1020,
        endMinute: 1260,
      ),
    ],
  );
  Backup withBlocking() => Backup(
    createdAt: backup.createdAt,
    sessions: backup.sessions,
    labels: backup.labels,
    pomodoro: backup.pomodoro,
    dailyGoal: backup.dailyGoal,
    blocking: blocking,
  );

  group('backup codec', () {
    test('round-trips block lists and focus times', () {
      final full = withBlocking();

      expect(decodeBackup(encodeBackup(full)), full);
    });

    test('reads a backup without blocking data, e.g. an older one', () {
      final json = encodeBackup(withBlocking())..remove('blocking');

      expect(decodeBackup(json).blocking, isNull);
    });

    test('rejects a focus time with an unknown block list', () {
      final json = encodeBackup(withBlocking());
      ((json['blocking']! as Map)['lists'] as List).clear();

      expect(() => decodeBackup(json), throwsFormatException);
    });

    test('rejects overlapping focus times', () {
      final json = encodeBackup(withBlocking());
      final times = (json['blocking']! as Map)['focusTimes'] as List;
      (times[1] as Map)['start'] = 600;

      expect(() => decodeBackup(json), throwsFormatException);
    });

    test('round-trips a backup', () {
      expect(decodeBackup(encodeBackup(backup)), backup);
    });

    test('rejects an unknown version', () {
      final json = encodeBackup(backup)..['focusBackup'] = 2;

      expect(() => decodeBackup(json), throwsFormatException);
    });

    test('rejects missing fields', () {
      final json = encodeBackup(backup)..remove('labels');

      expect(() => decodeBackup(json), throwsFormatException);
    });

    test('rejects data that is not a Focus backup', () {
      expect(() => decodeBackup({'hello': 'world'}), throwsFormatException);
    });
  });
}
