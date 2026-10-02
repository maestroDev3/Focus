import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/json_backup_codec.dart';
import 'data/method_channel_app_blocker.dart';
import 'data/method_channel_document_store.dart';
import 'data/method_channel_focus_time_reminders.dart';
import 'data/method_channel_installed_apps_source.dart';
import 'data/method_channel_session_end_alarm.dart';
import 'data/shared_preferences_block_list_repository.dart';
import 'data/shared_preferences_blocking_state_writer.dart';
import 'data/shared_preferences_focus_time_repository.dart';
import 'data/shared_preferences_label_repository.dart';
import 'data/shared_preferences_session_repository.dart';
import 'data/shared_preferences_settings_repository.dart';
import 'domain/backup.dart';
import 'domain/blocking.dart';
import 'domain/focus_timer.dart';
import 'l10n/app_localizations.dart';
import 'ui/focus_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final sessions = SharedPreferencesSessionRepository(preferences);
  final settings = SharedPreferencesSettingsRepository(preferences);
  final labels = SharedPreferencesLabelRepository(preferences);
  final blockList = SharedPreferencesBlockListRepository(preferences);
  final focusTimes = SharedPreferencesFocusTimeRepository(preferences);
  final l10n = lookupAppLocalizations(
    basicLocaleListResolution(
      WidgetsBinding.instance.platformDispatcher.locales,
      AppLocalizations.supportedLocales,
    ),
  );
  final timer = FocusTimer(
    repository: sessions,
    clock: DateTime.now,
    blocking: BlockingSync(
      blockList: blockList,
      writer: SharedPreferencesBlockingStateWriter(preferences),
      clock: DateTime.now,
      focusTimes: focusTimes,
    ),
    sessionEndAlarm: MethodChannelSessionEndAlarm(
      texts: (
        channelName: l10n.sessionEndChannel,
        title: l10n.sessionEndTitle,
        body: l10n.sessionEndBody,
      ),
    ),
  );
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
      blockList: blockList,
      installedApps: const MethodChannelInstalledAppsSource(),
      appBlocker: MethodChannelAppBlocker(),
      focusTimes: focusTimes,
      reminders: MethodChannelFocusTimeReminders(),
    ),
  );
}
