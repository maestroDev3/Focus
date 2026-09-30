import 'package:focus_timer/data/json_backup_codec.dart';
import 'package:focus_timer/domain/backup.dart';

import 'fake_document_store.dart';
import 'fake_label_repository.dart';
import 'fake_session_repository.dart';
import 'fake_settings_repository.dart';

/// [BackupFiles] wired to fakes, for widget tests.
BackupFiles backupFilesForTests({
  required FakeSessionRepository sessions,
  required FakeLabelRepository labels,
  required FakeSettingsRepository settings,
  required FakeDocumentStore documents,
  DateTime Function()? clock,
}) {
  return BackupFiles(
    service: BackupService(
      sessions: sessions,
      labels: labels,
      settings: settings,
      clock: clock ?? () => DateTime(2026, 9, 30, 21),
    ),
    documents: documents,
    codec: const JsonBackupCodec(),
  );
}
