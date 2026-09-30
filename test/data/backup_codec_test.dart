import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/backup_codec.dart';
import 'package:focus_timer/domain/backup.dart';
import 'package:focus_timer/domain/daily_goal.dart';
import 'package:focus_timer/domain/focus_label.dart';
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

  group('backup codec', () {
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
