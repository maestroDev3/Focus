import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/json_backup_codec.dart';
import 'data/method_channel_document_store.dart';
import 'data/shared_preferences_label_repository.dart';
import 'data/shared_preferences_session_repository.dart';
import 'data/shared_preferences_settings_repository.dart';
import 'domain/backup.dart';
import 'domain/focus_timer.dart';
import 'ui/focus_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final sessions = SharedPreferencesSessionRepository(preferences);
  final settings = SharedPreferencesSettingsRepository(preferences);
  final labels = SharedPreferencesLabelRepository(preferences);
  final timer = FocusTimer(repository: sessions, clock: DateTime.now);
  runApp(
    FocusApp(
      showIntro: true,
      timer: timer,
      settings: settings,
      labels: labels,
      backupFiles: BackupFiles(
        service: BackupService(
          sessions: sessions,
          labels: labels,
          settings: settings,
          clock: DateTime.now,
        ),
        documents: const MethodChannelDocumentStore(),
        codec: const JsonBackupCodec(),
      ),
    ),
  );
}
