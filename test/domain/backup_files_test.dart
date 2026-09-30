import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/json_backup_codec.dart';
import 'package:focus_timer/domain/backup.dart';
import 'package:focus_timer/domain/daily_goal.dart';
import 'package:focus_timer/domain/pomodoro.dart';

import '../support/backup_files_for_tests.dart';
import '../support/fake_document_store.dart';
import '../support/fake_label_repository.dart';
import '../support/fake_session_repository.dart';
import '../support/fake_settings_repository.dart';
import '../support/sample_sessions.dart';

void main() {
  late FakeDocumentStore documents;
  late BackupFiles files;

  setUp(() {
    documents = FakeDocumentStore();
    files = backupFilesForTests(
      sessions: FakeSessionRepository()..finished.add(completedSample()),
      labels: FakeLabelRepository(),
      settings: FakeSettingsRepository(),
      documents: documents,
    );
  });

  group('BackupFiles', () {
    test('exports the backup as a dated JSON file', () async {
      expect(await files.export(), isTrue);

      expect(documents.savedName, 'focus-backup-2026-09-30.json');
      final saved = const JsonBackupCodec().decode(documents.savedText ?? '');
      expect(saved.sessions, [completedSample()]);
    });

    test('reads a picked backup file', () async {
      documents.textToOpen = const JsonBackupCodec().encode(
        Backup(
          createdAt: DateTime(2026, 9, 29),
          sessions: [cancelledSample()],
          labels: const [],
          pomodoro: const PomodoroSettings(),
          dailyGoal: const DailyGoal(),
        ),
      );

      final backup = await files.pick();

      expect(backup?.sessions, [cancelledSample()]);
    });

    test('returns null when the picker was cancelled', () async {
      expect(await files.pick(), isNull);
    });

    test('rejects a file that is not a Focus backup', () async {
      documents.textToOpen = 'not json at all';

      expect(files.pick(), throwsFormatException);
    });
  });
}
