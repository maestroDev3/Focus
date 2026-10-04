import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/json_backup_codec.dart';
import 'data/method_channel_app_blocker.dart';
import 'data/method_channel_app_language_setting.dart';
import 'data/method_channel_document_store.dart';
import 'data/method_channel_focus_time_reminders.dart';
import 'data/method_channel_home_widget_bridge.dart';
import 'data/method_channel_installed_apps_source.dart';
import 'data/method_channel_session_countdown.dart';
import 'data/method_channel_session_end_alarm.dart';
import 'data/shared_preferences_block_list_repository.dart';
import 'data/shared_preferences_blocking_state_writer.dart';
import 'data/shared_preferences_focus_time_repository.dart';
import 'data/shared_preferences_label_repository.dart';
import 'data/shared_preferences_named_block_list_repository.dart';
import 'data/shared_preferences_session_repository.dart';
import 'data/shared_preferences_settings_repository.dart';
import 'domain/app_language.dart';
import 'domain/backup.dart';
import 'domain/blocking.dart';
import 'domain/focus_timer.dart';
import 'l10n/app_localizations.dart';
import 'ui/app_locale.dart';
import 'ui/focus_app.dart';
import 'ui/focus_time_text.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final sessions = SharedPreferencesSessionRepository(preferences);
  final settings = SharedPreferencesSettingsRepository(preferences);
  final labels = SharedPreferencesLabelRepository(preferences);
  final blockList = SharedPreferencesBlockListRepository(preferences);
  final focusTimes = SharedPreferencesFocusTimeRepository(preferences);
  final namedBlockLists = SharedPreferencesNamedBlockListRepository(
    preferences,
  );
  const languageSetting = MethodChannelAppLanguageSetting();
  var language = AppLanguage.system;
  try {
    language = await languageSetting.load();
  } on PlatformException {
    // Unknown language state: follow the phone.
  }
  // Texts for native notifications and the widget, looked up when they are
  // sent, so a language chosen in the settings applies right away.
  AppLocalizations l10n() => localizationsFor(language);
  final timer = FocusTimer(
    repository: sessions,
    clock: DateTime.now,
    blocking: BlockingSync(
      blockList: blockList,
      writer: SharedPreferencesBlockingStateWriter(preferences),
      clock: DateTime.now,
      focusTimes: focusTimes,
      namedLists: namedBlockLists,
    ),
    sessionEndAlarm: MethodChannelSessionEndAlarm(
      texts: () => (
        channelName: l10n().sessionEndChannel,
        title: l10n().sessionEndTitle,
        body: l10n().sessionEndBody,
      ),
    ),
    countdown: MethodChannelSessionCountdown(
      texts: () => (
        channelName: l10n().countdownChannel,
        focusing: l10n().countdownFocusing,
        focusingWithLabel: l10n().countdownFocusingWithLabel('{label}'),
        paused: l10n().countdownPaused('{time}'),
      ),
    ),
    labels: labels,
  );
  runApp(
    FocusApp(
      showIntro: true,
      language: languageSetting,
      onLanguageChanged: (chosen) => language = chosen,
      timer: timer,
      settings: settings,
      labels: labels,
      backupFiles: BackupFiles(
        service: BackupService(
          sessions: sessions,
          labels: labels,
          settings: settings,
          blockList: blockList,
          namedLists: namedBlockLists,
          focusTimes: focusTimes,
          clock: DateTime.now,
        ),
        documents: const MethodChannelDocumentStore(),
        codec: const JsonBackupCodec(),
      ),
      blockList: blockList,
      namedBlockLists: namedBlockLists,
      installedApps: const MethodChannelInstalledAppsSource(),
      appBlocker: MethodChannelAppBlocker(),
      focusTimes: focusTimes,
      reminders: MethodChannelFocusTimeReminders(),
      homeWidget: MethodChannelHomeWidgetBridge(
        texts: () => (
          start: l10n().widgetStart,
          progress: l10n().widgetProgress('{today}', '{goal}'),
          focusing: l10n().countdownFocusing,
          focusingWithLabel: l10n().countdownFocusingWithLabel('{label}'),
          countdownChannel: l10n().countdownChannel,
        ),
        formatDuration: (duration) => focusTimeText(l10n(), duration),
      ),
    ),
  );
}
