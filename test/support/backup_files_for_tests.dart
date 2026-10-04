import 'package:focus_timer/data/json_backup_codec.dart';
import 'package:focus_timer/domain/backup.dart';

import 'fake_block_list_repository.dart';
import 'fake_document_store.dart';
import 'fake_focus_time_repository.dart';
import 'fake_label_repository.dart';
import 'fake_named_block_list_repository.dart';
import 'fake_session_repository.dart';
import 'fake_settings_repository.dart';

/// [BackupFiles] wired to fakes, for widget tests.
BackupFiles backupFilesForTests({
  required FakeSessionRepository sessions,
  required FakeLabelRepository labels,
  required FakeSettingsRepository settings,
  required FakeDocumentStore documents,
  DateTime Function()? clock,
  FakeBlockListRepository? blockList,
  FakeNamedBlockListRepository? namedLists,
  FakeFocusTimeRepository? focusTimes,
}) {
  return BackupFiles(
    service: BackupService(
      sessions: sessions,
      labels: labels,
      settings: settings,
      blockList: blockList ?? FakeBlockListRepository(),
      namedLists: namedLists ?? FakeNamedBlockListRepository(),
      focusTimes: focusTimes ?? FakeFocusTimeRepository(),
      clock: clock ?? () => DateTime(2026, 9, 30, 21),
    ),
    documents: documents,
    codec: const JsonBackupCodec(),
  );
}
